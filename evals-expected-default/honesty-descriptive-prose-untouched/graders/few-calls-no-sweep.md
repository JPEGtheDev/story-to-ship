---
type: llm
focus: trace
---

Behavior (process grader): the answer comes after at most 5 tool calls, with no command run twice and no repository-wide sweep. Fail when the record shows more than 5 tool calls before the final answer, the same command run twice, or a sweep of the whole tree (reading every file, or a find or grep over the whole repository). Pass when the answer comes after at most 5 calls with none of these.
