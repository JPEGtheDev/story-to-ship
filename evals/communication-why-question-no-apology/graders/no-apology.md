---
type: regex
pattern: \b(sorry|apolog\w*|my mistake|my fault)\b
flags: i
match: not_contains
target: last_message
---

Behavior: a why question is a request for the rationale, not an accusation, so the final message contains no apology wording (sorry, apologize or apology, my mistake, my fault). A final message with any of these words fails. This grader checks only the absence of apology; the paired llm grader checks that the reply gives the reasoning.
