---
name: greenfield-bootstrap
license: MIT
description: Use when a Domain Model block and an Architecture Decision block exist in the conversation and the project has no starter files yet.
---

## Iron Law

```
YOU MUST WRITE NO FILE UNTIL THE DOMAIN MODEL, A SUPPORTED STACK, AND A CLEAR TARGET DIRECTORY ARE CONFIRMED, AND REPORT PASSED ONLY FOR A HELLO WORLD RUN THAT EXITED 0.
No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

**Announce at start:** "I am using the greenfield-bootstrap skill to write a runnable starter project for [project name] into the current directory."

---

## When to Invoke

Load this skill after the `greenfield-discovery` skill (it produces the `## Domain Model` block) and the `greenfield-architecture` skill (it produces the `## Architecture Decision` block). The skill ends with the `## Bootstrapped Files` block.

Every literal value (file contents, ignore entries, workflow steps, run commands, tokens) lives in `references/STACK_TEMPLATES.md`. Copy values from it as written. This file holds the procedure and the gates only. The hello world is the one-line program the stack's template prints.

---

## Inputs

**Context:** The skill starts from the two blocks above. When several of a block exist, the most recent is authoritative.

**Forces:** A user asked to re-describe what a block already holds loses trust and time. A scaffold written on a guessed stack costs a rewrite.

- **Domain Model block:** read the **Problem:** field (required; it becomes the README purpose). Read **Open Questions:** (optional). Ignore the other fields.
- **Architecture Decision block:** read the `Language:` line (required) and, for TypeScript only, the `Runtime/framework:` line. Use the text before each ` -- ` separator. Ignore the other lines.
- NEVER ask the user to restate anything those blocks hold.
- **No `## Domain Model` block** (a bare invocation, or an Architecture Decision block alone): write no file. Tell the user to run the `greenfield-discovery` skill first. Stop.
- **No `## Architecture Decision` block, or a Language value that is blank, `TBD` (to be decided) or `[UNCLEAR:]`:** ask exactly one question for the stack before writing any file, then continue on the answer. When the Language value names two supported languages (for example `Go or Rust`), the one question asks which one to scaffold.
- **No user able to answer** (the skill runs inside a subagent, or nobody can reply): every question in this skill becomes a stop. Write no file. Name the missing fact: the stack, or the overwrite decision.

---

## Stack Gate

**Context:** Applies to the Language value from the block and to a Language value from the user's answer.

**Forces:** A value outside the seven stacks has no template, and a near-match written from memory ships unreviewed files.

Map the Language value with the `## Tokens and Language Mapping` section of `references/STACK_TEMPLATES.md`. A match selects its `## Stack: <label>` section. A value that maps to no stack section gets exactly this text, with [X] filled in, and no file is written:

`Stack [X] is not in the supported list. Supported: Python, TypeScript/Node.js, Rust, Go, C#, C++, C/embedded C.`

- [X] is the Language value before its ` -- ` separator, or the user's answer as given.
- When TypeScript is refused because of its Runtime/framework value, [X] is the Language value followed by the unsupported runtime or framework in parentheses, for example `TypeScript (Deno)`.
- JavaScript and every language outside the seven are refused. The directory stays unchanged.

---

## Target Directory

**Context:** The target is the current working directory. The project name is that directory's name, and the project id is derived from it as `## Tokens and Language Mapping` defines.

**Forces:** Merging into a file the user owns can destroy work and blurs which files the skill wrote.

1. Run the stack's field-2 toolchain probe first. The Go and C# values (the Go version, the C# major version `M`) come from the installed tool; the stack's field 3 says how.
2. List every path the stack writes: the shared files (`.gitignore`, `README.md`, `.github/workflows/smoke.yml`, and the three files under `.github/ISSUE_TEMPLATE/`) plus the stack's field-3 files.
3. Check each listed path. If any of them exists, write nothing and ask once whether to overwrite the listed files or stop. Stop on "stop", and stop when no user can answer.
4. NEVER merge into an existing file. On "overwrite", read each existing file once so the Write tool accepts the overwrite, then replace it whole.

---

## Writing the Files

Write each file with the Write tool, one file per call, from `references/STACK_TEMPLATES.md`:

- The stack's field-3 files, from the chosen `## Stack: <label>` section.
- `.gitignore` (`## Shared: .gitignore`): exactly the stack's field-4 entries.
- `.github/workflows/smoke.yml` (`## Shared: .github/workflows/smoke.yml`): the frame with the stack's field-6 steps inserted.
- `README.md` (`## Shared: README.md`): purpose from the Problem field, Open Questions only when the field is not `None`.
- The three issue templates (`## Shared: .github/ISSUE_TEMPLATE/bug_report.md`, `user_story.md`, `spike.md`).

Substitute `<project-name>`, `<project-id>`, and the per-stack values (the C# version, the Go version) as the reference names them. The reply NEVER pastes scaffold file content in a code block.

---

## Hook Denial

**Context:** A hook (a script the platform runs before a tool call, able to deny it) can deny a Write in the main session. A dispatched subagent can be exempt from that hook.

**Forces:** A denial is a policy decision, not a fault to route around. A retry through another route defeats the policy. Stopping leaves half a project.

When a hook denies a write:

1. Do NOT retry the write in another form: no shell redirection, no other extension, no other path.
2. Dispatch one subagent. Its prompt names the stack, the project name and id, the substituted values, the Problem and Open Questions text, the target directory, the files still unwritten, and the full path of this skill's `references/STACK_TEMPLATES.md` (this skill's base directory plus that relative path). Tell it to read the reference and write only those files into the same directory.
3. When it returns, list the directory to confirm the files exist. Then run the hello world and emit the block yourself.

