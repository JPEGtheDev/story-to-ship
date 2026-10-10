---
name: contract-testing
license: MIT
description: Use when writing tests for any interface, abstract base class, or type with 2+ implementations (a mock counts).
---


## Iron Law

```
EVERY INTERFACE OR ABSTRACT TYPE WITH 2+ IMPLEMENTATIONS (A MOCK COUNTS) REQUIRES A CONTRACT TEST FIXTURE
YOU MUST write a contract test fixture before shipping any interface with 2+ implementations (a mock counts). No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

**Announce at start:** "I am using the contract-testing skill to write contract tests for [interface]."

---

## BEFORE PROCEEDING

1. Is this an interface, abstract class, or type with 2+ implementations (a mock counts)? If no, this skill does not apply -- stop here.
2. Does a contract test fixture exist for it?
3. Does every concrete implementation pass all contract tests?

[+] All met -> proceed
[-] Item 2 unmet -> write the contract test fixture before adding any new implementation
[-] Item 3 unmet -> fix the implementation (or fix the hierarchy if the invariant cannot hold for a legitimate subtype); do not merge

---

## What a Contract Test Is

A contract test describes the behavioral invariants all implementations must satisfy. Violating a contract test violates the Liskov Substitution Principle (LSP).

Use Google Test `TYPED_TEST_P` -- not `TEST_F` -- because `TEST_F` instantiates the fixture class directly and will not compile against a pure-virtual base. See `references/CONTRACT_TESTING.md` for the full `TYPED_TEST_P` / `INSTANTIATE_TYPED_TEST_SUITE_P` pattern.

In another language, parameterize one shared test suite over every implementation.

A failing contract test means an implementation breaks an invariant -- fix the implementation, not the test; if the invariant cannot hold for a legitimate subtype, fix the hierarchy.

---

## Rationalization Prevention

| Excuse | Reality |
|---|---|
| "Integration tests cover the contract" | Integration tests verify composition, not behavioral invariants. |
| "There is only one implementation" | A mock is a second implementation. With a mock or a second implementation, write the fixture now; with one implementation and no mock, this skill does not apply. |
| "The interface is simple, nothing to test" | Simple interfaces still have invariants (no-throw, non-null return). |
| "The mock already tests the behavior" | Mocks verify interactions, not behavioral contracts. Both are needed. |
| "The contract test is redundant -- the implementations are clearly equivalent" | Equivalence is an assumption, not evidence. Contract tests document and enforce invariants across all current and future implementations. |

---

## Red Flags -- STOP

- Adding a second implementation without verifying it against the existing contract fixture -- **STOP. Run the full contract suite against the new implementation before merging.**
- About to write an interface test using `TEST_F` instead of `TYPED_TEST_P` -- **STOP. `TEST_F` instantiates the concrete fixture directly; it does not test behavioral invariants across implementations.**
- Contract test failing, about to modify the test to make it pass -- **STOP. A failing contract test means an implementation violates the LSP. Fix the implementation, not the test; if the invariant cannot hold for a legitimate subtype, fix the hierarchy.**
- "The interface has only one implementation now, contract tests can wait" -- **STOP. Count the mock: a mock is a second implementation, so write the fixture now. With one real implementation and no mock, this skill does not apply.**
- Deleting a contract test because "the implementation was simplified" -- **STOP. Simplified implementations still have invariants. Removing a contract test removes the guarantee.**

---

## Related Skills

- `testing` -- parent skill; Test Doubles taxonomy, saw-the-test-fail gate, Arrange-Act-Assert (AAA) naming
- `oop-principles` -- sibling; contract tests enforce Liskov Substitution
- `architecture-review` -- sibling; interfaces also need layer boundary review
