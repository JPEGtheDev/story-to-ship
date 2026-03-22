---
name: code-quality
description: Enforce code formatting, static analysis, naming conventions, and project-specific C++ patterns. Use when writing code, reviewing style, running clang tools, or checking pre-commit requirements.
license: MIT
compatibility: Designed for GitHub Copilot and similar AI coding agents
metadata:
  author: JPEGtheDev
  version: "1.7"
  category: code-quality
  project: Particle-Viewer
---

# Instructions for Agent

## How This Skill is Invoked

In VS Code, users will activate this skill by:
- Typing `@workspace /code-quality [description]` in Copilot Chat
- Or asking: "Format the code", "Fix clang-tidy warnings", "What naming convention?", "Pre-commit checklist"

When activated, apply the formatting, naming, and pattern rules below.

---

## Core Principle: Tools Enforce Style, Humans Write Logic

Formatting and naming are automated via `.clang-format` and `.clang-tidy`. Never manually format code — run the tools.

---

## Step 1: Pre-Commit Checklist (MANDATORY)

Run these before **every** commit:

```bash
# 1. Format ALL changed C++ files
find src tests -name "*.cpp" -o -name "*.hpp" | xargs clang-format -i

# 2. Check what changed
git diff --name-only | head -20

# 3. Spot-check any files you touched (don't trust silent tool output)
# Look for: trailing semicolons after function }, exception handling, 
# multi-declaration statements, bracing consistency
git diff src/[touched_file].cpp | head -100

# 4. Verify formatting passes (same check CI runs)
find src tests -name "*.cpp" -o -name "*.hpp" | xargs clang-format --dry-run -Werror

# 5. Build and test
cmake --build build
./build/tests/ParticleViewerTests

# 6. (Optional) Static analysis
clang-tidy src/main.cpp -- -Isrc/glad/include
```

**⚠️ Critical:** Never trust that `clang-format --dry-run -Werror` with no output means success. Always visually inspect `git diff` of modified files. Silent tool output can mask formatting issues.

---

## Step 2: Formatting Rules (clang-format)

Auto-enforced via `.clang-format`. Key settings:

| Rule | Value |
|------|-------|
| Standard | C++20 |
| Indentation | 4 spaces (no tabs) |
| Line length | 120 characters |
| Functions/classes braces | Allman (new line) |
| Control structure braces | K&R (same line) |
| Include order | C++ standard → system → external libs → project headers |
| Pointer alignment | Left (`int* ptr`) |

Full configuration: `.clang-format`

---

## Step 3: Human-Reviewable Formatting Patterns

These require **manual inspection** after running clang-format — tools don't always catch them:

| Issue | Fix | Example |
|-------|-----|---------|
| Semicolon after function closing brace | Remove trailing `;` | `void foo() { }` not `void foo() { };` |
| Empty constructor syntax | Use `= default` | `Shader() = default;` not `Shader() {};` |
| Exception catching by value | Catch by const reference | `catch (const std::ifstream::failure& e)` |
| Multiple declarations in one line | Split to separate lines | `uint32_t w; uint32_t h;` not `uint32_t w, h;` |

**Always check `git diff` for these patterns after formatting.**

---

## Step 4: Naming Conventions (clang-tidy enforced)

| Element | Convention | Example |
|---------|-----------|---------|
| Classes/Structs/Enums | `PascalCase` | `ParticleSystem`, `RenderSettings` |
| Functions/Methods | `camelCase` (preferred, not enforced) | `initializeBuffers`, `getParticleCount` |
| Variables/Parameters | `snake_case` | `particle_count`, `delta_time` |
| Member variables | `snake_case` + trailing `_` for private | `window_width`, `camera_` |
| Constants/Macros | `UPPER_CASE` | `MAX_PARTICLES`, `PI` |
| File names | `snake_case` | `particle_system.hpp` |
| Include guards | `<PROJECT>_<PATH>_<FILE>_H` | `PARTICLE_VIEWER_PARTICLE_SYSTEM_H` |
| Namespaces | `snake_case` | `particle_viewer` |

---

## Step 5: Static Analysis (clang-tidy)

```bash
# Analyze a source file
clang-tidy src/main.cpp -- -Isrc/glad/include

# Analyze using compilation database
clang-tidy src/particle.hpp -p build

# Auto-fix (use carefully)
clang-tidy -fix src/main.cpp -- -Isrc/glad/include
```

Configuration in `.clang-tidy` enforces:
- `modernize-*` — Modern C++ practices (smart pointers, nullptr, auto, range-based loops)
- `readability-*` — Const correctness, function complexity (≤25 cognitive, ≤50 statements, <5 params)
- `cppcoreguidelines-*` — Microsoft C++ Core Guidelines
- `performance-*`, `bugprone-*`, `portability-*`, `clang-analyzer-*`

Header filter excludes embedded libs: `glad`, `tinyFileDialogs`, `stb_*`.

**CI status:** clang-tidy runs in CI as advisory (non-blocking). clang-format is blocking.

---

## Step 6: Project-Specific C++ Patterns

### Data Organization
- Group related member variables into POCOs/structs (e.g., `WindowConfig`, `SphereParams`)
- Structs provide their own defaults to reduce constructor initializer lists
- Use structs for vertex data (`QuadVertex` with x, y, u, v) instead of raw float arrays

