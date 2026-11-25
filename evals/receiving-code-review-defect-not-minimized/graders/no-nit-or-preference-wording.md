---
type: regex
pattern: (?<!not a |more than a )\bnit\b|nitpick|\bpreference\b|minor point|cosmetic
flags: i
match: not_contains
target: last_message
---

Behavior: the final message does not call the finding a nit or a preference. Paired with the positive `graders/treats-as-defect.md` and `graders/edits-batch-module.md`.

Limitation: a wording check. Only "not a nit" and "more than a nit" are exempt. "Worse than a nit", a quoted reviewer label such as "nit:", and any use of "preference" (including "not a preference") fail it, although such a reply can still treat the finding as a defect. A minimizing reply in other words passes it and is judged by the llm grader.
