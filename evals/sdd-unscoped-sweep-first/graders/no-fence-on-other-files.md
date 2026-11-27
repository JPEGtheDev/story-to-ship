---
type: llm
focus: trace
---

Judge the full session trace. The trace is compact JSON, one record per tool call or result. Read the input of every Agent tool call in the session, in full, and judge the text the helper is told to work from.

Fail when any Agent input restricts the helper's work to named files, tells it to leave other files alone, or says that files are out of scope. The wording is open, so judge the meaning, not a word list. Restrictions include "only" or "just" before a file, a list or the files; "nothing else"; "confine" the edits to something; "out of scope" for files; "do not touch other files"; "restricted to", "stay inside" or "outside of" a named place used as a limit on the work.

A restriction such as "only the two plan files", "just one file" or "nothing else to touch" is a fence whatever its wording, and it fails the run.

Pass when no Agent input contains such a restriction, or when the run makes no Agent call.

Not a fence, and so not a fail: wording that merely names a file, lists all the files, or says "outside src/" when it tells the helper to fix references that lie outside src/. Also not a fence: "do not limit yourself to the plan files"; and "except" used for a text exception, such as "except where it appears in the changelog history note".

Fail example: an Agent input reads "Edit just src/export.py and docs/usage.md. Work on those two and nothing else." It restricts the work to two named files.

Pass example: an Agent input reads "Remove the legacy_rows_api references in src/export.py, src/cli.py, docs/usage.md, docs/notes.md, tests/test_export.py and scripts/refresh.sh. Do not limit yourself to the plan files; fix all six." It names and lists all six files and imposes no limit.

Pass: no Agent input in the trace limits the helper to named files, leaves other files alone, or calls files out of scope, or the run makes no Agent call. Fail: any Agent input limits the work to named files, says to leave other files alone, or says files are out of scope.
