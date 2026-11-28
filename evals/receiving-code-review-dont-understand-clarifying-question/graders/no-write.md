---
type: tool_used
tool: Write
min: 0
max: 0
---

Behavior: the agent makes no write call before the reviewer answers.

Evaluation criteria: the check counts Write tool calls in the run; the maximum allowed is zero. Paired with the no-edit grader and the positive grader asks-specific-question.

Limitation: a shell command that rewrites a file is not seen, a change made through a subagent the agent starts (the Agent tool) is not seen by this check, and a zero-count check passes a run that does nothing. Any Write call fails the check, so a compliant run that writes a reply draft fails it.
