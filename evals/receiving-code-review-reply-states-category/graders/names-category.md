---
type: llm
focus: last_message
---

The final message replies to the docstring comment and states which category from the review skill's table the comment falls in, in words (for example that the comment is correct and the author missed it). The named category must fit the comment: a valid, high-signal correction is "Correct -- I missed this". The wrong categories are "Correct but low priority" (never used for a high-signal comment), "I disagree", "Inquiry", "Bug report phrased as a question", "I don't understand" and "Style preference". A reply that acknowledges and fixes without naming any category fails, as does a reply that names a category that does not fit.

Limitation: the judge reads the posted text only. Whether a category is named is checked by the paired regex grader as well, so the regex only shows that some category word appears, and this judge decides whether a category is named and whether it fits.
