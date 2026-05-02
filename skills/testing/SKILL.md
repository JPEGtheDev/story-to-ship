---
name: testing
license: MIT
description: Use when writing or reviewing any test for Particle-Viewer.
---

## Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

YOU MUST write a failing test before writing any production code. No exceptions.

Write the test. Watch it fail. THEN write code.

If you wrote code before the test: **Delete it. Start over.** No exceptions.
- Don't keep it as "reference"
- Don't "adapt" it while writing tests
- Don't look at it while writing tests
- Delete means delete

**Announce at start:** "I am using the testing skill to [write/review/fix] [specific test description]."

---

## TDD Cycle

**RED → GREEN → REFACTOR. In that order. Every time.**

- **RED:** Write one failing test. Name: `UnitName_Condition_ExpectedResult`. YOU MUST SEE IT FAIL — confirm it fails for the expected reason, not a compile error. If it passes immediately: the test is wrong. Fix it before writing production code.
- **GREEN:** Write the simplest code to make it pass. ALL tests must pass (not just the new one).
- **REFACTOR:** Remove duplication, improve names. Never add behavior. Tests stay green throughout.

For PV test runner commands, see `references/PV_TEST_CONVENTIONS.md`.

---

## Step 1: Determine Test Type

- **Unit test** — single class/function in isolation → `tests/core/`
- **Integration test** — component interactions → `tests/integration/`
- **Visual regression test** — pixel comparison → load `visual-regression-testing` skill
- **Test review** — check existing tests against standards → apply checklist in Step 3

---

## Step 2: Write Tests Following AAA Pattern

Every test MUST have three distinct comment sections: `// Arrange`, `// Act`, `// Assert`.

For the complete AAA rule set, code examples, and advanced patterns, see `references/TESTING_EXAMPLES.md`.

### Naming Convention

Use format: `UnitName_StateUnderTest_ExpectedResult`

Examples:
- `MoveForward_IncreasesZPosition`

See `references/TESTING_EXAMPLES.md` for PV naming examples.

For PV-specific test patterns (Camera, SettingsIO examples), test double taxonomy, file organization, and test size taxonomy, see `references/PV_TEST_CONVENTIONS.md`. For visual regression, see the `visual-regression-testing` skill.

---

## Step 3: Self-Review Checklist

Before presenting tests, verify:

- [ ] Every test has separate `// Arrange`, `// Act`, `// Assert` comments (no `// Arrange & Act`)
- [ ] Test name follows `UnitName_StateUnderTest_ExpectedResult` pattern
- [ ] Expected values are named variables in Arrange (not inline literals in Assert)
- [ ] One logical concept per test
- [ ] Saw the new test FAIL before writing production code (confirms the test can detect failure; a test that passes immediately is broken)
- [ ] External dependencies are mocked (OpenGL, file I/O)
- [ ] No testing of external libraries (std::, third-party code)
- [ ] Group related configuration into structs/POCOs instead of flat variables
- [ ] Resource cleanup: GL objects deleted in destructors/cleanup, check for leaks
- [ ] Tests compile and pass
- [ ] For visual regression tests: see visual-regression-testing skill checklist

✓ All met → proceed
✗ Any unmet → write the test first before touching implementation code

---

## Red Flags — STOP

If you catch yourself thinking any of these, STOP and start over with RED:

- Writing implementation code before writing a test
- "I'll write tests after to verify it works"
- "The visual regression test will cover this"
- "It's too complex to unit test with MockOpenGL" (MockOpenGL exists for exactly this)
- "I already manually tested it"
- Test passes immediately without seeing it fail first
- Fixed a bug without writing a regression test that reproduces it first

**All of these mean: Delete any code written before the test. Start over with RED.**

See `references/TESTING_EXAMPLES.md` for the Agile Alarm Bell warning on refactoring without tests.

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

---

## Self-Evaluation

When test work is complete, load the `self-evaluation` skill and follow its steps.

---

## CI Pipeline Rules

For CI workflow rules (artifact uploads, permissions, PR comments), see the `workflow` skill.

---

## Related Skills

- `contract-testing` — sub-domain skill; every abstract type or interface requires a contract test fixture — load this skill when the type has 2+ implementations
- `visual-regression-testing` — sub-domain skill; pixel-level output testing boundary; unit and contract tests do not replace visual regression
- `code-quality` — clang-format and naming conventions apply to test code too

**Testing principles (T2–T4):** See the `contract-testing` skill — unit tests as constraints, acceptance vs unit boundary, simplicity check

---

## Reference Files

- `references/testing-anti-patterns.md` — common testing anti-patterns (testing mock behavior, test-only methods in production classes, mocking without understanding, incomplete mock data, visual regression tests without Red-Green)
- `references/TEST_SMELLS.md` — test smells catalog (Fowler/van Deursen): patterns that undermine reliability, readability, or correctness

