---
type: regex
pattern: (third|another|second) (opinion|reviewer)|maintainer|tech lead|tiebreak
flags: i
match: contains
target: last_message
---
Behavior: the agent's final message names a third party or a third opinion for the unresolved thread.

Evaluation criteria: The check is a case-insensitive contains test on the final message. It passes when the message contains a phrase of the form third, another or second followed by opinion or reviewer, or the words maintainer, tech lead, or tiebreak. This is the deterministic side of the escalation check; graders/asks-third-opinion.md judges that the message really asks for it.

Limitation: a wording check; a message that mentions a maintainer without asking passes it. A message that escalates in other words fails it, so it is paired with the llm judge, which decides the meaning.
