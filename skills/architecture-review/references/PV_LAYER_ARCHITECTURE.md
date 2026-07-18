# Particle-Viewer Layer Architecture

The Particle-Viewer 4-layer inward-dependency model and common violations.

## The Layer Architecture

Particle-Viewer uses a strict inward-dependency model. Code in layer N may only depend on layers <= N. Never the reverse.

```
Layer 4 (outermost): main.cpp
  Entry point only -- instantiates ViewerApp and calls Run()

Layer 3: ViewerApp
  Orchestrator -- owns all runtime state, delegates to layers below
  Files: viewer_app.hpp, viewer_app.cpp

Layer 2: UI, Graphics, Camera, Shader, Particle
  Domain components -- each owns its own logic, no cross-component reach
  Files: ui/imgui_menu.hpp, ui/imgui_menu.cpp,
         graphics/SDL3Context.hpp, graphics/SDL3Context.cpp,
         camera.hpp, shader.hpp, particle.hpp

Layer 1 (innermost): Abstractions and utilities
  Files: graphics/IOpenGLContext.hpp, Image.hpp, Image.cpp
  Test utility (not production): src/testing/PixelComparator.hpp, src/testing/PixelComparator.cpp
```

### What Each Layer May Depend On

| Layer | May depend on |
|-------|--------------|
| 4 (main.cpp) | Layer 3 only |
| 3 (ViewerApp) | Layers 1-2 |
| 2 (UI/Graphics/Camera/Shader/Particle) | Layer 1 only |
| 1 (IOpenGLContext, Image) | No Particle-Viewer layers |

---

## Additional Gate Items (Particle-Viewer Specific)

Run these in addition to the general BEFORE PROCEEDING gate in the architecture-review skill:

1. Does raw OpenGL (`glXxx()`, `glXxx_ext()`) appear outside of `IOpenGLContext` implementations? (VIOLATION)
2. Does `ViewerApp` orchestrate or implement? (must orchestrate only -- rendering logic belongs in Shader/Particle classes)
3. Does `src/testing/PixelComparator` acquire OpenGL state directly, rather than receiving an `Image`? (VIOLATION)
4. Do any UI files (`ui/`) reach into `graphics/` internals beyond `IOpenGLContext`? (VIOLATION)

---

## Common Violations (Particle-Viewer Specific)

These are the violations most likely to appear in this codebase. Check for each explicitly.

| Violation | Example | Fix |
|-----------|---------|-----|
| Raw GL outside IOpenGLContext | `glDrawArrays(...)` in `viewer_app.cpp` | Move into `SDL3Context` behind an `IOpenGLContext` method |
| ViewerApp implementing rendering | Loop logic or shader setup inside `ViewerApp::Render()` | Extract to `Shader` or `Particle` class |
| Production code importing test code | `#include "../../tests/mocks/MockOpenGL.hpp"` in `src/` | Remove; mocks are test-only |
| PixelComparator acquiring GL state | `glReadPixels(...)` inside `PixelComparator` | Pass a pre-captured `Image` to `PixelComparator` |
| UI reaching into graphics internals | `#include "graphics/SDL3Context.hpp"` in `ui/imgui_menu.hpp` | Depend on `IOpenGLContext` interface only |

---

## Red Flags -- STOP (Particle-Viewer Specific)

Run these in addition to the general Red Flags in the architecture-review skill:

- "It only calls one GL function directly, that's fine" -> Stop. One raw GL call outside `IOpenGLContext` is a violation. Flag it.
- "ViewerApp is the orchestrator so it's fine to put logic there" -> Stop. Orchestration means delegation. Rendering logic belongs in domain classes.

---

## Rationalization Prevention (Particle-Viewer Specific)

| Excuse | Reality |
|--------|---------|
| "ViewerApp needed to call GL directly for performance" | Use `IOpenGLContext`. That abstraction exists precisely for this case. |

In the Barricade Model clean zone, the validated domain objects for this project are `ViewerApp` state, `Camera`, `Shader`, and `Particle`; a Layer 2 class checking data it received from `ViewerApp` is a barricade violation.
