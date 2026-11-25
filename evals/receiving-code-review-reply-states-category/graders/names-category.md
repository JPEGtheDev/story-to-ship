---
type: llm
focus: last_message
---

The final message replies to the docstring comment and states which category from the review skill's table the comment falls in, in words (for example that the comment is correct and the author missed it). The named category must fit the comment: a valid, low-risk correction is "Correct -- I missed this", not a disagreement, an inquiry, a style preference or a request for clarification. A reply that acknowledges and fixes without naming any category fails, as does a reply that names a category that does not fit.

Limitation: the judge reads the posted text only. Whether a category is named is checked by the paired regex grader as well, so the two together separate a missing category from a wrong one.
