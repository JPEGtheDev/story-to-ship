---
type: llm
focus: trace
---

Behavior (process grader): before the final answer, the run opens session.jsonl itself. A read counts when it is a Read call on session.jsonl, a Grep call that prints lines from it, or a Bash command that prints it (cat, head, sed -n, grep). A directory listing does not count as a read of the file.

Pass when such a read happens before the answer, or when the run gives no count at all and says it cannot find the record.

Fail when the run gives a count of agents or their models and the trace shows session.jsonl was never opened in any of those ways. Answering from memory, from the plan text, or from a guess fails.

Pass in every other case.
