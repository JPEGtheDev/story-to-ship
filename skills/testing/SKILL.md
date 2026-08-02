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

- **RED:** Write one failing test. Name: `UnitName_Condition_ExpectedResult`. YOU MUST SEE IT FAIL -- confirm it fails for the expected reason, not a compile error. If it passes immediately: the test is wrong. Fix it before writing production code.
- **GREEN:** Write the simplest code to make it pass. ALL tests must pass (not just the new one).
- **REFACTOR:** Remove duplication, improve names. Never add behavior. Tests stay green throughout.

---

## Step 1: Determine Test Type

- **Unit test** -- single class/function in isolation -> `tests/core/`
- **Integration test** -- component interactions -> `tests/integration/`

Classification gate: if a "unit test" touches a real file it is an integration test; a real GPU/display context makes it visual/large. Classify BEFORE writing. Full text: `references/TESTING_PATTERNS.md`.

- **Visual regression test** -- pixel comparison -> load `visual-regression-testing` skill
- **Test review** -- check existing tests against standards -> apply the `## BEFORE PROCEEDING` checklist

---

## Step 2: Write Tests Following AAA (Arrange-Act-Assert) Pattern

Every test MUST have three distinct comment sections: `// Arrange`, `// Act`, `// Assert`.

For the complete AAA rule set and template, see `references/TESTING_PATTERNS.md`.

### Naming Convention

Use format: `UnitName_StateUnderTest_ExpectedResult`

Examples:
- `UserLogin_WithValidCredentials_GrantsAccess`

**`_ExpectedResult` must describe the behavior or invariant proven -- not the return value.** The result name must answer "what property holds?" not "what did the call return?". `_SeekIsAbsolute` is better than `_ReturnsTrue`; `_CacheMissCallsReader` is better than `_ReturnsValue`.

See `references/TESTING_PATTERNS.md` for naming examples.

For visual regression, see the `visual-regression-testing` skill.

---

## BEFORE PROCEEDING

Before presenting tests, verify:

1. Every test has separate `// Arrange`, `// Act`, `// Assert` comments (no `// Arrange & Act`). Exception: `// Act & Assert` is acceptable ONLY for `EXPECT_THROW`/`EXPECT_NO_THROW` tests where the action IS the assertion; if no Arrange is needed, omit the `// Arrange` comment. Full text: `references/TESTING_PATTERNS.md`.
2. Test name follows `UnitName_StateUnderTest_ExpectedResult` pattern
3. Expected values are named variables in Arrange (not inline literals in Assert)
4. One logical concept per test
5. Depended-upon behavior is tested: any behavior your code relies on has a test; if behavior can change and no test breaks, it was untested. Full text: `references/TESTING_PATTERNS.md`.
6. Saw the new test FAIL before writing production code (confirms the test can detect failure; a test that passes immediately is broken)
7. External dependencies are mocked (OpenGL, file I/O). Use the least sophisticated double that answers the question, and mock the role (interface), not the concrete object. Full text: `references/TESTING_PATTERNS.md`.
8. No testing of external libraries (std::, third-party code)
9. Group related configuration into structs/POCOs instead of flat variables
10. Resource cleanup: GL objects deleted in destructors/cleanup, check for leaks
11. Tests compile and pass
12. For any class whose state feeds the UI: each UI-displayed field has a unit test verifying the public accessor returns the correct value (not just that the field is set internally)
13. For functions that return bool/error-code: failure-path tests assert output parameters are unchanged (e.g., `EXPECT_EQ(outValue, initialValue)` after `EXPECT_FALSE(call(..., &outValue))`)
14. For visual regression tests: see visual-regression-testing skill checklist

[+] All met -> proceed
[-] Any unmet -> write the test first before touching implementation code

---

## Red Flags -- STOP

If you catch yourself thinking any of these, STOP and start over with RED:

- Writing implementation code before writing a test
- "I'll write tests after to verify it works"
- "The visual regression test will cover this"
- "It's too complex to unit test with MockOpenGL" (MockOpenGL exists for exactly this)
- "I already manually tested it"
- Test passes immediately without seeing it fail first
- Fixed a bug without writing a regression test that reproduces it first
- A test double (mock or stub) that only ever returns happy-path values -- STOP. A double exists to FORCE the rare condition (error return, timeout, boundary value) deterministically on every run. Add the failure-forcing case, or state in the test why the double's collaborator cannot fail.
- A test that mirrors the implementation's structure, or that you could only write by reading the source -- it tests a coincidence, not a contract. Full text: `references/TESTING_PATTERNS.md`.
- "Let's refactor without writing tests first" -- reckless restructuring, not refactoring; characterization tests come first. Full text: `references/TESTING_PATTERNS.md`.
- "Tests after achieve the same goals"
- "I need to get the implementation right before I know what to test"
- "Just this once" or "This is different because..."

**All of these mean: Delete any code written before the test. Start over with RED.**

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. The test takes 30 seconds. |
| "I'll write tests after" | Tests passing immediately after implementation prove nothing. |
| "Visual regression test will cover it" | Visual tests are slow and test pixels, not logic. Unit test the logic. |
| "Too complex to test in isolation" | That's a design signal. Simplify the interface. MockOpenGL is there for GL calls. |
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

- `contract-testing` -- sub-domain skill; every abstract type or interface requires a contract test fixture -- load this skill when the type has 2+ implementations
- `visual-regression-testing` -- sub-domain skill; pixel-level output testing boundary; unit and contract tests do not replace visual regression
- `code-quality` -- clang-format and naming conventions apply to test code too

**Testing principles (T2-T4):** See the `contract-testing` skill -- unit tests as constraints, acceptance vs unit boundary, simplicity check

---

## Reference Files

- `references/testing-anti-patterns.md` -- common testing anti-patterns (testing mock behavior, test-only methods in production classes, mocking without understanding, incomplete mock data, visual regression tests without Red-Green, happy-path-only doubles)
- `references/TEST_SMELLS.md` -- test smells catalog (Fowler/van Deursen): patterns that undermine reliability, readability, or correctness
- `references/TESTING_PATTERNS.md` -- generic testing canon: AAA rules + template, test double taxonomy, test size model (Software Engineering at Google), depended-upon behavior rule, coincidence articulation, Agile Alarm Bell, naming examples

