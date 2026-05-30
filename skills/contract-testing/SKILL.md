---
name: contract-testing
license: MIT
description: Use when writing tests for any interface, abstract base class, or type with multiple implementations.
---


## Iron Law

```
EVERY ABSTRACT TYPE REQUIRES A CONTRACT TEST FIXTURE
YOU MUST write a contract test fixture before shipping any interface with multiple implementations. No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

**Announce at start:** "I am using the contract-testing skill to write contract tests for [interface]."

---

## BEFORE PROCEEDING

1. Is this an interface, abstract class, or type with 2+ implementations?
2. Does a contract test fixture exist for it?
3. Does every concrete implementation pass all contract tests?

✓ All met → proceed
✗ Any unmet → write the contract test fixture before adding any new implementation

---

## What a Contract Test Is

A contract test describes the behavioral invariants all implementations must satisfy. Violating a contract test violates the Liskov Substitution Principle.

Use `TYPED_TEST_P` — not `TEST_F` — because `TEST_F` instantiates the fixture class directly and will not compile against a pure-virtual base. See `references/CONTRACT_TESTING.md` for the full `TYPED_TEST_P` / `INSTANTIATE_TYPED_TEST_SUITE_P` pattern.

A failing contract test means the hierarchy is wrong — fix the hierarchy, not the test.

---

## Rationalization Prevention

| Excuse | Reality |
|---|---|
| "Integration tests cover the contract" | Integration tests verify composition, not behavioral invariants. |
| "There is only one implementation" | Write the fixture now. A second implementation arrives later. |
| "The interface is simple, nothing to test" | Simple interfaces still have invariants (no-throw, non-null return). |
| "The mock already tests the behavior" | Mocks verify interactions, not behavioral contracts. Both are needed. |
| "The contract test is redundant -- the implementations are clearly equivalent" | Equivalence is an assumption, not evidence. Contract tests document and enforce invariants across all current and future implementations. |

---

## Red Flags -- STOP

- Adding a second implementation without verifying it against the existing contract fixture -- **STOP. Run the full contract suite against the new implementation before merging.**
- About to write an interface test using `TEST_F` instead of `TYPED_TEST_P` -- **STOP. `TEST_F` instantiates the concrete fixture directly; it does not test behavioral invariants across implementations.**
- Contract test failing, about to modify the test to make it pass -- **STOP. A failing contract test means the implementation violates the LSP. Fix the implementation, not the test.**
- "The interface has only one implementation now, contract tests can wait" -- **STOP. Write the fixture now. A second implementation arrives later -- often from a mock. The fixture documents invariants the mock must satisfy.**
- Deleting a contract test because "the implementation was simplified" -- **STOP. Simplified implementations still have invariants. Removing a contract test removes the guarantee.**

---

## Related Skills

- `testing` -- parent skill; Test Doubles taxonomy, saw-the-test-fail gate, AAA naming
- `oop-principles` -- sibling; contract tests enforce Liskov Substitution
- `architecture-review` -- sibling; interfaces also need layer boundary review
