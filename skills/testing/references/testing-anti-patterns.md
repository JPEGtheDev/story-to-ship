# Testing Anti-Patterns

Load this reference when writing tests, adding mocks, or tempted to add test-only methods. **Tests must verify real behavior, not mock behavior.**

---

## Iron Laws

1. NEVER test mock behavior -- test what the real code does
2. NEVER add test-only methods to production classes
3. NEVER mock without understanding what you're mocking

---

## Anti-Pattern 1: Testing Mock Behavior

**The trap:** You set up a `MockDatabase`, call the code under test, then assert that the mock was called -- instead of asserting what the code _produced_.

```cpp
// BAD: asserting mock was called proves nothing about real behavior
TEST(QueryCompilerTest, Compile_ValidSource_Succeeds)
{
    // Arrange
    MockDatabase mockDB;
    EXPECT_CALL(mockDB, compileQuery(_)).Times(1);  // <- tests mock, not behavior

    // Act
    QueryCompiler compiler(mockDB, querySrc);

    // Assert
    // Nothing -- the EXPECT_CALL IS the assertion. This is wrong.
}
```

```cpp
// GOOD: assert what the production code actually produces
TEST(QueryCompilerTest, Compile_ValidSource_PlanIdIsNonZero)
{
    // Arrange
    MockDatabase mockDB;
    mockDB.DelegateToFake();  // fake returns realistic plan ids

    // Act
    QueryCompiler compiler(mockDB, querySrc);

    // Assert
    EXPECT_NE(compiler.getPlanId(), 0u);
}
```

**Gate function -- BEFORE asserting on any mock:**
> "Am I testing real behavior or mock existence?"
> If mock existence: delete the assertion and test the observable outcome instead.

---

## Anti-Pattern 2: Test-Only Methods in Production Classes

**The trap:** A test needs to reset state, so you add a `reset()` or `destroy()` method to the production class and mark it `// for tests only`.

**Why it is wrong:**
- Production classes accumulate dead weight that confuses maintainers
- `destroy()` called accidentally in production corrupts state with no safety net
- The method is never tested itself -- it becomes a landmine

**The fix:** put setup and teardown in test fixtures, not production classes.

```cpp
// BAD: production class polluted with test-only hook
class IndexBuilder {
public:
    void build(const Dataset& dataset);
    void resetForTest();  // <- never called in production, dangerous
};
```

```cpp
// GOOD: test fixture owns its own lifecycle
class IndexBuilderTest : public ::testing::Test {
protected:
    void SetUp() override   { builder_ = std::make_unique<IndexBuilder>(); }
    void TearDown() override { builder_.reset(); }
    std::unique_ptr<IndexBuilder> builder_;
};
```

**Gate function -- BEFORE adding any method to a production class:**
> "Is this method called from non-test code?"
> If no: don't add it. Move the logic to the test fixture.

---

## Anti-Pattern 3: Mocking Without Understanding

**The trap:** `MockDatabase` makes tests compile, so you mock every database call and ship the test -- without ever running the real path or knowing which calls actually matter.

**Why it is wrong:** if you mock the very method that produces the state your test depends on, the test becomes circular. It passes because the mock returns what you told it to return, not because the code is correct.

**The process:**
1. Run the test against real code first -- even if it crashes or fails due to a missing database connection
2. Read the failure. Understand what the code needs from the database layer
3. Mock ONLY the database boundary calls. Let the logic above the mock run for real

```cpp
// BAD: mocking getLastError "to be safe" when the test doesn't need it
MockDatabase mockDB;
ON_CALL(mockDB, getLastError()).WillByDefault(Return(DB_NO_ERROR));
ON_CALL(mockDB, openConnection()).WillByDefault(Return(1));
ON_CALL(mockDB, bindParameter(_, _)).WillByDefault(Return());
// ...20 more lines of mock setup for a test that checks a depth calculation
```

```cpp
// GOOD: mock only the database boundary; let the math run for real
MockDatabase mockDB;
ON_CALL(mockDB, openConnection()).WillByDefault(Return(1));

Submarine submarine(800, 600);  // maxDepth, ballastCapacity -- no DB needed, pure math
submarine.dive();
EXPECT_LT(submarine.position.z, 0.0f);
```

**Gate function -- BEFORE mocking any method:**
> "Run the test with real code first (even if it fails). Understand what the test actually needs. THEN mock at the correct level."

---

## Anti-Pattern 4: Incomplete Mock Data

**The trap:** A test needs index-entry data, so you create a `std::vector<std::array<float, 4>>` with one element and a made-up value -- without matching the layout the production code actually expects.

**Why it is wrong:** the test passes because the mocked data never exercises structural assumptions. When real data arrives, the code fails.

