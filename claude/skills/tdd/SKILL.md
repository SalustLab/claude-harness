---
name: tdd
description: Test-Driven Development - one test, make it pass, repeat, in vertical slices. Use for testable behavior changes (service/controller logic, validation, business rules, export/import, API contracts) and bug fixes with a clear cause; PT - "implementa", "corrige esse teste", "regra de negocio". Unknown or intermittent cause - diagnose first.
---

# Test-Driven Development

## Philosophy

**Core principle**: Tests should verify behavior through public interfaces, not implementation details. Code can change entirely; tests shouldn't.

**Good tests** are integration-style: they exercise real code paths through public APIs. They describe _what_ the system does, not _how_ it does it. A good test reads like a specification - "user can checkout with valid cart" tells you exactly what capability exists. These tests survive refactors because they don't care about internal structure.

**Bad tests** are coupled to implementation. They mock internal collaborators, test private methods, or verify through external means (like querying a database directly instead of using the interface). The warning sign: your test breaks when you refactor, but behavior hasn't changed. If you rename an internal function and tests fail, those tests were testing implementation, not behavior.

## Anti-Pattern: Horizontal Slices

**DO NOT write all tests first, then all implementation.** This is "horizontal slicing" - treating RED as "write all tests" and GREEN as "write all code."

This produces **crap tests**:

- Tests written in bulk test _imagined_ behavior, not _actual_ behavior
- You end up testing the _shape_ of things (data structures, function signatures) rather than user-facing behavior
- Tests become insensitive to real changes - they pass when behavior breaks, fail when behavior is fine
- You outrun your headlights, committing to test structure before understanding the implementation

**Correct approach**: Vertical slices via tracer bullets. One test → one implementation → repeat. Each test responds to what you learned from the previous cycle. Because you just wrote the code, you know exactly what behavior matters and how to verify it.

```
WRONG (horizontal):
  RED:   test1, test2, test3, test4, test5
  GREEN: impl1, impl2, impl3, impl4, impl5

RIGHT (vertical):
  RED→GREEN: test1→impl1
  RED→GREEN: test2→impl2
  RED→GREEN: test3→impl3
  ...
```

## Workflow

### 1. Planning

When exploring the codebase, read the project glossary (`GLOSSARY.md` / `GLOSSARY-MAP.md`, or the existing `CONTEXT.md` convention) so that test names and interface vocabulary match the project's language, and respect ADRs in the area you're touching.

Before writing any code:

- [ ] Identify interface changes from the request and existing contracts
- [ ] Prioritize behaviors from requirements, acceptance criteria and risk
- [ ] Identify opportunities for deep modules (small interface, deep implementation)
- [ ] Design interfaces for testability
- [ ] List the behaviors to test (not implementation steps)
- [ ] Resolve material ambiguities; reuse the user's existing decisions and authorization

When the request and repository leave a material choice unresolved, ask about that choice with a recommended answer.

**You can't test everything.** Use the stated acceptance criteria to determine which behaviors matter most. Focus testing effort on critical paths and complex logic, not every possible edge case.

### Test seams and independent expectations

Name the public seams under test before the first cycle. For each, state what it
catches and what it misses; use interfaces already settled by the request or
existing contracts. Ask when selecting a seam requires a material product or
interface decision. Keep the real caller chain when it is necessary to expose a
regression.

Avoid tautological assertions: the expected result must come from a specification,
a worked example or a known-good literal, rather than recomputing it with the
same algorithm as production. A test must be able to disagree with broken code.
See [references/test-quality.md](references/test-quality.md) for examples and
boundary mocking guidance when designing assertions or test doubles.

### 2. Tracer Bullet

Write ONE test that confirms ONE thing about the system:

```
RED:   Write test for first behavior → test fails
GREEN: Write minimal code to pass → test passes
```

This is your tracer bullet - proves the path works end-to-end.

### 3. Incremental Loop

For each remaining behavior:

```
RED:   Write next test → fails
GREEN: Minimal code to pass → passes
```

Rules:

- One test at a time
- Only enough code to pass current test
- Don't anticipate future tests
- Keep tests focused on observable behavior

### 4. Refactor

After all tests pass, look for refactor candidates:

- [ ] Extract duplication
- [ ] Deepen modules (move complexity behind simple interfaces)
- [ ] Apply SOLID principles where natural
- [ ] Consider what new code reveals about existing code
- [ ] Run tests after each refactor step

**Never refactor while RED.** Get to GREEN first.

## Checklist Per Cycle

```
[ ] Test describes behavior, not implementation
[ ] Test uses public interface only
[ ] Test would survive internal refactor
[ ] Code is minimal for this test
[ ] No speculative features added
```

## Handoffs

- Cause of a bug unknown or intermittent? Stop — run `diagnose` first; it returns here with the confirmed cause and (when a correct seam exists) a regression test.
- Unfamiliar area? Run `zoom-out` before planning tests.

## Acceptance evidence

Derive test priorities from the supplied requirements and acceptance criteria;
reuse decisions already provided by the user instead of requesting approval again.
Ask only when a material behavior or interface choice remains unresolved.

For non-trivial changes, keep a compact mapping from requirement to scenario,
expected behavior, observed result and evidence (test output or artifact path).
Distinguish `PASS`, `FAIL`, `BLOCKED` and `NOT_RUN`; a missing dependency or an
unexecuted test is never a pass. Re-run affected checks after corrections.

For UI changes, functional tests and visual comparison answer different questions.
When visual verification is in scope and authorized, compare the changed screens
and states against available mockups, including spacing, typography, dimensions
and responsive behavior. Report missing references or captures explicitly; do
not claim visual equivalence from a successful functional test.

When user-facing evidence is requested, select artifacts that prove acceptance
criteria, preferably the saved outcome rather than intermediate navigation.
Keep secondary technical checks in the validation report. Use the requested
language and deliverable format; do not publish evidence without authorization.
