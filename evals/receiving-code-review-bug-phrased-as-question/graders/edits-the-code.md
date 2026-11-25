---
type: tool_used
tool: Edit
min: 1
---

Behavior: the run makes at least one Edit call, since the question points at a missing check and the repository's own test shows the failure. Any Edit counts; the grader reads the tool name alone.

Limitation: the Edit may touch the wrong file or add something unrelated. The grader does not read the content, and a fix made with Write or a shell redirect fails it although the code changed.
