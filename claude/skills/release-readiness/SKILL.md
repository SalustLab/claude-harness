---
name: release-readiness
description: Evidence-based readiness audit at two levels - Task Readiness (was the requested task really done? works from the user's request when no ticket exists) and Release Readiness (can the changes be delivered, merged, sent to homologation or published?). Finds the specification, builds a requirement-to-evidence matrix, runs implementation, quality and manual-validation checklists, and decides GO, NO-GO or CONDITIONAL per level. Corporate mode for tickets with formal acceptance criteria. Works on Git and SVN, on finished or partial work. Use when asked whether a task, branch, revision or ticket is done or ready to deliver, release, close or send to homologation, and as the closing Task Readiness gate of a relevant implementation; PT - "ta pronto pra entregar?", "a tarefa ta concluida?", "valida o chamado", "checklist de entrega", "o que falta pra fechar?", "pode mandar pra homologacao?". Read-only; never publishes, deploys or updates tickets. Not for trivial edits.
metadata:
  short-description: Requirement-to-evidence delivery audit (GO / NO-GO / CONDITIONAL)
  source: original (claude-harness)
  invokes: [diff-review, security-audit, web-design-guidelines]
---

# Release Readiness

Answer one question with evidence: **does this delivery meet what was asked, and what still prevents it from being delivered?** A delivery can be technically correct and still miss something the ticket required. This skill exists to catch that gap.

## Levels

| Level | Question | Specification |
| --- | --- | --- |
| **Task Readiness** | Was the requested task actually completed? Personal features, tickets, bug fixes, refactors, behavior changes, multi-file work | The user's request and the decisions recorded since then are enough; a ticket's formal criteria when one exists |
| **Release Readiness** | Is this set of changes ready to deliver, merge, send to homologation, distribute or publish? | Task Readiness of the delivery scope plus the release requirements (Step 7) |

Pick the level from the question: "is it done / what is missing / close the task" is Task; "deliver, release, publish, merge, homologation, close the version" is Release. The router's closing gate is Task. A Task Readiness `GO` never implies a Release Readiness `GO`: the task can be done while the release still waits for homologation, hardware validation or an external approval.

Depth follows the scope: a medium change gets a short checklist (requirements, tests, docs, pending items); a large, corporate or high-risk one gets the full matrix.

## Modes

| Mode | When | Output |
| --- | --- | --- |
| **Readiness Check** | On demand, for a branch, SVN revision, diff, ticket or work in progress | Audit + checklist; changes nothing |
| **Pre-Release Gate** | Before a delivery or release, or at the close of an implementation (router or explicit request) | Collects validation evidence, lists blockers; never publishes or deploys |

Levels and modes combine: Task + Readiness Check (audit a partial feature), Task + Pre-Release Gate (the closing gate of an implementation), Release + Pre-Release Gate (ready to publish?), Release + Readiness Check (audit a release without publishing it). Both modes work on partial implementations: report what is done and what is missing, without assuming the work is finished.

## Ground Rules

- **Read-only.** Do not edit code, tests, tickets or docs. You may run read-only VCS commands and the project's own build/test/lint commands when they are safe: no real databases, deploys, external messages or production configuration.
- **Evidence or it did not happen.** A test that exists is not a test that passed. Code that looks right is not a verified requirement.
- **Do not invent requirements.** Record a missing source as missing. Label your own inferred checks as `derived`. They never replace official acceptance criteria.
- **No external effects.** Never change ticket status, comment, attach evidence, merge, tag, publish, deploy or notify anyone without explicit authorization for that action. A `GO` authorizes nothing.

## Step 1: Discover the Scope

Detect the VCS (subdirectories included). The innermost root wins:

```
git rev-parse --show-toplevel
svn info --show-item wc-root
```

| Need | Git | SVN |
| --- | --- | --- |
| Delivery files | `git status --short`, `git diff --stat <base>...HEAD`, `git diff HEAD` | `svn status`, `svn diff -r <base> --summarize`, `svn diff` |
| History / decisions | `git log --oneline <base>..HEAD` | `svn log -v -r <base>:HEAD` |
| Current point | `git rev-parse --short HEAD`, `git branch --show-current` | `svn info --show-item revision`, `svn info --show-item relative-url` |

No VCS: use the files and context supplied and record "VCS: none identified". Never run Git commands in SVN working copies.

Identify, citing the source of each:

- The task, issue or ticket (ID and title) and the **original specification**. Without a ticket, the user's request in the session and the decisions recorded since then are the specification (source: `session`); personal tasks do not need formal documents.
- Documents describing the feature: ticket text and attachments when accessible, `README.md`, `docs/`, `docs/specs/`, `GLOSSARY.md` / `CONTEXT.md`, ADRs, plans, test cases.
- **Explicit acceptance criteria** and the business rules that apply.
- Affected screens, APIs, integrations, modules and files.
- Which changes belong to this delivery and which were **pre-existing or unrelated**. List the excluded ones; ask only if the split is genuinely ambiguous.
- **Later decisions** that changed the requirements (session messages, ticket comments, commit messages).

Issue trackers and corporate systems are read only when a tool for them is available and authorized. Otherwise ask the user to paste the ticket or record its absence.

**Conflicts between sources**: explicit user instructions in this session and the latest valid recorded decision prevail over the original text. A material conflict that is not resolved is reported, and the affected criterion is `BLOCKED` ("conflicting requirement"). When documentation and implementation diverge, say so explicitly.

## Step 2: Traceability Matrix

One row per requirement. Use the source's IDs (`AC1`, `CA-03`); otherwise local IDs `R1`, `R2`, ...

| ID | Requirement | Source | Implementation | Verification | Evidence | Status | Pending |
| --- | --- | --- | --- | --- | --- | --- | --- |
| AC1 | ... | ticket §2 | `src/x.ts:40` | unit test | `npm test`: 12 passed (`x.test.ts` "rejects empty") | PASS | - |

**Statuses**

| Status | Meaning |
| --- | --- |
| `PASS` | Verified with evidence that matches the nature of the requirement |
| `FAIL` | Not met, behaves differently from the spec, not implemented, or its check failed |
| `BLOCKED` | Cannot be verified because of an identified impediment (no environment, no access, conflicting requirement) |
| `NOT_RUN` | An applicable verification exists but was not executed |
| `N/A` | Justifiably not applicable; the justification is mandatory |

**Evidence must match the requirement**: behavior needs an executed test, a command output or a confirmed manual validation. A static artifact (doc updated, config key present, field added) can be verified by inspecting `file:line`. Cite commands with their actual results. User statements count only for what they state, with date/environment when given.

## Step 3: Implementation Checklist

Mark each item `PASS` / `FAIL` / `BLOCKED` / `NOT_RUN` / `N/A` with evidence or reason:

- All requirements implemented; main and alternative flows covered; edge cases handled.
- Business rules match the documentation.
- API contracts respected (request/response, status codes, compatibility).
- Validations and error messages as specified (exact texts when the spec gives them).
- Authorization and permissions considered.
- Persistence and data integrity; migrations and scripts reviewed (never executed against real databases by this skill).
- Failure handling and logging adequate.
- No out-of-scope changes; no detected regressions.
- No TODOs, stubs or provisional implementations that block delivery.
- Affected documentation updated.

By intent, add: **bug** - the original symptom no longer reproduces (re-run the repro or a regression test that failed before the fix) and related behavior still passes; **refactor** - behavior preserved (the same tests pass, public contracts unchanged) and the refactor's own goals met; **architecture** - the stated structural goals are visible in the code, with the applicable evidence.

## Step 4: Quality Checklist

Run or collect only what is relevant and safe, and reuse valid evidence:

| Check | How |
| --- | --- |
| Build, unit, integration, E2E, regression tests | Project's own commands; record the command and the result |
| Lint / static analysis / formatting | Project's configured tools |
| Code review | `diff-review` on the delivery scope for medium+ deliveries or when the project requires review |
| Security | `security-audit` when the change touches a sensitive surface (auth, permissions, input to SQL/shell/HTML/paths/URLs, uploads, parsing, secrets, integrations) |
| UX and accessibility | `web-design-guidelines` when UI changed and UX is in scope; visual checks stay manual (Step 5) |
| Complexity | No unneeded abstraction, dependency or speculative code; no separate audit |
| Environment compatibility, dependencies, configuration | Inspect manifests, lockfiles and config changes |
| Diff integrity | Only intended files changed; no secrets, debug leftovers or generated noise |

**Reuse rule**: if a review, audit or test run already exists for the same scope and nothing in that scope changed afterwards (same commit/revision/diff), cite it instead of re-running. Re-run only what later changes invalidated. Scale depth to risk and size; a small, low-risk personal change does not need every check.

## Step 5: Manual and Real-Environment Validation

Some things can only be approved outside the code: corporate homologation, user/PO validation, representative data, external integrations, physical hardware, legacy systems, specific devices or browsers, UI evidence (screenshots), functional sign-off. Never substitute inference for them. A passing automated test does not prove homologation.

For each pending item, produce an objective checklist row. It stays `NOT_RUN` (or `BLOCKED` if impossible now) until confirmed:

| # | Step | Expected result | Evidence required | Owner | Status |
| --- | --- | --- | --- | --- | --- |
| M1 | Upload firmware to the ESP32 and power the board | LED blinks at 2 Hz | video or measured interval | user | NOT_RUN |

## Step 6: Corporate Mode (tickets)

Applies when the work is tied to a ticket, formal business requirement or documented acceptance criteria. Run every step:

1. Identify the ticket and the applicable documentation, or record that they are unavailable.
2. Extract every acceptance criterion verbatim.
3. Map each criterion to the changes that implement it.
4. Check each scenario described in the ticket.
5. Check business rules and their exceptions.
6. Check impact on existing features (regressions in related screens, reports, integrations).
7. Identify the evidence the ticket or the process requires (screenshots, logs, scripts, test reports).
8. Check homologation requirements (environment, who validates, data).
9. Identify pending approvals and deploy steps, as information only.
10. Produce the final acceptance checklist.

**Every known acceptance criterion gets an explicit status.** Code existence alone is never evidence of acceptance. A ticket is not ready while any mandatory criterion is not `PASS` (or justified `N/A`).

**Ticket unavailable**: say so, label the result "technical review only, not an acceptance verdict against official criteria", and do not invent the missing criteria. The decision cannot be `GO`.

## Step 7: Release Requirements (Release Readiness only)

On top of Task Readiness for the whole delivery scope, check what the project, ticket or release process actually requires; mark the rest `N/A` with the reason:

- Full delivery scope and integration with other changes in it (conflicts, ordering).
- Build and the test suites the project requires before delivery.
- Environment compatibility, migrations and configuration for each target environment.
- Security and regressions across the delivery, not only the last task.
- Versioning, changelog and release documentation.
- Real-hardware, homologation and other real-environment evidence (Step 5).
- Approvals and external requirements; deployment risks and rollback notes, as information only.

Never report `Release Readiness: GO` without assessing these items.

## Step 8: Decision

Apply the first rule that matches:

1. **`NO-GO`**: any mandatory requirement is `FAIL` (including "not implemented yet"), any required build/test is failing, or a confirmed blocking defect exists (`BUG` high/critical, high-confidence security finding).
2. **`CONDITIONAL`**: no `NO-GO` condition, but any mandatory requirement or required validation is `BLOCKED` or `NOT_RUN`, a manual validation, homologation or approval is pending, the specification is unavailable, or a material requirement conflict is unresolved.
3. **`GO`**: every mandatory requirement is `PASS` (or justified `N/A`), required validations passed, nothing mandatory is pending, and the specification was available.

"Specification available" means the ticket's criteria in corporate mode; otherwise the user's request and recorded decisions count. At the Release level, the decision is never better than the Task Readiness of its scope.

`CONDITIONAL` is **not** an approval to release. Never declare `GO` with a mandatory item `BLOCKED` or `NOT_RUN`. For partial work, the result is `NO-GO` with the list of what is missing and the progress (`x/y requirements PASS`).

## Step 9: Report

Always give a direct terminal summary in this shape (the matrix follows when there are several criteria). The header names the level; a short Task Readiness may drop the lines that do not apply:

```text
<TASK READINESS | RELEASE READINESS> — <Readiness Check | Pre-Release Gate>

Task: <ID - title | not identified>
VCS: <Git | SVN | none> · Revision / baseline: <sha/rev/branch/URL>
Specification source: <ticket/doc/session | none available>

Requirements: PASS n · FAIL n · BLOCKED n · NOT_RUN n · N/A n
Task readiness: <GO | NO-GO | CONDITIONAL>          (Release level only)
Release requirements: <hardware, homologation, versioning... with status>   (Release level only)

Validation:
- Build: <status + command>
- Unit tests: <status + command/result>
- Integration tests: <...>
- E2E: <...>
- Security: <...>
- Code review: <...>
- Manual QA: <...>
- Documentation: <...>

Unmet acceptance criteria: <IDs + why>
Outstanding validations: <IDs/checks + owner>
Risks: <residual risks>
Next actions: <objective steps>

Implementation complete: <yes/no/partial> · Validations executed: <list> · Acceptance criteria met: <x/y>
Task readiness: <decision> · Release readiness: <decision | not assessed> · Published/deployed: not performed by this skill

Decision: <GO | NO-GO | CONDITIONAL>
```

A medium Task Readiness (including the router's closing gate) can use the short form. It closes the final answer, after any summary of the work:

```text
TASK READINESS — Pre-Release Gate
Specification source: session request
Requirements: 3/3 PASS
Tests: PASS (npm test: 3 passed)
Regressions: PASS (existing tests still pass)
Documentation: N/A (no affected docs)
Manual validation: N/A
Release readiness: not assessed

Decision: GO
```

Other labels may follow the user's language, but two lines stay literal English: the level header (`TASK READINESS` or `RELEASE READINESS`, uppercase) and the final line `Decision: GO`, `Decision: NO-GO` or `Decision: CONDITIONAL` (nothing else on the line). They are the unambiguous, machine-checkable level and verdict; do not replace them with prose such as "decisão: GO para a tarefa". When both levels were asked, give the Release report (with its `Task readiness:` line) and end with the Release decision.

Write a Markdown report file only when the user asks, or when a long corporate matrix needs to travel with the homologation evidence. Use the project's existing location for such documents (ask if none exists). Never commit it, and never create report files for trivial tasks.

## Handoffs and Loop Prevention

- Invoked by the user or by `coding-skill-router` at the end of a relevant implementation. It may invoke `diff-review`, `security-audit` and `web-design-guidelines` once per scope as evidence steps. Those skills never call back, and this skill never calls the router.
- This skill never edits files. After an on-demand check, stop; fixing gaps is a new task routed by the router.
- As the closing gate of an implementation, hand the gaps back to that already-authorized implementation: it fixes what is inside its scope, then asks for one re-check of only what the fixes invalidated. Gaps outside the scope, or still failing after that re-check, are reported, not looped on. The task is not declared complete before the gate's decision.
- Re-checks never repeat validations that are still valid for the same scope (Step 4 reuse rule).