### Error Handling
- Check return values from OpenGL and file I/O operations
- Log errors to console with descriptive messages
- Use assertions for preconditions and invariants
- Open binary data files with `"rb"` mode for cross-platform correctness

### Memory Management
- Prefer stack allocation over heap
- Use RAII for resource management
- Smart pointers for dynamic memory
- Clean up ALL GL resources in destructors (VAOs, VBOs, FBOs, RBOs, textures)
- Prevent copy of classes that own GL resources (delete copy ctor/assignment)

### OpenGL Usage
- Check OpenGL errors after major operations
- GLAD loader call: `gladLoadGLLoader((GLADloadproc)SDL_GL_GetProcAddress)`
- Shaders loaded from `Viewer-Assets/shaders/`
- Modern VBO/VAO patterns for vertex data
- Bounds-check SDL3 scancode values before indexing key state arrays
- Prefer `glGetIntegerv(GL_VIEWPORT, ...)` over cached viewport values in render paths where viewport may change
- `gl_PointSize` clamped by `GL_POINT_SIZE_RANGE` (max 256px on Mesa/llvmpipe)
- For Flatpak/SDL3/GL gotchas: see `.github/skills/workflow/references/FLATPAK_GL_GOTCHAS.md`
- **SDL3 subsystem flags:** `SDL_Init` in `SDL3Context.cpp` must include the flag for every SDL3 subsystem used. Adding gamepad input requires `SDL_INIT_GAMEPAD`; adding audio requires `SDL_INIT_AUDIO`; etc. Missing a flag causes the subsystem to silently fail — no error, no events, no devices.
- **SDL3 `*ForID` query functions:** When querying joystick properties by instance ID, prefer the `SDL_Get*ForID()` variants (e.g. `SDL_GetJoystickGUIDForID`, `SDL_GetJoystickTypeForID`, `SDL_GetJoystickVendorForID`) over opening the joystick just to read the value and closing it. Opening a device unnecessarily consumes a file handle and triggers internal SDL3 reference counting.
- **SDL3 joystick type is distro-dependent:** `SDL_GetJoystickTypeForID()` returns `SDL_JOYSTICK_TYPE_GAMEPAD` on SteamOS for hardware like the 8BitDo 2.4GHz dongle, but `SDL_JOYSTICK_TYPE_UNKNOWN` on generic Linux (OpenSuse, Ubuntu, etc.) because stock udev rules don't set the GAMEPAD property. Any SDL3 input fallback that only checks `SDL_JOYSTICK_TYPE_GAMEPAD` will silently fail on non-SteamOS distros. Always pair type-based detection with a capability-based fallback: open the joystick, check `SDL_GetNumJoystickAxes() >= 4 && SDL_GetNumJoystickButtons() >= 6`, then close it.
- **Don't route gamepad hold-button state through `Camera::KeyReader()`:** `KeyReader` has a single-press dispatch block — calling it every frame with `is_pressed=true` would repeatedly fire single-press handlers for that key. For gamepad hold-buttons that mirror keyboard held keys (e.g. B → Shift for speed boost), add a dedicated method that sets only the key state directly (e.g. `Camera::setSpeedBoost(bool)`). See `src/camera.hpp` for the existing pattern.

### Headers
- Every header must include all headers it directly uses (no transitive include reliance)
- Mark functions defined in headers as `inline` to avoid multiple-definition linker errors

### ImGui Integration
- See [`docs/IMGUI_INTEGRATION.md`](../../../docs/IMGUI_INTEGRATION.md) for architecture, FetchContent setup, menu system, and overlay positioning

---

## Step 7: Adding a Feature / Fixing a Bug

### New Feature Workflow
1. **Scan the class interface** — before writing integration code that calls methods on an existing class, verify which members are public/private. Classes like `Camera` have a mix; don't assume public.
2. Make code changes following naming conventions
3. Add unit tests in `tests/core/` (see `testing` skill)
4. Run `clang-format -i` on ALL changed files
5. Build and verify tests pass
6. Commit: `feat: description`

### Removing Features / User-Requested Changes
When removing a gamepad feature or call site from `viewer_app.cpp` at user request, **do not also delete the supporting `Camera` public method**. The Camera API is stable across sessions; call sites in `viewer_app` change frequently with user preferences. Removing `isRenderingSphere()` when L3/R3 was dropped meant restoring it when L3/R3 came back one session later. Only remove a Camera method if it is architecturally wrong, not merely unused at the current moment.

### Bug Fix Workflow
1. Write a failing test that reproduces the bug
2. Fix the code
3. Verify test passes, run full suite
4. Run `clang-format -i` on changed files
5. Commit: `fix: description`

---

## Review Checklist

- [ ] `clang-format -i` run on all changed files
- [ ] `clang-format --dry-run -Werror` passes
- [ ] Build succeeds
- [ ] All tests pass
- [ ] Conventional commit message format used
- [ ] No raw `new`/`delete` — use RAII or smart pointers
- [ ] GL resources cleaned up in destructors
- [ ] Headers are self-contained

---

## Reference

- Full coding standards: [`docs/CODING_STANDARDS.md`](../../../docs/CODING_STANDARDS.md)
- clang-format config: `.clang-format`
- clang-tidy config: `.clang-tidy`
- Commit format: `versioning` skill (`.github/skills/versioning/`)
- Testing patterns: `testing` skill (`.github/skills/testing/`)
