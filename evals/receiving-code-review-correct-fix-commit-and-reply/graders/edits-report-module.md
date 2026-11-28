---
type: tool_used
tool: Edit
input_match: '"file_path":\s*"[^"]*src/report\.py"'
min: 1
---

Behavior: the agent fixes the reported defect in the code itself, not in the test and not only in its reply, since the comment reports a real defect and the fix belongs in the code.

Evaluation criteria: The check counts calls of the Edit tool in the run whose file_path field in the tool input holds the path src/report.py, and needs at least one. The case's setup plants the bug in src/report.py. The match is the path src/report.py in the file_path field, so an Edit to tests/test_report.py does not count, even when its new text mentions src/report.py.

Limitation: the grader does not check that the edit is the right one; the scaffold's test suite fails on the seeded defect, but the harness does not run it after the session. A run that fixes the file with a Write call or a shell redirect fails this grader although the code changed.
