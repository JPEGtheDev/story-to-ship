---
type: llm
focus: last_message
---

The final message is the reply posted on a review thread that raises a valid but low-priority point outside the purpose of the PR. It passes only when all of these hold:

1. It acknowledges that the point is valid.
2. It explains why the item is deferred, for example that it is unrelated to this change and not urgent.
3. It names or links a tracking issue for the item: an issue number, an issue link, or a plain statement that an issue was opened with a title or description of the item. A statement in the message that an issue was opened is acceptable when the message says what the issue covers.

A bare "I will address this separately" or "will do in a follow-up" with no tracking issue named fails. A reply that says the item was fixed in this PR fails.

Limitation: `gh` cannot reach GitHub in this scaffold, so no issue can truly exist. The judge reads only the final message, so it never sees a `gh issue create` attempt; it accepts a named tracking-issue reference in the text, and cannot tell a reference that points at a real issue from an invented number.
