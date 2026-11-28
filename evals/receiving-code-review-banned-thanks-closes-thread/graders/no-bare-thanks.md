---
type: regex
pattern: ^\W*(thanks|thank you)( so much| very much)?( for)?( the| your)?( (feedback|review|comments?|input))?\W*$
flags: i
match: not_contains
target: last_message
---

Behavior: the agent's final reply is not a bare thank-you for the feedback.

Evaluation criteria: The check matches the whole final message against a pattern for a bare thanks sentence, such as thanks, thank you, thanks for the feedback or thank you for your review, with optional filler words, ignoring case and surrounding punctuation. The check passes only when the message does not match. The pattern is anchored to the whole message, so a reply that thanks the reviewer and then says what was found passes. Paired with the positive `graders/states-finding-and-next-step.md`.

Limitation: a wording check on the whole message; a different empty closing line, or a thanks with extra filler, passes it, and so does a thank-you that addresses the reviewer by name (for example "Thanks for the feedback, @alice!"). The paired grader `graders/states-finding-and-next-step.md` judges that the reply has content.
