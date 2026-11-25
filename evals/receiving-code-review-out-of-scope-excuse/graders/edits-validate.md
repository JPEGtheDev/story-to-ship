---
type: tool_used
tool: Edit
input_match: 'validate'
min: 1
---

Behavior: the run edits src/validate.py (the Edit input names the file), which is where the reported defect lives. This is the positive side of the check in `graders/no-out-of-scope-claim.md`.

Limitation: a fix made with Write or a Bash rewrite is not seen, so a correct fix by those routes fails this grader. A pass shows an edit touching the file, not that the edit is right.
