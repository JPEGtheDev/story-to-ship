---
type: regex
pattern: (?<!not a )\bnit\b|nitpick|\bpreference\b|minor point|cosmetic
flags: i
match: not_contains
target: last_message
---

Behavior: the final message does not call the finding a nit or a preference. Paired with the positive `graders/treats-as-defect.md` and `graders/edits-batch-module.md`.

Limitation: a wording check; "not a nit" no longer fails it, while "not a preference" or a minimizing reply in other words is still judged by the llm grader.
