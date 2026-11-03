# Test Smells

Load this reference when reviewing tests or noticing patterns that make tests unreliable, hard to understand, or misleading. Test smells are drawn from the Fowler/van Deursen catalog and represent patterns that undermine test quality.

---

## What Are Test Smells?

Test code requires its own refactoring discipline. Just like production code can have "code smells" that signal deeper design problems, test code has patterns that make tests less trustworthy, harder to understand, or easier to break.

**Key principle:** Test code can tolerate some duplication that production code cannot -- because tests serve as documentation of behavior. However, that tolerance has limits. Excessive abstraction in tests obscures what was actually tested. The balance: extract duplication that obscures nothing; keep inline whatever the reader needs to understand the test's intent.

**Gate question:** _Does this test help me understand what the code should do, or does it hide the intent?_

---

## Classic Test Smells

### Mystery Guest

**What:** The test uses external data or resources (files, databases, environment variables, system clock) without making that dependency explicit in the test.

```
[-] BAD: Test reads from <path-to-data>/test-config.json without explaining where it comes from
[+] GOOD: Test creates all data inline or via explicit factory; reader immediately understands what data the test needs
```

**Why it hurts:**
- Test failure is mysterious -- you can't understand why it failed without understanding the external dependency
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
[-] BAD: Test assumes the image file exists and is readable; doesn't check
[+] GOOD: Test setup creates the resource or mocks it; test succeeds or fails consistently
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
[-] BAD: Test A creates global state; Test B relies on that state; Suite fails if B runs first
[+] GOOD: Each test is fully independent; shared state is reset in setup/teardown; no implicit order
```

**Why it hurts:**
- Tests pass in isolation but fail in the full suite
- Debugging is impossible -- failures are non-deterministic
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
[-] BAD:
  setUp() {
      createDatabase()
      createNetwork()
      createFileSystem()
      createQueryEngine()
      createIndexer()
      createUI()
      createNetworkClients(10)
      // ... test only needs one query engine
  }

[+] GOOD:
  setUp() {
      queryEngine = createQueryEngine()
      // test creates additional state it actually needs
  }
```

**Why it hurts:**
- Test intent is obscured -- hard to understand what the test is actually verifying
- Tests run slowly due to unnecessary setup
- Small changes to the fixture affect many unrelated tests
- When fixture fails to set up, many tests break for the wrong reason

**Fix:**
- Each test creates only the state it needs
- Extract targeted factory methods that build specific scenarios
- Use parameterized tests if many tests need similar (but not identical) fixtures
- Move heavy setup to lazy initialization (only create what a test actually uses)
- If many tests need the same base state, build it with composition and helper functions; do not derive one fixture class from another fixture class to share base state

---

### Eager Test (Testing Too Much)

**What:** A single test verifies multiple unrelated behaviors. When it fails, you don't know which behavior broke.

```
[-] BAD:
  test "Calculation_Works":
      // Tests addition AND subtraction AND multiplication in one test
      assertEq(add(2, 3), 5)
      assertEq(subtract(10, 2), 8)
      assertEq(multiply(3, 4), 12)
  // If assertion 2 fails, did addition work? Who knows -- test did multiple things.

[+] GOOD:
  test "Addition_TwoPositives_ReturnsSum": ...
  test "Subtraction_LargerFromSmaller_ReturnsNegative": ...
  test "Multiplication_TwoPositives_ReturnsProduct": ...
```

**Why it hurts:**
- When the test fails, you don't know which behavior broke
- Test name cannot accurately describe what it tests -- names become vague ("Calculation_Works")
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
[-] BAD:
  test "LoadImage_ValidPath_Succeeds":
      image = loadImage("test.png")
      assertTrue(image != null)  // Too weak. Doesn't verify actual content.

[+] GOOD:
  test "LoadImage_ValidPath_ReturnsCorrectDimensions":
      image = loadImage("test.png")
      assertEq(image.width(), 256)
      assertEq(image.height(), 512)
      assertEq(image.pixelData().size(), 256 * 512 * 4)  // RGBA: 4 bytes per pixel for 256 x 512 pixels
