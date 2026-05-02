---
name: build
license: MIT
description: Use when building, adding dependencies, configuring CMake options, troubleshooting build failures, or managing Flatpak packaging for Particle-Viewer.
---

## Iron Law

```
YOU MUST BUILD LOCALLY AND VERIFY IT PASSES BEFORE EVERY PUSH.
No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

YOU MUST run `cmake --build build` locally and verify it exits 0 before pushing. No exceptions.

**Announce at start:** "I am using the build skill to [build/configure/troubleshoot] [description]."

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

### One Version Rule

**Iron Gate:** One version of each dependency in the build. No version aliases, no parallel installations, no `if(FOUND v1) else(use v2)` chains.

**Rule:** Before adding or upgrading any dependency:
1. Check if that library is already a transitive dependency of another component
2. If it is: use the existing version — upgrade if needed, never add a parallel version
3. If a diamond dependency arises (A needs lib@v1, B needs lib@v2): resolve by upgrading to the higher version and confirming both A and B still work
4. Document the version pin (tag or commit SHA) in `CMakeLists.txt` — never use `HEAD` or `main` as a `FetchContent` ref in production builds

**Gate:** `grep -r "FetchContent_Declare" CMakeLists.txt` — every `FetchContent_Declare` must have a `GIT_TAG` pinned to a specific version, not a branch name.

✓ All tags pinned to a version tag or commit SHA → proceed to add or upgrade the dependency
✗ Any tag references a branch name → fix the ref before proceeding

```cmake
# CORRECT — pinned to tag
FetchContent_Declare(some_lib GIT_REPOSITORY ... GIT_TAG v1.2.3)

# WRONG — pinned to branch (non-reproducible)
FetchContent_Declare(some_lib GIT_REPOSITORY ... GIT_TAG main)
```

**Rationalization:** "The HEAD version has the fix we need." Counter: pin to the commit SHA that contains the fix, not to `HEAD`. Unpinned `HEAD` = a different build every `cmake` run.

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
See the `flatpak` skill (`.github/skills/flatpak/`) for MSAA fallback, SDL3 module setup, NVIDIA GL workarounds, and setenv gotchas.

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Small change, can't break the build" | Even single-line changes break builds. Run `cmake --build build` first. |
| "CI will catch it if the build fails" | CI is a safety net. Don't push broken builds intentionally. |
| "It built fine yesterday" | Dependencies change. State changes. Build locally before every push. |
| "The CMake error is too confusing to parse" | Read the first 10 lines of error output — that's always where the root cause is. |
| "I'll fix the FetchContent pin later" | Unpinned dependencies produce non-reproducible builds. Pin to tag/commit now. |
| "The tests don't need to be in the build target" | All test targets must build cleanly. No orphaned test binaries. |

---

## Red Flags — STOP

If you catch yourself thinking any of these, stop and follow the rule:
- "I'll push and see if CI builds it"
- "This small change couldn't break CMake"
- "The dependency version doesn't really matter"
- "I don't understand the CMake error but it probably works"
- "I'll update the dependency pin in a follow-up"
- About to push without running `cmake --build build` locally

**All of these mean: Run `cmake --build build` locally. Read the full output. Fix errors before pushing.**

---

## Reference

- Flatpak manifest: `flatpak/org.particleviewer.ParticleViewer.yaml`
- Flatpak GL/SDL3 gotchas: see the `flatpak` skill (`.github/skills/flatpak/`)
- Build scripts: `scripts/linuxBuildAndInstall.sh`, `scripts/build-flatpak.sh`
