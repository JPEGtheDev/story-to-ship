---
name: testing
license: MIT
description: Use when writing or reviewing any test.
---


## Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
YOU MUST write a failing test before writing any production code.
No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

Write the test. Watch it fail. THEN write code.

If you wrote code before the test: **Delete it. Start over.** No exceptions.
- Don't keep it as "reference"
- Don't "adapt" it while writing tests
- Don't look at it while writing tests
- Delete means delete

**Announce at start:** "I am using the testing skill to [write/review/fix] [specific test description]."

---

## TDD (Test-Driven Development) Cycle

**RED -> GREEN -> REFACTOR. In that order. Every time.**

- **RED:** Write one failing test. Name it per the Naming Convention section. YOU MUST SEE IT FAIL -- confirm it fails for the expected reason, not a compile error. If it passes immediately: the test is wrong. Fix it before writing production code.
- **GREEN:** Write the simplest code to make it pass. ALL tests must pass (not just the new one).
- **REFACTOR:** Remove duplication, improve names. Never add behavior. Tests stay green throughout.

**Three-role loop:** when the plan marks a todo `loop: three-role`, RED, GREEN and REFACTOR are done by three different implementers. The test-writer writes the RED test, touching test files only, and commits it only once the failure is a run-time assertion failure (not a compile or import error). The pass-maker writes the GREEN code, touching non-test files only, and keeps the full suite green. The refactorer cleans up, keeps the suite green, and changes no behaviour. The role rules are in the three-role loop reference of the subagent-driven-development skill.

---

## Step 1: Determine Test Type

- **Unit test** -- single class/function in isolation -> `tests/` root or subdirectory
- **Integration test** -- component interactions -> `tests/integration/`

Classification gate: if a "unit test" touches a real file it is an integration test; a real GPU (Graphics Processing Unit) or display context makes it visual/large. Classify BEFORE writing. Full text: `references/TESTING_PATTERNS.md`.

- **Visual regression test** -- pixel comparison -> load `visual-regression-testing` skill
- **Test review** -- check existing tests against standards -> apply the `## BEFORE PROCEEDING` checklist

---

## Step 2: Write Tests Following AAA (Arrange-Act-Assert) Pattern

Every test MUST have three distinct comment sections -- Arrange, Act, Assert -- in the test language's comment syntax: `// Arrange` (C++), `# Arrange` (Python, shell).

For the complete AAA rule set and template, see `references/TESTING_PATTERNS.md`.

### Naming Convention

Use format: `UnitName_StateUnderTest_ExpectedResult`

Examples:
- `UserLogin_WithValidCredentials_GrantsAccess`

**The ExpectedResult part must describe the behavior or invariant proven -- not the return value.** The result name must answer "what property holds?" not "what did the call return?". `_SeekIsAbsolute` is better than `_ReturnsTrue`; `_CacheMissCallsReader` is better than `_ReturnsValue`.

See `references/TESTING_PATTERNS.md` for naming examples.

For visual regression, see the `visual-regression-testing` skill.

---

## BEFORE PROCEEDING

Before presenting tests, verify:

1. Every test has separate Arrange, Act, and Assert comments in the test language's comment syntax (no combined Arrange-and-Act comment). Exception: a combined Act-and-Assert comment is acceptable ONLY for a test whose assertion wraps the action (it asserts that the call throws, or does not throw), where the action IS the assertion; if no Arrange is needed, omit the Arrange comment. Full text: `references/TESTING_PATTERNS.md`.
2. Test name follows `UnitName_StateUnderTest_ExpectedResult` pattern
3. Expected values are named variables in Arrange (not inline literals in Assert)
4. One logical concept per test
5. Depended-upon behavior is tested: any behavior your code relies on has a test; if behavior can change and no test breaks, it was untested. Full text: `references/TESTING_PATTERNS.md`.
6. Saw the new test FAIL before writing production code (confirms the test can detect failure; a test that passes immediately is broken)
7. Unit (Small) tests mock external dependencies (database, file input/output (I/O)); integration (Medium) tests may use local files. Use the least sophisticated double that answers the question, and mock the role (interface), not the concrete object. Full text: `references/TESTING_PATTERNS.md`.
8. No testing of external libraries (standard library, third-party code)
9. Group related configuration into plain data structures instead of flat variables
10. Resource cleanup: database connections and file handles closed by cleanup code, check for leaks
11. Tests compile and pass
12. For any class whose state feeds the UI (User Interface): each UI-displayed field has a unit test verifying the public accessor returns the correct value (not just that the field is set internally)
13. For functions that return bool/error-code: failure-path tests assert output parameters are unchanged
14. For visual regression tests: see visual-regression-testing skill checklist

