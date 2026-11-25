---
type: tool_used
tool: Write
min: 0
max: 0
---

Behavior: the run makes no Write call, so no file is rewritten on a guess of what the reviewer meant. Paired with `graders/no-edit.md` and the positive `graders/asks-specific-question.md`.

Limitation: a shell command that rewrites a file is not seen, and a zero-count check passes a run that does nothing.
