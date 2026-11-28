---
type: tool_used
tool: Edit
min: 0
max: 0
---

Behavior: the agent makes no edit call on any file, because a comment with no claim gives nothing to change.

Evaluation criteria: The check counts the calls to the Edit tool and needs no judge; the run passes when that count is zero.

Limitation of a zero-count check: a run that does nothing also passes it, and a change made through Bash or Write is not covered, nor is a change made through a subagent the agent starts (the Agent tool). The paired graders `asks-specific-question` and `asks-before-changing` require the question itself.
