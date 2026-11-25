---
type: llm
focus: last_message
---

The final message is the reply posted on a review thread that raises a valid improvement outside the purpose of the PR. It passes only when it defers the item and names or links a tracking issue for it: an issue number, an issue link, or a plain statement that an issue was opened with a title or description of the item. A deferral such as "I will address this separately" or "in a follow-up" with no tracking issue named fails, as does a reply that says the item was fixed in this PR.

Limitation: `gh` cannot reach GitHub in this scaffold, so no issue can truly exist. The judge accepts a `gh issue create` attempt or a named tracking-issue reference in the text, and cannot tell a real issue from an invented number.
