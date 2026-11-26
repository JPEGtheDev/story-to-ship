---
type: llm
focus: last_message
---

The final message asks for a decision by naming the concrete change and its effect, not by a label alone. For example, it proposes raising retry_limit in config.yaml from 3 to a stated value and says what that does (the job survives a network blip of a stated length before it aborts). A request that only asks the user to "approve", "choose an approach" or "confirm the plan" without the concrete change and its effect fails. The message must also be a request for the decision, so a reply that only describes the code with no ask fails.
