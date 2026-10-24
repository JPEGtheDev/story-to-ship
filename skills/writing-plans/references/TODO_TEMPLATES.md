# Todo Templates

Template for one implementation task in a writing-plans plan. The task is one todo; Steps 1-6 are its ordered steps, reviewed once at the end.

## Test-Driven Development (TDD) todo template

```
Task N: [Feature or component name]
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

Two todos run at the same time only when neither depends on the other and their `Files:` lists share no file, test files included. A todo without a `Files:` list or a `Depends on:` line runs alone (see the Parallel todos section of agents/story-coordinator.md).
