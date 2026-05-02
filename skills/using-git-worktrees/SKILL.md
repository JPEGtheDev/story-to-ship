---
name: using-git-worktrees
license: MIT
description: Use when running parallel agent work, testing an approach in isolation, or keeping the main branch clean while a subagent operates on a separate branch.
---

## Iron Law

```
YOU MUST NEVER LET A SUBAGENT COMMIT DIRECTLY TO THE MAIN WORKING BRANCH.
No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

Every subagent gets its own worktree. The main context reviews and merges.

**Announce at start:** "I am using the using-git-worktrees skill to create a worktree for [purpose]."

---

## Why Worktrees

Git worktrees let multiple agents work on different branches simultaneously **without branch switching**. Each agent gets:
- Its own working directory
- Its own branch
- Full access to the git history

Benefits:
- Main context stays clean — no dirty working tree from subagent experiments
- Parallel agent execution without conflicts
- Easy to discard failed experiments: delete the worktree
- Empirical A/B testing: two agents, two worktrees, compare results

---

## Worktree Lifecycle

### Create

```bash
# Step 1: Verify .worktrees is gitignored
git check-ignore -q .worktrees || echo "ADD .worktrees TO .gitignore FIRST"

# Step 2: Create the worktree on a new branch
git worktree add .worktrees/agent-<name> -b agent/<name>
# If nonzero exit: log the error, do NOT dispatch
#   stale lock:    git worktree prune; then retry
#   path exists:   remove or rename
#   branch in use: choose a different name

# Step 3: Verify you are NOT in the main directory
git -C .worktrees/agent-<name> rev-parse --show-toplevel
# Must equal the absolute path of .worktrees/agent-<name>, NOT the main repo root

# Step 4: Verify branch isolation
git -C .worktrees/agent-<name> branch --show-current
# Must NOT equal the active development branch
```

Use `.worktrees/agent-<name>` as the path — inside the repo, gitignored, named descriptively.

### List active worktrees

```bash
git worktree list
```

### Remove when done

```bash
git worktree remove .worktrees/agent-<name>
git branch -d agent/<name>   # only after merging or discarding
```

---

## BEFORE Creating a Worktree Gate

```
BEFORE creating a worktree, verify:
1. The task is independent enough for a subagent (not tightly coupled to in-progress main work)
2. A descriptive name for the branch exists: agent/<purpose>
3. The subagent prompt includes the worktree path explicitly

✓ All met → create the worktree and dispatch
✗ Any unmet → work in the main context instead
```

---

## Subagent Dispatch Pattern

When dispatching a subagent to a worktree:

1. Create the worktree first (main context)
2. Pass the worktree path to the subagent as its working directory
3. Subagent commits to its branch inside the worktree
4. Main context reviews the diff: `git diff main..agent/<name>`
5. If approved: merge or cherry-pick into main
6. If rejected: `git worktree remove` — no cleanup needed in main

**The subagent MUST NOT push to `main`, `master`, or the active development branch.**

---

## A/B Testing with Worktrees

When "I think" is not enough and empirical evidence is needed:

```bash
# Approach A
git worktree add .worktrees/approach-a -b agent/approach-a

# Approach B
git worktree add .worktrees/approach-b -b agent/approach-b

# Dispatch two agents — one per worktree — with identical test harness
# Compare: test results, line count, coupling, readability
# Adopt the winner; discard the loser's worktree
```

This pattern replaces "I think approach A is better" with measurable output.

---

## Red Flags — STOP

- Subagent working directly in the main repo directory — **STOP. Create a worktree in `.worktrees/` first.**
- Subagent output committed to `main` or the active feature branch without review
- Worktree left alive after the work is merged or discarded (leaks branch clutter)
- Dispatch to a worktree without passing the worktree path in the agent prompt
- Merging a worktree branch before reviewing the full diff: `git diff main..agent/<name>`
- Using `git worktree list | wc -l` to check if you are in a worktree — **STOP. This does NOT tell you which worktree you are in. Use `git rev-parse --show-toplevel` and compare against the expected path.**
- "I reviewed the diff mentally — running `git diff main..agent/<name>` explicitly is redundant" — **STOP. Run the diff command. Mental review is not a structural check.**

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "The task is simple enough to do in main" | Simple tasks don't need a worktree — this rule applies when you WOULD use a subagent |
| "I'll review the subagent output before merging" | Review happens in the main context; the subagent STILL needs its own worktree to work safely |
| "Worktrees add overhead" | One git command. The cleanup time saved from a subagent polluting main more than compensates |
| "I think this approach is right, no need for A/B" | "I think" is not evidence. Dispatch two agents and let the output decide. |
| "The subagent promised not to touch main" | Subagent discipline is not a structural guarantee. Worktrees are. Create the worktree. |
| "I'll clean up the worktree later — it's not hurting anything active" | Reality: YOU MUST remove worktrees immediately after merging or discarding. Stale worktrees accumulate into branch clutter that obscures active work. |

---

## Related Skills

- `subagent-driven-development` — governs how to dispatch subagents and review their work; worktrees are the isolation mechanism for every subagent dispatch
- `dispatching-parallel-agents` — governs parallel agent dispatch patterns; every parallel agent MUST have its own dedicated worktree
- `execution` — governs the overall work loop; worktrees support the commit rhythm and behavior preservation required by the execution skill