**The fix:** mirror the complete real data structure.

```cpp
// BAD: partial mock -- real code expects the 4th element to encode record type
std::vector<std::array<float, 4>> entries = { {1.0f, 2.0f, 3.0f, 0.0f} };  // last field is uninitialized

// GOOD: mirror the real layout (first 3 = coordinates, 4th = record type id)
std::vector<std::array<float, 4>> entries = {
    {1.0f,  2.0f, 3.0f, 1.0f},   // type 1
    {-1.0f, 0.0f, 1.0f, 2.0f},   // type 2
};
```

When a production factory or generator method already produces the exact structure the code needs, use it -- for test data here, the production `IndexEntry` class. Otherwise, hand-build data that mirrors the complete real structure (see the GOOD example above):

```cpp
IndexEntry entries;
entries.loadDefaultBatch();  // real production method -- no duplication
```

---

## Anti-Pattern 5: Visual Regression Tests Without Red-Green

**The trap:** create the baseline image, write the test, run it -- it passes immediately. Ship it.

**Why it is wrong:** a test that has never been red cannot be trusted. If the baseline was created from buggy output, the test permanently encodes that bug as "correct."

**The process (RED must come first):**

```
BAD sequence:
  1. Generate report
  2. Save as baseline.png
  3. Write test comparing against baseline.png
  4. Test passes [+]
  -> You have tested nothing. You compared output to itself.

GOOD sequence:
  1. Write the test with no baseline (or a deliberately wrong one)
  2. Run the test -> it FAILS [-]  (this is RED -- required)
  3. Inspect the failure: is the output artifact correct?
  4. If yes: promote it to baseline.png
  5. Run the test -> it PASSES [+]  (GREEN)
```

The visual test **MUST fail before the baseline is correct.** If it never failed, delete the baseline and start over.

---

## Anti-Pattern 6: Happy-Path-Only Doubles

**The trap:** You mock a failure-capable collaborator -- file I/O, a database call, an allocator -- and every configured return is a success value. The failure branch in the production code that handles that collaborator's error case is never executed by any test.

**Why it is wrong:** the rare failure is exactly what a double is _for_. Real collaborators fail rarely and nondeterministically -- a double is the only way to make that branch run deterministically, on every run. A double that only ever hands back success values idealizes the collaborator away instead of standing in for it.

This does not contradict using a happy-path default: Anti-Pattern 3's GOOD example sets `ON_CALL(mockDB, openConnection()).WillByDefault(Return(1))` so the test can target pure logic above the boundary -- that is a legitimate happy-path default. The defect this entry names is different: no test anywhere in the suite ever overrides such a default to force the failure branch.

**The fix:** for each mocked failure-capable call, add at least one test that forces its failure mode, or state in the test why this collaborator cannot fail.

```cpp
// BAD: every configured return is success -- the error path never runs
TEST(QueryCompilerTest, Compile_ValidSource_Succeeds)
{
    // Arrange
    MockDatabase mockDB;
    ON_CALL(mockDB, getCompileStatus(_, _, _)).WillByDefault(SetArgPointee<2>(true));

    // Act
    QueryCompiler compiler(mockDB, querySrc);

    // Assert
    EXPECT_TRUE(compiler.isValid());
    // No test anywhere forces getCompileStatus to report failure --
    // the error-handling branch in QueryCompiler is never exercised.
}
```

```cpp
// GOOD: a companion test forces the failure mode deterministically
TEST(QueryCompilerTest, Compile_QueryCompileFails_IsValidReturnsFalse)
{
    // Arrange
    MockDatabase mockDB;
    ON_CALL(mockDB, getCompileStatus(_, _, _)).WillByDefault(SetArgPointee<2>(false));

    // Act
    QueryCompiler compiler(mockDB, querySrc);

    // Assert
    EXPECT_FALSE(compiler.isValid());
}
```

---

## Red Flags -- Stop Before Proceeding

- Mock setup is longer than the test logic
- Test breaks when you change the mock, not the production code
- You cannot explain in one sentence why a mock is needed
- Mocking "to be safe" or "it might be slow without it"
- Production class has a method that is only called from test files
- Test assertions are on `*Mock` objects, not on production return values
- Visual test baseline was created from the same run that first produced the output

---

## Quick Reference

| Anti-Pattern | Fix |
|---|---|
| Assert on mock behavior | Test real behavior; remove the mock assertion |
| Test-only method in production class | Move to test fixtures / `TearDown()` |
| Mock without understanding | Run real code first; mock minimally and intentionally |
| Incomplete mock data | Use a production generator if one exists; otherwise hand-build the full structure |
| Visual test passes before baseline | Delete baseline; see it fail first, then promote |
| Happy-path-only doubles | Force each mocked failure mode in at least one test |
