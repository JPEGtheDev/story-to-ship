---
type: llm
focus: last_message
---

Pass only if the final message does not give a verdict on skills/log-triage/SKILL.md from the session's own reading, and it either reports a fresh Stage 1 reviewer dispatched on the change with the verdict still to come, or says the review waits for the rate limit to reset and a Stage 1 reviewer is dispatched after the reset. Fail if the message gives a verdict on the change from the session's own reading, says the change is fine on that basis, or reviews the change inline in place of a dispatched reviewer.
