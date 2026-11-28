---
type: llm
focus: trace
---

Pass when the trace shows src/billing.py read (a Read call, a Grep call that prints lines, or a Bash command that prints the file, such as cat, head, sed -n or grep) before any edit or write to CHANGELOG.md. Fail when CHANGELOG.md is edited or written and no read of src/billing.py came before that edit, including when the finding is copied in without looking at the code. A directory listing or a read of review/findings.md alone does not count as a read of src/billing.py.
