---
name: diff-review
description: Two-axis review of a change - Standards (repo conventions, architecture, maintainability, safety rules) and Spec (requirements, acceptance criteria, docs) - reported separately, each finding with severity, location and evidence, classified as proven bug, plausible risk or suggestion. Works on Git (working tree, commit, branch, range) and SVN (working-copy diff, revision, revision range, branch URL). Use when asked to review a diff, PR, branch, revision or work in progress, and as the review step of release-readiness; PT - "revisa", "faz code review", "revisa o diff", "revisa a revisao 1234", "revisa minhas alteracoes". Local alias of the upstream code-review skill; the built-in /code-review and /review commands stay available. Not for security-only audits (security-audit) or UI guideline audits (web-design-guidelines).
metadata:
  short-description: Standards + Spec review for Git and SVN changes
  source: mattpocock/skills code-review @4ae2317 (MIT), adapted 2026-11-11
  invokes: [security-audit]
---

# Diff Review

Two-axis review of a change against a fixed point:

- **Standards**: does the code conform to this repo's documented standards and the harness rules?
- **Spec**: does the code faithfully implement what the originating request, ticket or spec asked for?

The axes stay separate because a change can pass one and fail the other: code that follows every standard but implements the wrong thing, or code that does exactly what was asked but breaks the project's conventions. Reporting them separately stops one axis from masking the other.

This skill is read-only: it never edits files, commits, switches branches or updates the working copy.

## 1. Pin the scope

Detect the VCS from the working directory (subdirectories included):

```
git rev-parse --show-toplevel          # Git root
svn info --show-item wc-root           # SVN working-copy root (fallback: `svn info`, "Working Copy Root Path:")
```

If both answer, the innermost root (longest path) wins and the other is reported. If neither answers, review only the files or diff the user supplied and say that no VCS was identified. Never run Git commands in an SVN working copy or SVN commands in a Git repository.

Use the fixed point the user gave. Without one, review the uncommitted work. If there is none either, ask which commit/revision/branch to review.

| Scope | Git | SVN |
| --- | --- | --- |
| Uncommitted work (default) | `git status --short`, `git diff HEAD` | `svn status`, `svn diff` |
| Since a fixed point | `git diff <ref>...HEAD` + `git log --oneline <ref>..HEAD` | `svn diff -r <rev>` (rev → working copy, includes local changes) or `svn diff -r <a>:<b>` (repository only) + `svn log -v -r <a>:<b>` |
| One commit / revision | `git show <sha>` | `svn diff -c <rev>` + `svn log -v -c <rev>` |
| Branch vs mainline | `git diff <main>...<branch>` | `svn diff ^/trunk ^/branches/<name>`; commits via `svn log --stop-on-copy -v ^/branches/<name>` |

Validate before reviewing: the ref/revision resolves (`git rev-parse --verify <ref>`, `svn info -r <rev>`) and the diff is non-empty. Untracked (`??`) or unversioned (`?`) files that belong to the change must be read too. Separate files that belong to the change from unrelated pre-existing modifications, and say which ones you excluded.

## 2. Identify the spec source

Look, in order:

1. Text, path or link the user supplied, and requirements already settled in this session (approved plan or design).
2. Ticket/issue identifiers in the branch name, commit or log messages (`#123`, `Closes #45`, `AB#123`, `PROJ-123`). Read the ticket only through a tool that is available and authorized (for example `gh issue view` or an MCP connector). Never guess its contents.
3. Documents in `docs/` (including `docs/specs/`, where `brainstorming` saves approved designs), `specs/` or `.scratch/` matching the branch, feature or ticket.

No spec found: do not block. The Spec axis reports "no spec available" and limits itself to the intent stated in commit/log messages and the request. Ask only when the user explicitly wants a spec review.

## 3. Identify the standards sources

Collect the files that document how code should be written: `CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md`, `CODING_STANDARDS.md`, `.editorconfig`, linter/analyzer configuration, ADRs, `GLOSSARY.md` / `CONTEXT.md`. A documented repo standard always wins over the baselines below. Skip anything tooling already enforces.

**Harness baseline** (from the global instructions), always applied:

- Secrets, credentials or production config in the diff.
- Database and migration safety: unreviewed destructive SQL, unintended cascade delete, data updates without clear filters.
- Diff hygiene: unrelated changes, debug leftovers, commented-out code, blocking TODOs, generated files or lockfile churn without reason.
- Tests: changed behavior without a test where the project has a test seam.

**Smell baseline** (Fowler, _Refactoring_ ch.3). Each smell is a labelled judgement call ("possible Feature Envy"), never a hard violation:

