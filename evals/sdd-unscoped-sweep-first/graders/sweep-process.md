---
type: llm
focus: trace
---

Judge the full session for process. The trace is compact JSON, one record per tool call or result. Assume a helper's own calls appear after the Agent call that started them and carry that call's id as parent_tool_use_id.

Pass when a search of the whole repo for legacy_rows_api runs before any Edit, Write or edit-carrying hand-off, and the files the run edits or hands on come from that search output, not only from the two files in plan.md. A hand-off (an Agent call) may come before the run's own search when the helper's first action is a whole-repo search for legacy_rows_api that comes before the helper's first edit; that helper search counts as the sweep. Reading plan.md before the search is allowed.

Fail when an edit, write or hand-off comes before any whole-repo search for legacy_rows_api, and no helper search comes before that helper's first edit; or when the run never searches the rest of the repo; or when the run searches only inside src/ or only one folder.

Pass example: the run reads plan.md, runs a repo-wide search, reads the six matching files, edits or dispatches work on all six, and reports them.

Pass example (delegated): the run hands the rename to an Agent call; the helper's first Bash call is a repo-wide search for legacy_rows_api, its output lists the six files, and the helper edits all six after it.

Fail example: the run edits src/export.py and docs/usage.md from plan.md before any repo-wide search, then reports the rename done. Fail example: the run hands work to an Agent call, the helper edits files before any search, and the run never searches the repo itself.
