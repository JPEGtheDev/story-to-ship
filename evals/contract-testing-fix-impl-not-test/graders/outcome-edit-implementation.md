---
type: tool_used
tool: Edit
input_match: '"file_path"\s*:\s*"[^"]*src/store\.py"'
min: 1
---

Behavior: the run edits the implementation file `src/store.py` with an Edit call, which is the fix the rule requires when a shared contract test fails for one implementation. The check matches the `file_path` field only, so an `old_string` that happens to contain `src/store.py` does not count. It does not check that the edit is correct, and it does not check that the suite went green. The check is a field match, so no judge is needed.
