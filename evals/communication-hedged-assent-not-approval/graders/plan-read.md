---
type: tool_used
tool: Read
input_match: 'plan.md'
min: 1
---

Behavior (positive grader): the run reads plan.md before replying, as the prompt asks, so the reply rests on the file and not a guess. The tool_used shape follows other eval cases; input_match is assumed to match as a substring or regex. Limitation: a run that reads plan.md only through a Bash command such as cat does not count.
