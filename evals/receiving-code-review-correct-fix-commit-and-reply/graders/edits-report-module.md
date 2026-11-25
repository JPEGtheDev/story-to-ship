---
type: tool_used
tool: Edit
input_match: 'src/report\.py'
min: 1
---

Behavior: the run edits src/report.py with an Edit call, since the comment reports a real defect and the fix belongs in the code. The match is the path `src/report.py` in the tool input, so an Edit to `tests/test_report.py` does not count.

Limitation: the grader does not check that the edit is the right one, and any text in the tool input that holds `src/report.py` also matches; the scaffold's test suite fails on the seeded defect, but the harness does not run it after the session. A run that fixes the file with a Write call or a shell redirect fails this grader although the code changed.
