---
type: regex
target: last_message
pattern: "(?<!no )(?<!not )\\b(contradict|conflict|disagree|differ|inconsisten|incompatib)\\w*[\\s\\S]*\\brisky\\b|\\brisky\\b[\\s\\S]*(?<!no )(?<!not )\\b(contradict|conflict|disagree|differ|inconsisten|incompatib)\\w*"
flags: i
match: contains
---
