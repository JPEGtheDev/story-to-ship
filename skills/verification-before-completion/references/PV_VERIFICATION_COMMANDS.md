# Particle-Viewer Verification Commands

## The Verification Commands

> **Note (Particle-Viewer specific):** The commands below use this project's build system and test runner. Adapt `cmake --build build`, `./build/tests/ParticleViewerTests`, and the `find src tests` glob for your own project.

```bash
# Build
cmake --build build

# Tests
./build/tests/ParticleViewerTests

# Format check
find src tests -name "*.cpp" -o -name "*.hpp" | xargs clang-format --dry-run -Werror

# Full pre-commit gate (run all three before every commit)
find src tests -name "*.cpp" -o -name "*.hpp" | xargs clang-format -i
cmake --build build && ./build/tests/ParticleViewerTests
```
