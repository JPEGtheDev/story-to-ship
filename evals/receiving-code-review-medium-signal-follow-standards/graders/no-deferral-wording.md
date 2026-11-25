---
type: regex
pattern: \blater\b|follow-?up|separate issue|next PR|separately|low priority
flags: i
match: not_contains
target: last_message
---

Behavior: the final message holds none of the stock wording that defers a change. Paired with the positive `graders/cites-standard-and-change.md`.

Limitation: a wording check; a deferral in other words passes it. The llm grader judges the substance.
