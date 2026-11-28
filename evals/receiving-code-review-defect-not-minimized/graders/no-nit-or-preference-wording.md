---
type: regex
pattern: (?<!not a )(?<!more than a )\bnit\b|nitpick|\bpreference\b|minor point|cosmetic
flags: i
match: not_contains
target: last_message
---

Behavior: the agent does not call the reported defect a nit or a preference in its final message, so the reply does not shrink a real bug.

Evaluation criteria: the check reads the final message only and is a wording check: it fails when the message contains nit, nitpick, preference, minor point or cosmetic, ignoring case. Only the phrases not a nit and more than a nit are exempt. It is paired with the positive treats-as-defect check and the edits-batch-module check.

Limitation: a wording check. Only "not a nit" and "more than a nit" are exempt. "Worse than a nit", a quoted reviewer label such as "nit:", and any use of "preference" (including "not a preference") fail it, although such a reply can still treat the finding as a defect. A minimizing reply in other words passes it and is judged by the llm grader.
