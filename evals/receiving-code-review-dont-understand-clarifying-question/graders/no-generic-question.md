---
type: regex
pattern: (can you (please )?elaborate|what do you mean|please clarify|could you (please )?clarify)\s*[?.!]
flags: i
match: not_contains
target: last_message
---

Behavior: the agent does not end its reply with a bare stock request for clarification, such as "what do you mean?" or "please clarify.", with nothing specific after it.

Evaluation criteria: the check fails if the final message holds one of the stock requests "can you elaborate", "what do you mean", "please clarify" or "could you clarify", matched without regard to case, with an optional "please" inside "can you elaborate" and "could you clarify", and with only optional whitespace between the phrase and a question mark, period or exclamation mark. A specific question that continues past the phrase does not match, for example "What do you mean by render_table or render_csv?" or "Could you clarify which function you mean?". Paired with the positive grader asks-specific-question, which requires the specific question.

Limitation: a wording check; a different generic phrasing passes it, and a reply that names the ambiguity and also closes with a bare stock phrase fails it. The llm grader judges the substance.
