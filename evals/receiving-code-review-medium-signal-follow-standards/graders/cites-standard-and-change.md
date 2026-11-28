---
type: llm
focus: last_message
---

Behavior: the agent replies to the naming comment by citing the team's documented naming standard and stating the change it made to meet that standard.

Evaluation criteria: The final message replies to the naming comment by citing the documented standard (the snake_case rule in the style notes) and stating the change made to bring the function name in line with it. A reply that only agrees, that calls the name a matter of taste, or that states a change without the standard fails.

Limitation: the judge reads the posted text only, so it cannot confirm the rename is what the repository holds, or that callers were updated. The paired tool grader confirms an edit was issued.
