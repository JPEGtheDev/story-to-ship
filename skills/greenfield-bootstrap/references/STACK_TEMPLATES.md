# Stack Templates

Per-stack facts for `greenfield-bootstrap`. Each `## Stack:` section below holds the literal files, `.gitignore` entries, workflow steps, and local-run commands for one supported stack. Copy the values as written. Two tokens apply in every stack and are substituted when the files are written: `<project-name>` and `<project-id>`. The Go and C# sections each substitute one more value, stated where it appears. Each stack's smoke workflow is the GitHub Actions workflow at `.github/workflows/smoke.yml` that builds and runs the hello world on every push and pull request. The `## Shared:` sections after the stacks hold the stack-independent files, which are combined with the chosen stack's values. Each `## Stack:` section is a numbered list of seven items, and "field N" anywhere in this file means numbered item N of the chosen stack's section.

## Tokens and Language Mapping

### Tokens

- `<project-name>`: the target directory's name as the user wrote it. It may contain spaces and uppercase letters. It appears in the printed line and in the README.
- `<project-id>`: an identifier derived from the name. Lowercase the name. Replace every run of characters outside a-z, 0-9 and hyphen with one hyphen. Remove leading and trailing hyphens. Prefix `app-` when the result starts with a digit. When the result is empty, use `app`. Examples: `Tide Log` -> `tide-log`; `7seas` -> `app-7seas`.
- When `<project-name>` contains a double quote or a backslash, the printed line uses `<project-id>` in place of `<project-name>`, so the string literal stays valid in every stack.
- Every hello world prints exactly one line containing the name, for example `Hello from tide-log`, and exits 0. The Rust and C templates route the name through a format-safe call (`println!` with a `{}` argument, `puts`), so braces and percent signs in the name stay literal.

### Language-value mapping

Take the Language value from the `## Architecture Decision` block (produced by the `greenfield-architecture` skill) before its ` -- ` separator. Ignore version numbers and parenthetical notes when matching: `Python 3.12` -> Python; `C++20` -> C++; `C# (.NET 8)` -> C#. For TypeScript, also read the `Runtime/framework` value from the same block, again only the part before its ` -- ` separator.

| Language value | Stack section |
|---|---|
| Python | `## Stack: Python` |
| TypeScript, when every runtime or framework the `Runtime/framework` value names is on this list: Node.js, Express, NestJS, Fastify, Koa | `## Stack: TypeScript/Node.js` |
| Rust | `## Stack: Rust` |
| Go, Golang | `## Stack: Go` |
| C# | `## Stack: C#` |
| C++ | `## Stack: C++` |
| C, C99, C11, Embedded C | `## Stack: C/embedded C` |

Not supported: TypeScript whose `Runtime/framework` value names any runtime or framework outside that list (for example Deno, Bun, Next.js, React or Vite, even alongside Node.js), JavaScript, and every other language. The TypeScript template is a console program, so a browser app or a full-stack framework is out of scope.

### Action versions

Every generated workflow starts from `actions/checkout@v7`. Setup actions used below: `actions/setup-python@v7`, `actions/setup-node@v7`, `actions/setup-go@v7`, `actions/setup-dotnet@v6`. Rust, C and C++ use the toolchain preinstalled on the `ubuntu-latest` runner (Cargo, CMake, gcc and g++ are listed in its image readme), so those stacks have no setup step.

## Stack: Python

1. Accepted Language values: `Python`, with any version number or parenthetical note. The `Runtime/framework` value is not read for mapping, and any framework it names is not scaffolded.

2. Toolchain probe: `command -v python || command -v python3`. When neither prints a path, skip the local run and report `python3` as missing in the final `## Bootstrapped Files` summary.

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

5. Lockfile committed with the project: none.

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

1. Accepted Language values: `TypeScript`, when every runtime or framework the `Runtime/framework` value names (the part before its ` -- ` separator) is on this list: Node.js, Express, NestJS, Fastify, Koa. The framework itself is not scaffolded; the hello world stays a plain Node.js console program. A value that names any other runtime or framework, even alongside Node.js (for example Deno, Bun, Next.js, React or Vite), is not supported, because the template is a console program and a browser app or a full-stack framework is out of scope.

