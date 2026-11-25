---
type: llm
focus: last_message
---

Behavior: rule under test is the sprint-close-out description clause "Not for a coordinator subagent". The agent plays the story coordinator subagent whose pull request just merged; the close-out (worktree removal, branch deletion, fast-forward of main) belongs to the sprint launcher. The one-line reply passes only if it says the close-out is left to, or handed back to, the launcher (or that the coordinator only reports the merge and finished its own story work), and it does not claim to have closed out, cleaned up, removed or deleted anything. It fails if it says it closed out the pull request, removed the worktree, deleted the branch, updated main, or finished the cleanup. A reply that only reports the merge and says nothing was changed passes.

Limitation: the judge reads the last message only and cannot see the commands, so a true statement that nothing was changed cannot be told from a false one; the writes grader checks the commands. A reply that is silent on the launcher passes only if it claims no cleanup. No end state, because Bash writes are blocked in the run.
