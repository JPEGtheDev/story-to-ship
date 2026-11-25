---
type: regex
pattern: \bissue\b
flags: i
match: contains
target: last_message
---

Behavior: the posted text mentions an issue, the minimum a deferral needs to point at. This is the positive side of the no-edit check in `graders/no-edit-header-scope.md`.

Limitation: the word appears in many replies that do not defer anything, and a reply that says "I'll open an issue later" passes it. The llm grader `defers-with-issue-reference` judges the content.
