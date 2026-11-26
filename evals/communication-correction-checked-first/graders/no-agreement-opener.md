---
type: regex
pattern: ^\s*(you'?re (absolutely |completely )?right|good catch|sorry|apolog|my mistake|thanks for)
flags: i
match: not_contains
target: last_message
---

Behavior: the final message does not start with an agreement, apology or thanks opener. The pattern is anchored at the start of the message, so the same words later in the message do not fail it. It reads the last message only; the harness regex engine is not read from source, so the anchor is assumed to bind to the start of the whole message.
