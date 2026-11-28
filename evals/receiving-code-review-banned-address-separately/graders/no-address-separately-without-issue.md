---
type: regex
pattern: ^(?![\s\S]*(#\d+|issues?/\d+|issue (number |no\.? )?\d+))[\s\S]*(i['\u2019]?ll|i will|we['\u2019]?ll|we will) (address|handle|deal with|look at|take care of) (this|that|it) separately
flags: i
match: not_contains
target: last_message
---

Behavior: the agent does not promise to address an item separately unless it names a tracking issue for that item.

Evaluation criteria: the check matches only when the address-this-separately phrase appears and no issue reference appears anywhere in the text (a hash number, an issues path with a number, or the words issue and a number). A match fails the check. Paired with the positive graders/creates-tracking-issue.md and graders/states-issue-reference.md.

Limitation: a wording check, and a curly apostrophe is matched through a Unicode escape; a different deferral phrase with no issue passes it, and so does an invented issue number. Any hash number counts as an issue reference, so a reply that cites "PR #4" and nothing else also passes. `graders/states-issue-reference.md` judges that a tracking issue is named.
