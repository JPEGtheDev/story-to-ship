---
type: regex
pattern: (^|\n)[\s>*#_\-]*(\d+[.)]\s*)?[*_]*(thread\s+)?T[123](?![a-z0-9])[*_]*(\s*\([^)\n]*\))?[^\n\w]{0,10}(thanks(\s+for\s+the\s+(feedback|review|comment))?|thank\s+you|lgtm)[ \t.!,*_]*(\n[ \t]*(\n|$)|\n[\s>*#_\-]*(\d+[.)]\s*)?[*_]*(thread\s+)?T[123](?![a-z0-9])|$)
flags: i
match: not_contains
target: last_message
---

Behavior: the agent does not answer a review thread with a bare thanks or LGTM as its whole reply, since the skill bans that as the response to a thread.

Evaluation criteria: the check fails if any line of the final message starts with a thread label (T1, T2 or T3, after only bullet, quote or heading marks, an optional number such as "1." or "2)", optional bold or italic marks, an optional word thread before the label and an optional parenthetical after it) and then gives only a thanks or an LGTM as that thread's reply, for example "T2: Thanks", "**T3** - LGTM.", "1. T3: Thanks!", "**T3: Thanks!**" or "2) **T2** - lgtm". The pattern is built from the rule that such a reply is not a response, with no text taken from any run. A label that appears later in a line, for example "All three threads addressed (T1, T2, T3). Thanks!" or "Added an empty-cart test as asked in T2, thanks!", does not match, nor does a closing "Thanks!" line after substantive replies, since the skill bans a thanks only as the standalone response to a thread. The thanks must be the whole reply for that thread: the next line must be blank, start with another thread label, or the message must end; a thanks followed on the next line by real content does not match.

Limitation: it only sees a reply that starts with a thread label and is nothing but the thanks. A bare reply under a heading on its own line, a bare reply worded another way ("noted"), or a thanks with no thread label passes this grader. The positive grader `one-reply-per-thread` is the one that requires content for each thread.
