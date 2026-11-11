# claude-harness

My portable development harness for Claude Code: sixteen reusable skills, a small
instruction file and an agent-friendly installer. Clone it, ask your agent to
review and apply it to a project or user profile, and keep your existing setup.

No API keys, paid MCPs, plugins, model presets or permission overrides are
needed. The core installer uses **Python 3.10+ and its standard library** on
Windows, macOS and Linux. Claude Code must be installed separately.

## Install with an agent

```sh
git clone https://github.com/SalustLab/claude-harness.git
cd claude-harness
```

Open this checkout with your agent and send:

> Read AGENTS.md and docs/INSTALL.md. Inspect my existing setup and install this
> harness into the project at `<absolute project path>`. Preview the changes,
> preserve my instructions and skills, apply the conflict-free plan, and verify
> the result. Do not change permissions or install optional integrations.

Em português:

> Leia AGENTS.md e docs/INSTALL.md. Inspecione minha configuração e instale este
> harness no projeto em `<caminho absoluto do projeto>`. Mostre a prévia,
> preserve minhas instruções e skills, aplique o plano sem conflitos e verifique
> o resultado. Não altere permissões nem instale integrações opcionais.

For all projects, ask explicitly for a **user-level installation** instead.
Agents other than Claude can perform the installation; the installed paths and
discovery conventions target Claude Code, not every agent product.

## Install directly

```sh
# Preview only; the target project must already exist.
python scripts/install.py --project /path/to/project

# Apply, then verify. A conflict aborts the whole install without changing files.
python scripts/install.py --project /path/to/project --apply
python scripts/install.py --project /path/to/project --check

# Alternatively, install into the current user's Claude configuration.
python scripts/install.py --user
python scripts/install.py --user --apply
python scripts/install.py --user --check
```

Use quoted paths with spaces. On Windows, `py -3` can replace `python`; on
macOS/Linux the command may be `python3`. `--user` respects `CLAUDE_CONFIG_DIR`;
`--config-dir PATH` provides an explicit override for user scope.

Restart Claude Code and check `/skills`. Read [the installation guide](docs/INSTALL.md)
for collisions, upgrades, backup recovery, removal and optional tools.

## Included workflows

