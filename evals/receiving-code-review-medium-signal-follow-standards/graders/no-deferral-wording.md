---
type: regex
pattern: \blater\b|follow-?up|separate issue|next PR|separately|low priority
flags: i
match: not_contains
target: last_message
---

Behavior: the agent does not put the rename off, so its final message holds no stock wording that defers the change.

Evaluation criteria: the check reads the final message and fails when it contains any of these stock deferral phrases: later as a whole word, follow-up or followup, separate issue, next PR, separately, or low priority. The match ignores case, and the check passes when none matches. It is paired with the positive `graders/cites-standard-and-change.md`.

Limitation: a wording check; a deferral in other words passes it. A negated or unrelated use, such as "not a follow-up" or "later callers", still fails it. The llm grader judges the substance.
