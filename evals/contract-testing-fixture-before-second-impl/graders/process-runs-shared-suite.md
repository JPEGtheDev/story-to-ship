---
type: tool_used
tool: Bash
input_match: '-m\s+unittest|\bpytest\b'
min: 1
---

Behavior: the run issues a Bash command that runs the Python test runner, either `python3 -m unittest ...` or `pytest`, so the test files the run wrote get executed. The check counts the command only: it does not read the output and does not know which test file ran. It does not show that the suite covers both implementations; the outcome grader checks that. The check is a command form, so no judge is needed.
