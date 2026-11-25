---
type: tool_used
tool: Edit
input_match: 'stats'
min: 1
---

Behavior: the run edits src/stats.py with an Edit call, since the comment names a line and a consequence and the fix belongs in this change. The match is the module name in the tool input.

Limitation: the grader does not check that the edit is the right one; the scaffold's test suite fails on the seeded defect, but the harness does not run it after the session. A fix made through Write or a shell redirect fails this grader although the code changed.
