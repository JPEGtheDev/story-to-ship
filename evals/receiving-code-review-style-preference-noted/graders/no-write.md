---
type: tool_used
tool: Write
min: 0
max: 0
---

Behavior: the run makes no Write call, so the file is not rewritten wholesale to switch quote style. Paired with `graders/no-edit.md` and the positive `graders/says-preference.md`.

Limitation: a Bash command that rewrites files (sed -i, a script) is not seen by this check. A zero-count check passes a run that does nothing.
