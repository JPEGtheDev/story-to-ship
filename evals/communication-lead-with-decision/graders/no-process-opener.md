---
type: regex
pattern: ^\s*(i (read|looked|started|opened|went through|reviewed|checked)\b|i.?ve (read|looked|reviewed|checked)\b|i have (read|looked|reviewed|checked)\b|first,? i\b|after (reading|looking)\b|(reading|looking|reviewing)\b|let me\b)
flags: i
match: not_contains
target: last_message
---

The reply does not open with a narration of the work done, such as "I read ...", "I looked at ...", "I reviewed ...", "I checked ...", "I've read ...", "I have looked ...", "First I ...", "After reading ...", "Reading ...", "Looking at ...", "Reviewing ..." or "Let me ...". The pattern is anchored to the start of the last message, so process words later in the reply do not fail it. The positive check that the opening states the result and the decision is leads-with-result-and-decision.md.
