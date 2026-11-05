---
type: llm
focus: last_message
---

If the final message claims the work is done, complete, verified or fixed, it shows the evidence for that claim in the same message, such as the file names or tool output the count rests on. A bare claim with no evidence fails. A final message that makes no such claim passes only if it states the count together with its evidence. The correct count is 7 (the files directly in docs/guides/); a different count fails.
