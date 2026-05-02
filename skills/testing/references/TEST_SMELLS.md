# Test Smells

Load this reference when reviewing tests or noticing patterns that make tests unreliable, hard to understand, or misleading. Test smells are drawn from the Fowler/van Deursen catalog and represent patterns that undermine test quality.

---

## What Are Test Smells?

Test code requires its own refactoring discipline. Just like production code can have "code smells" that signal deeper design problems, test code has patterns that make tests less trustworthy, harder to understand, or easier to break.

**Key principle:** Test code can tolerate some duplication that production code cannot — because tests serve as documentation of behavior. However, that tolerance has limits. Excessive abstraction in tests obscures what was actually tested. The balance: extract duplication that obscures nothing; keep inline whatever the reader needs to understand the test's intent.

**Gate question:** _Does this test help me understand what the code should do, or does it hide the intent?_

---

## Classic Test Smells

### Mystery Guest

**What:** The test uses external data or resources (files, databases, environment variables, system clock) without making that dependency explicit in the test.

```
✗ BAD: Test reads from /home/user/data/test-config.json without explaining where it comes from
✓ GOOD: Test creates all data inline or via explicit factory; reader immediately understands what data the test needs
```

**Why it hurts:**
- Test failure is mysterious — you can't understand why it failed without understanding the external dependency
- Test may pass locally but fail in CI (environment differences)
- When the external resource changes, tests fail silently

**Fix:**
- Make all test data explicit and local
- Use factory methods that clearly show what data the test needs
- If reading from disk is necessary, create the test file within the test itself
- Never rely on environment variables without documenting them in the test

---

### Resource Optimism

**What:** Test assumes an external resource (file, network service, database, system directory) is available and ready without verifying or controlling it.

```
✗ BAD: Test assumes the image file exists and is readable; doesn't check
✓ GOOD: Test setup creates the resource or mocks it; test succeeds or fails consistently
```

**Why it hurts:**
- Tests fail intermittently (flaky tests) based on environment state
- CI passes when someone happens to have the resource; fails when they don't
- Makes it impossible to run tests in parallel or on fresh environments

**Fix:**
- Mock or stub the external dependency
- Test setup must guarantee what the test needs (create temp files, mock API responses, etc.)
- Verify resources exist before tests use them; fail fast with a clear setup error
- Never assume external services are running

---

### Test Run War (Order Dependence)

**What:** Tests interfere with each other when run simultaneously or in unexpected order. One test's success depends on another test having run first.

```
✗ BAD: Test A creates global state; Test B relies on that state; Suite fails if B runs first
✓ GOOD: Each test is fully independent; shared state is reset in setup/teardown; no implicit order
```

**Why it hurts:**
- Tests pass in isolation but fail in the full suite
- Debugging is impossible — failures are non-deterministic
- Running tests in parallel (faster CI) reveals the problem
- Order-dependent tests hide design flaws in the production code

**Fix:**
- Each test is fully independent; no test depends on side effects from another test
- Use setup/teardown (fixtures, before/after methods) to reset shared state for each test
- No test relies on another test having run first
- Use unique temporary directories or database instances per test if multiple tests share infrastructure
- Run tests in randomized order during development to catch order dependencies early

---

### General Fixture (Overly Generic Setup)

**What:** Test setup creates far more state than any individual test needs. The fixture sets up 20 objects when the test only uses 3.

```
✗ BAD:
  setUp() {
      createDatabase()
      createNetwork()
      createFileSystem()
      createRenderer()
      createParticleSystem()
      createUI()
      createNetworkClients(10)
      // ... test only needs one renderer
  }

✓ GOOD:
  setUp() {
      renderer = createRenderer()
      // test creates additional state it actually needs
  }
```

**Why it hurts:**
- Test intent is obscured — hard to understand what the test is actually verifying
- Tests run slowly due to unnecessary setup
- Small changes to the fixture affect many unrelated tests
- When fixture fails to set up, many tests break for the wrong reason

**Fix:**
- Each test creates only the state it needs
- Extract targeted factory methods that build specific scenarios
- Use parameterized tests if many tests need similar (but not identical) fixtures
- Move heavy setup to lazy initialization (only create what a test actually uses)
- If many tests need the same base state, use inheritance sparingly — favor composition and helper functions

---

### Eager Test (Testing Too Much)

**What:** A single test verifies multiple unrelated behaviors. When it fails, you don't know which behavior broke.

