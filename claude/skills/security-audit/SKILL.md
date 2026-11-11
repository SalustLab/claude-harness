---
name: security-audit
description: Risk-based security audit of a change or component - traces attacker-controlled input through data flow, validation and framework protections, reports only confirmed exploitable findings (injection, XSS, authn/authz, IDOR, path traversal, SSRF, uploads, deserialization, secrets, data exposure, dependencies, trust boundaries). Use on request, or when a change touches a sensitive surface (auth, permissions, input reaching SQL/shell/HTML/paths/URLs, uploads, parsing, secrets, external integrations); PT - "auditoria de seguranca", "revisa a seguranca", "tem vulnerabilidade?", "OWASP". Works on Git and SVN diffs. Local alias of the upstream security-review skill; the built-in /security-review command stays available. Not for trivial changes without a sensitive surface or for exploit development against systems the user does not own.
license: LICENSE
metadata:
  short-description: Data-flow security audit with high-confidence findings
  source: getsentry/skills security-review @e94f222 (Apache-2.0; references from OWASP Cheat Sheets, CC BY-SA 4.0), adapted 2026-11-11
---

<!--
Reference material based on OWASP Cheat Sheet Series (CC BY-SA 4.0)
https://cheatsheetseries.owasp.org/
-->

# Security Audit

Identify exploitable security vulnerabilities in code. Report only **HIGH CONFIDENCE** findings: a vulnerable pattern with attacker-controlled input confirmed through the data flow.

## When to Run

- On explicit request ("auditoria de segurança", "security review", "OWASP").
- When the router, `diff-review` or `release-readiness` sees a **sensitive surface** in the change: authentication, sessions, permissions/roles, multi-tenant filtering, input reaching SQL/shell/HTML/file paths/URLs/redirects, uploads/downloads, deserialization or parsing of external data, secrets/tokens/credentials/config, crypto, logging of personal data, new dependencies or CI/build changes, external integrations (APIs, webhooks, queues).
- Depth follows risk, not file count: a one-line change to a login query deserves an audit; a 30-file CSS refactor does not.
- Reuse: if an audit of the same scope exists and nothing in that scope changed since, cite it instead of re-running.

## Scope: Research vs. Reporting

- **Report on**: only the files, diff or component in scope.
- **Research**: the whole codebase, to build confidence before reporting.

Pin the scope first. If the user named files or a component, use them. For a change, detect the VCS (`git rev-parse --show-toplevel`, then `svn info --show-item wc-root`; the innermost root wins) and read the diff with read-only commands only:

| Scope | Git | SVN |
| --- | --- | --- |
| Uncommitted work | `git status --short` + `git diff HEAD` | `svn status` + `svn diff` |
| Since a baseline | `git diff <base>...HEAD` | `svn diff -r <base>` (includes local changes) or `svn diff -r <a>:<b>` |
| One commit/revision | `git show <sha>` | `svn diff -c <rev>` + `svn log -v -c <rev>` |

Never run Git commands in an SVN working copy or vice versa. Never change files, branches or the working copy during an audit.

Before flagging any issue, research:

- Where does this input actually come from? (Trace the data flow.)
- Is there validation/sanitization elsewhere?
- How is this configured? (Settings, config files, middleware.)
- What framework protections exist?

**Do not report issues based solely on pattern matching.** Investigate first, then report only what you're confident is exploitable.

## Confidence Levels

| Level | Criteria | Action |
| --- | --- | --- |
| **HIGH** | Vulnerable pattern + attacker-controlled input confirmed | **Report** with severity |
| **MEDIUM** | Vulnerable pattern, input source unclear | **Note** as "Needs verification" |
| **LOW** | Theoretical, best practice, defense-in-depth | **Do not report** |

## Do Not Flag

### General Rules
- Test files (unless explicitly reviewing test security)
- Dead code, commented code, documentation strings
- Patterns using **constants** or **server-controlled configuration**
- Code paths that require prior authentication to reach (note the auth requirement instead)

### Server-Controlled Values (NOT Attacker-Controlled)

| Source | Example | Why It's Safe |
| --- | --- | --- |
| Django settings | `settings.API_URL`, `settings.ALLOWED_HOSTS` | Set via config/env at deployment |
| .NET configuration | `IConfiguration["X"]`, `ConfigurationManager.AppSettings["X"]`, `Web.config` | Server-side configuration |
| Environment variables | `os.environ.get('DATABASE_URL')` | Deployment configuration |
| Config files | `config.yaml`, `app.config['KEY']`, `appsettings.json` | Server-side files |
| Hardcoded values | `BASE_URL = "https://api.internal"` | Compile-time constants |

**SSRF example, NOT a vulnerability:** `requests.get(f"{settings.SEER_AUTOFIX_URL}{path}")` (URL from settings).
**SSRF example, IS a vulnerability:** `requests.get(request.GET.get('url'))` (URL from the request).

### Framework-Mitigated Patterns

