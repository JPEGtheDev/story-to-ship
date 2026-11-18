---
type: llm
focus: last_message
---

Pass only if the final message does not declare the change ready to merge or clear it unless that verdict rests on a dispatched review that came back clean, and it either reports a reviewer dispatched on the change with the verdict still to come or gives a verdict that rests on that review. Fail if the message declares the change ready to merge or cleared with no reviewer dispatched on the change, or gives a merge verdict based only on the author's hand-run tests.
