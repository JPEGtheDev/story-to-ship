# Stack Templates

Per-stack facts for `greenfield-bootstrap`. Each `## Stack:` section below holds the literal files, `.gitignore` entries, workflow steps, and local-run commands for one supported stack. Copy the values as written. Two tokens are substituted when the files are written: `<project-name>` and `<project-id>`.

## Tokens and Language Mapping

### Tokens

- `<project-name>`: the target directory's name as the user wrote it. It may contain spaces and uppercase letters. It appears in the printed line and in the README.
- `<project-id>`: an identifier derived from the name. Lowercase the name. Replace every run of characters outside a-z, 0-9 and hyphen with one hyphen. Remove leading and trailing hyphens. Prefix `app-` when the result starts with a digit or is empty. Examples: `Tide Log` -> `tide-log`; `7seas` -> `app-7seas`.
- When `<project-name>` contains a double quote or a backslash, the printed line uses `<project-id>` in place of `<project-name>`, so the string literal stays valid in every stack.
- Every hello world prints exactly one line containing the name, for example `Hello from tide-log`, and exits 0. The Rust and C templates route the name through a format-safe call (`println!` with a `{}` argument, `puts`), so braces and percent signs in the name stay literal.

### Language-value mapping

Take the Language value from the `## Architecture Decision` block before its ` -- ` separator. Ignore version numbers and parenthetical notes when matching: `Python 3.12` -> Python; `C++20` -> C++; `C# (.NET 8)` -> C#.

| Language value | Stack section |
|---|---|
| Python | `## Stack: Python` |
| TypeScript, with a Runtime of Node.js or no runtime named | `## Stack: TypeScript/Node.js` |
| Rust | `## Stack: Rust` |
| Go, Golang | `## Stack: Go` |
| C# | `## Stack: C#` |
| C++ | `## Stack: C++` |
| C, C99, C11, Embedded C | `## Stack: C/embedded C` |

Not supported: TypeScript with a Deno or Bun runtime, JavaScript, and every other language.

### Action versions

Every generated workflow starts from `actions/checkout@v7`. Setup actions used below: `actions/setup-python@v7`, `actions/setup-node@v7`, `actions/setup-go@v7`, `actions/setup-dotnet@v6`. Rust, C and C++ use the toolchain preinstalled on the `ubuntu-latest` runner (Cargo, CMake, gcc and g++ are listed in its image readme), so those stacks have no setup step.

## Stack: Python

1. Accepted Language values: `Python`, with any version number or parenthetical note. The Runtime line is not used.

2. Toolchain probe: `command -v python || command -v python3`. When neither prints a path, skip the local run and name `python3`.

3. Files:

File: `main.py`
```python
print("Hello from <project-name>")
```

No `requirements.txt` is written. No other file is needed.

4. .gitignore entries:

```
__pycache__/
*.pyc
```

5. Lockfiles not gitignored: none.

6. Smoke workflow steps:

```yaml
      - uses: actions/setup-python@v7
        with:
          python-version: '3.x'
      - name: Build
        run: if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
      - name: Run
        run: python main.py
```

7. Local run, in the project directory: `python main.py`; when `python` is absent, `python3 main.py`. There is no build command.

## Stack: TypeScript/Node.js

1. Accepted Language values: `TypeScript` with a Runtime of `Node.js` or no runtime named. A Runtime of Deno or Bun is not supported.

2. Toolchain probe: `command -v node && command -v npm`. When either prints nothing, skip the local run and name `node` (npm ships with Node.js).

3. Files:

File: `package.json`
```json
{
  "name": "<project-id>",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "build": "tsc"
  },
  "devDependencies": {
    "typescript": "^7.0.2"
  }
}
```

File: `tsconfig.json`
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "commonjs",
    "outDir": "dist",
    "rootDir": "src",
    "strict": true
  },
  "include": ["src"]
}
```

File: `src/main.ts`
```typescript
console.log("Hello from <project-name>");
```

4. .gitignore entries:

```
node_modules/
dist/
```

5. Lockfiles not gitignored: `package-lock.json` (created by `npm install`).

6. Smoke workflow steps:

```yaml
      - uses: actions/setup-node@v7
        with:
          node-version: 'lts/*'
      - name: Build
        run: npm install && npm run build
      - name: Run
        run: node dist/main.js
