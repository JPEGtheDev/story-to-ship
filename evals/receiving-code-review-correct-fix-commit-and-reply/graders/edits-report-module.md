---
type: tool_used
tool: Edit
input_match: 'report'
min: 1
---

Behavior: the run edits src/report.py with an Edit call, since the comment reports a real defect and the fix belongs in the code. The match is the module name in the tool input.

Limitation: the grader does not check that the edit is the right one; the scaffold's test suite fails on the seeded defect, but the harness does not run it after the session. A run that fixes the file with a Write call or a shell redirect fails this grader although the code changed.
