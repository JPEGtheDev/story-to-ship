---
name: testing
description: Write tests for Particle-Viewer following AAA pattern, naming conventions, and project testing standards. Use when writing unit tests, integration tests, visual regression tests, or reviewing test code. Covers Google Test patterns, mock usage, and visual comparison testing.
license: MIT
compatibility: Designed for GitHub Copilot and similar AI coding agents
metadata:
  author: JPEGtheDev
  version: "1.1"
  category: testing
  project: Particle-Viewer
---

# Instructions for Agent

## How This Skill is Invoked

In VS Code, users will activate this skill by:
- Typing `@workspace /testing [description]` in Copilot Chat
- Or asking: "Write a test for [feature]", "Add visual regression tests", "Review my test code"

When activated, write tests that strictly follow the project's testing standards.

---

## Core Approach: Standards-First Testing

**Every test MUST follow the Arrange-Act-Assert (AAA) pattern with all three phases as separate sections.**

Before writing any test, **load and review** [references/TESTING_EXAMPLES.md](references/TESTING_EXAMPLES.md) for concrete examples of correct and incorrect patterns.

---

## Step 1: Determine Test Type

Ask the user what they need:

> "What would you like to test? I support:
> 1. **Unit tests** — Test a single class/function in isolation
> 2. **Integration tests** — Test component interactions
> 3. **Visual regression tests** — Compare images pixel-by-pixel
> 4. **Test review** — Check existing tests against our standards"

---

## Step 2: Write Tests Following AAA Pattern

### The Three Phases (ALWAYS separate)

Every test MUST have three distinct comment sections:

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

### Critical Rules

1. **NEVER combine phases.** Do not write `// Arrange & Act` or `// Act & Assert`. Each phase gets its own comment and section.
   - **Exception:** `// Act & Assert` is acceptable only for `EXPECT_NO_THROW`/`EXPECT_THROW` tests where the action IS the assertion.
2. **If no Arrange is needed**, omit `// Arrange` entirely — start with `// Act`.
3. **Move expected values to Arrange** as named variables, not inline in Assert.
4. **One logical concept per test** — split if testing multiple behaviors.

### Naming Convention

Use format: `UnitName_StateUnderTest_ExpectedResult`

Examples:
- `MoveForward_IncreasesZPosition`
- `Compare_IdenticalImages_ReturnsMatch`
- `ParsePPM_InvalidFile_ReturnsEmptyData`

---

## Step 3: Choose the Right Test Pattern

### Unit Tests (tests/core/)

Test a single class method in isolation. Use MockOpenGL for OpenGL calls.

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

### Integration Tests (tests/integration/)

Test component interactions. May involve multiple classes.

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

### Visual Regression Tests (tests/visual-regression/)

Use production classes (e.g., `Particle`) directly — **never duplicate production logic in test helpers**.
Use `PixelComparator` and the `Image` class for pixel comparison.

```cpp
TEST_F(RenderingRegressionTest, RenderDefaultCube_AngledView_MatchesBaseline)
{
    // Arrange
    Shader particleShader(vertexPath.c_str(), fragmentPath.c_str());
    Particle particles;  // Uses production Particle class directly
    glm::mat4 view = glm::lookAt(cameraPos, cameraTarget, cameraUp);
    glm::mat4 projection = glm::perspective(glm::radians(45.0f), aspect, 0.1f, 3000.0f);

    // Act
    glContext_.bindFramebuffer();
    renderParticle(particles, particleShader, view, projection);
    Image currentImage = glContext_.captureFramebuffer();

    // Assert
    Image baseline = Image::load(baselinePath, ImageFormat::PNG);
    PixelComparator comparator;
    ComparisonResult result = comparator.compare(baseline, currentImage, tolerance, true);
    EXPECT_TRUE(result.matches);
}
```

---

## Step 4: Apply Test File Organization

### Directory Structure

- `tests/core/` — Unit tests for `src/*.hpp` classes
- `tests/integration/` — Multi-component tests
- `tests/testing/` — Tests for test utilities (PixelComparator, Image)
- `tests/visual-regression/` — Visual regression tests
- `tests/mocks/` — Mock implementations

### File Naming

Each test file matches its source: `CameraTests.cpp` tests `camera.hpp`.

### Test Ordering

Within a file, order tests: basic → complex, common → edge cases.

---

## Step 5: Self-Review Checklist

Before presenting tests, verify:

- [ ] Every test has separate `// Arrange`, `// Act`, `// Assert` comments (no `// Arrange & Act`)
- [ ] Test name follows `UnitName_StateUnderTest_ExpectedResult` pattern
- [ ] Expected values are named variables in Arrange (not inline literals in Assert)
- [ ] One logical concept per test
- [ ] External dependencies are mocked (OpenGL, file I/O)
- [ ] No testing of external libraries (std::, third-party code)
- [ ] Visual regression tests use production classes (Particle, Camera) — no duplicated test helpers
- [ ] Group related configuration into structs/POCOs instead of flat variables
- [ ] Resource cleanup: GL objects deleted in destructors/cleanup, check for leaks
- [ ] Tests compile and pass

---

## Key Design Principles (Learned from Review Feedback)

1. **Use production classes in tests.** Visual regression tests should use `Particle` directly instead of re-implementing particle creation logic in a test helper class. This ensures tests stay in sync with production code.

2. **Group related data into POCOs/structs.** When a test or test helper has many flat member variables, group them into domain-specific structs (e.g., `RenderConfig`, `CameraSetup`). This mirrors the production code pattern.

3. **Clean up GL resources.** Every test that creates GL objects (VAOs, VBOs, FBOs, textures) must clean them up. Check for leaks in `cleanup()` / destructors.

4. **Binary file I/O.** Always open binary data files with `"rb"` mode (not `"r"`) for cross-platform correctness.

---

## Key Types for Visual Regression

| Type | Location | Purpose |
|------|----------|---------|
| `Image` | `src/Image.hpp` | RGBA pixel buffer with save/load (PPM, PNG) |
| `ComparisonResult` | `src/testing/PixelComparator.hpp` | Match status, similarity, diff image |
| `PixelComparator` | `src/testing/PixelComparator.hpp` | Pixel comparison engine |
| `ImageFormat` | `src/Image.hpp` | Format enum (PPM, PNG) for Image::save/load |
| `Particle` | `src/particle.hpp` | Production particle data (std::vector<glm::vec4>) |

---

## Common Edge Cases to Handle

- Ask if the user wants `EXPECT_*` (non-fatal) or `ASSERT_*` (fatal) assertions
- For visual tests: recommend `0.0f` tolerance for synthetic data, `2.0f/255.0f` for GPU-rendered
- If a test seems to test external library behavior, suggest focusing on the wrapper/integration instead
- If Arrange and Act seem identical, the test might be a constructor test — put expected values in Arrange, constructor call in Act

---

## CI Pipeline Rules

For CI workflow rules (artifact uploads, permissions, PR comments), see the `workflow` skill (`.github/skills/workflow/`).