For C++ tests, items 1, 8, 9, 10, and 13 have specifics in `## C++ and Google Test Specifics`.

[+] All met -> proceed
[-] Any unmet -> write the test first before touching implementation code

---

## C++ and Google Test Specifics

- Item 1 exception: `EXPECT_THROW`/`EXPECT_NO_THROW` tests may use `// Act & Assert`.
- Item 8: do not test `std::` or other external library code.
- Item 9: group related configuration into structs/POCOs (Plain Old C++ Objects).
- Item 10: close database connections and file handles in destructors or other cleanup code.
- Item 13: after a failing call, assert the output is unchanged, e.g. `EXPECT_EQ(outValue, initialValue)` after `EXPECT_FALSE(call(..., &outValue))`.

---

## Red Flags -- STOP

If you catch yourself thinking any of these, STOP and take the action the item names:

- Writing implementation code before writing a test
- "I'll write tests after to verify it works"
- "The visual regression test will cover this"
- "It's too complex to unit test with a database double" (write a database double; that is what doubles are for)
- "I already manually tested it"
- Test passes immediately without seeing it fail first -- fix the test
- Fixed a bug without writing a regression test that reproduces it first
- A test double (mock or stub) that only ever returns happy-path values -- STOP. A double exists to FORCE the rare condition (error return, timeout, boundary value) deterministically on every run. Add the failure-forcing case, or state in the test why the double's collaborator cannot fail.
- A test that mirrors the implementation's structure, or that you could only write by reading the source -- it tests a coincidence, not a contract; rewrite the test from the requirements. Full text: `references/TESTING_PATTERNS.md`.
- "Let's refactor without writing tests first" -- reckless restructuring, not refactoring; characterization tests come first. Full text: `references/TESTING_PATTERNS.md`.
- "Tests after achieve the same goals"
- "I need to get the implementation right before I know what to test"
- "Just this once" or "This is different because..."

**Each item above names its own action; items without one: delete code written before the test and start over with RED.**

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. The test takes 30 seconds. |
| "I'll write tests after" | Tests passing immediately after implementation prove nothing. |
| "Visual regression test will cover it" | Visual tests are slow and test pixels, not logic. Unit test the logic. |
| "Too complex to test in isolation" | That's a design signal. Simplify the interface, and use a database double for database calls. |
| "Already manually tested it" | Manual testing is ad-hoc. No record, can't re-run, misses edge cases. |
| "TDD slows me down" | TDD is faster than debugging production failures. |
| "Tests after achieve the same goals" | Tests-after answer "what does this do?" Tests-first answer "what SHOULD this do?" |
| "Deleting X hours of work is wasteful" | Sunk cost. Keeping untested code is technical debt. |
| "The bug was a one-off, no regression test needed" | One-off bugs recur after the next refactoring. A regression test takes 5 minutes; a re-investigation takes hours. |

---

## Self-Evaluation

When test work is complete, load the `self-evaluation` skill and follow its steps.

---

## CI Pipeline Rules

For CI workflow rules (artifact uploads, permissions, PR comments), see the `workflow` skill.

---

## Related Skills

- `contract-testing` -- sub-domain skill; every interface or abstract type with 2+ implementations (a mock counts) requires a contract test fixture -- load it for such a type
- `visual-regression-testing` -- sub-domain skill; pixel-level output testing boundary; unit and contract tests do not replace visual regression
- `code-quality` -- clang-format and naming conventions apply to test code too

**Testing principles:** See the `contract-testing` skill -- unit tests as constraints, acceptance vs unit boundary, simplicity check

---

## Reference Files

- `references/testing-anti-patterns.md` -- common testing anti-patterns (testing mock behavior, test-only methods in production classes, mocking without understanding, incomplete mock data, visual regression tests without Red-Green, happy-path-only doubles)
- `references/TEST_SMELLS.md` -- test smells catalog (Fowler/van Deursen): patterns that undermine reliability, readability, or correctness
- `references/TESTING_PATTERNS.md` -- generic testing canon: AAA rules + template, test double taxonomy, test size model (Software Engineering at Google), depended-upon behavior rule, coincidence articulation, Agile Alarm Bell, naming examples

