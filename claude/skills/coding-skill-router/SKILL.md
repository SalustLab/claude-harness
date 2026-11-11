---
name: coding-skill-router
description: Select workflows for non-trivial code changes, debugging, architecture reviews, change reviews, security-sensitive work, delivery readiness, agent instructions and skill maintenance. Route by scope and intent rather than task names. Skip for mechanical edits and unrelated questions.
license: MIT
---

# Coding Skill Router

Inspect the request, relevant project instructions and existing implementation.
Choose the workflows that help with the actual task. Explain the choice briefly,
open the selected skills, apply them, and report what they found. Announcing a
skill is not evidence that it ran. Use the host's skill loader or read its
installed `SKILL.md` directly; do not invent tools or capabilities.

## Scope and intent

| Work | Workflow | Conditions |
|---|---|---|
| Mechanical or familiar local edit | Direct edit and relevant check | No mandatory skill package. |
| Unfamiliar or cross-layer behavior | `zoom-out` + `tdd` | Map callers and flow, then test meaningful behavior at public seams. |
| Localized testable behavior or known-cause bug | `tdd` | Establish expected behavior independently of the implementation. |
| Unknown-cause, intermittent or performance bug | `diagnose` | Reproduce and minimise first; confirmed cause hands off to `tdd` at a correct seam. |
| Open product/design decision | `brainstorming` | Only when material choices remain unresolved after inspection. |
| Domain decision or glossary/ADR work | `grill-with-docs` | Check settled requirements without forcing an interview or creating docs. |
| Structural architecture review | `zoom-out` + `improve-codebase-architecture` | Use only when requested or genuinely needed; ordinary refactors use behavior protection. |
| Refactor | `zoom-out` + `tdd` where useful | Preserve observable behavior; do not write tests that merely repeat the implementation. |
| Agent instructions or skill maintenance | `zoom-out` + `grill-with-docs` as a consistency check | Validate metadata/references for skills; no TDD unless executable behavior changes. |
| Agent-readiness audit | `agent-doctor` | Documentation/navigation gaps, not application runtime bugs. |
| Review of a diff, commit, branch or revision | `diff-review` | Add `security-audit` for a sensitive surface and `web-design-guidelines` when UI review is requested. |
| Security-sensitive change or security request | `security-audit` | Selected by the affected surface, not by size (see gates below). |
| UI/UX or accessibility review | `web-design-guidelines` | Static review; visual checks need authorized browser tools. |
| External skill import or upstream skill update | `skill-scanner`, then `skill-creator` | Scan before copying anything into a skills folder; never run the target's scripts. |
| Skill creation, tuning or evaluation | `skill-creator` | Register new skills in this router; never add a second router. |
| Explicit request for an isolated Git worktree | `using-git-worktrees` | Git only; never automatic and never a prerequisite. |
| "Is it done?" or "is it ready to deliver?" | `release-readiness` | Task level for completion; Release level for merge, homologation or publication. |

Select multiple skills when the task spans concerns, but do not load every skill
by default. Use the project's actual scope and risk to scale exploration and
validation. A task's title or tracker does not select a workflow or grant access.

Detect the version control system before VCS-specific steps (`git rev-parse
--show-toplevel`, `svn info --show-item wc-root`; the innermost root wins). Never
run Git commands in an SVN working copy. Skills marked `metadata.vcs: git` are
not selected for SVN or folders without Git.

## Review, security and delivery gates

- **Depth by risk.** Do not stack every skill on every task. Small, low-risk
  changes get the finish checks below only.
- **Security by surface.** Authentication, sessions, permissions, tenant
  filtering, input reaching SQL/shell/HTML/file paths/URLs/redirects, uploads,
  parsing of external data, secrets, crypto, personal-data logging, new
  dependencies, CI changes and external integrations get `security-audit` on that
  scope, even for a one-line change.
- **Review.** `diff-review` on request, for PRs/branches/revisions, or for complex
  diffs before delivery.
- **Task completion.** Close medium or larger implementations with
  `release-readiness` at the Task level, once, after the last change: a short
  checklist for medium work, the full matrix for large or high-risk work. The
  user's request and recorded decisions are the specification when no ticket
  exists. Fix in-scope gaps, re-check what the fixes affected and report the rest.
  Docs-only and skill work use their own validations instead.
