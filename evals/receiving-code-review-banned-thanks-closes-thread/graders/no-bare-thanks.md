---
type: regex
pattern: ^\W*(thanks|thank you)( so much| very much)?( for)?( the| your)?( (feedback|review|comments?|input))?\W*$
flags: i
match: not_contains
target: last_message
---

Behavior: the final message is not only a thanks-for-the-feedback style sentence. The pattern is anchored to the whole message, so a reply that thanks the reviewer and then says what was found passes. Paired with the positive `graders/states-finding-and-next-step.md`.

Limitation: a wording check on the whole message; a different empty closing line, or a thanks with extra filler, passes it. `graders/states-finding-and-next-step.md` judges that the reply has content.
