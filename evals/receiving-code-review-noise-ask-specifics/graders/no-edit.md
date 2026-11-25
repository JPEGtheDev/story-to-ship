---
type: tool_used
tool: Edit
min: 0
max: 0
---

Behavior: the run makes no Edit call. A comment with no claim gives nothing to change, so no code edit is made. The check is a command form, so no judge is needed.

Limitation of a zero-count check: a run that does nothing also passes it, and a change made through Bash or Write is not covered. The paired graders `asks-specific-question` and `asks-before-changing` require the question itself.
