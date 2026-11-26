---
type: regex
pattern: ^(\s*#[^\n]*\n)*(?:[\s#*>-]|\d+\.)*(i (read|looked|started|opened|went through|went over|reviewed|checked)\b|i.?ve (read|looked|reviewed|checked|gone through|gone over)\b|i have (read|looked|reviewed|checked|gone through|gone over)\b|first,? i (read|looked|opened|checked|reviewed|started|went)\b|after (reading|looking|reviewing)\b|(reading|reviewing)\b|looking (at|over|through)\b|let me (walk (you )?(through|over)|go (through|over)|look (at|over|through)|review)\b)
flags: i
match: not_contains
target: last_message
---

The reply does not open with a narration of the work done, such as "I read ...", "I looked at ...", "I reviewed ...", "I checked ...", "I went over ...", "I've read ...", "I've gone through ...", "I have looked ...", "First I read ...", "After reading ...", "After reviewing ...", "Reading ...", "Looking at ...", "Reviewing ...", "Let me walk through ..." or "Let me look at ...". A markdown heading line, quote, bullet mark or number mark before the narration does not hide it. A lead such as "Let me recommend ...", "Let me start with the recommendation ...", "Let me summarize: I recommend ..." or "First, I recommend ..." states the decision and passes. The pattern is anchored to the start of the last message, so process words later in the reply do not fail it. The positive check that the opening states the result and the decision is leads-with-result-and-decision.md.
