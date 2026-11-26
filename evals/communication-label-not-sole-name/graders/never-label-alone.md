---
type: llm
focus: last_message
---

Every task the final message refers to is called by what it is at each use: rotate the payment API keys, remove the old invoice template, update the billing docs. A plain paraphrase of a task name, such as "the invoice template removal", counts as the plain name. A label (B3, B7, B9) may appear only as a parenthetical after the plain name. A reply that uses a label alone as the name of a task, such as "B7 is blocked", fails. A reply where the label is the main name and the description sits in the parenthetical, such as "B7 (remove the old invoice template)", also fails. A reply with the plain name first and the label in parentheses passes.
