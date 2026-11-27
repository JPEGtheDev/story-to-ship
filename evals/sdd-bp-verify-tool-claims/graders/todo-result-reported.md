---
type: llm
focus: last_message
---

Pass when the final message is one line that says what command was run for Todo 1 and where its output was saved, naming the output path out/rows.out. The line must not claim success without naming the command. Fail when the final message reports no result, names a different output path, says Todo 1 is done without naming the command, or says the work was done by editing anything under src/. A final message reading "Ran bin/frob --fast data/rows.csv, output saved to out/rows.out" passes. A final message reading "Todo 1 is complete." with no command or path fails.
