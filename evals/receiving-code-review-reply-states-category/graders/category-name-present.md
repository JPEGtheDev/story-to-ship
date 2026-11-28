---
type: regex
pattern: \bcorrect\b|\bmissed (this|it)\b|low priority|\bdisagree|\binquiry\b|bug report|\bunderstand\b|style preference
flags: i
match: contains
target: last_message
---

Behavior: the agent's final reply names the review category that fits the comment, using a category word from the review skill's table.

Evaluation criteria: the check reads the final message (last message) and passes when it contains, ignoring case, one of these: the word correct; missed this or missed it (from the Correct -- I missed this row); low priority; disagree at the start of a word; the word inquiry; bug report; the word understand; style preference. It is a word match in contains mode and needs no judge on its own. It is paired with the llm grader graders/names-category.md, which judges that the category fits.

Limitation: a word check; "correct" or "understand" can appear in a sentence that names no category, so the pattern alone proves little. The llm grader judges the substance.
