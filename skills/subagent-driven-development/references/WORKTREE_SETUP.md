# Worktree Setup for Subagent Dispatch

Run these checks before dispatching any agent (read-only or write-side):

```bash
# 1. Ensure .worktrees/ is gitignored before first use
git check-ignore -q .worktrees || echo "ADD .worktrees TO .gitignore FIRST — stop here"

# 2. Create the worktree
git worktree add .worktrees/agent-<name> -b agent/<name>
# If nonzero exit: log error, do NOT dispatch, surface to user. Common causes:
# - stale lock file: git worktree prune; then retry
# - path already exists: remove it or rename
# - branch name already registered: choose a different branch name

# 3. Verify path is a worktree (not the main repo root)
git -C .worktrees/agent-<name> rev-parse --show-toplevel
# Output must be the absolute path of .worktrees/agent-<name> — NOT the main repo root

# 4. Write-side agents only — verify branch isolation
git -C .worktrees/agent-<name> branch --show-current
# Output must NOT equal the current development branch (e.g. feat/my-branch or main)
# Read-only agents (explorer, researcher, reviewers, skeptic, postmortem) skip step 4.
```

The worktree path confirmed in step 3 is the value to pass as `{{WORKTREE_PATH}}` in the agent prompt.

## Why Read-Only Agents Also Need Worktrees

The main context continues making commits while agents run. Without a worktree, a read-only agent observes a dirty working tree or partially-committed state — producing findings against a snapshot that no longer matches any branch. A worktree gives every agent a stable, isolated view at dispatch time.