| Pattern | Why It's Usually Safe |
| --- | --- |
| Django `{{ variable }}`, Vue `{{ variable }}`, React `{variable}` | Auto-escaped by default |
| Razor `@variable`, Blazor `@variable`, Web Forms `<%: variable %>` | HTML-encoded by default |
| `User.objects.filter(id=input)`, EF Core LINQ | ORM parameterizes queries |
| `cursor.execute("...%s", (input,))`, `SqlCommand` + `Parameters` | Parameterized query |
| EF Core `FromSql($"...{x}")` / `ExecuteSql($"...")` | Interpolated values become parameters |
| `innerHTML = "<b>Loading...</b>"` | Constant string, no user input |

**Only flag these when:**
- Django: `{{ var|safe }}`, `{% autoescape off %}`, `mark_safe(user_input)`
- React: `dangerouslySetInnerHTML={{__html: userInput}}`; Vue: `v-html="userInput"`
- Razor/Blazor/Web Forms: `Html.Raw`, `HtmlString`, `MarkupString`, `<%= %>`, `Label.Text`/`Literal` without encoding
- ORM: `.raw()`, `.extra()`, `RawSQL()`, EF Core `FromSqlRaw`/`ExecuteSqlRaw`/`SqlQueryRaw` with string interpolation or concatenation

## Review Process

### 1. Detect Context

| Code Type | Load These References |
| --- | --- |
| API endpoints, routes, controllers, handlers | `references/authorization.md`, `references/authentication.md`, `references/injection.md` |
| Frontend, templates, Razor/Blazor/Web Forms pages | `references/xss.md`, `references/csrf.md`, `references/modern-threats.md` |
| File handling, uploads, downloads | `references/file-security.md` |
| Crypto, secrets, tokens | `references/cryptography.md`, `references/data-protection.md` |
| Data serialization, ViewState | `references/deserialization.md` |
| External requests, webhooks | `references/ssrf.md` |
| Business workflows | `references/business-logic.md` |
| GraphQL, REST design | `references/api-security.md` |
| Config, headers, CORS | `references/misconfiguration.md` |
| Error handling | `references/error-handling.md` |
| Audit, logging | `references/logging.md` |
| Object merging/cloning, `__proto__`, DOM `id`/`name` lookups, WebSocket handlers, LLM prompt construction | `references/modern-threats.md` |
| Dependencies, lockfiles, CI/CD, build scripts | Dependencies checklist below (upstream `supply-chain.md` is referenced by the source skill but not shipped) |

### 2. Load Language Guide

| Indicators | Guide |
| --- | --- |
| `.py`, `django`, `flask`, `fastapi` | `languages/python.md` |
| `.js`, `.ts`, `express`, `react`, `vue`, `next` | `languages/javascript.md` |
| `.cs`, `.vb`, `.aspx`, `.ascx`, `.ashx`, `.cshtml`, `.razor`, `Web.config`, `appsettings.json`, EF Core | `languages/dotnet.md` |

For other languages, rely on the `references/` files and verify framework protections directly in the codebase.

### 3. Load Infrastructure Guide (if applicable)

| File Type | Guide |
| --- | --- |
| `Dockerfile`, `.dockerignore`, compose files | `infrastructure/docker.md` |

### Dependencies checklist (no bundled reference)

- New or upgraded packages: is each one needed, maintained, from the official registry, pinned by the lockfile?
- Install scripts (`postinstall`, MSBuild targets) and binaries committed to the repo.
- Known-vulnerability data: use `npm audit --omit=dev`, `dotnet list package --vulnerable` or the ecosystem equivalent only when the tool is already available. These commands read the lockfile and query the public advisory database; they install nothing. Report what you could not run as `NOT_RUN`.
- CI files: secrets exposure, untrusted input in scripts, permissions of tokens.

### 4. Research Before Flagging

For each potential issue, trace where the value comes from, whether it is configured at deployment or user-supplied, what validation/sanitization/allowlisting exists, and which framework protections apply. Only report issues with HIGH confidence after understanding the broader context.

### 5. Verify Exploitability

| Attacker-Controlled (Investigate) | Server-Controlled (Usually Safe) |
| --- | --- |
| `request.GET`, `request.POST`, `request.args`, `Request.QueryString`, `Request.Form` | `settings.X`, `app.config['X']`, `IConfiguration` |
| `request.json`, `request.body`, model-bound parameters | `os.environ.get('X')` |
| `request.headers` (most headers), unsigned cookies | Hardcoded constants |
| URL path segments: `/users/<id>/` | Internal service URLs from config |
| File uploads (content and names) | Database content from admin/system |
| Database content written by other users | Signed session data |
| WebSocket / SignalR messages | Framework settings |

Also ask: does the framework mitigate this (auto-escaping, parameterization, middleware)? Is there validation upstream?

### 6. Report HIGH Confidence Only

Skip theoretical issues. Use the Needs Verification section for MEDIUM confidence.

## Severity Classification

