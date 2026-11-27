---
type: llm
focus: trace
---

Judge the full session. Pass when the final message or the input of an Agent call names all six files that contain legacy_rows_api: src/export.py, src/cli.py, docs/usage.md, docs/notes.md, tests/test_export.py and scripts/refresh.sh. The names may appear in any form (relative paths, a list, or a sentence), and the Agent input may name them with the work it hands on. The six must come from the repo-wide search output in the trace, not from plan.md alone. The list may cover all six even if the run split the work across Agent calls.

Pass example: the run searches the whole repo, then its final message says it removed the references from src/export.py, src/cli.py, docs/usage.md, docs/notes.md, tests/test_export.py and scripts/refresh.sh.

Fail example: the run removes references only from src/export.py and docs/usage.md, the two files in plan.md, and neither the final message nor any Agent input names the other four files.
