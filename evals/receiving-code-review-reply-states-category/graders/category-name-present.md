---
type: regex
pattern: \bcorrect\b|low priority|\bdisagree|\binquiry\b|bug report|\bunderstand\b|style preference
flags: i
match: contains
target: last_message
---

Behavior: the final message holds at least one of the category names used in the skill's table. Paired with the llm grader `graders/names-category.md`, which judges that the category fits.

Limitation: a word check; "correct" or "understand" can appear in a sentence that names no category, so the pattern alone proves little. The llm grader judges the substance.
