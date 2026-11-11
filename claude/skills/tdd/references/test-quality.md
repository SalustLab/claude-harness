# Test quality at public seams

Use this reference when choosing assertions or test doubles.

## Independent expectations

An expected value must be able to expose an incorrect implementation. For a
total of items priced 10 and 5, assert the worked result 15. Computing the
expectation with the same reduction as production can reproduce the same bug.
Use acceptance examples, known-good literals or an independent specification.

Assert what callers observe: create a user, retrieve it through the public
interface, and check the resulting name. Internal method call counts or a direct
database query can bypass the behavior the caller depends on. A database
interface is itself a valid seam when persistence is the contract under test.

## Test doubles

Prefer real internal collaborators. Isolate external APIs, time, randomness or
filesystem effects when needed for deterministic, safe tests. Use an isolated
test database when practical; otherwise substitute at the persistence boundary.
Never use real production effects to avoid a mock.

Pass external dependencies through existing injection points rather than
constructing authenticated clients inside the behavior under test. Prefer
operation-specific doubles to a generic fetch mock with conditional routing.
Do not introduce a speculative interface or dependency solely to match an example.

Adapted from Matt Pocock's [tests.md](https://github.com/mattpocock/skills/blob/main/skills/engineering/tdd/tests.md)
and [mocking.md](https://github.com/mattpocock/skills/blob/main/skills/engineering/tdd/mocking.md).
