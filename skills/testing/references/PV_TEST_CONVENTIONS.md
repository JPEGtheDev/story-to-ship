# Particle-Viewer Test Conventions

Project-specific testing patterns, examples, and design principles for Particle-Viewer.

---

## Unit Test Example (Camera)

```cpp
TEST(CameraTest, MoveForward_DefaultSpeed_IncreasesPosition)
{
    // Arrange
    Camera camera(800, 600);
    camera.cameraPos = glm::vec3(0.0f, 0.0f, 0.0f);
    camera.setSpeed(1.0f);

    // Act
    camera.moveForward();

    // Assert
    EXPECT_LT(camera.cameraPos.z, 0.0f);
}
```

---

## Integration Test Example (SettingsIO)

```cpp
TEST(DataLoadingPipelineTest, LoadSettings_ValidFile_PopulatesParticles)
{
    // Arrange
    SettingsIO settings;
    std::string test_file = createTestSettingsFile();

    // Act
    bool result = settings.loadSettings(test_file);

    // Assert
    EXPECT_TRUE(result);
    EXPECT_GT(settings.getParticleCount(), 0u);
}
```

---

## Test File Organization

- `tests/core/` — Unit tests for `src/*.hpp` classes
- `tests/integration/` — Multi-component tests
- `tests/testing/` — Tests for test utilities (PixelComparator, Image)
- `tests/visual-regression/` — Visual regression tests
- `tests/mocks/` — Mock implementations

File naming: each test file matches its source — `CameraTests.cpp` tests `camera.hpp`.

---

## Key Design Principles (Learned from Review Feedback)

1. **Use production classes in tests.** Visual regression tests MUST use `Particle` directly instead of re-implementing particle creation logic in a test helper class. This ensures tests stay in sync with production code.

2. **Group related data into POCOs/structs.** When a test or test helper has many flat member variables, group them into domain-specific structs (e.g., `RenderConfig`, `CameraSetup`). This mirrors the production code pattern.

3. **Clean up GL resources.** Every test that creates GL objects (VAOs, VBOs, FBOs, textures) must clean them up. Check for leaks in `cleanup()` / destructors.

4. **Binary file I/O.** Always open binary data files with `"rb"` mode (not `"r"`) for cross-platform correctness.

5. **Ensure output directories exist.** In test `SetUp()`, create all output directories (artifacts/, baselines/, diffs/) before tests run. Check `save()` return values so failures are actionable, not silent.

6. **Visual test resolution.** Use the viewer's default resolution (1280x720) for visual regression tests unless specifically testing other resolutions. Non-default resolutions can cause warping and scaling artifacts.

7. **Camera positioning for visual tests.** Don't blindly copy debug camera coordinates — debug shows interactive state, not ideal test framing. Extract the viewing **direction** from debug output, then calculate **distance** based on desired viewport coverage: `distance = subject_size / (coverage_% * tan(FOV/2))`. See `docs/visual-regression/camera-positioning-lessons-learned.md`.

8. **Every bug fix requires a regression test.** Write a test that reproduces the bug (fails before the fix). Fix the code. Confirm the test now passes. A bug fixed without a test is a bug scheduled for a return visit.

---

For project test runner commands, see the `execution` skill.

---

## Test Double Taxonomy

Use the **least sophisticated double** that answers your question. Reaching for `EXPECT_CALL` when a stub suffices is over-engineering.

| Double | Behavior | Verifies Calls? | When to Use |
|--------|----------|-----------------|-------------|
| **Stub** | No-op methods; returns null/zero/false | No | You need `IOpenGLContext` to not crash; you don't care what it called |
| **Fake** | Returns programmable values via setters | No | You need to control what `glGetError()` returns without interaction verification |
| **Mock** | Returns values AND verifies call expectations | Yes — test fails if expected calls are not made | You must assert `glDrawArrays` was called exactly once with specific arguments |
| **Shunt / SelfShunt** | The test fixture itself implements the interface | Inspected in teardown | Lowest setup overhead when the fixture plays both collaborator and verifier |

**Google Mock mapping:** Stub → subclass returning constants. Fake → subclass with setters. Mock → `MOCK_METHOD` + `EXPECT_CALL` + `Times()`. Shunt → `TEST_F` fixture inherits from the interface.

**Key principle:** Mock the *role* (interface), not the concrete object. `MockOpenGLContext` mocks `IOpenGLContext` — stable across implementation changes.

**When NOT to use Google Mock:** If the question is "does this run without crashing?", a stub suffices. Only use `EXPECT_CALL` when the interaction itself is the behavior under test.

---

For directory layout and file naming conventions, see **Test File Organization** above.

### Test Ordering

Within a file, order tests: basic → complex, common → edge cases.

---

## Test Size Taxonomy (SE@G Model)

Apply this taxonomy when classifying tests and deciding where they belong:

| Size | Resource use | Scope | Directory |
|------|-------------|-------|-----------|
| **Small** | No I/O, no network, no filesystem, no external processes, no OpenGL context | Single unit in memory | `tests/` root or subdirectory |
| **Medium** | Localhost I/O permitted (files, sockets), no external services, no real OpenGL | Component interactions, file I/O | `tests/integration/` |
| **Large** | Real OpenGL context, real GPU, external processes, full system | End-to-end rendering, visual output | `tests/visual-regression/` |

**Classification gate:** Before writing a test, classify it. If a "unit test" uses a real file, it is Medium. If it uses a real OpenGL context, it is Large. Misclassified tests in the wrong directory produce slow/unreliable CI runs.

---

## Additional Rationalization Prevention Rows

These supplement the core rows kept in SKILL.md:

| Excuse | Reality |
|--------|---------|
| "Tests after achieve the same goals" | Tests-after answer "what does this do?" Tests-first answer "what SHOULD this do?" |
| "Deleting X hours of work is wasteful" | Sunk cost. Keeping untested code is technical debt. |
| "The bug was a one-off, no regression test needed" | One-off bugs recur after the next refactoring. A regression test takes 5 minutes; a re-investigation takes hours. |

Additional Red Flags — STOP:

- "Tests after achieve the same goals"
- "Just this once" or "This is different because..."
- "I need to get the implementation right before I know what to test"
