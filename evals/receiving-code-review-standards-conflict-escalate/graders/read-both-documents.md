---
type: llm
focus: trace
---

Read the whole session record. It passes only when the agent opened both docs/STYLE.md and docs/CONTRIBUTING.md (or searched them in a way that shows both texts) before it wrote the reply. A record where only one of the two was read fails.

Limitation: an llm grader is not deterministic, so two judgings of one record can differ. A document shown only as a search hit may be judged as read or not read.
