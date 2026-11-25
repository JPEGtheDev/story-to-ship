---
type: tool_used
tool: Edit
input_match: '"file_path"\s*:\s*"(?:[^"\\]|\\.)*?/tests/test_store_contract\.py"(?:,"[a-z_]+"\s*:\s*(?:"(?:[^"\\]|\\.)*"|true|false))*,"new_string"\s*:\s*"(?:[^"\\]|\\.)*SqliteStore'
min: 1
---

Behavior: the run edits tests/test_store_contract.py and the new text it inserts mentions SqliteStore, so the new implementation is added to the shared contract suite. The match reads the Edit `new_string` only, so a SqliteStore mention in `old_string` does not count. A Write to the same file is not counted by this grader; the check covers the Edit tool only. The check is a substring match on the tool input, so no judge is needed.
