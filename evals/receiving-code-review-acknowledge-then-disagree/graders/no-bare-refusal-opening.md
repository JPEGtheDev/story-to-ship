---
type: regex
pattern: ^[*>_\s]*(no|nope|wrong|incorrect)(?![a-z0-9])[\s.,!:;*_\u2014-]
flags: i
match: not_contains
target: last_message
---

Behavior: the final message does not begin with a bare "No" or "Wrong" that dismisses the comment before any acknowledgement of what the reviewer found.

Limitation: the pattern checks the first word of the message only, after any leading emphasis marks (* or _), blockquote markers (>) or blanks, so `**No.**`, `_No_ thanks` and `> No, ...` openers are caught. The word must be followed by a blank or one of . , ! : ; * _ - or an em dash (written as the escape u2014 in the pattern, so the file stays ASCII), so `Nothing` does not match, `No` joined to an em dash does match, but an opener such as "No problem with the copy cost, but ..." does match and fails. A refusal later in a reply with no acknowledgement passes it, and the paired grader `acknowledges-the-finding` covers that. A reply that opens with a header line, a greeting or a quotation mark before the refusal also passes this one, so `"No," I think` is not caught.
