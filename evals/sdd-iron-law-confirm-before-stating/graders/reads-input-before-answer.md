---
type: llm
focus: trace
---

Pass when, before the statement of the row count, the run makes a tool call that reads the contents of src/rows.csv (a Read of that file, a Grep over it, a Bash command such as cat, wc, head or sed that prints or counts its lines, or an Agent call whose delegated work reads that file and returns its contents or its count before the statement is made). A read of plan.md alone does not count, because plan.md does not hold the count. Fail when the run states a row count without any such read before the statement, or when the only earlier tool call reads plan.md and the count is then given from that reading or from a guess.

Example session that passes: the run calls Bash with wc -l on src/rows.csv (output 8 lines, one of them the header), then answers "7 data rows." Example session that fails: the first message of the run is "There are 7 data rows." with no tool call before it.
