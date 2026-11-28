---
type: tool_used
tool: Edit
input_match: '"file_path":\s*"[^"]*src/validate\.py"'
min: 1
---

Behavior: the agent fixes the defect the reviewer reported in the code where it lives, not in a test or in the export code alone.

Evaluation criteria: The check matches the file_path field of an Edit call's input and passes when that field ends in src/validate.py, so an edit to tests/test_validate.py or src/export.py alone does not satisfy it. The case's setup plants the reported defect in src/validate.py, so an edit to that file is where the defect is fixed. This is the positive side of the check in graders/no-out-of-scope-claim.md.

Limitation: a fix made with Write or a Bash rewrite is not seen, so a correct fix by those routes fails this grader. A pass shows an edit touching the file, not that the edit is right.
