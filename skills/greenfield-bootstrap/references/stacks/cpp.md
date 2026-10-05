## Stack: C++

1. Accepted Language values: `C++`, with any standard such as `C++20`. The `Runtime/framework` value is not read for mapping, and any framework it names is not scaffolded.

2. Toolchain probe: `command -v cmake && command -v g++`. When either prints nothing, skip the local run and report the missing tool (`cmake` or `g++`) in the final `## Bootstrapped Files` summary.

3. Files:

File: `CMakeLists.txt`
```cmake
cmake_minimum_required(VERSION 3.16)
project(hello_world CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(hello_world main.cpp)
```

File: `main.cpp`
```cpp
#include <iostream>

int main() {
  std::cout << "Hello from <project-name>" << '\n';
  return 0;
}
```

4. .gitignore entries:

```
build/
```

5. Lockfile committed with the project: none.

6. Smoke workflow steps (no setup step; CMake and g++ are preinstalled on `ubuntu-latest`):

```yaml
      - name: Build
        run: cmake -B build && cmake --build build
      - name: Run
        run: ./build/hello_world
```

7. Local run, in the project directory: `cmake -B build && cmake --build build`, then `./build/hello_world`.
