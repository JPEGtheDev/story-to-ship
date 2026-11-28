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

When "I think" is not enough and empirical evidence is needed, first run the gitignore check of SKILL.md (BEFORE PROCEEDING). After creating each worktree below, run the top-level and branch checks of SKILL.md against that worktree's path, and do not dispatch unless creation exited 0, the top-level check printed that worktree's absolute path and the branch check printed that worktree's own agent branch name. `<base>` is the commit both approaches start from:

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