- **Delivery.** The Release level runs on request. A Task `GO` never implies a
  Release `GO`.
- **No repeats, no loops.** Evidence stays valid for the same scope until a later
  change invalidates it. Calls go one way: router -> `release-readiness` ->
  `diff-review` -> `security-audit`, plus `web-design-guidelines`; none of them
  calls back into the router or `release-readiness`.
- **Decisions authorize nothing external.** A `GO`, a clean review or an approved
  audit never authorizes commit, push, merge, publish, deploy, ticket updates or
  messages.

## Design and questions

Settled requirements with one sensible implementation, clear bug fixes and
mechanical changes do not need another design conversation. A directive verb
alone does not resolve an open product choice. Honor an explicit request to skip
design discussion and state material assumptions.

After brainstorming approval or explicit opt-out, return here for execution
skills without selecting brainstorming again for the same settled scope. An
authorized throwaway spike answers a specific uncertainty; retaining it as the
finished product needs its own agreed scope.

Use the project's existing glossary and context layout. Prefer `GLOSSARY.md` /
`GLOSSARY-MAP.md` for new domain glossaries; do not rename or migrate an existing
`CONTEXT.md` convention automatically. Ask only about consequential choices the
request and repository cannot answer. Reuse scoped decisions and authorizations.

## Tools and references

Inspect installed versions and local conventions. When a decision depends on
external framework/library semantics, consult the matching official docs; use
Context7 if available and appropriate. It is optional, not an installation
requirement. If documentation is unavailable, report that and inspect installed
packages/local sources with explicit assumptions. Never claim a lookup occurred
when it did not.

No external documentation tool is needed for changes confined to local
instructions and established patterns without new external-semantic claims.
Announced tools must be called or their unavailability reported.

Use browser automation and subagents only when available and authorized for the
task. Otherwise perform the relevant review directly or report the limitation.
Accepting a local visual companion does not authorize unrelated remote mutations.
No specific agent model or plugin is assumed.

## Evidence proportional to the work

- `zoom-out`: affected modules/docs, callers and data flow; cross-repo context
  only when needed.
- `grill-with-docs`: requirements checked and contradictions or unresolved
  decisions. Say when no interview or new glossary/ADR is needed.
- `tdd`: public seams, what they cover/miss, and an independent expected result.
  Record RED/GREEN only after actually running the test.
- `diagnose`: a symptom-specific repro command and redacted output, minimised
  scenario and confirmed cause as they become available. A plan is not a run.
- `brainstorming`: agreed design, applicable approval, opt-out or spike scope.
- Architecture review: chosen scope, observed friction and grounded candidates.
- `diff-review`: VCS and scope command, specification source (or none), findings
  per axis.
- `security-audit`: the surface that triggered it, scope, and findings or "no
  high-confidence vulnerabilities".
- `web-design-guidelines`: rules source (live or snapshot), files reviewed, and
  what still needs visual validation.
- `skill-scanner`: target and source/commit, automated scan run or `NOT_RUN` with
  the reason, assessment.
- `skill-creator`: overlap check, validation result, evals run or `NOT_RUN`.
- `using-git-worktrees`: Git confirmed, existing isolation checked, consent for
  location and branch.
- `release-readiness`: level, specification source, requirement counts by status
  and decision.

In plan mode, perform read-only exploration and record the resulting map and
validation strategy. Describe reproduction rather than executing mutations.
Do not claim reproduction, minimisation or confirmed hypotheses before their
prerequisites occurred. Mark unexecuted checks pending. After approval, reuse
actual evidence from the plan and run whatever remains missing.

## Finish and resume

Review the diff for requirement coverage, regression risk, project-rule
compliance, unrelated changes and bug validation when applicable. Re-run the
checks affected by corrections. Functional tests do not establish visual
equivalence; compare actual changed screens/states with references when that
validation is requested and possible.

Report the outcome, files changed, relevant checks and remaining limitations.
Distinguish `PASS`, `FAIL`, `BLOCKED` and `NOT_RUN`; do not turn missing evaluation
into success. Keep detailed evidence in task artifacts instead of duplicating
it in status messages. Redact secrets.

For resumed work, reconcile task notes with actual Git, service and database
state before repeating external effects. Preserve original authorization scope.
Do not create state files or new process layers when existing task context is
sufficient. `caveman` is optional style and never substitutes for a work skill.
