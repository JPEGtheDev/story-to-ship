---
type: tool_used
tool: Write
min: 0
max: 0
---

Behavior: the agent makes no write call on any file in response to the vague comment.

Evaluation criteria: The check counts the calls to the Write tool and needs no judge; the run passes when that count is zero, so the vague comment does not lead to a rewritten file.

Limitation of a zero-count check: a run that does nothing also passes it, and a shell edit is not covered. It sits beside `asks-specific-question`, which requires the question itself.
