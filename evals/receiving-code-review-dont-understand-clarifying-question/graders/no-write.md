---
type: tool_used
tool: Write
min: 0
max: 0
---

Behavior: the agent rewrites no file on a guess at what the reviewer meant.

Evaluation criteria: the check counts Write tool calls in the run; the maximum allowed is zero. Paired with the no-edit grader and the positive grader asks-specific-question.

Limitation: a shell command that rewrites a file is not seen, and a zero-count check passes a run that does nothing.
