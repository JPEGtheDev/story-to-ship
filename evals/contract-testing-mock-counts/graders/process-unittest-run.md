---
type: tool_used
tool: Bash
input_match: '(?:-m\s+(?:unittest|pytest)\b|\bpytest\b)'
min: 1
---

Behavior: the run executes a Python test runner (`python -m unittest` or `pytest`) in at least one Bash call, so a shared test suite is actually run. The check is a command-form match on the Bash input, so no judge is needed. It does not check which tests ran, whether they passed, or whether the suite contains a contract test; the outcome grader covers the suite's content.
