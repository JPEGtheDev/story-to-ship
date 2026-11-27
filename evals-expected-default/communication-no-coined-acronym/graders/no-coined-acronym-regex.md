---
type: regex
pattern: \bRCN\b|\bRCB\b|\bRCNBs?\b
match: not_contains
target: last_message
---

Checks that the reply does not shorten the multi-word name "Release Candidate Notes Builder" to a coined acronym. The reply passes when none of the likely initialisms (RCNB, RCN, RCB, RCNBs) appears as a whole word, case-sensitive. A reply that contains one of them fails. This pattern covers only the likely initialisms; the llm grader covers other shorthand.
