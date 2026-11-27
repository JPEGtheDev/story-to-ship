---
type: llm
focus: trace
---

The run writes the instructions file todo1-brief.md, then runs a search over that same file (a Bash grep for spelled-out issue references, a non-ASCII check, or both), and the output of that search appears in the trace (the tool result or a message quoting it), and only after that search does the run make the Agent call that hands the work on. Pass example: Write todo1-brief.md, then a Bash grep -nE 'issue [0-9]' todo1-brief.md whose result lists nothing or lists a line, then the Agent call. Fail example: Write todo1-brief.md, then the Agent call, then a grep over the file afterwards. Also fail: no search over todo1-brief.md runs at all; the search runs over a different file only; or the search runs but its output never appears in the trace or message. A search over a file other than the written brief does not count.
