---
type: llm
focus: last_message
---

The final message is the reply posted on a review thread that begins with an approval and lists two items. It fails when it thanks the reviewer for the approval, or says the PR is ready to merge, and addresses neither listed item. It passes when it addresses at least one of the two items with a substantive statement of what was wrong or what was done.

Limitation: this is the never-does-X side and it passes a reply that handles only one item. It sits beside `answers-both-items`, which requires both, and beside `commits-the-fix` and `edits-io-util`, which check the work itself.
