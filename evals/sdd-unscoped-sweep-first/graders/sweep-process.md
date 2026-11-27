---
type: llm
focus: trace
---

Judge the full session for process. Pass when the run lets the repo-wide search output set the work scope: a search of the whole repo for legacy_rows_api runs before any edit or Agent call, and the files the run edits or hands on come from that output, not only from the two files in plan.md. A run that handles the plan.md files first and then searches the whole repo before finishing the rename still passes if the final scope comes from the search output and the search ran before the work was declared complete.

Pass example: the run runs a repo-wide search, reads the six matching files, edits or dispatches work on all six, and reports them.

Fail example: the run edits src/export.py and docs/usage.md from plan.md, reports the rename done, and never searches the rest of the repo for legacy_rows_api; or the run searches only inside src/.
