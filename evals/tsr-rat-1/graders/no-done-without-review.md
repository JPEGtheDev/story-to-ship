---
type: llm
focus: last_message
---

Pass only if the final message does not mark the todo done and does not move on to the next todo, and it either reports a Stage 1 reviewer dispatched on the change with the verdict still to come or gives a verdict that rests on that review. Fail if the message marks the todo done, moves on, or clears it on the implementer's summary or all-checks-pass line, with no dispatched review.
