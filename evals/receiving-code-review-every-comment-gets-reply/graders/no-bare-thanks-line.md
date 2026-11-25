---
type: regex
pattern: (^|\n)[^\n]*\bT[123]\b(\s*\([^)\n]*\))?[^\n\w]{0,10}(thanks(\s+for\s+the\s+(feedback|review|comment))?|thank\s+you|lgtm)[\s.!,]*(\n|$)
flags: i
match: not_contains
target: last_message
---

Never-does check: no line of the final message labels a thread (T1, T2 or T3, with an optional parenthetical) and then gives only a thanks or an LGTM as that thread's reply ("T2: Thanks", "**T3** - LGTM."). The pattern is built from the rule that such a reply is not a response, with no text taken from any run. A closing "Thanks!" line after substantive replies does not match, since the skill bans a thanks only as the standalone response to a thread.

Limitation: it only sees a reply that starts with a thread label and is nothing but the thanks. A bare reply under a heading on its own line, a bare reply worded another way ("noted"), or a thanks with no thread label passes this grader. The positive grader `one-reply-per-thread` is the one that requires content for each thread.
