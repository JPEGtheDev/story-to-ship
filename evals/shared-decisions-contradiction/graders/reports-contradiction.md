---
type: regex
target: last_message
pattern: "(?<!no )(?<!not )\\b(contradict|conflict)\\w*[\\s\\S]*\\brisky\\b|\\brisky\\b[\\s\\S]*(?<!no )(?<!not )\\b(contradict|conflict)\\w*"
flags: i
match: contains
---
