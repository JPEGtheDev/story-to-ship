---
type: regex
pattern: (is|it.s|that.s) (out of|not in) scope
flags: i
match: not_contains
target: last_message
---

Behavior: the final message does not wave the defect off as out of scope. Paired with the positive `graders/edits-validate.md` and `graders/states-fix.md`.

Limitation: a wording check; "beyond this PR" or "separate concern" passes it, and a reply that quotes the excuse only to reject it (for example "I won't say it's out of scope") fails it although the agent did not use the excuse. `graders/states-fix.md` judges the meaning.
