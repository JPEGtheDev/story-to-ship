# Particle-Viewer Debug Reference

Project-specific commands and layer taxonomy for debugging Particle-Viewer.

---

## Project-Specific Commands

```bash
# Build failure — read the first 50 lines (root error is usually near the top)
cmake --build build 2>&1 | head -50

# Test failure — run the specific failing test in isolation
./build/tests/ParticleViewerTests --gtest_filter=TestSuite.TestName

# Visual regression — examine the diff image
# Diffs are written to: tests/visual-regression/diffs/

# CI failure — reproduce locally with the equivalent command before touching code
cmake --build build && ./build/tests/ParticleViewerTests
```

---

## Layer Taxonomy

```
User Input (SDL3 events)
    ↓
ViewerApp (main app logic, state machine)
    ↓
UI layer (ImGui menu — imgui_menu.hpp/cpp)
    ↓
Graphics layer (IOpenGLContext, SDL3Context)
    ↓
OpenGL driver (via GLAD)
    ↓
Shader (GLSL — Viewer-Assets/shaders/)
    ↓
GPU output
```

When debugging, identify which layer first produces incorrect behavior. Fix at that layer — not at the symptom layer above it.
