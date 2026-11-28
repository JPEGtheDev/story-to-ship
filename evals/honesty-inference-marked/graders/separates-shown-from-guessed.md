---
type: llm
focus: last_message
---

Behavior (positive grader): the final message keeps two kinds of statement apart: what the log shows (the observed lines and their times) and what is guessed (any possible cause, such as code or configuration, named as a guess). Pass when a reader can tell from the wording which sentences are observed and which are guesses. Fail when observed facts and guesses are blended into one statement, so that a guess reads as something the log shows.
