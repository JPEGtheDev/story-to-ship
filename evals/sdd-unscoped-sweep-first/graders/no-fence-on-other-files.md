---
type: llm
focus: trace
---

Judge the full session trace. The trace is compact JSON, one record per tool call or result. Assume each Agent call's prompt text is in the input field of its record; read every Agent call in the session in full and judge the text the helper is told to work from.

Fail when any Agent input restricts the helper's work to named files, tells it to leave other files alone, or says that files are out of scope. The wording is open, so judge the meaning, not a word list. Restrictions include "only" or "just" before a file, a list or the files; "nothing else"; "confine" the edits to something; "out of scope" for files; "do not touch other files"; "restricted to", "stay inside" or "outside of" a named place used as a limit on the work.

A restriction such as "only the two plan files", "just one file" or "nothing else to touch" is a fence whatever its wording, and it fails the run.

Not a fence, and so not a fail: wording that merely names a file, lists all the files, or says "outside src/" when it tells the helper to fix references that lie outside src/. Also not a fence: "do not limit yourself to the plan files"; "except" used for a text exception, such as "except where it appears in the changelog history note"; and a limit to the files that the repo-wide search output lists, in any wording (for example "only the files the search lists", or "do not touch files the search does not list"), because that output is the wanted scope. Such a limit is not a fence and is not a fail, even where it uses "only", "other files" or "leave alone".

Pass: no Agent input in the trace limits the helper to named files other than the search output, and no Agent input says to leave other files alone or calls files out of scope except where "other" or "out of scope" is defined by the search output, or the run makes no Agent call. Fail: any Agent input limits the work to named files other than the search output, or says to leave other files alone or that files are out of scope, with "other" or "out of scope" not tied to the search output.

Pass example: an Agent input reads "Remove the legacy_rows_api references in src/export.py, src/cli.py, docs/usage.md, docs/notes.md, tests/test_export.py and scripts/refresh.sh. Do not limit yourself to the plan files; fix all six." It names and lists all six files and imposes no limit.

Fail example: an Agent input reads "Edit just src/export.py and docs/usage.md. Work on those two and nothing else." It restricts the work to two named files.
