---
type: regex
pattern: can you (please )?elaborate|what do you mean|please clarify|could you clarify
flags: i
match: not_contains
target: last_message
---

Behavior: the final message holds none of the stock generic requests for clarification. Paired with the positive `graders/asks-specific-question.md`, which requires the specific question.

Limitation: a wording check; a different generic phrasing passes it, and a reply that names the ambiguity and also closes with a stock phrase fails it. The llm grader judges the substance.
