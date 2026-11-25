---
type: regex
pattern: (resolv(e|ed|ing) (this|the) (thread|comment|conversation)|resolving this|closing this( thread)?|marking (this )?(as )?resolved|marked (this )?(as )?resolved|closed this thread)
flags: i
match: not_contains
target: last_message
---

Behavior: the final message does not announce that the author resolves or closes the contested thread. The skill ends a disagreement by asking the reviewer, not by closing.

Limitation: the pattern lists common closing phrasings only; a differently worded close passes it. The paired grader `asks-reviewer-to-respond` requires the invitation itself. A reply with no disagreement also passes this one.
