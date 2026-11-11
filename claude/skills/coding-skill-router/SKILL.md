---
name: coding-skill-router
description: Select workflows for non-trivial code changes, debugging, architecture reviews, agent instructions and skill maintenance. Route by scope and intent rather than task names. Skip for mechanical edits and unrelated questions.
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

Select multiple skills when the task spans concerns, but do not load every skill
by default. Use the project's actual scope and risk to scale exploration and
validation. A task's title or tracker does not select a workflow or grant access.

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
