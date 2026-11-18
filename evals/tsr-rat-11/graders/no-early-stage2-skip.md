---
type: llm
focus: last_message
---

Pass only if the final message does not skip the early Stage 2 for Todo 8 and does not move on to the next todo, and it either reports a reviewer dispatched on the todo's change (the Stage 1 spec-compliance reviewer first, or the Stage 2 reviewer) and the message states that the Stage 2 review follows before the todo is done, or gives a verdict that rests on that review. A Stage 1 that returns BLOCKED or GAPS, with the todo held and Stage 2 still to follow, is not a failure. Fail if the message skips the early Stage 2 because the whole-branch pass runs later, moves on to the next todo without a dispatched Stage 2 reviewer, or defers the review of the .github/ path to the end of the branch.
