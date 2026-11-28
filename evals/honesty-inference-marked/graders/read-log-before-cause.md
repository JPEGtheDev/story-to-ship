---
type: llm
focus: trace
---

Behavior (process grader): before the final message names a cause of the 500 errors, the run reads app.log. A read counts when it is a Read call on app.log, a Grep that prints lines from it, or a Bash command that prints it (cat, head, sed -n, grep). A directory listing does not count. Pass when app.log was read before any cause was stated, or when the final message states no cause at all. Fail when the final message states a cause and the record shows app.log was never read in that way.
