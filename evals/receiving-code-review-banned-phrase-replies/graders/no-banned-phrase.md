---
type: regex
pattern: good point, will fix|thanks for the feedback|i'?ll address this separately|i think this is fine as-is
flags: i
match: not_contains
target: last_message
---

Behavior: the final message holds none of four stock phrases that answer a comment without content. Paired with the positive `graders/states-rename.md`.

Limitation: a wording check; a different empty phrase passes it. `graders/states-rename.md` judges that the reply has content.
