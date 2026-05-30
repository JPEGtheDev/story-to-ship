# Write Agent Worktree Setup

When parallelizing write work, create one isolated worktree per agent before dispatching:

```bash
# Create isolated worktrees
git worktree add .worktrees/agent-feature-a -b feat/agent-feature-a
git worktree add .worktrees/agent-feature-b -b feat/agent-feature-b

# Review diffs after completion
git -C .worktrees/agent-feature-a diff main
git -C .worktrees/agent-feature-b diff main
```

See `using-git-worktrees` skill for full worktree lifecycle.
