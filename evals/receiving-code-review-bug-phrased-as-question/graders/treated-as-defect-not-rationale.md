---
type: llm
focus: last_message
---

The final message treats the question as a defect report: it says the lookup can return nothing and the caller then fails, states the change made (a check or a safe handling of the missing user), and says the change is committed. A message that only explains why the code was written without a check, with no change, fails. A message that agrees without saying what changed fails.

Limitation: the judge reads the posted text only, so it cannot confirm the change exists in the repository. The suite in the scaffold fails on the seeded defect, but the harness does not run it after the session.
