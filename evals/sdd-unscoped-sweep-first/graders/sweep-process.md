---
type: llm
focus: trace
---

Judge the full session for process. Pass when a search of the whole repo for legacy_rows_api runs before any Edit, Write or Agent call, and the files the run edits or hands on come from that search output, not only from the two files in plan.md. Reading plan.md before the search is allowed; an edit, write or hand-off before the whole-repo search is not.

Pass example: the run reads plan.md, runs a repo-wide search, reads the six matching files, edits or dispatches work on all six, and reports them.

Fail example: the run edits src/export.py and docs/usage.md from plan.md before any repo-wide search, then reports the rename done; or the run hands work to an Agent call before any repo-wide search; or the run never searches the rest of the repo for legacy_rows_api; or the run searches only inside src/.
