---
type: tool_used
tool: Edit
input_match: 'io_util'
min: 1
---

Behavior: the run edits a path that contains `io_util`, the file both listed items concern. The check is a command form, so no judge is needed.

Limitation: it shows an edit was made on that file, not that both items were fixed. A run that edits only the docstring or only the handle passes it. The llm grader `answers-both-items` checks that the posted text covers both.
