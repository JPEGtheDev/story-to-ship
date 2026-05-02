---
name: visual-regression-testing
license: MIT
description: Use when writing or maintaining visual regression tests, approving visual baselines, or deciding whether something belongs in a VR test vs a MockOpenGL unit test.
---

## Iron Law

```
YOU MUST NEVER AUTO-APPROVE A VISUAL BASELINE — HUMAN MUST REVIEW EVERY NEW OR CHANGED RENDER.
No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

YOU MUST get explicit human approval before committing any new or changed visual baseline. No exceptions.

A visual regression test proves output **hasn't changed**, not that it was correct to begin with.

**Announce at start:** "I am using the visual-regression-testing skill to [write/update/debug] visual regression tests for [description]."

---

## BEFORE PROCEEDING

- [ ] Any associated logic (non-pixel behavior) has a passing MockOpenGL or unit test already.
- [ ] The test file is in `tests/visual-regression/` — not mixed with unit or integration tests.
- [ ] If updating an existing baseline: the old baseline has been deleted and the test is confirmed failing.
- [ ] Human baseline approval is an explicit, scheduled step in the workflow — not auto-commit.

✓ All met → proceed
✗ Any unmet → resolve the unmet condition before writing any test code or committing any baseline

---

# Instructions for Agent

## When to Load This Skill

Load this skill when:
- Writing visual regression tests (`tests/visual-regression/`)
- Baseline images need to be created or updated
- Debugging a visual regression failure
- Deciding whether something belongs in a visual test vs a MockOpenGL unit test

---

## OpenGL Visual Testing Boundary

OpenGL rendering is inherently visual. Pixel output depends on GPU drivers, platform, and rendering state that unit tests cannot fully capture.

### What MockOpenGL CAN test (full TDD applies)

- Shader compilation logic (uniform locations, program linking)
- Buffer creation and binding sequences (VAO, VBO, EBO)
- Draw call parameters (primitive type, index count, offset)
- State machine transitions (depth test, blending, viewport)
- Camera matrix calculations
- Particle data loading and transformation
- Any logic in `viewer_app`, `camera`, `shader` that doesn't produce pixels

**TDD iron law applies fully here.** Write the failing MockOpenGL test first.

### What visual regression tests cover (NOT unit tests)

- Final rendered pixel output
- Color correctness and blending
- Particle rendering at scale
- UI overlay rendering

---

## TDD Nuance for Visual Regression

| Path | TDD rule |
|------|----------|
| Logic (MockOpenGL, unit tests) | Full RED-GREEN-REFACTOR. No exceptions. |
| New visual baseline (first render) | Write the test framework first. Run it against no baseline (fail). Human approves the first baseline. THEN the test is green. |
| Changing existing visual output | Delete the old baseline. Test fails. Implement the change. Human reviews the new diff. Approve new baseline. Green. |

**The TDD iron law still applies** — you just can't produce the expected output yourself; the human does that for visual baselines.

---

## Writing a Visual Regression Test

Use production classes directly — **never duplicate production logic in test helpers**.

```cpp
TEST_F(RenderingRegressionTest, RenderDefaultCube_AngledView_MatchesBaseline)
{
    // Arrange
    Shader particleShader(vertexPath.c_str(), fragmentPath.c_str());
    Particle particles;  // Production class directly — no test helper duplication
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

## Testing Utilities

| Type | Location | Purpose |
|------|----------|---------|
| `Image` | `src/Image.hpp` | RGBA pixel buffer with save/load (PPM, PNG) |
| `ComparisonResult` | `src/testing/PixelComparator.hpp` | Match status, similarity, diff image |
| `PixelComparator` | `src/testing/PixelComparator.hpp` | Pixel comparison engine |
| `ImageFormat` | `src/Image.hpp` | Format enum (PPM, PNG) for Image::save/load |
| `Particle` | `src/particle.hpp` | Production particle data (std::vector<glm::vec4>) |

---

## Tolerance Values

- `0.0f` tolerance — synthetic data (perfect match expected)
- `2.0f/255.0f` tolerance — GPU-rendered output (accounts for driver variation)
- Never use tolerance above `5.0f/255.0f` without explicit human approval and documented justification

---

## Camera Positioning

Use the viewer's default resolution (1280×720). Do NOT copy debug camera coordinates.

**Distance calculation:** `distance = subject_size / (coverage_% × tan(FOV/2))`

Full guidance: `docs/visual-regression/camera-positioning-lessons-learned.md`

---

## Self-Review Checklist

Before presenting visual regression tests:

- [ ] Visual tests use production classes (`Particle`, `Camera`) — no duplicated test helpers
- [ ] `SetUp()` creates all output directories (`artifacts/`, `baselines/`, `diffs/`)
- [ ] `save()` return values are checked, not silently ignored
- [ ] Resolution is 1280×720 (viewer default) unless specifically testing other resolutions
- [ ] Tolerance is appropriate for the render type (`0.0f` for synthetic, `~2/255` for GPU)
- [ ] Human baseline approval is an explicit workflow step — not auto-committed

---

## Red Flags — STOP

- Auto-committing a new baseline without human review
- Using a visual regression test to verify logic that MockOpenGL could test
- Tolerance above `5.0f/255.0f` without documented justification
- Test resolution doesn't match viewer defaults and reason isn't documented
- Baseline set from debug camera position without calculating proper framing

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "The visual looks fine to me" | Auto-approval bypasses the human review requirement |
| "MockOpenGL can't test this" | If it's logic, not pixels, MockOpenGL likely can — reconsider |
| "High tolerance is more robust" | High tolerance masks real regressions |
| "I'll set the resolution later" | Wrong resolution causes artifacts in every subsequent baseline |
| "Visual tests cover what the unit tests don't" | Visual tests are slow and cover pixels; unit tests cover logic. Both are needed. |

---

## Related Skills

- [`testing`](.github/skills/testing/) — parent skill; TDD iron law and AAA naming conventions apply to all test files including visual regression tests
- [`code-quality`](.github/skills/code-quality/) — code conventions, clang-format, and naming rules apply to test code in this directory
- [`systematic-debugging`](.github/skills/systematic-debugging/) — use when investigating visual regression failures before proposing fixes
- [`cpp-patterns`](.github/skills/cpp-patterns/) — production class patterns (GL resource cleanup, RAII) used in visual test fixtures
