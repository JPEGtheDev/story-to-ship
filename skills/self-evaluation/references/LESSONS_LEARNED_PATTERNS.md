# Lessons Learned Patterns

Concrete examples of lessons captured from past sessions and how they were incorporated into project skills.

---

## Code Quality Lessons

### Binary File I/O (PR #73)

**Problem:** `getCOM()` opened binary data files with text mode (`"r"`), which on Windows translates `\r\n` bytes and corrupts binary reads.

**Lesson:** Always open binary data files with `"rb"` mode for cross-platform correctness.

**Added to:** `copilot-instructions.md` → Error Handling section, `testing` skill → Key Design Principles

### Return By Const Reference (PR #73)

**Problem:** `getProjection()` returned a `glm::mat4` by value, copying a 4x4 matrix every frame in the render loop.

**Lesson:** Return large objects (matrices, vectors, structs) by `const&` from getters when the member is stored in the class.

**Added to:** `copilot-instructions.md` → Common Pitfalls

### GLFW Key Bounds Check (PR #73)

**Problem:** `keys_[key]` indexed without validation. GLFW can pass `GLFW_KEY_UNKNOWN` (-1), causing out-of-bounds access.

**Lesson:** Bounds-check GLFW key callbacks — `GLFW_KEY_UNKNOWN` is -1.

**Added to:** `copilot-instructions.md` → OpenGL Usage section

---

## Testing Lessons

### Separate Act and Assert (PR #64)

**Problem:** Tests combined `// Act & Assert` phases, making failures harder to diagnose.

**Lesson:** Always keep Act and Assert as separate phases, even when they seem naturally combined.

**Added to:** `testing` skill → Critical Rules, `TESTING_EXAMPLES.md` → Incorrect Examples

### Production Classes in Tests (PR #73)

**Problem:** Visual regression test helper duplicated Particle's cube generation logic, creating a maintenance burden and false confidence.

**Lesson:** Use production classes (e.g., `Particle`) directly in tests — never duplicate production logic in test helpers.

**Added to:** `testing` skill → Key Design Principles, `TESTING_EXAMPLES.md` → correct/incorrect patterns

### Ensure Output Directories Exist (PR #72)

**Problem:** Tests saved artifacts to `artifacts/` but only ensured `baselines/` existed. Silent write failures in CI.

**Lesson:** Ensure all output directories exist in test `SetUp()`, and check `save()` return values.

**Added to:** `testing` skill → Self-Review Checklist

### Camera Positioning for Visual Tests (PR #71)

**Problem:** Debug camera output was blindly copied as test camera coordinates, but debug shows interactive state, not ideal framing.

**Lesson:** Extract viewing direction from debug output, but calculate distance based on desired viewport coverage. Formula: `distance = subject_size / (coverage_% * tan(FOV/2))`.

**Added to:** `copilot-instructions.md` → Visual Regression Tests section, `docs/visual-regression/camera-positioning-lessons-learned.md`

---

## Architecture Lessons

### Group Related State Into Structs (PR #73)

**Problem:** `ViewerApp` had 10+ flat member variables for window, rendering, recording state.

**Lesson:** Group related member variables into POCOs/structs (e.g., `WindowConfig`, `RenderResources`). Structs should provide their own defaults.

**Added to:** `copilot-instructions.md` → Data Organization, `testing` skill → Key Design Principles

### Headers Must Be Self-Contained (PR #70)

**Problem:** `debugOverlay.hpp` used `std::cerr` without including `<iostream>`, relying on transitive includes.

**Lesson:** Headers must include all their own dependencies. Don't rely on transitive includes from other headers.

**Added to:** `copilot-instructions.md` → Common Pitfalls

### GL Resource Cleanup (PR #73)

**Problem:** `cleanup()` only deleted FBO, leaking other GL objects (textures, renderbuffers, VAOs, VBOs).

**Lesson:** Clean up ALL GL resources in destructors — VAOs, VBOs, FBOs, RBOs, textures. Check for non-zero before deleting.

**Added to:** `copilot-instructions.md` → Memory Management

### GL_POINT_SIZE_RANGE Clamping (PR #81)

**Problem:** Resolution independence test at 4K computed `gl_PointSize` of 366px, but hardware max was 256px. OpenGL silently clamped it, making the particle appear ~50% smaller. A loose test tolerance (0.01) masked the defect.

**Lesson:** `gl_PointSize` is silently clamped by `GL_POINT_SIZE_RANGE` (256px on Mesa/llvmpipe). When testing resolution-independent scaling, choose camera distances that keep computed point sizes under this limit at all target resolutions. Use tolerances proportional to the values being compared — an absolute tolerance larger than the expected value itself will mask real failures.

**Added to:** `copilot-instructions.md` → OpenGL Usage

### Cross-Mesa Baseline Stability (PR #81)

