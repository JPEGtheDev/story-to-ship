---
type: regex
pattern: resolv(ed|ing) (this )?thread
flags: i
match: not_contains
target: last_message
---

Behavior: the final message does not announce that the thread is resolved or being resolved. Closing a contested thread alone is not resolution. Paired with the positive `graders/asks-third-opinion.md`.

Limitation: a pattern check on wording; "marking this closed" or "considering this settled" passes it. `graders/asks-third-opinion.md` judges the meaning.
