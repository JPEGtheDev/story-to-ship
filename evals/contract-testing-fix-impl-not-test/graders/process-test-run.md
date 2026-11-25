---
type: tool_used
tool: Bash
input_match: 'unittest|pytest'
min: 1
---

Behavior: the run executes the test suite with a Bash call that names `unittest` or `pytest`, so the agent saw the failing contract test before it changed anything. The check is a command match on the Bash input, so no judge is needed. It does not check that the suite passed afterwards, and it does not check which file was edited.
