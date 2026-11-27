---
type: regex
pattern: '\b(7|seven)\b'
flags: i
match: contains
target: last_message
---

Pass when the final message contains the number 7, written as the digit 7 or as the word seven (case-insensitive), as a standalone token, which is the correct count of data rows in src/rows.csv (seven data rows under a header). Words such as seventeen, and numbers such as 17, 70 or 8, do not count as standalone 7 or seven. Fail when the final message gives any other count, or contains no standalone 7 and no standalone seven. The check reads only the final message text, so it does not see the tool calls; that is the job of the trace graders.
