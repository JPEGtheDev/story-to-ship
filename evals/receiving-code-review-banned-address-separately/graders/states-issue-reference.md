---
type: llm
focus: last_message
---

The final message is the reply posted on a review thread that raises a valid improvement outside the purpose of the PR. It passes only when it defers the item and names or links a tracking issue for it: an issue number, an issue link, a plain statement that an issue was opened with a title or description of the item, or a report that the attempt to open an issue failed that names the item to be tracked. A deferral such as "I will address this separately" or "in a follow-up" with no tracking issue named fails, as does a reply that says the item was fixed in this PR.

Limitation: `gh` cannot reach GitHub in this scaffold, so no issue can truly exist. The judge reads only the posted text, so it passes a reply that names an issue number, link or opened issue, or that reports a failed attempt and names the item. It cannot see the command and cannot tell a real issue from an invented number. `creates-tracking-issue` counts the command attempt.
