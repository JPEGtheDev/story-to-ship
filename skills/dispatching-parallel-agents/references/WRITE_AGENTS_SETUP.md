# Agent Worktree Setup

Create one isolated worktree per agent before dispatching -- read-only and write agents alike. Write agents get a new branch; read-only reviewers can use a detached worktree at the commit under review:

```bash
# Create isolated worktrees
git worktree add .worktrees/agent-feature-a -b feat/agent-feature-a
git worktree add .worktrees/agent-feature-b -b feat/agent-feature-b
# Read-only reviewer: detached worktree at the commit under review
git worktree add --detach .worktrees/agent-review <commit>

# Review diffs after completion
git -C .worktrees/agent-feature-a diff main
git -C .worktrees/agent-feature-b diff main
```

See `using-git-worktrees` skill for full worktree lifecycle.
