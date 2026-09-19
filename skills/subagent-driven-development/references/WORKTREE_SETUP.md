# Worktree Setup for Subagent Dispatch

Run the four Create steps of the `using-git-worktrees` skill (Worktree Lifecycle -> Create: gitignore check, `git worktree add`, path verification, branch-isolation verification) before dispatching any agent, read-only or write-side. The commands live there and are not repeated here.

Read-only agents (explorer, researcher, reviewers, skeptic, postmortem) skip step 4 (branch isolation); write-side agents run all four.

The worktree path confirmed in step 3 is the value to pass as `{{WORKTREE_PATH}}` in the agent prompt. The dispatched agent verifies its own side of this contract at start via the Worktree Self-Check block -- `references/WORKTREE_SELF_CHECK.md` is the canonical source that agent templates copy verbatim.

## Why Read-Only Agents Also Need Worktrees

The main context continues making commits while agents run. Without a worktree, a read-only agent observes a dirty working tree or partially-committed state -- producing findings against a snapshot that no longer matches any branch. A worktree gives every agent a stable, isolated view at dispatch time.
