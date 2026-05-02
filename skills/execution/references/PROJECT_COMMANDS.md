# Particle-Viewer Project Commands

Particle-Viewer specific commands for build, test, and format operations.

## Build

```bash
cmake --build build
```

## Test Runner

```bash
./build/tests/ParticleViewerTests

# Run a specific test
./build/tests/ParticleViewerTests --gtest_filter=TestSuite.TestName
```

## Format

```bash
find src tests -name "*.cpp" -o -name "*.hpp" | xargs clang-format -i
```

## Pre-Commit Gate (combined)

```bash
find src tests -name "*.cpp" -o -name "*.hpp" | xargs clang-format -i \
  && cmake --build build \
  && ./build/tests/ParticleViewerTests
```
