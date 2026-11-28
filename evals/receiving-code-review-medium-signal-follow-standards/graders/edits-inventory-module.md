---
type: tool_used
tool: Edit
input_match: '"file_path":\s*"[^"]*src/inventory\.py"'
min: 1
---

Behavior: the agent renames the misnamed function in the inventory module, since the documented naming standard calls for it.

Evaluation criteria: the check passes when an Edit call has the path src/inventory.py in the file_path field, and needs at least one such call. The setup places the misnamed function in src/inventory.py, the file the check names. The match is the path src/inventory.py in the file_path field of the tool input, so an edit to tests/test_inventory.py alone does not satisfy it.

Limitation: the grader does not check that the edit is the right one, and the rename also touches the test file, which this check does not require. A change made through Write or a shell command fails this grader although the code changed.
