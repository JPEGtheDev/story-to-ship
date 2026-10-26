# Todo Templates

Template for one implementation task in a writing-plans plan. The task is one todo; Steps 1-6 are its ordered steps, reviewed once at the end.

## Single-implementer template (`loop: single`)

Use for a todo marked `loop: single`: one implementer runs Steps 1-6. Rule for choosing the loop is under "Loop marker" below.

```
Task N: [Feature or component name]
loop: single -- reason: [one line]
Files:
  - Create: exact/path/to/NewFile.<ext>
  - Modify: exact/path/to/ExistingFile.<ext>
  - Test:   tests/path/to/TestFile.<ext>
Depends on: none | Task numbers (required on every todo)

Step 1 RED:      Write the failing test for [behavior]
Step 2 RED:      Run test -- verify it fails for the right reason
Step 3 GREEN:    Write minimal implementation to pass the test
Step 4 GREEN:    Run full suite -- verify all tests pass
Step 5 REFACTOR: Clean up -- rename, extract, remove duplication; tests must stay green
Step 6 COMMIT:   git add / git commit -m "feat(scope): description"
```

Two todos run at the same time only when neither depends on the other and their `Files:` lists share no file, test files included. A todo without a `Files:` list or a `Depends on:` line runs alone (see the Parallel todos section of the story coordinator agent).

## Seam table (before todo 1 of a code story)

Name the seams before any todo starts. One row per code todo:

```
Seams:
| Todo | Type or interface (signature) | Module (path) | Collaborators |
|------|-------------------------------|---------------|---------------|
| 1 | parseRecord(text: string) -> Record | exact/path/to/Parser.<ext> | none |
| 2 | formatRecord(record: Record) -> string | exact/path/to/Formatter.<ext> | Locale |
Test paths: <one extended regular expression (ERE) matching test file paths, or "default">
Architecture review: <verdict line from the architecture-review skill>
```

- `Collaborators` writes `none` when the seam has no collaborators; otherwise it names the collaborator types, which are the types or interfaces the unit under test talks to and the test-writer must fake or inject. Todo order is a planning matter, not a seam cell.
- A todo whose row has a blank cell is not dispatched; it returns to planning.
- A cell that reads TBD (to be determined) counts as blank.

## Loop marker (every plan entry)

Every plan entry carries one marker line, with a one-line reason:

```
loop: three-role -- reason: adds parseRecord to a non-prose source file with a runnable suite
loop: single -- reason: prose-only change to the template
```

A CI fixture test exercises tools/role_check/plan-check.sh; CI does not check live plans, so run `sh tools/role_check/plan-check.sh <plan file>` on a plan to check it. An entry header is a line starting `Todo N:` or `Task N:` (digits, then a colon), and each entry needs a `loop: three-role` or `loop: single` line before the next header.

Rule for choosing:

- `loop: three-role` when the todo adds or changes behaviour in a non-prose source file of a repo with a runnable test suite.
- `loop: single` for prose, config, a repo with no runnable suite, a pure refactor or deletion, fix rounds after the end review, and reconcile fix rounds.
- A todo mixing code and prose is split into a code todo and a prose todo.

## Three-role todo template (`loop: three-role`)

Three dispatches, each by a different implementer, against the seam named in the seam table:

```
Todo N: [Behaviour name]
loop: three-role -- reason: [one line]
Seam: [row from the seam table]

Role 1 test-writer: Write one failing test against the named seam. Touch test files only.
  Run it and confirm it fails at run time with an assertion failure, not a compile or import error. Commit `test(scope): description`
  with the failure output pasted.
Role 2 pass-maker: A different implementer. Touch non-test files only. Write the least
  code this todo can justify. Run the full suite. Commit `feat(scope): description` or
  `fix(scope): description` with the full suite run pasted.
Role 3 refactorer: A different implementer. Improve names, function size, duplication
  and dependency direction; the suite stays green. Commit `refactor(scope): description`,
  or record `no refactor needed: <reason>` and commit nothing.
Review: One spec review over the three commits.
```

One commit per role; the refactorer may commit nothing, as stated above.
A `loop: three-role` todo runs alone and is never put in a batch of todos that run at the same time.
