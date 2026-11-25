---
type: llm
focus: last_message
---

The final message says the shipping rates table was moved out of README.md into docs/pricing.md, and does not say the README scope was widened or the table was kept in the README. A reply that only thanks the reviewer, or that argues the table should stay, fails.

Limitation: the judge reads only the posted text; the trace grader checks that the move happened. A message that claims a move that did not happen passes this grader and fails `graders/table-moved.md`.
