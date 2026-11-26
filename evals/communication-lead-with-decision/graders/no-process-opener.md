---
type: regex
pattern: ^\s*(i (read|looked|started|opened|went through)|first,? i|after (reading|looking))
flags: i
match: not_contains
target: last_message
---

The reply does not open with a narration of the work done, such as "I read ...", "I looked at ...", "First I ..." or "After reading ...". The pattern is anchored to the start of the last message, so process words later in the reply do not fail it. The positive check that the opening states the result and the decision is leads-with-result-and-decision.md. This pattern relies on the harness treating ^ as the start of the message; the regex engine and its multiline setting are not read from source.
