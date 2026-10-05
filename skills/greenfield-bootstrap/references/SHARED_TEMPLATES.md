# Shared Templates

Shared facts for `greenfield-bootstrap`. This file holds the tokens, the Language-value mapping, the action versions and the stack-independent file templates. Each supported stack's literal files, `.gitignore` entries, workflow steps, and local-run commands are in its own file under `stacks/`, which the mapping table names. Copy the values as written. Two tokens apply in every stack and are substituted when the files are written: `<project-name>` and `<project-id>`. The Go and C# stack files each substitute one more value, stated where it appears. Each stack's smoke workflow is the GitHub Actions workflow at `.github/workflows/smoke.yml` that builds and runs the hello world on every push and pull request. The `## Shared:` sections in this file hold the stack-independent files, which are combined with the chosen stack's values. Each stack file holds one `## Stack:` section, a numbered list of seven items, and "field N" anywhere in this file means numbered item N of the `## Stack:` section in the chosen stack file.

## Tokens and Language Mapping

### Tokens

- `<project-name>`: the target directory's name as the user wrote it. It may contain spaces and uppercase letters. It appears in the printed line and in the README.
- `<project-id>`: an identifier derived from the name. Lowercase the name. Replace every run of characters outside a-z, 0-9 and hyphen with one hyphen. Remove leading and trailing hyphens. Prefix `app-` when the result starts with a digit. When the result is empty, use `app`. Examples: `Tide Log` -> `tide-log`; `7seas` -> `app-7seas`.
- When `<project-name>` contains a double quote or a backslash, the printed line uses `<project-id>` in place of `<project-name>`, so the string literal stays valid in every stack.
- Every hello world prints exactly one line containing the name, for example `Hello from tide-log`, and exits 0. The Rust and C templates route the name through a format-safe call (`println!` with a `{}` argument, `puts`), so braces and percent signs in the name stay literal.

### Language-value mapping

Take the Language value from the `## Architecture Decision` block (produced by the `greenfield-architecture` skill) before its ` -- ` separator. Ignore version numbers and parenthetical notes when matching: `Python 3.12` -> Python; `C++20` -> C++; `C# (.NET 8)` -> C#. For TypeScript, also read the `Runtime/framework` value from the same block, again only the part before its ` -- ` separator.

| Language value | Stack file |
|---|---|
| Python | `stacks/python.md` (`## Stack: Python`) |
| TypeScript, when every runtime or framework the `Runtime/framework` value names is on this list: Node.js, Express, NestJS, Fastify, Koa | `stacks/typescript-node.md` (`## Stack: TypeScript/Node.js`) |
| Rust | `stacks/rust.md` (`## Stack: Rust`) |
| Go, Golang | `stacks/go.md` (`## Stack: Go`) |
| C# | `stacks/csharp.md` (`## Stack: C#`) |
| C++ | `stacks/cpp.md` (`## Stack: C++`) |
| C, C99, C11, Embedded C | `stacks/c-embedded.md` (`## Stack: C/embedded C`) |

Not supported: TypeScript whose `Runtime/framework` value names any runtime or framework outside that list (for example Deno, Bun, Next.js, React or Vite, even alongside Node.js), JavaScript, and every other language. The TypeScript template is a console program, so a browser app or a full-stack framework is out of scope.

### Action versions

Every generated workflow starts from `actions/checkout@v7`. The stack files' workflow steps use these setup actions: `actions/setup-python@v7`, `actions/setup-node@v7`, `actions/setup-go@v7`, `actions/setup-dotnet@v6` (which installs the .NET Software Development Kit (SDK)). Rust, C and C++ use the toolchain preinstalled on the `ubuntu-latest` runner (Cargo, CMake, gcc and g++ are listed in its image readme), so those stacks have no setup step.

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
