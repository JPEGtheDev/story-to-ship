---
type: tool_used
tool: Edit
input_match: '"file_path":\s*"[^"]*src/stats\.py"'
min: 1
---

Behavior: the agent fixes the defect in the statistics module's code during this change, since the comment names the line and the consequence, so the fix belongs in this change.

Evaluation criteria: the check requires at least one Edit call (min 1) whose file_path field ends with src/stats.py, the file the case's setup plants the defect in (the mean function divides by one more than the number of values). The pattern reads the file_path field only, so an edit to tests/test_stats.py alone does not count, and neither does an Edit whose new text mentions src/stats.py.

Limitation: the grader does not check that the edit is the right one; the scaffold's test suite fails on the seeded defect, but the harness does not run it after the session. A fix made through Write or a shell redirect fails this grader although the code changed.