| Skill | Purpose | Original source |
|---|---|---|
| `coding-skill-router` | Select workflows by scope and intent; skip ceremony for mechanical changes. | Original |
| `zoom-out` | Map unfamiliar code, callers and data flow before editing. | [Matt Pocock](https://github.com/mattpocock/skills/blob/ab45d5e6e1733b7ae27a0795f2a86418c2d451a0/zoom-out/SKILL.md) |
| `tdd` | Test observable behavior in small RED/GREEN slices. | [Matt Pocock](https://github.com/mattpocock/skills/tree/main/skills/engineering/tdd) |
| `diagnose` | Reproduce, minimise and investigate an unclear bug. | [Matt Pocock: diagnosing-bugs](https://github.com/mattpocock/skills/tree/main/skills/engineering/diagnosing-bugs) |
| `brainstorming` | Resolve open product/design choices without reopening settled requirements. | [obra/superpowers](https://github.com/obra/superpowers/tree/main/skills/brainstorming) |
| `grill-with-docs` | Stress-test domain decisions and maintain glossaries/ADRs when useful. | [Matt Pocock](https://github.com/mattpocock/skills/tree/main/skills/engineering/grill-with-docs) |
| `improve-codebase-architecture` | Identify grounded structural improvements. | [Matt Pocock](https://github.com/mattpocock/skills/tree/main/skills/engineering/improve-codebase-architecture) |
| `agent-doctor` | Audit agent documentation and navigation. | Original |
| `caveman` | Optional concise communication style, only when requested. | [Julius Brussee](https://github.com/JuliusBrussee/caveman) |
| `diff-review` | Review a diff, commit, branch or revision on two axes: standards and specification. | [Matt Pocock: code-review](https://github.com/mattpocock/skills/tree/4ae2317ddb22/skills/engineering/code-review) |
| `security-audit` | Trace untrusted input on sensitive surfaces and report confirmed vulnerabilities. | [Sentry: security-review](https://github.com/getsentry/skills/tree/e94f22214528/skills/security-review), [OWASP Cheat Sheets](https://cheatsheetseries.owasp.org/) |
| `web-design-guidelines` | Static UI/UX and accessibility review of web interface code. | [Vercel Labs](https://github.com/vercel-labs/agent-skills/tree/1a2c79d4e6c4/skills/web-design-guidelines), [rules](https://github.com/vercel-labs/web-interface-guidelines/tree/434b7f913646) |
| `release-readiness` | Check with evidence whether a task is done and whether changes are ready to deliver. | Original |
| `skill-scanner` | Audit an external skill before importing or updating it. | [Sentry](https://github.com/getsentry/skills/tree/e94f22214528/skills/skill-scanner) |
| `skill-creator` | Create, validate and evaluate skills with this harness's conventions. | [Anthropic](https://github.com/anthropics/skills/tree/2c5958ecac7c/skills/skill-creator) |
| `using-git-worktrees` | Optional isolated Git worktree, only on explicit request. | [obra/superpowers](https://github.com/obra/superpowers/tree/22f0b463e7a5/skills/using-git-worktrees) |

All of the above skills were modified by me to work better together, with this harness.
They're not the same as their original versions.
The harness reuses the project's language, conventions and authorization.
Skills can be selected automatically or invoked explicitly. They are guidance,
not enforcement of permissions or a guarantee of correct agent behavior.

## Recommended MCP servers

The harness works without MCP servers, but two of them pair well with the skills.
They are recommendations only: the installer never adds or configures them.

| MCP | Use it for | Pairs with |
|---|---|---|
| [Context7](https://github.com/upstash/context7) | Current, version-specific documentation for libraries, frameworks, SDKs and CLIs, so decisions do not rely on stale training data. | `tdd`, `diagnose`, `brainstorming`, `zoom-out`, `security-audit` and `diff-review` whenever a change depends on external framework or library behavior. |
| [REA](https://github.com/morluto/rea) | Reverse engineering of native binaries, managed assemblies, Android/Apple apps, web bundles and runtimes, with evidence attached to each result. | `zoom-out` and `diagnose` when the source is missing or incomplete, `security-audit` for compiled dependencies, `skill-scanner` for bundled binaries or minified scripts. |

```sh
claude mcp add --scope user --transport http context7 https://mcp.context7.com/mcp
claude mcp add --scope user rea -- npx -y rea-agents@6.3.0 mcp
```

REA needs Node.js. On native Windows, wrap the command as
`cmd /c npx -y rea-agents@6.3.0 mcp`. Context7 works without a key; an API key
from its dashboard (`--header "CONTEXT7_API_KEY: <key>"`) raises rate limits.
Keep keys in your own configuration, never in this repository. Review each
server's documentation and license before installing, and run reverse
engineering only on artifacts you own or are authorized to analyze.

When a server is unavailable, the router falls back to official documentation,
installed packages and local sources, and reports the lookup as not performed.

## What gets installed

```text
<project>/.claude/          # or the user config directory
  CLAUDE.md                # managed block; existing text stays outside it
  skills/<name>/           # skill instructions, references, helpers and licenses
  .harness-backups/         # only when existing files change; ignored by Git
```

Existing settings, MCPs, hooks, plugins, model choices, credentials and unrelated
skills are left alone. There is no command that snapshots your profile back into
this public repository. Optional visual brainstorming uses bundled Node/Bash
helpers only after user acceptance; the core harness works without them.

## Development

```sh
python -m unittest discover -s tests -p "test_*.py" -v
python scripts/check.py
node tests/test-brainstorming.cjs  # optional companion integration test
```

CI runs installer checks on Windows, macOS and Linux. Local validation does not
replace a Claude Code session check in the recipient's environment.

## Sources and licensing

Original harness code is MIT licensed. Adapted skills retain their upstream MIT
or Apache-2.0 notices. See [ATTRIBUTION.md](ATTRIBUTION.md), [LICENSE](LICENSE) and
[LICENSES/](LICENSES). No third-party plugin is vendored or installed.

Installation paths and discovery follow the official
[skills](https://code.claude.com/docs/en/skills) and
[memory](https://code.claude.com/docs/en/memory) documentation.
