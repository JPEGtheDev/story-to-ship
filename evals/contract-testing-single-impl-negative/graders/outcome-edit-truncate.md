---
type: tool_used
tool: Edit
input_match: '^(?=.*"file_path"\s*:\s*"[^"]*src/formatter\.py")(?=.*def truncate)'
min: 1
---

Behavior: the run edits `src/formatter.py` and the edit text defines `truncate`, so the requested method is added to `Formatter`. The check matches the JSON text of the Edit input: the `file_path` value must end in `src/formatter.py`, so `tests/test_formatter.py` does not count, and `def truncate` must appear in the edit text, in any order. It does not check the method body, the signature, or the test result. The grader counts `Edit` calls only, because a tool_used grader names one tool; a run that adds the method only with `Write` is not counted. That is a known limitation of this grader, and the case does not add a second grader for `Write`.
