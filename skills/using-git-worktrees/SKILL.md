---
name: using-git-worktrees
license: MIT
description: Use when dispatching any subagent (every dispatched agent runs in its own worktree), testing an approach in isolation, or keeping the main branch clean while a subagent operates on a separate branch.
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

Run every command in this section from the main checkout (the repo root), or prefix it with `git -C <repo-root>`: a relative `.worktrees/` path resolved inside another worktree creates a nested worktree there.

### Feature branch

**Context:** Starting the feature branch for a multi-todo plan.
**Forces:** Creating the branch in the main checkout is one command, but when the session loads its skills from the checkout (in this repo `.claude/skills` is a symlink to `../skills`), a feature branch there makes the session load that branch's half-edited skills instead of main's. A worktree costs one more command and keeps the skills the session loads fixed to main's.

The feature branch lives in its own worktree, never in the main checkout. The main checkout stays on `main` from session start to PR hand-off.

```bash
git -C <repo-root> fetch origin main
git -C <repo-root> worktree add .worktrees/<feature> -b <feature-branch> origin/main
```

The main context's edits, commits, and pushes for the feature happen in `.worktrees/<feature>`. Enforcement: the postmortem-reviewer template's Branch-location audit row.

### Create

```bash
# Step 1: Verify .worktrees is gitignored
git check-ignore -q .worktrees || echo "ADD .worktrees TO .gitignore FIRST"

# Step 2: Create the worktree on a new branch
git worktree add .worktrees/agent-<name> -b agent/<name> <base>
# <base>: the feature branch for an implementer, main for a read-only agent
# If nonzero exit: log the error, do NOT dispatch, surface the error to the user
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
- About to create a worktree from a `<base>` other than the feature branch -- **STOP. Run `git -C <repo-root> rev-list --left-right --count origin/main...<base>` first. Output is `L<tab>R` (L = commits on main not in `<base>`; R = commits in `<base>` not on main). If L > 0 and R = 0: `<base>` is behind main -- for `main`, run `git -C <repo-root> pull --ff-only` (the main checkout is on `main`). If R > 0: `<base>` has local commits -- only valid base if the user explicitly named it. Only `0<tab>0` means current with main.**
- About to run `git checkout -b`, `git switch`, `git checkout <branch or commit>`, or `gh pr checkout` in the main checkout, other than returning it to `main` -- **STOP. The main checkout stays on `main`. Create the feature branch in a worktree: `git -C <repo-root> fetch origin main`, then `git -C <repo-root> worktree add .worktrees/<feature> -b <branch> origin/main`.**

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
| "The existing branch name matches the feature domain, so it is the right base" | Branch names are semantic labels, not currency guarantees. Run `git -C <repo-root> rev-list --left-right --count origin/main...<branch>` -- `L<tab>R` output: L > 0 means behind main; R > 0 means ahead with local commits; only `0<tab>0` is main-current. A branch named for the active feature domain that predates a recent merged PR is stale regardless of name. |

---

## Related Skills

- `subagent-driven-development` -- governs how to dispatch subagents; worktrees are the isolation mechanism for every subagent dispatch
- `two-stage-review` -- governs how each subagent's work is reviewed
- `dispatching-parallel-agents` -- governs parallel agent dispatch patterns; every parallel agent MUST have its own dedicated worktree
- `execution` -- governs the overall work loop; worktrees support the commit rhythm and behavior preservation required by the execution skill
