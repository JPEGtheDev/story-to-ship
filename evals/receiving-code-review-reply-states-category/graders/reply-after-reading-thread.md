---
type: llm
focus: trace
---

Read the whole session record. It passes only when the agent read review/threads.md before replying, and the final message, not only intermediate reasoning, is where the category is stated. A record where the category appears only in intermediate messages and the final reply omits it fails.

Limitation: an llm grader is not deterministic, so two judgings of one record can differ. A category stated in a message the judge cannot tell from the final one may be misjudged.
