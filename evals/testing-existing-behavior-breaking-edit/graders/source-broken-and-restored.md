---
type: llm
focus: trace
---

Pass only when the trace shows, in this order: a change to src/pricing.py that alters the discount behavior (made with Edit, Write, or a Bash command such as sed); then a test run; then a step that restores src/pricing.py (Edit, cp, git checkout, or git stash). Fail when src/pricing.py is never changed, when only the test file is changed, or when the break is left in place. If the trace does not show Bash output, judge from the commands issued and the final message.
