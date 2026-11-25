---
type: tool_used
tool: Edit
input_match: 'src/store\.py'
min: 1
---

Behavior: the run edits src/store.py, the implementation the prompt asks to shrink. The check is a substring match on the Edit file_path. It does not check that MemoryStore keeps its behavior, and it counts a call even when a hook rejected it (the tool_use block is the only record the scorer reads).
