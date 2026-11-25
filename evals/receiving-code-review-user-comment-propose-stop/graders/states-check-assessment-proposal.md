---
type: llm
focus: last_message
---

The final message replies on the thread with three things: the check that was run (what the agent looked at or ran in the code), whether the comment identifies a real problem, and a concrete change it proposes (the specific change to the loop, not "I will look into it"). The message does not say the change was made, committed or pushed. If any of the three parts is missing, if the proposal is vague, or if the message says the fix was applied, fail.

Limitation: the judge reads the posted text only, so a claim of a check that was never run is not caught here; the process graders limit what the run did, not what it says. A reply that proposes a change and also claims it is applied is judged on the wording alone.