```
✗ BAD:
  test "Calculation_Works":
      // Tests addition AND subtraction AND multiplication in one test
      assertEq(add(2, 3), 5)
      assertEq(subtract(10, 2), 8)
      assertEq(multiply(3, 4), 12)
  // If assertion 2 fails, did addition work? Who knows — test did multiple things.

✓ GOOD:
  test "Addition_TwoPositives_ReturnsSum": ...
  test "Subtraction_LargerFromSmaller_ReturnsNegative": ...
  test "Multiplication_TwoPositives_ReturnsProduct": ...
```

**Why it hurts:**
- When the test fails, you don't know which behavior broke
- Test name cannot accurately describe what it tests — names become vague ("Calculation_Works")
- Debugging is hard because multiple things can cause failure
- Refactoring breaks one behavior but the test still passes (the other behaviors still work)

**Fix:**
- One test, one behavior
- Test name must accurately describe what is being tested
- Split tests if you're tempted to write "and" in the name
- If test requires many setup steps, that's a signal to break it into smaller tests or extract a helper

---

### Lazy Test (Testing Too Little)

**What:** Test makes assertions so broad or weak they can't catch real failures. "Is not null", "is true", "is greater than zero".

```
✗ BAD:
  test "LoadImage_ValidPath_Succeeds":
      image = loadImage("test.png")
      assertTrue(image != null)  // Too weak. Doesn't verify actual content.

✓ GOOD:
  test "LoadImage_ValidPath_ReturnsCorrectDimensions":
      image = loadImage("test.png")
      assertEq(image.width(), 256)
      assertEq(image.height(), 512)
      assertGt(image.pixelData().size(), 0)  // Specific, observable outcome
```

**Why it hurts:**
- Creates false confidence — test passes but the code is broken
- Doesn't actually verify the behavior; just checks that something happened
- Easy to pass accidentally (e.g., allocate memory without initializing it correctly)

**Fix:**
- Assert specific, observable outcomes
- Prefer exact expected values over "is not null" or "is true"
- If you can't specify an expected value, ask: does this test matter?
- Use equality assertions (`==`, `===`) before inequality assertions (`>`, `<`)
- Test boundary conditions and specific cases, not just "something happened"

---

### Assertion Roulette

**What:** Multiple assertions in a test with no message explaining which assertion failed or why. When the test fails, you must re-run it or trace through code to identify the culprit.

```
✗ BAD:
  test "Operations_Work":
      vec.append(1)
      vec.append(2)
      vec.append(3)
      
      assertEq(vec.size(), 3)
      assertEq(vec[0], 1)
      assertEq(vec[1], 2)
      assertEq(vec[2], 3)
      // If test fails, which assertion triggered? You have to re-run.

✓ GOOD (One assert per test):
  test "Append_SingleElement_IncrementsSize":
      vec.append(1)
      assertEq(vec.size(), 1)

✓ ALSO GOOD (Multiple asserts with messages):
  test "Append_ThreeElements_PopulatesCorrectly":
      vec.append(1)
      vec.append(2)
      vec.append(3)
      
      assertEq(vec.size(), 3, "Expected size 3 after three appends")
      assertEq(vec[0], 1, "First element should be 1")
      assertEq(vec[1], 2, "Second element should be 2")
      assertEq(vec[2], 3, "Third element should be 3")
```

**Why it hurts:**
- When the test fails, you must re-run or trace to identify which assertion triggered
- Masks the first failure — if assertion 1 and 2 both fail, only the first is reported
- Slows debugging

**Fix:**
- Prefer: one assert per test (simplest and clearest)
- Alternatively: multiple asserts with clear messages identifying context
- Use assertion messages that identify what you're checking: "Element at index 2", "Vector capacity", etc.
- Test name must describe the single behavior being verified

---

### Test Code Duplication

**What:** Same setup or assertion logic copied across multiple tests. Changing the production code requires updating many tests; copy errors introduce inconsistency.

```
✗ BAD (duplicated setup):
  test "ParseValidJSON_ReturnsObject":
      json = '{ "name": "test", "age": 25 }'
      parser = new Parser()
      result = parser.parse(json)
      assertTrue(result.valid())
  
  test "ParseJSON_ExtractsName":
      json = '{ "name": "test", "age": 25 }'  // copied
      parser = new Parser()
      result = parser.parse(json)
      assertEq(result.name(), "test")
  
  test "ParseJSON_ExtractsAge":
      json = '{ "name": "test", "age": 25 }'  // copied again
      parser = new Parser()
      result = parser.parse(json)
      assertEq(result.age(), 25)

✓ GOOD (extracted helper):
  function validTestJSON():
      return '{ "name": "test", "age": 25 }'
  
  test "ParseValidJSON_ReturnsObject":
      result = new Parser().parse(validTestJSON())
      assertTrue(result.valid())
  
  test "ParseJSON_ExtractsName":
      result = new Parser().parse(validTestJSON())
      assertEq(result.name(), "test")
  
  test "ParseJSON_ExtractsAge":
      result = new Parser().parse(validTestJSON())
      assertEq(result.age(), 25)
```

