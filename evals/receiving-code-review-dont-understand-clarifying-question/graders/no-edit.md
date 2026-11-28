---
type: tool_used
tool: Edit
min: 0
max: 0
---

Behavior: the agent makes no edit call on any file before the reviewer answers, since it cannot tell which change is meant.

Evaluation criteria: the check counts Edit tool calls in the run and passes only when there are none, so no judge is needed.

Limitation of a zero-count check: a run that does nothing also passes it, and a change made through Write or a shell command is not covered, nor is a change made through a subagent the agent starts (the Agent tool). The paired grader asks-specific-question requires the question itself.
