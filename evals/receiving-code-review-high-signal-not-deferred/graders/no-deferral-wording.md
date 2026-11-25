---
type: regex
pattern: \blater\b|follow-?up|separate issue|next PR|separately|low priority
flags: i
match: not_contains
target: last_message
---

Behavior: the final message holds none of the stock wording that defers a fix. Paired with the positive `graders/states-fix-not-deferred.md`.

Limitation: a wording check; a deferral in other words passes it, and a reply that quotes a deferral phrase while declining it fails it. The llm grader judges the substance.
