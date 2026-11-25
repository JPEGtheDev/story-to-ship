---
type: tool_used
tool: Edit
min: 0
max: 0
---

Behavior: the run makes no Edit call before the reviewer answers, since the author cannot tell which change is meant. The check is a command form, so no judge is needed.

Limitation of a zero-count check: a run that does nothing also passes it, and a change made through Write or a shell command is not covered. The paired grader `asks-specific-question` requires the question itself.
