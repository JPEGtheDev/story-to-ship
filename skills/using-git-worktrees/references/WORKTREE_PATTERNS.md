# Git Worktree Patterns Reference

## Why Worktrees

Git worktrees let multiple agents work on different branches simultaneously **without branch switching**. Each agent gets its own working directory, its own branch, and full access to git history.

Benefits:
- Main context stays clean -- no dirty working tree from subagent experiments
- Parallel agent execution without conflicts
- Easy to discard failed experiments: delete the worktree
- Empirical A/B testing: two agents, two worktrees, compare results

---

## A/B Testing with Worktrees

When "I think" is not enough and empirical evidence is needed:

```bash
# Approach A
git worktree add .worktrees/approach-a -b agent/approach-a

# Approach B
git worktree add .worktrees/approach-b -b agent/approach-b

# Dispatch two agents -- one per worktree -- with identical test harness
# Compare: test results, line count, coupling, readability
# Adopt the winner; discard the loser's worktree
```

This pattern replaces "I think approach A is better" with measurable output.