```

7. Local run, in the project directory: `npm install && npm run build`, then `node dist/main.js`.

## Stack: Rust

1. Accepted Language values: `Rust`. The Runtime line is not used.

2. Toolchain probe: `command -v cargo`. When it prints nothing, skip the local run and name `cargo` (installed with `rustup`).

3. Files:

File: `Cargo.toml`
```toml
[package]
name = "<project-id>"
version = "0.1.0"
edition = "2021"
```

File: `src/main.rs`
```rust
fn main() {
    println!("Hello from {}", "<project-name>");
}
```

4. .gitignore entries:

```
target/
```

5. Lockfiles not gitignored: `Cargo.lock` (created by `cargo build`).

6. Smoke workflow steps (no setup step; Cargo is preinstalled on `ubuntu-latest`):

```yaml
      - name: Build
        run: cargo build
      - name: Run
        run: cargo run
```

7. Local run, in the project directory: `cargo build && cargo run`.

## Stack: Go

1. Accepted Language values: `Go`, `Golang`. The Runtime line is not used.

2. Toolchain probe: `command -v go`. When it prints nothing, skip the local run and name `go`.

3. Files:

File: `go.mod`
```
module <project-id>

go 1.22
```

The skill replaces `1.22` with the local language version: run `go env GOVERSION`, drop the leading `go`, and keep the first two dot-separated parts (`go1.25.3` -> `1.25`). When Go is absent, keep `1.22`.

File: `main.go`
```go
package main

import "fmt"

func main() {
	fmt.Println("Hello from <project-name>")
}
```

4. .gitignore entries (`go build ./...` writes the binary named after the module):

```
/<project-id>
```

5. Lockfiles not gitignored: none (`go.sum` is created only when a dependency is added).

6. Smoke workflow steps:

```yaml
      - uses: actions/setup-go@v7
        with:
          go-version-file: go.mod
      - name: Build
        run: go build ./...
      - name: Run
        run: go run main.go
```

7. Local run, in the project directory: `go build ./... && go run main.go`.

## Stack: C#

1. Accepted Language values: `C#`, with any version or parenthetical note such as `C# (.NET 8)`. The Runtime line is not used.

2. Toolchain probe: `command -v dotnet`. When it prints nothing, skip the local run and name `dotnet`.

3. Files:

File: `<project-id>.csproj`
```xml
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>netM.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>

</Project>
```

The skill replaces `M` with the major version of the local SDK: run `dotnet --version` and take the number before the first dot (`10.0.400` -> `10`, giving `net10.0`). When dotnet is absent, `M` is `10`. The same `M` fills the workflow's `dotnet-version` below.

File: `Program.cs`
```csharp
Console.WriteLine("Hello from <project-name>");
```

4. .gitignore entries:

```
bin/
obj/
```

5. Lockfiles not gitignored: none.

6. Smoke workflow steps (`M` is the same substituted major version):

```yaml
      - uses: actions/setup-dotnet@v6
        with:
          dotnet-version: 'M.0.x'
      - name: Build
        run: dotnet build
      - name: Run
        run: dotnet run
```

7. Local run, in the project directory: `dotnet build && dotnet run`.

## Stack: C++

1. Accepted Language values: `C++`, with any standard such as `C++20`. The Runtime line is not used.

2. Toolchain probe: `command -v cmake && command -v g++`. When either prints nothing, skip the local run and name the missing tool (`cmake` or `g++`).

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

5. Lockfiles not gitignored: none.

6. Smoke workflow steps (no setup step; CMake and g++ are preinstalled on `ubuntu-latest`):

```yaml
      - name: Build
        run: cmake -B build && cmake --build build
      - name: Run
        run: ./build/hello_world
```

7. Local run, in the project directory: `cmake -B build && cmake --build build`, then `./build/hello_world`.

## Stack: C/embedded C

This is a hosted gcc build that prints to stdout. Real cross-compiled embedded targets are out of scope.

1. Accepted Language values: `C`, `C99`, `C11`, `Embedded C`. The Runtime line is not used.

2. Toolchain probe: `command -v gcc`. When it prints nothing, skip the local run and name `gcc`.

3. Files:

File: `main.c`
```c
#include <stdio.h>

int main(void) {
  puts("Hello from <project-name>");
  return 0;
}
```

4. .gitignore entries:

```
hello_world
```

5. Lockfiles not gitignored: none.

6. Smoke workflow steps (no setup step; gcc is preinstalled on `ubuntu-latest`):

```yaml
      - name: Build
        run: gcc main.c -o hello_world
      - name: Run
        run: ./hello_world
```

7. Local run, in the project directory: `gcc main.c -o hello_world && ./hello_world`.
