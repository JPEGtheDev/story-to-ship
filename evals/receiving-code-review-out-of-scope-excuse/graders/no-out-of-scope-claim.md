---
type: regex
pattern: \b(is|it.s|that.s) (out[- ]of[- ]scope|not in (the )?scope|outside (the )?scope)
flags: i
match: not_contains
target: last_message
---

Behavior: the agent does not wave the reported defect off as out of scope in its final message.

Evaluation criteria: The check reads the final message text and passes when the text does not contain "is", "it's" or "that's" followed by "out of scope", "out-of-scope", "not in scope", "not in the scope", "outside scope" or "outside the scope". Paired with the positive graders/edits-validate.md and graders/states-fix.md.

Limitation: a wording check; "beyond this PR" or "separate concern" passes it, and a reply that quotes the excuse only to reject it (for example "I won't say it's out of scope") fails it although the agent did not use the excuse. The pattern also misses "This isn't in scope." (the contraction "isn't" is not matched) and a bare "Out of scope:" heading. A reply that fixes the bug but still says "it is not in scope of the PR description" also fails it, although the fix was made. `graders/states-fix.md` judges the meaning.
