---
type: tool_used
tool: Edit
input_match: 'src/validate\.py'
min: 1
---

Behavior: the run edits src/validate.py (the match is the path `src/validate.py` in the Edit input, so an edit to tests/test_validate.py or src/export.py alone does not satisfy it), which is where the reported defect lives. This is the positive side of the check in `graders/no-out-of-scope-claim.md`.

Limitation: a fix made with Write or a Bash rewrite is not seen, so a correct fix by those routes fails this grader. A pass shows an edit touching the file, not that the edit is right.
