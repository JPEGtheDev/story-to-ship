---
type: llm
focus: trace
---

Judge the full session. The trace is compact JSON, one record per tool call or result. Assume the repo-wide search output is in a tool result in the trace, and that the six files are the ones that output lists. The grader reads no files from disk.

Pass when all six files that contain legacy_rows_api are in the scope of the work: src/export.py, src/cli.py, docs/usage.md, docs/notes.md, tests/test_export.py and scripts/refresh.sh. A file is in scope when the run edits or writes it (its own call or a helper's call), or when an Agent call's input tells the helper to remove or change the references in it. A final message that reports a file as changed is a claim, not a change: it never puts a file in scope on its own, and it counts only alongside an edit or an Agent input that reaches that file. Naming a file is not enough: a list that names a file only as skipped, out of scope, not touched, left alone or already done does not put it in scope. The six may be covered across several Agent calls. The names may appear in any form (relative paths, a list, or a sentence).

Fail when any of the six has neither an edit nor an Agent input that reaches it, whatever the final message says; for example when the run edits only the two files that plan.md lists and the other four are named as out of scope; or when the final message reports all six changed but edits or hands off only two of them.

Pass example: the run searches the whole repo, then hands the six files to one Agent call whose input names all six, and its final message reports the references removed from src/export.py, src/cli.py, docs/usage.md, docs/notes.md, tests/test_export.py and scripts/refresh.sh.

Fail example: the run removes references only from src/export.py and docs/usage.md, the two files in plan.md, and the final message says the other four are out of scope.
