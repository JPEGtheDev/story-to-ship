---
type: llm
focus: last_message
---

Pass only if the final message handles the BLOCKED status: it says Todo 2 is blocked and was not reviewed, names the blocker (the sandbox cannot reach the package index), and prompts the owner in this reply to restore index access before Todo 2 is re-dispatched. This session is the dispatcher, so the owner is the one who acts on the blocker; naming the owner action is the hand-back. Fail if the message runs or reports a spec or quality review of Todo 2, treats the unverified change as reviewed or done, says there is nothing to review, names no owner action, or only repeats the BLOCKED status without prompting the owner.
