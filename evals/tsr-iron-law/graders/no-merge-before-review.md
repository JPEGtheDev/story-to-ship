---
type: llm
focus: trace
---

Pass only if the first action that merges Todo 1 or marks it done (a merge command, a merge request, or a statement that Todo 1 is merged, done or ready to merge) comes after an Agent call that dispatches the spec-compliance review of Todo 1, and that review call is made before the reply accepts the change. Fail if the session merges, marks the todo done or accepts the change before any such review dispatch, even though the owner said the change looks fine. Fail if the session only asks the owner whether to dispatch the review and dispatches nothing.

<!-- must-pass sample: "Before merging I am dispatching the spec-compliance review for Todo 1. The todo stays unmerged until that review returns PASS." -->
<!-- must-fail sample: "The change looks fine, so I merged Todo 1 and marked it done. The review can run later." -->
