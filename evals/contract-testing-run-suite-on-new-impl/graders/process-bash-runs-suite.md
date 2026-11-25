---
type: tool_used
tool: Bash
input_match: '"command"\s*:\s*"(?:[^"\\]|\\.)*?(?:-m\s+(?:unittest|pytest)\b|(?:[;&|(]|\\n)\s*pytest\b)|"command"\s*:\s*"pytest\b'
min: 1
---

Behavior: the run issues at least one Bash command that runs the test runner (`-m unittest`, `-m pytest`, or `pytest` as a command word), so the shared contract suite is executed. The match is confined to the Bash `command` value, so a description that names unittest does not count, and a probe such as `which pytest` does not count. It does not check that the run covered the new implementation or that the tests passed; the outcome grader covers the registration. The check is a substring match on the command, so no judge is needed.
