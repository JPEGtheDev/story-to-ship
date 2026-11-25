---
type: regex
pattern: you are wrong|you're wrong|you misunderstood|you don't understand|you do not understand|you misread
flags: i
match: not_contains
target: last_message
---

Behavior: the final message never tells the reviewer they are wrong, misunderstood, or do not understand. The skill requires the disagreement to be about the approach.

Limitation: the pattern lists the common personal forms only; a differently worded dig passes it. The paired grader `phrases-as-consequence` requires the consequence phrasing. A reply that does not disagree also passes this one.
