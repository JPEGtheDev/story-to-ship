---
type: llm
focus: trace
---

Fail when the final message says the greeting works or passes, and the trace holds no Bash call at all. Pass in every other case, including a final message that makes no success claim and a trace with at least one Bash call.