2. Toolchain probe: `command -v node && command -v npm`. When either prints nothing, skip the local run and report `node` as missing (npm ships with Node.js) in the final `## Bootstrapped Files` summary.

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

5. Lockfile committed with the project: `package-lock.json` (created by `npm install`).

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

1. Accepted Language values: `Rust`. The `Runtime/framework` value is not read for mapping, and any framework it names is not scaffolded.

2. Toolchain probe: `command -v cargo`. When it prints nothing, skip the local run and report `cargo` as missing (installed with `rustup`) in the final `## Bootstrapped Files` summary.

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

5. Lockfile committed with the project: `Cargo.lock` (created by `cargo build`).

6. Smoke workflow steps (no setup step; Cargo is preinstalled on `ubuntu-latest`):

```yaml
      - name: Build
        run: cargo build
      - name: Run
        run: cargo run
```

7. Local run, in the project directory: `cargo build && cargo run`.

## Stack: Go

1. Accepted Language values: `Go`, `Golang`. The `Runtime/framework` value is not read for mapping, and any framework it names is not scaffolded.

2. Toolchain probe: `command -v go`. When it prints nothing, skip the local run and report `go` as missing in the final `## Bootstrapped Files` summary.

3. Files:

File: `go.mod`
```
module <project-id>

go 1.22
```

The extra substituted value here is the Go version. The skill replaces `1.22` with the local language version: run `go env GOVERSION`, drop the leading `go`, and keep the first two dot-separated parts (`go1.25.3` -> `1.25`). When Go is absent, keep `1.22`.

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

5. Lockfile committed with the project: none (`go.sum` is created only when a dependency is added).

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

1. Accepted Language values: `C#`, with any version or parenthetical note such as `C# (.NET 8)`. The `Runtime/framework` value is not read for mapping, and any framework it names is not scaffolded.

2. Toolchain probe: `command -v dotnet`. When it prints nothing, skip the local run and report `dotnet` as missing in the final `## Bootstrapped Files` summary.

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

The extra substituted value here is `M`. The skill replaces `M` with the major version of the local .NET Software Development Kit (SDK): run `dotnet --version` and take the number before the first dot (`10.0.400` -> `10`, giving `net10.0`). When dotnet is absent, `M` is `10`. The same `M` fills the workflow's `dotnet-version` below.

File: `Program.cs`
```csharp
Console.WriteLine("Hello from <project-name>");
```

4. .gitignore entries:

```
bin/
obj/
```

5. Lockfile committed with the project: none.

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

## Stack: C/embedded C

This is a hosted gcc build that prints to stdout. Real cross-compiled embedded targets are out of scope.

1. Accepted Language values: `C`, `C99`, `C11`, `Embedded C`. The `Runtime/framework` value is not read for mapping, and any framework it names is not scaffolded.

2. Toolchain probe: `command -v gcc`. When it prints nothing, skip the local run and report `gcc` as missing in the final `## Bootstrapped Files` summary.

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

5. Lockfile committed with the project: none.

6. Smoke workflow steps (no setup step; gcc is preinstalled on `ubuntu-latest`):

```yaml
      - name: Build
        run: gcc main.c -o hello_world
      - name: Run
        run: ./hello_world
```

7. Local run, in the project directory: `gcc main.c -o hello_world && ./hello_world`.

## Shared: README.md

The README is the same for every stack except the prerequisites line and the run commands. Write it from this template:

```markdown
# <project-name>

<Purpose: one paragraph of plain sentences restating the Problem field of the `## Domain Model` block.>

## Open questions

- <one open question from the Open Questions field of the `## Domain Model` block>

## Prerequisites

- <the prerequisites line for the chosen stack, from the table below>

## How to run

In the project directory, run:

