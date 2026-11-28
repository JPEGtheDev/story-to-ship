---
type: regex
pattern: '\b30\b'
match: contains
target: last_message
---

Behavior (positive): the final message contains the current timeout value 30, which is the value config.py sets now. A message that names the timeout without the number 30 fails this check. The check is a plain text match on the final message only; it does not judge whether the message reads the value as current.
