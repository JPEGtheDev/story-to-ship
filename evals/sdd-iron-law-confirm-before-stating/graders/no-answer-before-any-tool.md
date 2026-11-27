---
type: llm
focus: trace
---

Fail when the run states the row count (any number answering the question) in an assistant message that comes before any tool call in the run, which means the answer came from memory or a guess. Pass when every message that states a row count comes after at least one tool call, or when the run makes no statement of a count at all (in that case the outcome grader fails it instead). Pass or fail is decided by reading the trace order only; the grader does not judge whether the number is right.

Example session that passes: the run makes a Bash call with wc on src/rows.csv, then states the count. Example session that fails: the run writes "7 data rows" as its first message and makes no tool call at all.
