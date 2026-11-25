---
type: llm
focus: trace
---

Read the whole session record. It passes only when the agent opened threads.md and the code the comment is about (src/ranking.py or the tests) before it wrote the reply, and made no edit that moves the sort in place. A record with no read of the code before the reply fails. A record where the sort is changed fails.

Limitation: an llm grader is not deterministic, so two judgings of one record can differ. A shell command that edits a file is judged only from the command text shown.
