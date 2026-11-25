---
type: regex
pattern: \bdisagree
flags: i
match: contains
target: last_message
---

Behavior: the posted text uses the word form "disagree" (disagree, disagreement), the direct statement the rule asks for. This is the positive side of the personal-attack check in `graders/no-personal-attack.md`.

Limitation: the word can appear in a reply that goes on to soften or drop the position, or in a reply that disagrees with a different point. The llm grader `states-disagreement-directly` judges the content; this check only requires that the stance is named.
