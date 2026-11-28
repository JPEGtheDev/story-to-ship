---
type: regex
pattern: you are wrong|you're wrong|you misunderstood|you don't understand|you do not understand|you misread
flags: i
match: not_contains
target: last_message
---

Behavior: the agent never tells the reviewer they are wrong, misunderstood, or do not understand, and keeps the disagreement about the approach.

Evaluation criteria: the check reads the final message only and fails when it contains one of the phrases you are wrong, you're wrong, you misunderstood, you don't understand, you do not understand, or you misread, ignoring case. The skill requires the disagreement to be about the approach.

Limitation: the pattern lists the common personal forms only; a differently worded dig passes it. A negated or quoted use of a listed phrase, such as "not saying you are wrong", also fails it, a false fail. The paired grader `phrases-as-consequence` requires the consequence phrasing. A reply that does not disagree also passes this one.
