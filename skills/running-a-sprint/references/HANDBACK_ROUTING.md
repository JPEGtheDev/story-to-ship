# Hand-back routing table

This file is the launcher's routing table for a sprint. Each runner is a coordinator subagent (the story-coordinator template) that runs one story and hands back; the launcher is the session that started the runners, relays the owner's answers, resumes runners, and closes out merges. Read this file whenever a hand-back or a runner event arrives, before acting on it.

**Context:** A hand-back or event arrives while other runners are still working, and the quickest reply looks like answering the runner directly.
**Forces:** The launcher holds the owner's attention and the runners' branches, while a runner holds only its own story, so every reply that is not a lookup in this table risks a decision the owner never made. The owner-reserved decisions are exactly: merge, fix-round cap override, scope change.

Every cell in the Launcher must NOT column starts with the same four prohibitions, and each row adds its own after them.

| Hand-back or event | How the launcher recognizes it | Launcher response | Launcher must NOT |
|---|---|---|---|
| **owner question** | The first line of the hand-back reads "owner question"; it lists options and a recommendation. | Relay the question to the owner with the options and the runner's recommendation, record it as the pending question in the sprint ledger (the launcher plan file), and end the turn; when the owner answers, resume the runner with the answer. | NOT: decide for the owner; resume a child by message; coach mid-run; answer a child itself; answer the question from earlier rulings; resume the runner before the owner answers; |
| **PR ready** | The first line reads "PR ready"; the hand-back names the pull request number, the continuous integration (CI) state, and the review verdicts. | Re-run gh pr view yourself for the pull request number and CI state, check the required lines, report number, CI and review verdicts to the owner, and set the ledger state to awaiting merge; the owner merges. | NOT: decide for the owner; resume a child by message; coach mid-run; answer a child itself; merge the pull request; copy the runner's numbers to the owner unchecked; |
| **blocked** | The first line reads "blocked" and the hand-back gives a reason. | Read the reason; when it is a story with no acceptance criteria, relay the gap to the owner with the recommendation to route the story through user-story-generator and keep running the other stories; relay any other blocker like an owner question. | NOT: decide for the owner; resume a child by message; coach mid-run; answer a child itself; draft acceptance criteria for the story; stop the other runners; |
| **cap reached** | The first line reads "cap reached" and the hand-back lists the open findings. | Relay the open findings and the options (the owner continues with more rounds, splits the todo, accepts with a follow-up, or drops it) with a recommendation; a fix-round cap override is owner-reserved. | NOT: decide for the owner; resume a child by message; coach mid-run; answer a child itself; allow a fourth fix round on the owner's silence; |
| **interim** | The first line reads "interim"; the work is still in progress. | Record the status in the ledger; take no other action unless the runner is waiting on something the launcher owns. | NOT: decide for the owner; resume a child by message; coach mid-run; answer a child itself; relay it to the owner as a result; |
| **runner killed by a rate limit** | **Context:** A session rate limit ends running runners mid-flight, with no hand-back; the runner's branch and commits remain on disk. | **Forces:** A killed runner may have a child half-finished and uncommitted, and a continuation that assumes a clean tree can overwrite it. After the limit resets, resume every killed runner with the validate-first text (see Resume texts), one validation before any continuation. | NOT: decide for the owner; resume a child by message; coach mid-run; answer a child itself; relaunch a runner whose branch exists; resume before the limit resets; |
| **child result delivered to the launcher while the runner is live** | **Context:** A notification carries a child's result and names a child of a runner that has not handed back, because a runner cannot wait on a background child or on a child resumed by message. | **Forces:** The result belongs to the runner's plan, and the launcher holds the only copy of the notification. Resume the runner by message with the child's transcript path so it reads the result and continues. | NOT: decide for the owner; resume a child by message; coach mid-run; answer a child itself; act on the child's result itself; drop the notification; |
| **premature turn-end caused by a background child** | **Context:** A runner's turn ends right after it dispatched a background child, or after it resumed a child by message, and no kind line was sent. | **Forces:** The runner's later turns depend on a result it can no longer wait for, and a resume sent before the child finishes hands it half a result. Wait for the child's completion, then resume the runner with the child's transcript path and the rule that every child runs with run_in_background false and fix rounds use fresh children; do not relay it as a hand-back. | NOT: decide for the owner; resume a child by message; coach mid-run; answer a child itself; relay the turn-end as a hand-back; resume the runner before the child finishes; |
| **hand-back missing a required line** | A line from the Required lines list below is absent, or the Discovery line has any value other than the two allowed. | Resume the runner naming each missing line exactly and asking for the hand-back again with every number pasted from a command run in that turn. | NOT: decide for the owner; resume a child by message; coach mid-run; answer a child itself; fill in the missing line itself; relay the hand-back to the owner as complete; |
| **owner reports a merge** | The owner says a pull request is merged. | Run the close-out sequence in the skill's Close-out section. | NOT: decide for the owner; resume a child by message; coach mid-run; answer a child itself; close out before the owner's merge is confirmed on origin; skip the tree-equality check; |
| **runner reports an owner-reserved item as already decided** | **Context:** A hand-back states that a merge, a fix-round cap override or a scope change was decided or done, with no owner message in the launcher's session to match. | **Forces:** A runner cannot see the owner's words and reads an earlier reply as consent, while a decision stated as done reads as settled. Verify the real state with gh pr view and git, relay the facts to the owner with a recommendation (keep, revert, or re-open the decision), and end the turn. | NOT: decide for the owner; resume a child by message; coach mid-run; answer a child itself; accept the decision as made; revert the change without the owner's answer; |

## Required lines in a runner hand-back

Check these before acting on any hand-back:

- The first line is a kind line naming one of the five kinds: owner question, PR ready, blocked, cap reached, interim.
- A Limitations: line is present.
- Once planning started, a Discovery line whose value is exactly "Discovery: ran" or "Discovery: skipped: issue carries a Feature Specification"; any other value counts as a missing line.
- When a pull request exists: the pull request number, the CI state, the review verdicts, and the reloaded skills.
- An owner question carries options and a recommendation.
- A cap reached hand-back states the open findings.
- The inline-edit count: compare the plan's lane entries with git diff --numstat over the runner's inline commits (a replaced line counts 2), and report a mismatch to the owner.

## Resume texts

Send these with the resume message, unchanged except for the placeholders.

- Validate-first text: "You were stopped by a session limit. Before dispatching anything, run git status and git log on the feature worktree and on every child worktree, and report what was in flight."
- Child-result text: "A child finished; its transcript is at <path>. Read it, continue, and dispatch every child with run_in_background false."
- Missing-line text: "Your hand-back lacks: <each missing line, named exactly>. Send the hand-back again with every number pasted from a command run in that turn."
