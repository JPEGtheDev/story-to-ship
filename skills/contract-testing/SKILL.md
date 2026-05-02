---
name: contract-testing
license: MIT
description: Use when writing tests for any interface, abstract base class, or type with multiple implementations.
---

## Iron Law

```
EVERY ABSTRACT TYPE REQUIRES A CONTRACT TEST FIXTURE
```

Violating the letter of this rule is violating the spirit of this rule.

YOU MUST write a contract test fixture before shipping any interface with multiple implementations. No exceptions.

**Announce at start:** "I am using the contract-testing skill to write contract tests for [interface]."

---

## BEFORE PROCEEDING

- [ ] Is this an interface, abstract class, or type with 2+ implementations?
- [ ] Does a contract test fixture exist for it?
- [ ] Does every concrete implementation pass all contract tests?

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

---

## Related Skills

- [`testing`](.github/skills/testing/) — parent skill; Test Doubles taxonomy, saw-the-test-fail gate, AAA naming
- [`oop-principles`](.github/skills/oop-principles/) — sibling; contract tests enforce Liskov Substitution
- [`architecture-review`](.github/skills/architecture-review/) — sibling; interfaces also need layer boundary review
