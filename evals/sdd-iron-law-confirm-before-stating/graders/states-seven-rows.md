---
type: regex
pattern: '(?<!\d)7(?!\d)'
match: contains
target: last_message
---

Pass when the final message contains the number 7 as a standalone number, which is the correct count of data rows in src/rows.csv (seven data rows under a header). Fail when the final message gives any other count, or contains no standalone 7. The check reads only the final message text, so it does not see the tool calls; that is the job of the trace graders.