**Problem:** Adding `* (viewportHeight / REFERENCE_HEIGHT)` to the shader (where both equal 720.0, so `* 1.0`) caused a 1-pixel sprite-boundary difference on CI's Mesa version but not locally. The baseline comparison required 100% pixel match, so 1 pixel out of 921,600 failed the entire test.

**Lesson:** Different Mesa/llvmpipe versions may compile the same shader differently, causing sprite-boundary rounding differences. Visual regression baselines should allow a small `MAX_DIFF_RATIO` (e.g., 0.01%) instead of requiring 100% pixel match. Always `ASSERT_TRUE(image.save(...))` artifact writes so debug images are not silently lost.

**Added to:** `copilot-instructions.md` → Test Issues

---

## ImGui Integration Lessons

### FetchContent for Libraries Without CMakeLists.txt (PR #79, updated PR #82)

**Problem:** ImGui doesn't ship a CMakeLists.txt, so `FetchContent_MakeAvailable()` tries to call `add_subdirectory()` and fails. Using `FetchContent_Populate()` works but is deprecated in CMake 3.31+.

**Lesson:** Use `FetchContent_Declare()` with `SOURCE_SUBDIR` set to a non-existent path, then call `FetchContent_MakeAvailable()`. This downloads the source without attempting `add_subdirectory()`, and avoids the `FetchContent_Populate()` deprecation warning. Then add the source files manually to your target.

**Added to:** `copilot-instructions.md` → ImGui Integration

### GLFW Callback Chaining Order (PR #79)

**Problem:** ImGui's GLFW backend saves and chains to existing callbacks when `install_callbacks=true`. If ImGui is initialized before ViewerApp sets its callbacks, the chain is broken.

**Lesson:** Set application GLFW callbacks (e.g., `glfwSetKeyCallback`) **before** calling `ImGui_ImplGlfw_InitForOpenGL(window, true)`. ImGui saves the current callbacks and chains to them, ensuring both ImGui and the application receive input events.

**Added to:** `copilot-instructions.md` → ImGui Integration

### ImGui Renders to Default Framebuffer (PR #79)

**Problem:** Needed to ensure ImGui menus don't appear in FBO-based screenshots and frame recordings.

**Lesson:** ImGui renders to the default framebuffer after the FBO blit pass. Since recording reads pixels from the offscreen FBO (before the blit), ImGui content is naturally excluded. This is an architectural advantage of the FBO pipeline — no special handling needed.

**Added to:** `copilot-instructions.md` → ImGui Integration

### Debug Overlay Must Offset for Menu Bar (PR #79)

**Problem:** Debug overlay positioned at y=5 was hidden behind the ImGui menu bar (~25px high). The first line (including FPS counter) was not visible.

**Lesson:** Use ImGui windows instead of raw GL overlays — `ImGui::GetFrameHeight()` gives the actual menu bar height for dynamic positioning. This avoids hard-coded offsets that break with DPI/font scaling changes.

**Added to:** `copilot-instructions.md` → ImGui Integration

---

## Process Lessons

### Fix Issues at the Source, Not in CI (PR #82)

**Problem:** Visual regression test artifacts used names like `single_particle_720p.png` that didn't match the CI workflow regex `_baseline|_current|_diff`. The quick fix was to expand the regex; the correct fix was to rename artifacts at the source.

**Lesson:** When CI reports show incorrect categorization (e.g., "unknown" type for test images), fix the naming convention in the test code — not the CI regex. CI patterns should enforce conventions, not accommodate deviations.

**Added to:** Self-evaluation skill (this file)

### Don't Modify README Unless Asked (PR #64)

**Problem:** Agent added visual regression testing docs to README, which wasn't requested.

**Lesson:** Don't update README unless specifically asked by the user.

### Skills Should Cross-Reference (PR #64)

**Problem:** Testing skill duplicated CI pipeline rules from workflow skill.

**Lesson:** Minimize duplication across skills. Each skill owns one domain. Skills reference other skills instead of repeating content.

**Added to:** `copilot-instructions.md` → Skill Architecture section

### Always Upload Current Images (PR #64)

**Problem:** Visual regression CI only uploaded artifacts on failure, making it hard to review passing tests.

**Lesson:** Always save and upload current rendered images, even when tests pass. Use `if: always()` on upload steps.

**Added to:** `workflow` skill → Artifact Upload Pattern

---

## Quick Reference: Where to Add Lessons

| If the lesson is about... | Add to... |
|---|---|
| Code patterns, naming, error handling | `copilot-instructions.md` |
| Test writing, AAA, mocking, visual regression | `.github/skills/testing/SKILL.md` |
| CI/CD workflows, artifacts, permissions | `.github/skills/workflow/SKILL.md` |
| Documentation format, linking, content | `.github/skills/documentation/SKILL.md` |
| User story creation, estimation | `.github/skills/user-story-generator/SKILL.md` |
| Meta/process (skill creation, evaluation) | `.github/skills/self-evaluation/SKILL.md` |
