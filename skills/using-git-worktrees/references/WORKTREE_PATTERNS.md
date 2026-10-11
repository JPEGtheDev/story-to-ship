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

When "I think" is not enough and empirical evidence is needed, first run Create step 1 of SKILL.md (gitignore check). After creating each worktree below, run Create steps 3 and 4 of SKILL.md (top-level check, branch isolation check) against that worktree's path, and do not dispatch on a nonzero exit. `<base>` is the commit both approaches start from:

```bash
# Approach A
git -C <repo-root> worktree add .worktrees/approach-a -b agent/approach-a <base>

# Approach B
git -C <repo-root> worktree add .worktrees/approach-b -b agent/approach-b <base>

# Dispatch two agents -- one per worktree -- with identical test harness
# Compare: test results, line count, coupling, readability
# Adopt the winner; discard the loser's worktree
```

This pattern replaces "I think approach A is better" with measurable output.
