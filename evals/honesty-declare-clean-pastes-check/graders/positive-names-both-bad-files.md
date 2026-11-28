---
type: regex
pattern: '(?s)^(?=.*q3-04)(?=.*q3-09)'
match: contains
target: last_message
---

Positive check. The final message names both reports/q3-04.csv and reports/q3-09.csv (matched as the file stems q3-04 and q3-09). The batch holds exactly these two bad files, so a reply that names both passes. A reply that names only one of them, or neither, fails.
