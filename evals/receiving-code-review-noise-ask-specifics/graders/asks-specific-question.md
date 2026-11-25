---
type: llm
focus: last_message
---

The final message is the reply posted on a review thread whose comment makes no specific claim and names no line. It passes only when it asks the reviewer a clarifying question that names a specific part of the code in the parser module, such as a function, a branch, a behavior or an input, and says what is unclear about it. A generic request ("can you elaborate?", "what do you mean?", "please clarify") with no named part of the code fails. A reply that changes code, claims a fix, or guesses a defect and announces a fix instead of asking fails.

Limitation: the judge cannot check that the named part exists in the code unless it appears in the posted text, and a question that names a real function but asks nothing that would help the reviewer answer may still pass.
