---
name: build
description: Build, configure, and troubleshoot the Particle-Viewer CMake project. Use when building, adding dependencies, configuring CMake options, troubleshooting build failures, or managing Flatpak packaging.
license: MIT
compatibility: Designed for GitHub Copilot and similar AI coding agents
metadata:
  author: JPEGtheDev
  version: "1.0"
  category: build
  project: Particle-Viewer
---

# Instructions for Agent

## How This Skill is Invoked

In VS Code, users will activate this skill by:
- Typing `@workspace /build [description]` in Copilot Chat
- Or asking: "How do I build?", "Fix the build", "Add a dependency", "Set up Flatpak"

When activated, use the commands and patterns below.

---

## Core Principle: CMake Is the Single Source of Build Truth

All build configuration lives in `CMakeLists.txt`. No manual file copying, no build scripts beyond convenience wrappers.

---

## Step 1: Build Commands

```bash
# Standard build
cmake -B build -S .
cmake --build build

# Development mode (all warnings + coverage)
cmake -B build -S . -Dalloutput=ON
cmake --build build

# Run the application
./build/Viewer

# Install (copies binary + shader assets to bin/)
cmake --install build
```

---

## Step 2: Build Requirements

| Requirement | Minimum Version |
|-------------|----------------|
| CMake | 3.24 |
| C++ compiler | C++20 (GCC ≥ 10, Clang ≥ 11, MSVC 2019+) |
| OpenGL | Development libraries (`OpenGL::GL` target) |
| GLM | System-installed |
| SDL3 | Auto-downloaded via FetchContent (local) or Flatpak module |
| clang-format | For code formatting |
| clang-tidy | For static analysis (advisory) |

---

## Step 3: Dependency Management

### SDL3
- **Local builds:** `CMakeLists.txt` calls `find_package(SDL3)` first, falls back to `FetchContent` if not found.
- **Flatpak builds:** SDL3 is built as a standalone Flatpak module (before the app) so the Freedesktop SDK pkg-config paths detect `SDL_X11` and `SDL_WAYLAND`. FetchContent is NOT used in Flatpak.

### Dear ImGui
- Always downloaded via `FetchContent`.

### Embedded Libraries (no management needed)
- `src/glad/` — GLAD OpenGL loader
- `src/tinyFileDialogs/` — File dialog library
- `src/stb_*.h` — stb single-header libraries

### Dependency Upgrades
- Allowed as long as all tests pass and build succeeds
- Visual regression tests are a hard requirement — must pass without modification unless the approver is explicitly shown the new output
- Test updates for API changes (e.g., GoogleTest) are acceptable

---

## Step 4: Build Notes

- **Shaders:** Files in `src/shaders/` are auto-copied to `Viewer-Assets/shaders/` during build.
- **Tests:** Enabled by default (`BUILD_TESTS=ON`). Run with `./build/tests/ParticleViewerTests`.
- **Version:** See `versioning` skill for how version is resolved at build time.

---

## Step 5: Troubleshooting

**Missing SDL3:**
Run `cmake -B build -S .` — SDL3 downloads automatically via FetchContent.

**OpenGL headers not found:**
Install OpenGL development packages. Ensure `OpenGL::GL` CMake target is available.

**Shader files not found at runtime:**
Run from the build directory, or ensure `Viewer-Assets/shaders/` exists alongside the binary.

**Flatpak build issues:**
See the `workflow` skill and [FLATPAK_GL_GOTCHAS.md](../workflow/references/FLATPAK_GL_GOTCHAS.md).

---

## Reference

- Flatpak manifest: `flatpak/org.particleviewer.ParticleViewer.yaml`
- Flatpak GL/SDL3 gotchas: `.github/skills/workflow/references/FLATPAK_GL_GOTCHAS.md`
- Build scripts: `scripts/linuxBuildAndInstall.sh`, `scripts/build-flatpak.sh`
