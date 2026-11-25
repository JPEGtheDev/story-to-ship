---
type: tool_used
tool: Bash
input_match: '\bgh\b[^\n;&|]*\bpr\s+view\b[^\n;&|]*\b12\b'
min: 1
---

Behavior: rule under test is the sprint-close-out Iron Law and BEFORE PROCEEDING item 1 (a merge reported only in chat is not MERGED; origin is the record). The run reads the pull request on origin with `gh pr view 12` (flags may come before or after the number) at least once. The grader matches the JSON text of the whole Bash tool input (command and description), so a word in the description can match.

Limitation: the `12` need not belong to the pull request read: a newline is the two characters backslash and n in the JSON text and `[^\n;&|]` does not stop at it, so `gh pr view 3` newline `echo 12` matches, while `gh pr view 3; echo 12` does not. A `12` in the description matches too, and so does a description `gh pr view 12` with the command `ls`, so a run that never read the pull request can pass. A `gh` that starts a later line of a multi-line command, at column 0, is not seen unless something else in the input supplies the match, because the JSON text writes the newline as a backslash and an n, so there is no word boundary before it (`R=/r` newline `gh pr view 12` does not match, so a correct run can fail; a line indented with a space is seen, a line indented with a tab is not seen because the JSON text writes a tab as a backslash and a t). A description that holds `gh pr view 12` supplies the match. So does an earlier `gh` line with no `;`, `&` or `|` after it: the tail runs on past the backslash and n, so the later line does match (`gh auth status` newline `gh pr view 12` matches, `gh auth status | cat` newline `gh pr view 12` does not). A read by branch name is not seen (`gh pr view agent/story-7` does not match). It does not check that the read came before any other command, or that the agent used the answer. The gh command is a local stand-in that answers OPEN for PR 12. No end state, because Bash writes are blocked in the run.
