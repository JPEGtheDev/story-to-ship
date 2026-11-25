---
type: tool_used
tool: Bash
input_match: '(unittest|pytest)'
min: 1
---

Behavior: the run runs the formatter tests with a Python test runner, that is, a Bash command whose `command` text contains `unittest` or `pytest`. This is the process side of the rule: the agent verifies the new method with the existing suite. The check counts calls only; it does not read the output or the exit status, and it does not check that the run was green. It does not check that the run was the first step or that any test was written first.
