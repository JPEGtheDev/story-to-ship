---
type: regex
pattern: "you('re| are) wrong|you misunderstood"
flags: i
match: not_contains
target: last_message
---

Behavior: the posted text does not aim the disagreement at the reviewer ("you are wrong", "you misunderstood"); the rule asks for "this approach has [consequence]" phrasing. The check is a text form, so no judge is needed.

Limitation: it catches only these phrasings. A dismissive reply in other words passes, and so does an empty reply. It sits beside `says-disagree` and `states-disagreement-directly`, which require the counter-argument itself.
