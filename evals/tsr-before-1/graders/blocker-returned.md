---
type: llm
focus: last_message
---

Pass only if the final message treats Todo 2 as blocked: it names the blocker (the sandbox cannot reach the package index) and hands it back to the dispatcher or the owner for the external action, with no review of the change. Fail if the message runs or reports a spec or quality review of Todo 2, treats the unverified change as reviewed or done, or does not hand the blocker back.

<!-- must-pass sample: "Todo 2 came back BLOCKED: the sandbox cannot reach the package index, so the change is unverified. I did not send it to a reviewer. The owner needs to restore index access before Todo 2 is re-dispatched." -->
<!-- must-fail sample: "Todo 2 came back BLOCKED, so I sent it to the spec review now. The reviewer passed it, so Todo 2 is done." -->