| Severity | Impact | Examples |
| --- | --- | --- |
| **Critical** | Direct exploit, severe impact, no auth required | RCE, SQL injection to data, auth bypass, hardcoded secrets |
| **High** | Exploitable with conditions, significant impact | Stored XSS, SSRF to metadata, IDOR to sensitive data |
| **Medium** | Specific conditions required, moderate impact | Reflected XSS, CSRF on state-changing actions, path traversal |
| **Low** | Defense-in-depth, minimal direct impact | Missing headers, verbose errors, weak algorithms in non-critical context |

## Quick Patterns Reference

### Always Flag (Critical)
```
eval(user_input)           # Any language
pickle.loads(user_data)    # Python
yaml.load(user_data)       # Python (not safe_load)
unserialize($user_data)    # PHP
BinaryFormatter.Deserialize(untrusted)   # .NET (also LosFormatter, ObjectStateFormatter, NetDataContractSerializer)
shell=True + user_input    # Python subprocess
child_process.exec(user)   # Node.js
```

### Always Flag (High)
```
innerHTML = userInput                    # DOM XSS
dangerouslySetInnerHTML={user}           # React XSS
v-html="userInput"                       # Vue XSS
@Html.Raw(userInput) / (MarkupString)x   # Razor / Blazor XSS
f"SELECT * FROM x WHERE {user}"          # SQL injection
"SELECT ... WHERE Id = " + id            # SQL injection (SqlCommand, FromSqlRaw)
os.system(f"cmd {user_input}")           # Command injection
```

### Always Flag (Secrets)
Hard-coded passwords, API keys, cloud keys or private keys in source or committed config. Report the location and type; **never print the secret value** in the report.

### Check Context First (MUST Investigate Before Flagging)
```
requests.get(request.GET['url'])     # FLAG: user-controlled URL (SSRF)
requests.get(settings.API_URL)       # SAFE: server-controlled config
open(request.GET['file'])            # FLAG: user-controlled path
Path.Combine(baseDir, input)         # CHECK: rooted input discards baseDir
redirect(request.GET['next'])        # FLAG: open redirect
hashlib.md5(file_content)            # SAFE: checksum
hashlib.md5(password)                # FLAG: password hashing
random.random() for token            # FLAG: use a CSPRNG
```

## Output Format

```markdown
## Security Audit: [File/Component/Diff]

Scope: [VCS + command, or files] · References loaded: [list]

### Summary
- **Findings**: X (Y Critical, Z High, ...)
- **Risk Level**: Critical/High/Medium/Low
- **Confidence**: High/Mixed

### Findings

#### [VULN-001] [Vulnerability Type] (Severity)
- **Location**: `file.ext:123`
- **Confidence**: High
- **Issue**: [What the vulnerability is]
- **Data flow**: [source → transformations → sink]
- **Impact**: [What an attacker could do]
- **Evidence**: [vulnerable snippet, secrets redacted]
- **Fix**: [How to remediate]

### Needs Verification

#### [VERIFY-001] [Potential Issue]
- **Location**: `file.ext:456`
- **Question**: [What needs to be verified]

### Not Verified
[Checks that could not run (dependency audit, runtime config) and why]
```

If no vulnerabilities are found, state: "No high-confidence vulnerabilities identified." That sentence is a review result, not proof of security.

## Handoffs

- Returns its report to the caller (user, router, `diff-review` or `release-readiness`). It does not invoke other skills and never decides release readiness.
- Fixing findings is a new task routed by `coding-skill-router` (normally `tdd` with a regression test).

## Reference Files

| File | Covers |
| --- | --- |
| `references/injection.md` | SQL, NoSQL, OS command, LDAP, template injection |
| `references/xss.md` | Reflected, stored, DOM-based XSS |
| `references/authorization.md` | Authorization, IDOR, privilege escalation |
| `references/authentication.md` | Sessions, credentials, password storage |
| `references/cryptography.md` | Algorithms, key management, randomness |
| `references/deserialization.md` | Pickle, YAML, Java, PHP deserialization |
| `references/file-security.md` | Path traversal, uploads, XXE |
| `references/ssrf.md` | Server-side request forgery |
| `references/csrf.md` | Cross-site request forgery |
| `references/data-protection.md` | Secrets exposure, PII, logging |
| `references/api-security.md` | REST, GraphQL, mass assignment |
| `references/business-logic.md` | Race conditions, workflow bypass |
| `references/modern-threats.md` | Prototype pollution, LLM injection, WebSocket |
| `references/misconfiguration.md` | Headers, CORS, debug mode, defaults |
| `references/error-handling.md` | Fail-open, information disclosure |
| `references/logging.md` | Audit failures, log injection |
| `languages/python.md` | Django, Flask, FastAPI |
| `languages/javascript.md` | Node, Express, React, Vue, Next.js |
| `languages/dotnet.md` | ASP.NET Web Forms/MVC/Core, Razor, Blazor, EF Core (local addition) |
| `infrastructure/docker.md` | Container security |
