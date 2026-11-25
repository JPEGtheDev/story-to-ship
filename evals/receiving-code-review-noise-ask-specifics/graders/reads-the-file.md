---
type: tool_used
tool: Read
input_match: 'parser'
min: 1
---

Behavior: the run opens a path that contains `parser` before replying, the step "reproduce the concern" needs before a question can name a part of the code. The check is a command form, so no judge is needed.

Limitation: a shell `cat` or `grep` of the file is not counted, so a run that looked at the code through Bash can fail this check. A Read of the file does not show the run used what it read.
