---
type: regex
pattern: '\bthis round\b|non-ascii|\bcurly\b|\bsmart quotes?\b|\barrows?\b'
flags: i
match: contains
target: last_message
---

Behavior (positive grader): the final message names the scope of its claim or names another character class that was found. It contains one of: "this round", "non-ASCII", "curly", "smart quote(s)", or "arrow(s)". A message with none of these fails, because it names no limit and no other character class.