```

**Why it hurts:**
- Creates false confidence -- test passes but the code is broken
- Doesn't actually verify the behavior; just checks that something happened
- Easy to pass accidentally (e.g., allocate memory without initializing it correctly)

**Fix:**
- Assert specific, observable outcomes
- Assert exact expected values instead of "is not null" or "is true" whenever a specific expected value exists
- If no specific expected value exists, do not fall back to a weak assertion -- ask instead: does this test matter?
- Use equality assertions (`==`, `===`) before inequality assertions (`>`, `<`)
- Test boundary conditions and specific cases, not just "something happened"

---

### Assertion Roulette

**What:** Multiple assertions in a test with no message explaining which assertion failed or why. When the test fails, you must re-run it or trace through code to identify the culprit.

```
[-] BAD:
  test "Operations_Work":
      vec.append(1)
      vec.append(2)
      vec.append(3)
      
      assertEq(vec.size(), 3)
      assertEq(vec[0], 1)
      assertEq(vec[1], 2)
      assertEq(vec[2], 3)
      // If test fails, which assertion triggered? You have to re-run.

[+] GOOD (One assert per test):
  test "Append_SingleElement_IncrementsSize":
      vec.append(1)
      assertEq(vec.size(), 1)

[+] ALSO GOOD (Multiple asserts with messages):
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
- Masks the first failure -- if assertion 1 and 2 both fail, only the first is reported
- Slows debugging

**Fix:**
- Use one assert per test when the test verifies a single fact
- When the test verifies several related facts about one outcome (e.g., checking each element of a produced structure), use multiple asserts, each with a clear message identifying context
- Use assertion messages that identify what you're checking: "Element at index 2", "Vector capacity", etc.
- Test name must describe the single behavior being verified

---

### Test Code Duplication

**What:** Same setup or assertion logic copied across multiple tests. Changing the production code requires updating many tests; copy errors introduce inconsistency.

```
[-] BAD (duplicated setup):
  test "Parser_ValidJson_ReturnsObject":
      json = '{ "name": "test", "age": 25 }'
      parser = new Parser()
      result = parser.parse(json)
      assertTrue(result.valid())
  
  test "Parser_ValidJson_ExtractsName":
      json = '{ "name": "test", "age": 25 }'  // copied
      parser = new Parser()
      result = parser.parse(json)
      assertEq(result.name(), "test")
  
  test "Parser_ValidJson_ExtractsAge":
      json = '{ "name": "test", "age": 25 }'  // copied again
      parser = new Parser()
      result = parser.parse(json)
      assertEq(result.age(), 25)

[+] GOOD (extracted helper):
  function validTestJSON():
      return '{ "name": "test", "age": 25 }'
  
  test "Parser_ValidJson_ReturnsObject":
      result = new Parser().parse(validTestJSON())
      assertTrue(result.valid())
  
  test "Parser_ValidJson_ExtractsName":
      result = new Parser().parse(validTestJSON())
      assertEq(result.name(), "test")
  
  test "Parser_ValidJson_ExtractsAge":
      result = new Parser().parse(validTestJSON())
      assertEq(result.age(), 25)
```

**Why it hurts:**
- Changing the test data requires updating many places
- Copy errors introduce inconsistencies (test A uses age 25, test B uses age 30 -- which was intended?)
- Tests are harder to maintain

