---
type: regex
pattern: (^|\n)\s*(thanks|thank you|lgtm)[\s.!,]*(thanks|thank you)?[\s.!]*(\n|$)
flags: i
match: not_contains
target: last_message
---

Never-does check: no line of the final message consists only of a thanks or an LGTM. The pattern is built from the rule that such a line is not a response, with no text taken from any run.

Limitation: it only sees a line that is nothing but the thanks. A thanks followed by empty content on the same line, or a bare reply worded another way ("noted"), passes this grader. The positive grader `one-reply-per-thread` is the one that requires content for each thread.
