---
type: tool_used
tool: Edit
min: 1
---

Behavior: the agent changes the code, since the reviewer's question points at a missing check that the repository's own test shows as failing.

Evaluation criteria: The check counts calls of the Edit tool in the run and needs at least one. Any Edit counts; the grader reads the tool name alone.

Limitation: the Edit may touch the wrong file or add something unrelated. The grader does not read the content, and a fix made with Write or a shell redirect fails it although the code changed.