**Fix:**
- Extract shared setup to helper functions (factories)
- Extract shared assertions to helper functions
- BUT preserve enough test detail that reading the test still reveals what it's testing -- don't hide the important parts in abstract helpers
- Use test fixtures or parameterized tests for common setup scenarios
- **Key balance:** DRY (Don't Repeat Yourself) is good; overly abstract tests are bad. Extract the "what" not the "why". Readers MUST be able to understand the test's intent from the test itself.

---

## Smells About Tests That Cannot Fail

These smells describe tests that cannot fail, or that fail only in ways that tell you nothing. Such a test looks like coverage while it verifies nothing, so review should flag it the same way it flags a missing assertion. The examples below are pseudocode; no rule depends on a particular tool or framework.

### Self-Agreeing Expected Value

**What:** The expected value is computed by the code under test, or by a helper that the code under test also uses. The test compares the code's output with the same logic that produced it, so it agrees with itself and cannot fail.

```
[-] BAD:
  test "Discount_TenPercent_AppliesRate":
      price = 200
      expected = applyDiscount(price, 10)   // same function under test
      assertEq(applyDiscount(price, 10), expected)

[+] GOOD:
  test "Discount_TenPercent_AppliesRate":
      assertEq(applyDiscount(200, 10), 180)  // 200 minus 10 percent, worked out by hand
```

**Why it hurts:**
- A bug in the shared logic changes the expected value and the actual value together, so the test still passes
- The test records whatever the code does today, not what it should do
- Reviewers read the test as a check and skip verifying the expected value

**Fix:**
- Write the expected value as a literal worked out independently, from the specification or by hand
- Never call the code under test, or its helpers, to compute the expected side
- See also the "Never Red" smell below

---

### Restated Constant

**What:** The test copies a string or number from the code and checks it against that copy, so the code that reads the constant never runs. The test still passes if the code stops using the constant or changes its value.

A deliberate wording pin on documentation text is allowed: there the text is the behavior, and CI checks the text itself. A constant copied from code and checked against itself stays the smell.

```
[-] BAD:
  RETRY_LIMIT = 5                              // copied from the production constant
  test "RetryLimit_Default_IsFive":
      assertEq(RETRY_LIMIT, 5)                 // reads the test's own copy; production code never runs

[+] GOOD:
  test "Client_NoRetryConfigured_StopsAfterDefaultLimit":
      client = new Client()                    // default configuration from production code
      result = client.send(alwaysFailingTransport())
      assertEq(result.attempts(), 5)           // asserts on what the default produces
```

**Why it hurts:**
- The test keeps passing after the code changes, so the constant can drift or become unused unnoticed
- It gives false confidence that the default behavior is covered
- Reviewers see a passing check and assume the code path ran

**Fix:**
- Exercise the code that reads the constant, and assert on what it produces
- Keep a wording pin only for documentation text, as described above

---

### Assertion on Self-Built Data

**What:** The assertion checks data the test built itself, such as the fixture or the mock's setup, not what the system produced. The system under test could drop or change that data and the assertion would still hold.

```
[-] BAD:
  test "UserStore_Save_PersistsUser":
      user = User(name: "Ada")
      fakeDb.rows = [user]                     // the test put the row in the fake itself
      store.save(user)
      assertEq(fakeDb.rows.size(), 1)          // checks the row the test added, not what save() wrote

[+] GOOD:
  test "UserStore_Save_PersistsUser":
      user = User(name: "Ada")
      store.save(user)
      assertEq(fakeDb.rows.size(), 1)
      assertEq(fakeDb.rows[0].name, "Ada")     // checks what save() produced
```

**Why it hurts:**
- The test passes even when the code under test does nothing
- Setup and assertion mirror each other, so the test verifies the fixture rather than the behavior
- A failure points at the fixture, not at the code

**Fix:**
- Assert on the output of the code under test
- Use the fixture only to supply inputs; read state back from the system after the call
- See also the "Never Red" smell below

---

### Timing-Dependent Test

**What:** The test uses a fixed sleep, the wall clock or a real timer to decide when work is done or when a deadline has passed. It passes on a fast machine and fails on a slow one.

```
[-] BAD:
  test "Cache_EntryExpires_AfterTtl":
      cache.put("k", v, ttl: 100 ms)
      sleep(150 ms)                            // hopes the timer has fired
      assertFalse(cache.contains("k"))

[+] GOOD:
  test "Cache_EntryExpires_AfterTtl":
      clock = FakeClock(start: 0)
      cache = new Cache(clock: clock)
      cache.put("k", v, ttl: 100)
      clock.advance(101)                       // move time explicitly
      assertFalse(cache.contains("k"))
```

**Why it hurts:**
- Fails intermittently under load and slows the suite
- The timing contract is hidden in a sleep value that nobody checks
- Hidden reads of the system clock are the Mystery Guest smell above

**Fix:**
- Pass the clock in, and advance it inside the test
- Where real concurrency cannot be avoided, wait on a condition with a timeout instead of a fixed sleep
- See `FLAKY_TESTS.md` for the flaky-test rules

---

### Oversized Harness

**What:** Broad setup, slow end-to-end infrastructure, or a large fixture is used for a small fix. The test starts a whole system to check one function.

```
[-] BAD:
  test "Tax_FractionalCents_Truncates":
      startDatabase()
      startHttpServer()
      seedFixtureFile("customers-10000.csv")
      result = callCheckoutApi(cartWith(item(price: 1999)))
      assertEq(result.tax, 159)

[+] GOOD:
  test "Tax_FractionalCents_Truncates":
      assertEq(computeTax(1999, rate: 8), 159) // unit level: the function that does the rounding
```

**Why it hurts:**
- The test is slow to run and hard to run locally
- It fails for reasons unrelated to the fix, so failures get ignored
- Developers skip the suite, and the check stops guarding anything

**Fix:**
- Use the narrowest test level that already exists for that code
- If the logic lives in one function, test that function
- Do not build new harnesses to cover a small fix

---

### Throwaway Test

**What:** A test is written to prove a fix and deleted right after the fix lands. The fixed behavior is then unchecked, so the bug can return without any test failing.

```
[-] BAD:
  test "Parser_TrailingComma_NoCrash":
      assertEq(parse("[1, 2,]"), list(1, 2))
  // Fix merged; test deleted because "it was only for checking the fix"

[+] GOOD:
  test "Parser_TrailingComma_ParsesWithoutError":
      assertEq(parse("[1, 2,]"), list(1, 2))
  // Kept in the suite as the regression test for the trailing-comma crash
```

**Why it hurts:**
- Nothing guards the fixed behavior after the change lands
- The same bug can return unnoticed in a later change

**Fix:**
- Keep the test that proved the fix as the regression test
- Name it for the behavior it protects, not for the bug ticket
- Confirm it fails on the old code before the fix is applied (RED-first)

---

## The Test Duplication Trade-Off

Key principle: **test duplication is more tolerable than production duplication** because tests serve as documentation.

```
[-] BAD: Over-abstracted test that obscures the behavior
  test "SeniorityAllValid":
      sub = makeValidSubmarine(submarineClassStandard)
      verifyBehavior(sub, expectedStateA)
  // Reader has to trace through makeValidSubmarine and verifyBehavior to understand what's being tested

[+] GOOD: Test repeats some setup but intent is clear
  test "Submarine_AtSurface_DiveIncreasesDepth":
      // Arrange
      submarine = new Submarine(maxDepth: 800, ballastCapacity: 600)
      submarine.position = Vector3(0, 0, 0)
      
      // Act
      submarine.dive(depth: 50)
      
      // Assert
      expectEq(submarine.position.z, -50)
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
- Visual regression test baseline created from first run without ever seeing the test fail
- Baseline image generated from the same code path it's testing
- Integration test that passes immediately without verifying any assertions are actually checked

**Fix:**
- **RED-first discipline:** Write the test FIRST, see it fail, understand the failure, THEN write code.
- If a test passes immediately without changes: the test is wrong. Fix it before writing production code.
- Verify each test can actually detect breakage: intentionally break the production code and confirm the test fails.

---

## Key Principles

1. **One behavior per test.** If the test name contains "and", split it.

2. **Explicit over implicit.** All test data is visible in the test; no external files or magic setup.

3. **Independent execution.** No test depends on another test running first. No shared mutable state between tests.

4. **Red-first always.** Write the test, watch it fail, understand the failure, THEN write production code.

5. **Test the contract, not the implementation.** If production code changes internally but the behavior is the same, the test MUST still pass. If the test must change, it was testing implementation details, not behavior.

6. **Weak assertions hide bugs.** "Is not null" is not a valid assertion. Assert specific, observable outcomes.

7. **Messages matter.** When a test fails, the message must immediately explain what went wrong and why -- not force re-running or tracing.

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
| Never Red | Test has always passed | Fix the test; RED-first. See it fail. |
| Self-Agreeing Expected Value | Expected value is computed by the code under test | Write the expected value as a literal worked out by hand |
| Restated Constant | Test checks a copied constant against itself; code never runs | Exercise the code that reads the constant; wording pins only for docs |
| Assertion on Self-Built Data | Assertion checks data the test itself set up | Assert on the output of the code under test |
| Timing-Dependent Test | Fixed sleep, wall clock or real timer decides the outcome | Pass the clock in; wait on a condition |
| Oversized Harness | Broad setup or slow infrastructure for a small fix | Use the narrowest test level that already exists |
| Throwaway Test | Test written to prove a fix and then deleted | Keep it as the regression test |
