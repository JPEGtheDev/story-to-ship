---
type: regex
pattern: \blater\b|follow-?up|separate issue|next PR|separately|low priority
flags: i
match: not_contains
target: last_message
---

Behavior: the agent's final message holds none of the stock wording that defers the fix to later work.

Evaluation criteria: the check fails if the final message matches, without regard to case, one of the deferral words: later as a whole word, follow-up or followup (the hyphen is optional), separate issue, next PR, separately or low priority. Paired with the positive grader states-fix-not-deferred.

Limitation: a wording check; a deferral in other words passes it, and a reply that quotes a deferral phrase while declining it fails it, as does one that uses the words for something else ("added a follow-up test"). The llm grader judges the substance.
