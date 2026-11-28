---
type: tool_used
tool: Edit
min: 0
max: 0
---

Behavior: the agent makes no edit call on the code before the reviewer answers, since it cannot tell which change is meant.

Evaluation criteria: the check counts Edit tool calls in the run and passes only when there are none, so no judge is needed.

Limitation of a zero-count check: a run that does nothing also passes it, and a change made through Write or a shell command is not covered. The paired grader `graders/asks-specific-question.md` requires the question itself.
