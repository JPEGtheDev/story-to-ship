---
type: tool_used
tool: Edit
input_match: 'inventory'
min: 1
---

Behavior: the run edits src/inventory.py with an Edit call, since the documented naming standard calls for a change. The match is the module name in the tool input.

Limitation: the grader does not check that the edit is the right one, and the rename also touches the test file, which this check does not require. A change made through Write or a shell command fails this grader although the code changed.
