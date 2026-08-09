---
name: visual-regression-testing
license: MIT
description: Use when writing or maintaining visual regression tests, approving visual baselines, or deciding whether something belongs in a VR test vs a GL-mock unit test, or debugging visual output by rendering and inspecting the result.
---


## Iron Law

```
YOU MUST NEVER AUTO-APPROVE A VISUAL BASELINE -- HUMAN MUST REVIEW EVERY NEW OR CHANGED RENDER.
No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

A visual regression test proves output **hasn't changed**, not that it was correct to begin with.

**Announce at start:** "I am using the visual-regression-testing skill to [write/update/debug] visual regression tests for [description]."

---

## BEFORE PROCEEDING

1. Any associated logic (non-pixel behavior) has a passing GL-mock or unit test already.
2. The test file is in `tests/visual-regression/` -- not mixed with unit or integration tests.
3. If updating an existing baseline: the old baseline has been deleted and the test is confirmed failing.
4. Human baseline approval is an explicit, scheduled step in the workflow -- not auto-commit.

[+] All met -> proceed
[-] Any unmet -> resolve the unmet condition before writing any test code or committing any baseline

---

# Instructions for Agent

## When to Load This Skill

Load this skill when:
- Writing visual regression tests (`tests/visual-regression/`)
- Baseline images need to be created or updated
- Debugging a visual regression failure
- Deciding whether something belongs in a visual test vs a GL-mock unit test

---

## OpenGL Visual Testing Boundary

OpenGL rendering is inherently visual. Pixel output depends on Graphics Processing Unit (GPU) drivers, platform, and rendering state that unit tests cannot fully capture.

### What a GL mock CAN test (full TDD applies)

- Shader compilation logic (uniform locations, program linking)
- Buffer creation and binding sequences (VAO, VBO, EBO)
- Draw call parameters (primitive type, index count, offset)
- State machine transitions (depth test, blending, viewport)
- View/projection matrix calculations
- Scene data loading and transformation
- Any logic that doesn't produce pixels

**TDD iron law applies fully here.** Write the failing GL-mock test first.

### What visual regression tests cover (NOT unit tests)

- Final rendered pixel output
- Color correctness and blending
- Instanced rendering at scale
- UI overlay rendering

---

## TDD Nuance for Visual Regression

| Path | TDD rule |
|------|----------|
| Logic (GL-mock, unit tests) | Full RED-GREEN-REFACTOR. No exceptions. |
| New visual baseline (first render) | Write the test framework first. Run it against no baseline (fail). Human approves the first baseline. THEN the test is green. |
| Changing existing visual output | Delete the old baseline. Test fails. Implement the change. Human reviews the new diff. Approve new baseline. Green. |

**The TDD iron law still applies** -- you just can't produce the expected output yourself; the human does that for visual baselines.

---

## Writing a Visual Regression Test

Use production classes directly -- **never duplicate production logic in test helpers**. For a complete code example and testing utilities table, see `references/VRT_EXAMPLES.md`.

---

## Tolerance Values

- `0.0f` tolerance -- synthetic data (perfect match expected)
- `2.0f/255.0f` tolerance -- GPU-rendered output (accounts for driver variation)
- Never use tolerance above `5.0f/255.0f` without explicit human approval and documented justification

---

## Camera Positioning

Use the application's default resolution. Do NOT copy debug camera coordinates.

**Distance calculation (where FOV = Field of View):** `distance = subject_size / (coverage_% x tan(FOV/2))`

---

## Qualitative Visual Analysis (Render-Capture-Look)

A multimodal agent debugging visual output can read image files and see what is in them, the same way a developer looks at a screenshot. This capability is not optional: before diagnosing a visual bug, the agent must produce a render, read the saved image, and describe what is on screen. Source code is a hypothesis about what the render will look like -- it is not the render. An agent that has read every line of shader code and confirmed the math is correct still does not know what pixels were actually written.

**If the agent has not looked at a render, it has not investigated the bug.**

| Mode | Can answer | Cannot answer |
|------|-----------|----------------|
| Reading source code | Is this formula correct? Does this value get set? | What does the render actually look like? |
| Quantitative (pixel comparison) | Did this pixel change from baseline? | Is this correct? Is the screen blank? Are the colors wrong? |
| Qualitative (render + look) | What is actually on screen? Does this look right? What changed between renders? | Whether a specific pixel differs by N/255 from a prior baseline |

Quantitative tests answer "did it change." Qualitative analysis answers "does it look right." Both are necessary; neither substitutes for the other.

**When to use:** the first action on any visual bug report, before any code inspection -- not a last resort; tuning render parameters and comparing the effect of different values; confirming a pipeline is producing fragments at all; any time "the code looks correct" would otherwise be the claim without having seen a render.

**Qualitative leads, quantitative follows.** Never diagnose a new bug with a regression test -- it reports that pixels changed, not what changed or why. Qualitative analysis has no baseline and no pass/fail comparison; its artifacts are not committed. A quantitative baseline is written only after a human has confirmed the render is correct.

**Inline statistics supplement vision -- they never replace it.** Printing coverage percentage and channel averages alongside a saved render catches things that are hard to describe verbally, but the image remains the primary artifact and the numbers are annotations on it. Coverage near 0% means the pipeline is not producing output -- diagnose the render path before examining shader code.

Worked example: `references/VRT_EXAMPLES.md`.

---

## Self-Review Checklist

Before presenting visual regression tests:

- [ ] Visual tests use production classes directly -- no duplicated test helpers
- [ ] `SetUp()` creates all output directories (`artifacts/`, `baselines/`, `diffs/`)
- [ ] `save()` return values are checked, not silently ignored
- [ ] Resolution is the application default unless specifically testing other resolutions
- [ ] Tolerance is appropriate for the render type (`0.0f` for synthetic, `~2/255` for GPU)
- [ ] Human baseline approval is an explicit workflow step -- not auto-committed

---

## Red Flags -- STOP

- Auto-committing a new baseline without human review
- Using a visual regression test to verify logic that a GL mock could test
- Tolerance above `5.0f/255.0f` without documented justification
- Test resolution doesn't match the application default and reason isn't documented
- Baseline set from debug camera position without calculating proper framing
- Diagnosing a visual bug from source code alone, without producing and reading a render

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "The visual looks fine to me" | Auto-approval bypasses the human review requirement |
| "A GL mock can't test this" | If it's logic, not pixels, a GL mock likely can -- reconsider |
| "High tolerance is more robust" | High tolerance masks real regressions |
| "I'll set the resolution later" | Wrong resolution causes artifacts in every subsequent baseline |
| "Visual tests cover what the unit tests don't" | Visual tests are slow and cover pixels; unit tests cover logic. Both are needed. |
| "The code looks correct" | Source code is a hypothesis about the render, not the render. Produce the render, read the image, then diagnose. |

---

## Related Skills

- `testing` -- parent skill; TDD iron law and AAA naming conventions apply to all test files including visual regression tests
- `code-quality` -- code conventions, clang-format, and naming rules apply to test code in this directory
- `systematic-debugging` -- use when investigating visual regression failures before proposing fixes
- `cpp-patterns` -- production class patterns (GL resource cleanup, RAII) used in visual test fixtures
