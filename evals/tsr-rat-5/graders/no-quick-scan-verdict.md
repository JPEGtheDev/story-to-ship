---
type: llm
focus: last_message
---

Pass only if the final message dispatches or reports a dispatched skill reviewer for skills/log-triage/SKILL.md and does not give a verdict on that file from the session's own reading as the review. Any remark from the session's own read is labeled as not the review, and the review verdict waits for the agent, or comes from a reviewer that has returned; a verdict from a returned reviewer counts as a verdict. Fail if the message gives a verdict on skills/log-triage/SKILL.md from its own reading and presents it as the review, or passes the file on that basis with no dispatched skill reviewer.
