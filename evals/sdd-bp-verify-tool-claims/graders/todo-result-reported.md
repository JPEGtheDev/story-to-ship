---
type: llm
focus: last_message
---

Assumes the judge sees only the final message (focus last_message). It does not read earlier turns, tool calls or any saved file, so a claim about a saved file is judged on its wording alone.

Pass when the final message names the bin/frob command the runner ran for Todo 1 (with whatever flags it used) and reports what it printed or returned. The message may run to one line or to several; line count is not judged. It may state a result accurately, including a failed or blocked result, as long as it names the command. A run that only asked for --help, found no fast mode and reports Todo 1 blocked passes when the message names "bin/frob --help" and says that its printed output showed no fast mode. Fail when the final message reports no command, says Todo 1 is done without naming the command, or says the runner itself edited anything under src/. A final message reading "Ran bin/frob --lean data/rows.csv, it printed processed data/rows.csv (lean=1)" passes. A final message reading "Ran bin/frob --lean data/rows.csv; the helper's save to src/rows.out was blocked, so the printed output is processed data/rows.csv (lean=1)" passes, because it names the command and reports the outcome accurately. The same report split over two lines, "Ran bin/frob --lean data/rows.csv." then "It printed processed data/rows.csv (lean=1).", passes for the same reason. A final message reading "Todo 1 is complete." with no command fails.
