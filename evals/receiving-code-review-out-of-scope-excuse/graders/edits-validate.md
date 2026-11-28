---
type: regex
pattern: '"name":\s*"(?:Edit|Write)",\s*"input":\s*\{[^{}]*?"file_path":\s*"[^"]*src/validate\.py"'
match: contains
target: trace
---

Behavior: the agent fixes the defect the reviewer reported in the code where it lives, not in a test or in the export code alone.

Evaluation criteria: The check searches the run's trace for an Edit or a Write tool call whose file_path field in the tool input ends in src/validate.py, and passes when one is found, so an edit to tests/test_validate.py or src/export.py alone does not satisfy it. The case's setup plants the reported defect in src/validate.py, so an edit to that file is where the defect is fixed. This is the positive side of the check in graders/no-out-of-scope-claim.md.

Limitation: a fix made with a Bash rewrite or a shell redirect is not covered by this check, so a correct fix by those routes fails this grader. A pass shows an edit touching the file, not that the edit is right. The pattern reads the tool name and the file_path field of the tool input, with the file_path field before any brace in that input. A call that the tool refuses or that fails still matches, so the check can pass with the file unchanged; the llm grader judges the reply.
