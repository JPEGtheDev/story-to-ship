# Generic Testing Patterns

Generic testing canon: decision rules promoted in SKILL.md live here in full, with tables and templates.

---

## AAA Pattern -- Critical Rules

1. **NEVER combine phases.** Do not write `// Arrange & Act` or `// Act & Assert`. Each phase gets its own comment and section.
   - **Exception:** `// Act & Assert` is acceptable only for `EXPECT_NO_THROW`/`EXPECT_THROW` tests where the action IS the assertion.
2. **If no Arrange is needed**, omit `// Arrange` entirely -- start with `// Act`.
3. **Move expected values to Arrange** as named variables, not inline in Assert.
4. **One logical concept per test** -- split if testing multiple behaviors.

---

## AAA Pattern -- Template (Three Phases)

```cpp
TEST(SuiteName, MethodName_Condition_ExpectedResult)
{
    // Arrange
    // Set up test preconditions, create objects, define expected values

    // Act
    // Execute the single operation being tested

    // Assert
    // Verify the outcome
}
```

---

## Test Double Taxonomy

Use the **least sophisticated double** that answers your question. Reaching for `EXPECT_CALL` when a stub suffices is over-engineering.

| Double | Behavior | Verifies Calls? | When to Use |
|--------|----------|-----------------|-------------|
| **Stub** | No-op methods; returns null/zero/false | No | You need the collaborator interface to not crash; you don't care what it called |
| **Fake** | Returns programmable values via setters | No | You need to control what an error-code getter returns without interaction verification |
| **Mock** | Returns values AND verifies call expectations | Yes -- test fails if expected calls are not made | You must assert a specific method was called exactly once with specific arguments |
| **Shunt / SelfShunt** | The test fixture itself implements the interface | Inspected in teardown | Lowest setup overhead when the fixture plays both collaborator and verifier |

**Google Mock mapping:** Stub -> subclass returning constants. Fake -> subclass with setters. Mock -> `MOCK_METHOD` + `EXPECT_CALL` + `Times()`. Shunt -> `TEST_F` fixture inherits from the interface.

**Key principle:** Mock the *role* (interface), not the concrete object. `MockWidget` mocks `IWidget` -- stable across implementation changes.

**When NOT to use Google Mock:** If the question is "does this run without crashing?", a stub suffices. Only use `EXPECT_CALL` when the interaction itself is the behavior under test.

---

## Test Size Taxonomy (Software Engineering at Google Model)

Apply this taxonomy when classifying tests and deciding where they belong:

| Size | Resource use | Scope | Directory |
|------|-------------|-------|-----------|
| **Small** | No I/O, no network, no filesystem, no external processes, no GPU (Graphics Processing Unit)/display context | Single unit in memory | `tests/` root or subdirectory |
| **Medium** | Localhost I/O permitted (files, sockets), no external services, no real GPU/display context | Component interactions, file I/O | `tests/integration/` |
| **Large** | Real GPU/display context, real GPU, external processes, full system | End-to-end rendering, visual output | `tests/visual-regression/` |

**Classification gate:** Before writing a test, classify it. If a "unit test" uses a real file, it is Medium. If it uses a real GPU/display context, it is Large. Misclassified tests in the wrong directory produce slow/unreliable CI runs.

---

## The Depended-Upon Behavior Rule

Any behavior that your code **relies upon** must have a test. This applies to:
- Your own functions (don't assume they work; prove it)
- Libraries you depend on (test the integration point, not the library internals)
- Configuration assumptions (if the behavior would surprise you if it changed, test it)

The inverse: if behavior changes and no test breaks, that behavior was untested. It is not safe to change -- it is merely unverified to be safe. Add the test now.

---

## Coincidence Articulation

Tests that mirror the implementation's structure detect nothing -- they fail together or pass together regardless of correctness.

**Rule:** The test must reason about the problem independently from the implementation.
- Test input/output contracts, not internal data structures
- Test what the function is supposed to do, not how it currently does it
- If the test would pass for any implementation that uses the same algorithm, it is not testing a contract -- it is testing an implementation coincidence

Signal: if modifying the test file requires looking at the source file, the test is mirroring implementation structure. The test MUST be written from requirements, not from reading the implementation.

---

## Agile Alarm Bell

**Agile Alarm Bell:** "Let's refactor without writing tests first" is the most dangerous phrase pair in software. Refactoring without a test suite to hold behavior constant is not refactoring -- it is reckless restructuring. Stop. Write characterization tests first. Then refactor.

---

## Naming Examples

Use format: `UnitName_StateUnderTest_ExpectedResult`

- `ParseConfig_MissingFile_ReturnsEmptyConfig`
- `Cache_EvictionUnderPressure_PreservesNewestEntry`
