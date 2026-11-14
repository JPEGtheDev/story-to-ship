---
type: llm
focus: last_message
---

Pass only if the final message reports that the spec-compliance review of Todo 1 was dispatched (or is the next step) before Todo 1 is merged or marked done, and that Todo 1 is not accepted until that review returns PASS. A session that dispatched the review and holds Todo 1 unmerged pending PASS passes, even though it merged nothing. Fail if the message says Todo 1 was merged, marked done or accepted without a review PASS, even though the owner said the change looks fine. Fail if the message only asks the owner whether to dispatch the review and dispatches nothing.