**Why it hurts:**
- Changing the test data requires updating many places
- Copy errors introduce inconsistencies (test A uses age 25, test B uses age 30 — which was intended?)
- Tests are harder to maintain

**Fix:**
- Extract shared setup to helper functions (factories)
- Extract shared assertions to helper functions
- BUT preserve enough test detail that reading the test still reveals what it's testing — don't hide the important parts in abstract helpers
- Use test fixtures or parameterized tests for common setup scenarios
- **Key balance:** DRY (Don't Repeat Yourself) is good; overly abstract tests are bad. Extract the "what" not the "why". Readers should still understand the test's intent from the test itself.

---

## The Test Duplication Trade-Off

Key principle: **test duplication is more tolerable than production duplication** because tests serve as documentation.

```
✗ BAD: Over-abstracted test that obscures the behavior
  test "SeniorityAllValid":
      cam = makeValidCamera(cameraPerspective)
      verifyBehavior(cam, expectedStateA)
  // Reader has to trace through makeValidCamera and verifyBehavior to understand what's being tested

✓ GOOD: Test repeats some setup but intent is clear
  test "MoveForward_IncreasesDepth":
      // Arrange
      camera = new Camera(width: 800, height: 600)
      camera.position = Vector3(0, 0, 0)
      
      // Act
      camera.moveForward()
      
      // Assert
      expectLt(camera.position.z, 0)
```

The balance: extract duplication that obscures nothing; keep inline whatever the reader needs to understand the test's intent.

---

## The "Never Red" Smell

**What:** A test that has never failed cannot be trusted.

If a test has always passed:
- Either the test never truly verified the behavior
- Or the baseline was generated from the same code it's supposed to verify
- Or the test is so weak it can't detect breakage

**Why it hurts:**
- False confidence: you believe the behavior is tested, but it's not
- The test encodes the current behavior (buggy or correct) as "correct"

**Examples:**
- Visual regression test baseline created from first render without ever seeing the test fail
- Baseline image generated from the same render loop it's testing
- Integration test that passes immediately without verifying any assertions are actually checked

**Fix:**
- **RED-first discipline:** Write the test FIRST, see it fail, understand the failure, THEN write code.
- If a test passes immediately without changes: delete it. The test is broken. Start over.
- Verify each test can actually detect breakage: intentionally break the production code and confirm the test fails.

---

## Key Principles

1. **One behavior per test.** If the test name contains "and", split it.

2. **Explicit over implicit.** All test data is visible in the test; no external files or magic setup.

3. **Independent execution.** No test depends on another test running first. No shared mutable state between tests.

4. **Red-first always.** Write the test, watch it fail, understand the failure, THEN write production code.

5. **Test the contract, not the implementation.** If production code changes internally but the behavior is the same, the test should still pass. If the test must change, it was testing implementation details, not behavior.

6. **Weak assertions hide bugs.** "Is not null" is not a valid assertion. Assert specific, observable outcomes.

7. **Messages matter.** When a test fails, the message must immediately explain what went wrong and why — not force re-running or tracing.

8. **Tests document behavior.** If reading the test doesn't clarify what the code should do, the test is not serving its purpose.

---

## Quick Reference

| Smell | Signal | Fix |
|-------|--------|-----|
| Mystery Guest | Test uses external data with no explanation | Make all data explicit; use factories |
| Resource Optimism | Test assumes external resource exists | Mock or create resource in setup; verify it exists |
| Test Run War | Tests pass alone, fail in suite | Eliminate shared state; reset in setup/teardown |
| General Fixture | Setup creates far more than test needs | Extract targeted factories; each test builds its own |
| Eager Test | One test checks multiple behaviors | Split into focused tests; one behavior per test |
| Lazy Test | Assertions are too weak ("is not null") | Assert exact, observable outcomes |
| Assertion Roulette | Multiple asserts, no way to know which failed | One assert per test, or use clear messages |
| Test Code Duplication | Same setup/assert copied across tests | Extract to helpers, but preserve test intent |
| Never Red | Test has always passed | Delete and restart; RED-first. See it fail. |
