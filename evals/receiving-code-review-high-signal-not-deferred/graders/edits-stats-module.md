---
type: regex
pattern: '"name":\s*"(?:Edit|Write)",\s*"input":\s*\{[^{}]*?"file_path":\s*"[^"]*src/stats\.py"'
match: contains
target: trace
---

Behavior: the agent fixes the defect in the statistics module's code during this change, since the comment names the line and the consequence, so the fix belongs in this change.

Evaluation criteria: the check searches the run's trace for an Edit or a Write tool call whose file_path field ends with the planted path src/stats.py, the file the case's setup plants the defect in (the mean function divides by one more than the number of values), and needs at least one such call. The pattern reads the file_path field only, so an edit to tests/test_stats.py alone does not count, and neither does an Edit whose new text mentions src/stats.py.

Limitation: the grader does not check that the edit is the right one; the scaffold's test suite fails on the seeded defect, but the harness does not run it after the session. A fix made through a shell redirect or a shell command is not covered by this check, although the code changed. The pattern reads the tool name and the file_path field of the tool input, with the file_path field before any brace in that input.
