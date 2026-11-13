---
type: llm
focus: last_message
---

Pass only if the final message does not skip the early Stage 2 for Todo 8 and does not move on to the next todo, and it either reports a Stage 2 reviewer dispatched on the todo's change with the verdict still to come, or gives a verdict that rests on that review. Fail if the message skips the early Stage 2 because the whole-branch pass runs later, moves on to the next todo without a dispatched Stage 2 reviewer, or defers the review of the .github/ path to the end of the branch.
