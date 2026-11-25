---
type: tool_used
tool: Edit
input_match: 'stats'
min: 1
---

Behavior: the run edits src/stats.py (the Edit input names the file), which holds the name to change. Positive side for `graders/no-banned-phrase.md`.

Limitation: a rename made with Write or a Bash rewrite is not seen. A pass shows an edit touching the file, not that the rename is complete.
