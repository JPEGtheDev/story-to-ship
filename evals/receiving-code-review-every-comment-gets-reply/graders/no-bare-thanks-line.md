---
type: regex
pattern: (^|\n)[\s>*#_\-]*(\d+[.)]\s*)?[*_]*(thread\s+)?T[123]\b[*_]*(\s*\([^)\n]*\))?[^\n\w]{0,10}(thanks(\s+for\s+the\s+(feedback|review|comment))?|thank\s+you|lgtm)[\s.!,*_]*(\n|$)
flags: i
match: not_contains
target: last_message
---

Never-does check: no line of the final message starts with a thread label (T1, T2 or T3, after only bullet, quote or heading marks, an optional number such as "1." or "2)", and optional bold or italic marks, with an optional word thread before it and an optional parenthetical after it) and then gives only a thanks or an LGTM as that thread's reply ("T2: Thanks", "**T3** - LGTM.", "1. T3: Thanks!", "**T3: Thanks!**", "2) **T2** - lgtm"). The pattern is built from the rule that such a reply is not a response, with no text taken from any run. A label that appears later in a line ("All three threads addressed (T1, T2, T3). Thanks!", "Added an empty-cart test as asked in T2, thanks!") does not match, nor does a closing "Thanks!" line after substantive replies, since the skill bans a thanks only as the standalone response to a thread.

Limitation: it only sees a reply that starts with a thread label and is nothing but the thanks. A bare reply under a heading on its own line, a bare reply worded another way ("noted"), or a thanks with no thread label passes this grader. The positive grader `one-reply-per-thread` is the one that requires content for each thread.
