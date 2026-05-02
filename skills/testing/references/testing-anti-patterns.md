# Testing Anti-Patterns

Load this reference when writing tests, adding mocks, or tempted to add test-only methods. **Tests must verify real behavior, not mock behavior.**

---

## Iron Laws

1. NEVER test mock behavior — test what the real code does
2. NEVER add test-only methods to production classes
3. NEVER mock without understanding what you're mocking

---

## Anti-Pattern 1: Testing Mock Behavior

**The trap:** You set up a `MockOpenGL`, call the code under test, then assert that the mock was called — instead of asserting what the code _produced_.

```cpp
// BAD: asserting mock was called proves nothing about real behavior
TEST(ShaderTest, Compile_ValidSource_Succeeds)
{
    // Arrange
    MockOpenGL mockGL;
    EXPECT_CALL(mockGL, glCreateShader(_)).Times(1);  // ← tests mock, not behavior

    // Act
    Shader shader(mockGL, vertSrc, fragSrc);

    // Assert
    // Nothing — the EXPECT_CALL IS the assertion. This is wrong.
}
```

```cpp
// GOOD: assert what the production code actually produces
TEST(ShaderTest, Compile_ValidSource_ProgramIdIsNonZero)
{
    // Arrange
    MockOpenGL mockGL;
    mockGL.DelegateToFake();  // fake returns realistic GL ids

    // Act
    Shader shader(mockGL, vertSrc, fragSrc);

    // Assert
    EXPECT_NE(shader.getProgramId(), 0u);
}
```

**Gate function — BEFORE asserting on any mock:**
> "Am I testing real behavior or mock existence?"
> If mock existence: delete the assertion and test the observable outcome instead.

---

## Anti-Pattern 2: Test-Only Methods in Production Classes

**The trap:** A test needs to reset state, so you add a `reset()` or `destroy()` method to the production class and mark it `// for tests only`.

**Why it is wrong:**
- Production classes accumulate dead weight that confuses maintainers
- `destroy()` called accidentally in production corrupts state with no safety net
- The method is never tested itself — it becomes a landmine

**The fix:** put setup and teardown in test fixtures, not production classes.

```cpp
// BAD: production class polluted with test-only hook
class Renderer {
public:
    void render(const Scene& scene);
    void resetForTest();  // ← never called in production, dangerous
};
```

```cpp
// GOOD: test fixture owns its own lifecycle
class RendererTest : public ::testing::Test {
protected:
    void SetUp() override   { renderer_ = std::make_unique<Renderer>(); }
    void TearDown() override { renderer_.reset(); }
    std::unique_ptr<Renderer> renderer_;
};
```

**Gate function — BEFORE adding any method to a production class:**
> "Is this method called from non-test code?"
> If no: don't add it. Move the logic to the test fixture.

---

## Anti-Pattern 3: Mocking Without Understanding

**The trap:** `MockOpenGL` makes tests compile, so you mock every GL call and ship the test — without ever running the real path or knowing which calls actually matter.

**Why it is wrong:** if you mock the very method that produces the state your test depends on, the test becomes circular. It passes because the mock returns what you told it to return, not because the code is correct.

**The process:**
1. Run the test against real code first — even if it crashes or fails due to missing GL context
2. Read the failure. Understand what the code needs from the GL layer
3. Mock ONLY the GL boundary calls. Let the logic above the mock run for real

```cpp
// BAD: mocking glGetError "to be safe" when the test doesn't need it
MockOpenGL mockGL;
ON_CALL(mockGL, glGetError()).WillByDefault(Return(GL_NO_ERROR));
ON_CALL(mockGL, glCreateBuffer()).WillByDefault(Return(1));
ON_CALL(mockGL, glBindBuffer(_, _)).WillByDefault(Return());
// ...20 more lines of mock setup for a test that checks a matrix calculation
```

```cpp
// GOOD: mock only the GL boundary; let the math run for real
MockOpenGL mockGL;
ON_CALL(mockGL, glCreateBuffer()).WillByDefault(Return(1));

Camera camera(800, 600);  // no GL needed — camera is pure math
camera.moveForward();
EXPECT_LT(camera.cameraPos.z, 0.0f);
```

**Gate function — BEFORE mocking any method:**
> "Run the test with real code first (even if it fails). Understand what the test actually needs. THEN mock at the correct level."

---

## Anti-Pattern 4: Incomplete Mock Data

**The trap:** A test needs particle data, so you create a `std::vector<glm::vec4>` with one element and a made-up value — without matching the layout the production code actually expects.

**Why it is wrong:** the test passes because the mocked data never exercises structural assumptions. When real data arrives, the code fails.

**The fix:** mirror the complete real data structure.

```cpp
// BAD: partial mock — real code expects w component to encode particle type
std::vector<glm::vec4> particles = { {1.0f, 2.0f, 3.0f, 0.0f} };  // w=0 is uninitialized

// GOOD: mirror the real layout (x,y,z = position, w = particle type id)
std::vector<glm::vec4> particles = {
    {1.0f,  2.0f, 3.0f, 1.0f},   // type 1
    {-1.0f, 0.0f, 1.0f, 2.0f},   // type 2
};
```

Use the production `Particle` class to generate test data wherever possible:

```cpp
Particle particles;
particles.loadDefaultCube();  // real production method — no duplication
```

---

## Anti-Pattern 5: Visual Regression Tests Without Red-Green

**The trap:** create the baseline image, write the test, run it — it passes immediately. Ship it.

**Why it is wrong:** a test that has never been red cannot be trusted. If the baseline was created from buggy output, the test permanently encodes that bug as "correct."

**The process (RED must come first):**

```
BAD sequence:
  1. Render scene
  2. Save as baseline.png
  3. Write test comparing against baseline.png
  4. Test passes ✓
  → You have tested nothing. You compared output to itself.

GOOD sequence:
  1. Write the test with no baseline (or a deliberately wrong one)
  2. Run the test → it FAILS ✗  (this is RED — required)
  3. Inspect the failure: is the rendered output visually correct?
  4. If yes: promote it to baseline.png
  5. Run the test → it PASSES ✓  (GREEN)
```

The visual test **MUST fail before the baseline is correct.** If it never failed, delete the baseline and start over.

---

## Red Flags — Stop Before Proceeding

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
| Incomplete mock data | Mirror complete real data structure; prefer production classes |
| Visual test passes before baseline | Delete baseline; see it fail first, then promote |
