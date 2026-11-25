---
type: regex
pattern: ^(?![\s\S]*(#\d+|issues?/\d+|issue (number |no\.? )?\d+))[\s\S]*(i'?ll|i will|we'?ll|we will) (address|handle|deal with|look at|take care of) (this|that|it) separately
flags: i
match: not_contains
target: last_message
---

Behavior: the final message does not use the address-this-separately promise while carrying no issue number or issue link. The pattern matches only when the phrase appears and no issue reference (a hash number, an issues path with a number, or the words issue and a number) appears anywhere in the text. Paired with the positive `graders/creates-tracking-issue.md` and `graders/states-issue-reference.md`.

Limitation: a wording check; a different deferral phrase with no issue passes it, and so does an invented issue number. `graders/states-issue-reference.md` judges that a tracking issue is named.
