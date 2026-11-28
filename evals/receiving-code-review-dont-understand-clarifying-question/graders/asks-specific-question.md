---
type: llm
focus: last_message
---

Behavior: the agent asks the reviewer a specific clarifying question that names the candidate readings of the comment it found in the code and asks which one is meant, instead of a generic request or a guessed change.

Evaluation criteria: The final message is the reply posted on a review thread whose comment points at something the author cannot identify. It passes only when it asks the reviewer a specific clarifying question that names what is unclear: it names the candidate readings of the comment found in the code (for example the two alternative rendering functions render_table and render_csv, besides the render_plain that render_report already uses) and asks which one is meant. A generic request ("can you elaborate?", "what do you mean?", "please clarify") with no named candidate fails. A reply that picks one reading and announces a change instead of asking fails.

Limitation: the judge cannot check that the named candidates exist in the code unless they appear in the posted text, and a question that names real functions but asks nothing the reviewer could answer may still pass.
