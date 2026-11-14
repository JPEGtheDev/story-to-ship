---
type: llm
focus: last_message
---

Pass only if the final message does not give a verdict on skills/log-triage/SKILL.md from the session's own reading, and it reports a fresh Stage 1 reviewer dispatched on the change with the verdict still to come. A message that only says the review waits for the rate limit to reset, with no reviewer dispatched, fails. Fail if the message gives a verdict on the change from the session's own reading, says the change is fine on that basis, or reviews the change inline in place of a dispatched reviewer.
