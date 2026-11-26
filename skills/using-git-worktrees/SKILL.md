---
name: using-git-worktrees
license: MIT
description: Use when dispatching any subagent (every dispatched agent runs in its own worktree), testing an approach in isolation, or keeping the main branch clean while a subagent operates on a separate branch.
---

```
YOU MUST DISPATCH EVERY SUBAGENT INTO ITS OWN WORKTREE UNDER .worktrees/ AND NEVER LET IT COMMIT TO MAIN OR THE ACTIVE DEVELOPMENT BRANCH.
No exceptions.
```

## BEFORE PROCEEDING

Before creating a worktree, verify:
1. The task is independent enough for a subagent (not tightly coupled to in-progress main work)
2. A descriptive name for the branch exists: agent/<purpose>
3. The subagent prompt includes the worktree path explicitly

[+] All met -> create the worktree and dispatch.
[-] Condition 1 unmet -> do the work in the main context, no subagent
[-] Condition 2 or 3 unmet -> name the branch agent/<purpose> (condition 2) and add the absolute worktree path to the prompt (condition 3), whichever is unmet, then re-check this list

Before every `worktree add`, run `git -C <repo-root> fetch origin main`, then `git -C <repo-root> rev-list --left-right --count origin/main...<base>`. L is the commits on `main` that `<base>` lacks and R the commits `<base>` has that `main` lacks: L above 0 with R at 0 means `<base>` is behind, so use `main` as the base (for `main` itself, run `git -C <repo-root> pull --ff-only`); R above 0 means local commits, a valid base only when the user named it.

The `<base>` of a `worktree add` is the feature branch for an implementer; for a read-only agent it is the commit it inspects (`main` for research, the branch under review for a reviewer).

Every git command names its checkout with `git -C <path>`, for example `git -C .worktrees/<name> status`: the Bash working directory persists after a `cd`, so a bare `git` after a `cd` reads the wrong checkout.

Before every `worktree add`, run `git -C <repo-root> check-ignore -q .worktrees/`; if it fails, append `.worktrees/` as the new last line of the top-level `.gitignore` with one Edit, then run the check again.

A feature branch lives in its own worktree, never in the main checkout, which stays on `main`: `git -C <repo-root> fetch origin main`, then `git -C <repo-root> worktree add .worktrees/<feature> -b <branch> origin/main`.

An agent worktree is created with `git -C <repo-root> worktree add .worktrees/agent-<name> -b agent/<name> <base>`.

If `worktree add` exits nonzero, do not dispatch and surface the error. A stale lock: run `git -C <repo-root> worktree prune`, then retry. A path that exists: remove or rename it. A branch in use: choose a different name.

A subagent MUST NOT push to `main`, `master` or the active development branch. A subagent's promise to stay off them is not isolation: dispatch it into its own worktree anyway. Before any merge or cherry-pick, run `git -C <repo-root> diff <base>...agent/<name>` in its own call and read it; a merge before that diff is the failure, and rejected work gets its worktree removed.

After each `worktree add` of an agent worktree, run `git -C .worktrees/agent-<name> rev-parse --show-toplevel`; it must equal the absolute path of that worktree, not the main repo root. Then run `git -C .worktrees/agent-<name> branch --show-current`; it must not equal the active development branch.

After the branch is merged or discarded, run `git -C <repo-root> worktree remove .worktrees/agent-<name>`, then `git -C <repo-root>/.worktrees/<feature> branch -d agent/<name>` (`-D` for a cherry-picked or discarded branch). A worktree left alive after merge or discard is the failure.

Background and A/B setup: `references/WORKTREE_PATTERNS.md`.
