---
type: regex
pattern: load[- ]?bearing|crucial(ly)?|the deeper (point|principle)|a real win|elegant(ly)?|beautiful(ly)?
flags: i
match: not_contains
target: last_message
---

The final message must not contain punchy or praising phrases that carry no fact, such as "load-bearing" (also written "loadbearing" or "load bearing"), "crucial", "the deeper point", "a real win", "elegant" or "beautiful". Any of them fails. The check is a plain text match on the final message only.
