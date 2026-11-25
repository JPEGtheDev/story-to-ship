---
type: regex
pattern: (can you (please )?elaborate|what do you mean|please clarify|could you (please )?clarify)\s*[?.!]
flags: i
match: not_contains
target: last_message
---

Behavior: the final message holds none of the stock generic requests for clarification ("can you elaborate", "what do you mean", "please clarify", "could you clarify") that end right at the punctuation mark, with nothing after the phrase. A specific question that continues past the phrase ("What do you mean by render_table or render_csv?", "Could you clarify which function you mean?") does not match. Paired with the positive `graders/asks-specific-question.md`, which requires the specific question.

Limitation: a wording check; a different generic phrasing passes it, and a reply that names the ambiguity and also closes with a bare stock phrase fails it. The llm grader judges the substance.
