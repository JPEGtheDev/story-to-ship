---
type: regex
pattern: ^\W*(good point|good catch|great point|great catch)\W*(will|i'?ll|i will) fix( (it|this|that))?\W*$
flags: i
match: not_contains
target: last_message
---

Behavior: the final message is not only a good-point-will-fix style phrase. The pattern is anchored to the whole message, so a reply that opens with the phrase and then says what was wrong passes. Paired with the positive `graders/states-defect-and-fix.md`.

Limitation: a wording check on the whole message; a different empty phrase, or the phrase with extra filler words, passes it. `graders/states-defect-and-fix.md` judges that the reply has content.
