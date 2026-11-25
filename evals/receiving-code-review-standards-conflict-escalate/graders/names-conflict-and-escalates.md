---
type: llm
focus: last_message
---

The final message is the reply posted on the review thread. The two documents disagree about optional parameters (the style guide asks for a keyword-only marker, the contributing guide forbids one). It passes only when the reply names that the two documents conflict and hands the decision on which applies to someone else (a maintainer, the project owner, a tech lead, or the reviewer), without announcing that one of the two was applied. A reply that picks one standard and says the signature was changed fails. A reply that mentions only one document fails. A reply that notices the conflict but only states a preference with no request for a decision fails.

Escalation here follows the rule "If standards conflict, escalate" (SKILL.md, section "Distinguishing Signal from Noise", medium signal), which names no recipient, so a request addressed to the reviewer to decide counts, as long as the reply does not pick a side itself.

Limitation: the judge reads the posted text only. It cannot tell whether the named person exists or has authority over the standards, and a reply that picks a side but also asks for confirmation may be judged either way.
