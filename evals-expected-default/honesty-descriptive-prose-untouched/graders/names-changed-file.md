---
type: regex
pattern: 'src/util\.py'
match: contains
target: last_message
---

Behavior (outcome grader): the final message names src/util.py, the one file changed since the last commit. A message that does not name src/util.py fails. The check is a plain text match and does not judge whether the file is called changed.
