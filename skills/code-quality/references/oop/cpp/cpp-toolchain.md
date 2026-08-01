# C++ Toolchain Configuration

Clang-format settings and clang-tidy configuration for Particle-Viewer.

---

## clang-format Settings

Auto-enforced via `.clang-format`. Key settings:

| Rule | Value |
|------|-------|
| Standard | C++20 |
| Indentation | 4 spaces (no tabs) |
| Line length | 120 characters |
| Functions/classes braces | Allman (new line) |
| Control structure braces | K&R (same line) |
| Include order | C++ standard -> system -> external libs -> project headers |
| Pointer alignment | Left (`int* ptr`) |

Full configuration: `.clang-format`

---

## clang-tidy Commands

```bash
# Analyze a source file
clang-tidy src/main.cpp -- -Isrc/glad/include

# Analyze using compilation database
clang-tidy src/particle.hpp -p build

# Auto-fix (always review auto-fix output before committing -- it can change behavior)
clang-tidy -fix src/main.cpp -- -Isrc/glad/include
```

Configuration in `.clang-tidy` enforces:
- `modernize-*` -- Modern C++ practices (smart pointers, nullptr, auto, range-based loops)
- `readability-*` -- Const correctness, function complexity (<=25 cognitive, <=50 statements, <5 params)
- `cppcoreguidelines-*` -- Microsoft C++ Core Guidelines
- `performance-*`, `bugprone-*`, `portability-*`, `clang-analyzer-*`

Header filter excludes embedded libs: `glad`, `stb_*`.

**CI status:** clang-tidy runs in CI as advisory (non-blocking). clang-format is blocking.

---

## STL vs. C++ Standard Library

The Standard Template Library started out as an independent, template-based library of generic containers and algorithms, organized around an iterator abstraction that lets a pre-written algorithm run over both built-in and user-defined containers. It predates the C++ Standard Library, having been absorbed into it only afterward; the resulting Standard Library added a large amount of functionality that the earlier template library had never included.

Treating "STL" and "the C++ standard library" as interchangeable produces concrete, checkable errors. Four categories belong to the Standard Library but were never part of the STL proper:
- numeric-limits queries
- locale and character-facet support
- the string class
- the stream-based I/O types

**Check:** Before accepting a documentation line, code comment, or claim that attributes a C++ feature to "the STL," verify the feature is not one of the four categories above.

---

## PV Workflow Patterns

## Step 7: Adding a Feature / Fixing a Bug

### New Feature Workflow
1. **Scan the class interface** -- before writing integration code that calls methods on an existing class, verify which members are public/private. Classes like `Camera` have a mix; don't assume public.
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


