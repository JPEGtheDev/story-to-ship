---
type: regex
pattern: \?
match: contains
target: last_message
---

Behavior: the posted text contains a question mark, so it asks something. This is the positive side of the no-edit checks in `graders/no-edit.md` and `graders/no-write.md`.

Limitation: any question mark passes, including a generic "can you elaborate?". The llm grader `asks-specific-question` judges whether the question is specific.