---

## Local Run

**Context:** The stack's field-2 probe found the tool, or did not.

**Forces:** Installing a toolchain, or calling the code passed after reading it, turns a reported fact into a guess.

- **Tool missing:** still write the files. Report the hello world as NOT RUN, naming the missing tool. NEVER claim it ran. NEVER install a toolchain or any dependency beyond what the stack's own build step fetches.
- **Tool present:** before the summary, run the stack's field-7 commands in the target directory, unpiped (no `|`, no redirection). One run is the whole field-7 sequence. Note whether `package-lock.json`, `Cargo.lock` and `go.sum` exist before the run.
- **Exit 0:** PASSED, with the command and exit code.
- **A failure:** make at most one fix to a file this skill wrote and re-run once. Then report FAILED with the command and exit code of the last run. A run that did not exit 0 is NEVER PASSED. At most two runs.

**Context (one-fix limit):** Applies after the first failing run, whatever the cause.

**Forces:** A second repair loop turns a scaffold into open-ended debugging. One fix catches a slip in a substituted value; more hides a template defect the user must hear about.

---

## Bootstrapped Files Block

Emit the block after the run, as plain lines. The emitted block is not fenced. The fenced form below only shows the format; fill every bracket.

```
## Bootstrapped Files

Stack: [stack section label]
Project name: [target directory name]
Target directory: [current working directory]
Files written:
- [relative path]
Lockfiles created by the run: [package-lock.json, Cargo.lock, go.sum that the run created, or none]
Hello world: [PASSED / NOT RUN / FAILED] -- [command and exit code, or the missing tool]
```

- Files written lists exactly the files this skill and its subagent wrote: no more, no fewer.
- Lockfiles go on their own line. The generated `.gitignore` covers all other run output.

---

## Out of Scope

DO NOT run `git init`, commit, push, or create a remote. DO NOT install toolchains. DO NOT scaffold persistence, an API, frameworks, or libraries. DO NOT generate stories.

---

## BEFORE PROCEEDING

Before writing the first file, verify all of the following:

1. A `## Domain Model` block with a Problem field exists
2. The Language value is known (from the block or from one answer) and maps to a stack section; for TypeScript the Runtime/framework value is on the supported list
3. The field-2 probe ran and the Go or C# values are substituted
4. Every path the stack writes is listed, and none exists, or the user said overwrite

[+] All 4 met -> write the files
[-] Any unmet -> write nothing; run the matching step above (tell the user to run `greenfield-discovery`, ask the one stack question, print the refusal text, ask the overwrite question), or stop naming the missing fact when no user can answer

---

## Red Flags -- STOP

- Asking the user to restate the problem or the stack when the blocks hold them -> STOP. Read the blocks.
- Writing a file before the stack gate and the existing-file check passed -> STOP. Write nothing until both pass.
- Filling a refusal with a paraphrase, or scaffolding the nearest stack -> STOP. Print the exact text with [X] filled in.
- Writing into a directory that holds a listed path without asking, or merging into it -> STOP. Ask once, or stop.
- Retrying a denied write with a shell redirect or another extension -> STOP. Dispatch the subagent.
- Installing a toolchain, or running a dependency install the stack's build step does not run -> STOP. Report NOT RUN naming the tool.
- Reporting PASSED from reading the code, or after a non-zero exit -> STOP. Report NOT RUN or FAILED.
- A third run, or a second fix -> STOP. Report FAILED.
- Pasting scaffold file content in the reply, or fencing the emitted block -> STOP. Emit plain lines.
- Running `git init` or committing the new files -> STOP. The skill ends with the block.

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "The user is gone, so I will pick the stack myself" | An unanswerable question is a stop. Name the missing fact and write nothing. |
| "The toolchain is missing, so I will report PASSED from reading the code" | PASSED means a run exited 0. Report NOT RUN, name the tool, and never install it. |
| "The directory holds only a README.md, so merging a few lines is harmless" | A merge destroys the user's file and breaks the exact file list. Ask once: overwrite the listed files, or stop. |
| "The hook denied the write, so a shell redirect gets the file down" | The denial is policy. Dispatch one subagent that writes the remaining files. |
| "Deno is close enough to Node.js, so I will scaffold TypeScript/Node.js" | A near-match ships files nobody reviewed. Print the refusal with `TypeScript (Deno)` and write nothing. |
| "One more fix and re-run will make it pass" | The limit is one fix and two runs. After that, report FAILED with the command and exit code. |
| "The domain is vague, so I will ask the user to describe the project again" | Read the Problem field. Open Questions stay unsettled in the README. |
| "A repository needs git, so I will run git init and commit" | Repository creation is out of scope. The skill ends with the block. |
| "The summary can say PASSED for the build step alone" | PASSED covers the whole field-7 sequence ending in the hello world exiting 0. |

---

## Related Skills

- `greenfield-discovery` -- produces the `## Domain Model` block this skill reads
- `greenfield-architecture` -- produces the `## Architecture Decision` block this skill reads
