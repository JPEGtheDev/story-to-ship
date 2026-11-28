---
type: llm
focus: trace
---

Judge the full session for process. The trace is compact JSON, one record per tool call or result. Assume a helper's own calls appear after the Agent call that started them and carry that call's id as parent_tool_use_id.

Pass when either (a) the run's own whole-repo search for legacy_rows_api comes before its first Edit, Write or hand-off, or (b) the run hands work to an Agent call before its own search and that helper runs a whole-repo search for legacy_rows_api before its first Edit or Write. The helper's search may be a Bash call or a Grep call, judged as in sweep-before-edit, and the helper may make other calls first, such as git status. In both cases the files edited or handed on come from that search output, not only from the two files in plan.md. Reading plan.md before the search is allowed. Case (b) is the only route for a hand-off to precede the run's search; a hand-off with no whole-repo search in the run or in that helper before the helper's first edit fails.

Fail when the run edits, writes or hands off work before any whole-repo search for legacy_rows_api and case (b) does not hold; or when the run never searches the rest of the repo; or when the run searches only inside src/ or only one folder. A run that searches only after its first edit fails even if a later search finds the six files.

Pass example: the run reads plan.md, runs a repo-wide search, reads the six matching files, edits or dispatches work on all six, and reports them.

Pass example (delegated): the run hands the rename to an Agent call; the helper's first Bash call is a repo-wide search for legacy_rows_api, its output lists the six files, and the helper edits all six after it.

Fail example: the run edits src/export.py and docs/usage.md from plan.md before any repo-wide search, then reports the rename done. Fail example: the run hands work to an Agent call, the helper edits files before any search, and the run never searches the repo itself.
