---
type: llm
focus: last_message
---

Behavior: the agent answers the vague comment by asking the reviewer for specifics, such as which line, behavior or input looks wrong, and does not change code.

Evaluation criteria: The final message is the reply posted on a review thread whose comment makes no specific claim and names no line. It passes only when it asks the reviewer for specifics, such as which line, which behavior or which input looks wrong, so that a claim can be stated. A question that also names a part of the code passes, and a question that names none passes too. A reply that changes code, claims a fix, guesses a defect and announces a fix instead of asking, or only says the comment is unclear without asking anything fails. A generic request with no specific, such as "can you elaborate?" or "what do you mean?", fails; the question must ask for a line, a behavior or an input.

Limitation: the judge reads the posted text only, so a question that asks for specifics in a way the reviewer could not answer may still pass.