- **Mysterious Name**: a name that doesn't reveal what it does or holds. → rename; if no honest name comes, the design is murky.
- **Duplicated Code**: the same logic shape in more than one hunk or file. → extract the shared shape.
- **Feature Envy**: a method reaching into another object's data more than its own. → move it to the data.
- **Data Clumps**: the same fields/params travelling together. → bundle them into one type.
- **Primitive Obsession**: a primitive standing in for a domain concept. → give the concept its own type.
- **Repeated Switches**: the same `switch`/`if` cascade on the same type recurring. → polymorphism or one shared map.
- **Shotgun Surgery**: one logical change forcing scattered edits. → gather what changes together.
- **Divergent Change**: one module edited for several unrelated reasons. → split by reason to change.
- **Speculative Generality**: abstraction or parameters the spec doesn't need. → delete; inline until a real need shows.
- **Message Chains**: long `a.b().c().d()` navigation. → hide the walk behind one method.
- **Middle Man**: a class/function that mostly delegates. → call the real target.
- **Refused Bequest**: a subclass ignoring most of what it inherits. → composition.

Do not turn this into a separate diff-bloat audit; flag only the smells above.

## 4. Review both axes

**Size the effort.** For small or medium diffs, review inline: Standards first, then Spec, keeping separate notes. Use two parallel sub-agents with fresh context only for complex reviews (roughly 400+ changed lines, 10+ files, cross-layer changes) or on request. Issue both calls together and give each the scope commands, the change list and its brief:

- **Standards brief**: the standards files found plus both baselines pasted in full. "Report, per file/hunk, every place the diff violates a documented standard (cite file + rule) and any baseline smell (name it, quote the hunk). Documented-standard breaches can be hard violations; smells are always judgement calls; a documented repo standard overrides the baseline. Skip anything tooling enforces. Under 400 words."
- **Spec brief**: the spec path or contents. "Report (a) requirements missing or partial, (b) behaviour in the diff that wasn't asked for (scope creep), (c) requirements that look implemented but wrongly. Quote the spec line for each finding. Under 400 words."

**Classify every finding:**

| Class | Meaning | Required evidence |
| --- | --- | --- |
| `BUG` | Proven defect | Concrete input/state → wrong output, crash or data damage, traced through the code (or a failing test you actually ran) |
| `RISK` | Plausible problem, not proven | What would have to be true for it to fail, and how to verify |
| `SUGGESTION` | Improvement, no defect | Why it helps; never blocking |

`BUG` and `RISK` carry a severity (`critical`, `high`, `medium`, `low`). Prioritise concrete problems; cite `path:line`. A review is static unless you ran something. Never imply tests passed when they were not run.

**Sensitive surface.** If the change touches authentication, permissions, input reaching SQL/shell/HTML/paths/URLs, uploads, deserialization, secrets/config or external integrations, run `security-audit` on the same scope once, unless a valid audit of that scope already exists. Reference its report; do not duplicate its findings.

## 5. Report

Present the axes under separate headings, verbatim or lightly cleaned. Do **not** merge or rerank findings across axes. Never fold findings into a generic list such as "points to check".

**Language.** Write every heading, label and sentence of the report in the language of the conversation (the user's latest explicit choice wins). There is no English template to copy: "Standards" and "Spec" name the axes in this file, not the words to print. Keep literal only what must stay stable across languages: the axis codes `(STD)` and `(SPEC)` at the end of each axis heading, the finding IDs (`STD-n`, `SPEC-n`), the classes `BUG` / `RISK` / `SUGGESTION` and `MISSING` / `PARTIAL` / `WRONG` / `SCOPE-CREEP`, severities, paths, commands, identifiers and quoted requirements. The axis heading is the translated axis name plus its code: in Portuguese, for example, `## Padrões (STD)`; in English `## Standards (STD)`; in Spanish `## Estándares (STD)`.

Report structure, in this order. Each item below describes a slot; label it briefly in the conversation's language.

1. Title line: a level-2 heading naming the review and its scope.
2. Scope line: VCS, commands run, number of files and +/- lines, files excluded as unrelated (or none).
3. Spec source: path, ticket or session, or the explicit statement that no spec is available.
4. Standards sources: files read, plus the harness and smell baselines.
5. Standards axis heading ending in `(STD)`, then one line per finding:
   `[STD-1] BUG (high) path/file.ext:42 — <issue> · <evidence> · <rule and its source> · <fix>`
   `[STD-2] SUGGESTION path/file.ext:88 — <smell name> · <quoted hunk>`
6. Spec axis heading ending in `(SPEC)`, then one line per finding:
   `[SPEC-1] MISSING — "<quoted requirement>" (<source>) · <what is absent>`
   `[SPEC-2] WRONG path/file.ext:10 — "<quoted requirement>" · <evidence>`
   `[SPEC-3] SCOPE-CREEP path/file.ext:120 — <unrequested behaviour>`
   An axis with no findings still gets its heading and a one-line statement that nothing was found (or why it could not be checked).
7. Security section: link to or summary of the `security-audit` report, or "not applicable" with the reason.
8. Closing line: per axis, the finding count and the worst issue, plus what was not verified.

Inside a finding line, the `·` separated parts may carry short labels in the conversation's language (for example evidence, rule, fix), never fixed English labels in a non-English conversation. Don't pick a winner across axes.

## Handoffs

- Called by the user, the router or `release-readiness`. Return the report; never invoke `release-readiness` or the router from here, and never decide release readiness.
- Fixes are a new task routed by `coding-skill-router`.
- UI changes: mention `web-design-guidelines` when UX/accessibility is in scope; do not run it unasked.
