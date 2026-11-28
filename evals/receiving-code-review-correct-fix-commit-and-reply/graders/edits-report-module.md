---
type: regex
pattern: '"name":\s*"(?:Edit|Write)",\s*"input":\s*\{[^{}]*?"file_path":\s*"[^"]*src/report\.py"'
match: contains
target: trace
---

Behavior: the agent fixes the reported defect in the code itself, not in the test and not only in its reply, since the comment reports a real defect and the fix belongs in the code.

Evaluation criteria: The check searches the run's trace for an Edit or a Write tool call whose file_path field in the tool input holds the planted path src/report.py, and needs at least one. The case's setup plants the bug in src/report.py. The match is the path src/report.py in the file_path field, so an Edit to tests/test_report.py does not count, even when its new text mentions src/report.py.

Limitation: the grader does not check that the edit is the right one; the scaffold's test suite fails on the seeded defect, but the harness does not run it after the session. A run that fixes the file through a shell redirect or a shell command is not covered by this check, although the code changed. The pattern reads the tool name and the file_path field of the tool input, with the file_path field before any brace in that input. A call that the tool refuses or that fails still matches, so the check can pass with the file unchanged; the llm grader judges the reply.
