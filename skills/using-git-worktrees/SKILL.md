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

For background on why worktrees and A/B testing patterns, see `references/WORKTREE_PATTERNS.md`.

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

## BEFORE PROCEEDING

Before creating a worktree, verify:
1. The task is independent enough for a subagent (not tightly coupled to in-progress main work)
2. A descriptive name for the branch exists: agent/<purpose>
3. The subagent prompt includes the worktree path explicitly

[+] All met -> create the worktree and dispatch
[-] Any unmet -> work in the main context instead

---

## Subagent Dispatch Pattern

Create worktree -> pass path to subagent -> subagent commits to its branch -> main context reviews diff (`git diff main..agent/<name>`) -> merge or cherry-pick if approved, `git worktree remove` if rejected.

**The subagent MUST NOT push to `main`, `master`, or the active development branch.**

See `subagent-driven-development` for the full dispatch protocol.

---

## A/B Testing with Worktrees

Dispatch two agents, one per worktree, with an identical test harness. Compare results. Adopt the winner; discard the loser's worktree. See `references/WORKTREE_PATTERNS.md` for setup commands.

---

## Red Flags -- STOP

- Subagent working directly in the main repo directory -- **STOP. Create a worktree in `.worktrees/` first.**
- Subagent output committed to `main` or the active feature branch without review
- Worktree left alive after the work is merged or discarded (leaks branch clutter)
- Dispatch to a worktree without passing the worktree path in the agent prompt
- Merging a worktree branch before reviewing the full diff: `git diff main..agent/<name>`
- Using `git worktree list | wc -l` to check if you are in a worktree -- **STOP. This does NOT tell you which worktree you are in. Use `git rev-parse --show-toplevel` and compare against the expected path.**
- "I reviewed the diff mentally -- running `git diff main..agent/<name>` explicitly is redundant" -- **STOP. Run the diff command. Mental review is not a structural check.**
- Using `git worktree add ../name` (relative `../` path) -- **STOP. This places the worktree OUTSIDE the repo root as an unpredictable sibling directory. The resulting absolute path differs from the path you think you passed to the agent, causing BLOCKED dispatches. Always use `.worktrees/agent-<name>` (inside the repo, gitignored).**
- Running any git command without `-C <repo-root>` after a `cd` appeared in any prior Bash call this session -- **STOP. The Bash tool's working directory persists across calls. A prior `cd` into a worktree will cause the next bare `git` command to run inside that worktree's branch, not the main branch. Always use `git -C /absolute/repo/path` or verify with `pwd` before any git operation that touches the main branch.**
- About to create a worktree when the current branch is not `main` -- **STOP. Run `git log origin/main..HEAD --oneline` first. If any commits appear, the branch is not main-current. A branch with a semantically relevant name is NOT a valid base unless the user explicitly named it. Run `git checkout main && git pull` before creating any worktree.**

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "The task is simple enough to do in main" | Simple tasks don't need a worktree -- this rule applies when you WOULD use a subagent |
| "I'll review the subagent output before merging" | Review happens in the main context; the subagent STILL needs its own worktree to work safely |
| "Worktrees add overhead" | One git command. The cleanup time saved from a subagent polluting main more than compensates |
| "I think this approach is right, no need for A/B" | "I think" is not evidence. Dispatch two agents and let the output decide. |
| "The subagent promised not to touch main" | Subagent discipline is not a structural guarantee. Worktrees are. Create the worktree. |
| "I'll clean up the worktree later -- it's not hurting anything active" | Reality: YOU MUST remove worktrees immediately after merging or discarding. Stale worktrees accumulate into branch clutter that obscures active work. |
| "The existing branch name matches the feature domain, so it is the right base" | Branch names are semantic labels, not currency guarantees. Run `git log origin/main..HEAD --oneline` -- if any commits appear, the branch is behind or diverged from main. A branch named for the active feature domain that predates a recent merged PR is stale regardless of name. |

---

## Related Skills

- `subagent-driven-development` -- governs how to dispatch subagents and review their work; worktrees are the isolation mechanism for every subagent dispatch
- `dispatching-parallel-agents` -- governs parallel agent dispatch patterns; every parallel agent MUST have its own dedicated worktree
- `execution` -- governs the overall work loop; worktrees support the commit rhythm and behavior preservation required by the execution skill
