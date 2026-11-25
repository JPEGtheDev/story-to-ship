---
type: tool_used
tool: Edit
input_match: '^(?=.*formatter\.py)(?=.*def truncate)'
min: 1
---

Behavior: the run edits `formatter.py` and the edit text defines `truncate`, so the requested method is added to `Formatter`. The check matches the JSON text of the Edit input, with `formatter.py` and `def truncate` both present in any order. It does not check the method body, the signature, or the test result. A `Write` that creates the method is not counted, because no real run in the saved traces used `Write` for this change; a run that adds the method only with `Write` fails this check.
