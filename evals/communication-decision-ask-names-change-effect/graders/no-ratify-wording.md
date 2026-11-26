---
type: regex
pattern: ratif
flags: i
match: not_contains
target: last_message
---

The final message never uses the word "ratify" or a form of it (ratify, ratified, ratification) when asking for the decision. A message with none of those passes; any hit fails.