<the stack's field-7 local-run commands>
```

Fill rules:

- `<project-name>` is the token defined above.
- The purpose paragraph restates the Problem field in plain sentences. When the Open Questions field is not `None`, the paragraph does not state the answer to any open question as settled.
- The `## Open questions` section is written only when the Open Questions field is not `None`. It lists each open question as one bullet. When the field is `None`, omit the whole section, heading included.
- `## How to run` holds the text of field 7 in the chosen `## Stack:` section after its `Local run, in the project directory:` label, copied as written, including its own code spans, any fallback or second command (`python3 main.py`, `node dist/main.js`, `./build/hello_world`) and any closing sentence. Do not wrap the copied text in another code span.

Prerequisites line per stack:

| Stack | Prerequisites line |
|---|---|
| Python | Python 3 |
| TypeScript/Node.js | Node.js Long-Term Support (LTS) release with npm |
| Rust | Rust toolchain with Cargo |
| Go | Go |
| C# | .NET SDK of version M |
| C++ | CMake and a C++ compiler |
| C/embedded C | gcc for a hosted build; the build runs on the host, not cross-compiled for a device |

In the C# row, `M` is the major version substituted in the C# section; write that value in place of `M`.

## Shared: .gitignore

The `.gitignore` holds exactly the chosen stack's field-4 entries, one per line. It holds no generic entries and no entries from any other stack.

## Shared: .github/workflows/smoke.yml

The workflow frame is the same for every stack. Insert the chosen stack's field-6 steps in place of the marker comment line. The field-6 snippets are already indented six spaces, which matches the `steps:` list below, so paste them without re-indenting. Delete the marker comment line after the insert.

```yaml
name: Smoke

on:
  push:
  pull_request:

permissions:
  contents: read

jobs:
  smoke:
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@v7
      # INSERT THE STACK'S FIELD-6 STEPS HERE
```

Build and run stay separate steps. No step is followed by a command that forces success, and build and run commands are never joined with a semicolon, so a failing hello world fails the job.

## Shared: .github/ISSUE_TEMPLATE/bug_report.md

```markdown
---
name: Bug report
about: Report something that does not work as expected
title: "[Bug] "
labels: bug
---

## Summary

[One or two sentences describing the bug]

## Steps to reproduce

1. [First step]
2. [Second step]
3. [What you see]

## Expected behavior

[What you expected to happen]

## Actual behavior

[What happened instead, with error messages or output]

## Environment

- OS: [e.g., Ubuntu 24.04]
- Tool versions: [e.g., language runtime and build tool versions]
- Commit or version: [e.g., git commit hash]
```

## Shared: .github/ISSUE_TEMPLATE/user_story.md

```markdown
---
name: User story
about: Describe a unit of work as a story with acceptance criteria
title: "[Story] "
---

**Type:** Feature | Refactor | Spike | Bug
**Size:** S | M | L
**Depends On:** [Issue numbers or "None"]

---

## User Story

**As a** [role: developer, tester, user]
**I want to** [action]
**So that** [outcome/business value]

---

## Acceptance Criteria

- [ ] [Specific, measurable outcome]
- [ ] [Another measurable outcome]
- [ ] [Edge case or constraint]

---

## Technical Notes

**Dependencies:**
- [Other stories, external packages, or "None"]

**Constraints:**
- [Platform requirements, performance targets]

**Files to Create/Modify:**
- [List of modules with specific file paths]

---

## Definition of Done

- [ ] Code written and peer-reviewed
- [ ] Tests written and passing
- [ ] No new linter or compiler warnings
- [ ] Documentation updated
- [ ] Ready to merge to the main branch
```

## Shared: .github/ISSUE_TEMPLATE/spike.md

```markdown
---
name: Spike
about: Time-boxed investigation to answer a question before committing to work
title: "[Spike] "
---

## Question

[The single question this spike answers]

## Timebox

[Maximum time to spend, e.g., 4 hours]

## Approach

[How you will investigate: what to read, build, or measure]

## Findings

[What was learned, with evidence such as links, numbers, or code snippets]

## Decision and next step

[The decision the findings support and the follow-up issue to open]

## Exit criteria

- [ ] The question is answered
- [ ] Findings are recorded above
- [ ] A decision and next step are written down
```
