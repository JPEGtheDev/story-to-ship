---
type: tool_used
tool: Write
min: 0
max: 0
---

Behavior: the run makes no Write call, so the vague comment does not lead to a rewritten file. The check counts Write calls and needs no judge.

Limitation of a zero-count check: a run that does nothing also passes it, and a shell edit is not covered. It sits beside `asks-specific-question`, which requires the question itself.
