# Plan Rationale and Templates

Templates and rationale moved out of SKILL.md to keep it under its size cap.

## TDD todo template

```
Task N: [Feature or component name]
Files:
  - Create: exact/path/to/NewFile.<ext>
  - Modify: exact/path/to/ExistingFile.<ext>
  - Test:   tests/path/to/TestFile.<ext>

RED   todo: Write the failing test for [behavior]
RED   todo: Run test -- verify it fails for the right reason
GREEN todo: Write minimal implementation to pass the test
GREEN todo: Run full suite -- verify all tests pass
REFACTOR todo: Clean up -- rename, extract, remove duplication; tests must stay green
COMMIT todo: git add / git commit -m "feat[scope]: description"
```
