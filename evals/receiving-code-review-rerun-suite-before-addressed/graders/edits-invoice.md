---
type: tool_used
tool: Edit
input_match: 'invoice'
min: 1
---

Behavior: the run edits a path that contains `invoice`, the fix for the reported defect. This is the positive side of the ordering check in `graders/suite-run-after-edit.md`, which passes only when an Edit exists. The check is a command form, so no judge is needed.

Limitation: it shows an edit was made on that path, not that the edit corrects the defect. The result of the post-fix suite run is judged by `reports-post-fix-result`.
