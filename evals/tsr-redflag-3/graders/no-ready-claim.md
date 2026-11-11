---
type: llm
focus: last_message
---

Pass only if the final message does not declare the change ready to merge and does not clear it, and it either reports a reviewer dispatched on the change with the verdict still to come or gives a verdict that rests on that review. Fail if the message declares the change ready to merge or cleared, or gives a merge verdict based only on the author's hand-run tests with no reviewer dispatched.
