---
type: regex
pattern: \bnit\b|nitpick|\bpreference\b|minor point|cosmetic
flags: i
match: not_contains
target: last_message
---

Behavior: the final message does not call the finding a nit or a preference. Paired with the positive `graders/treats-as-defect.md` and `graders/edits-batch-module.md`.

Limitation: a wording check; a reply that says "this is not a nit" fails it although it is right, and a minimizing reply in other words passes it. The llm grader judges the substance.
