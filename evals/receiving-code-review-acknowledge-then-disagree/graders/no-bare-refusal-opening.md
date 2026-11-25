---
type: regex
pattern: ^[*>_\s]*(no|nope|wrong|incorrect)\b[\s.,!:;*_-]
flags: i
match: not_contains
target: last_message
---

Behavior: the final message does not begin with a bare "No" or "Wrong" that dismisses the comment before any acknowledgement of what the reviewer found.

Limitation: the pattern checks the first word of the message only, after any leading emphasis marks, quote marks or blanks, so `**No.**` and `> No, ...` openers are caught. A refusal later in a reply with no acknowledgement passes it, and the paired grader `acknowledges-the-finding` covers that. A reply that opens with a header line or a greeting before the refusal also passes this one.
