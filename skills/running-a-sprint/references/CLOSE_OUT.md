# Close-out scripts

The Close-out section of `../SKILL.md` lists the steps. Two POSIX sh scripts in `../scripts/` run its steps 1 to 5 and the reads of step 6. The rules stay in SKILL.md. The Close-out section is unchanged; these scripts are the way to run its steps 1-5 and the reads of step 6. The lane_sum count and the scorecard row, the checkbox tick of step 6, the reconcile of step 7 and the ledger edit stay manual.

## closeout-check.sh (step 1, step 2 and the worktree part of step 3)

Run it with absolute paths from the launcher's session:

`sh skills/running-a-sprint/scripts/closeout-check.sh -r <repo root> -n <PR number> -b <branch> -p <prefix> [-x <reconcile prefix>] [-P <plan file name>]`

- `-r` is the absolute path of the repository root.
- `-n` is the pull request number.
- `-b` is the story branch name.
- `-p` is the runner worktree prefix. The runner worktree is `<root>/.worktrees/<prefix>`, and its children are the registered `<root>/.worktrees/<prefix>-*` worktrees.
- `-x` (optional) is the reconcile worktree prefix. The patch check then uses `origin/<branch>` as the branch tip, and the reconcile worktree and its children are checked too.
- `-P` (optional) is the plan file name a clean worktree may hold untracked at its top. The default is `plan.md`.

The check prints one line per check, in this order:

1. `merged`: the PR state is MERGED and it has a merge commit (step 1). `FAIL merged: gh failed` when gh fails.
2. `NOTE fetch`: the fetch the check ran. It fetches origin main, and fetches the branch only when origin has it. This line is a note, not a check.
3. `ancestry`: the merge commit is in origin/main (step 1).
4. `patch`: the squash diff equals the branch diff from the merge base (step 2).
5. `worktree`: each worktree is absent, or clean (only the plan file untracked), or it names each status line (step 3). An ignored file counts as well: the check runs `git status --short --ignored`, which lists an ignored file as a `!!` line, so an ignored file makes the worktree FAIL.

Each check prints `OK <name>: <value>` or `FAIL <name>: <value>`. The exit codes are 0 when every line is OK, 1 when any line is FAIL, and 2 on a usage error (the usage message goes to stderr and nothing to stdout). The check changes no branch, worktree or file. Its fetch updates only remote-tracking refs.

## closeout-steps.sh (steps 3 to 5 and the reads of step 6)

It takes the same options as the check, plus `-i <issue number>` (required) and `-e <epic issue number>` (optional). It runs in this order:

1. It runs closeout-check.sh with the same options and prints the check output unchanged. A FAIL line in the check, or a repo root that is not on main, refuses the run before any change: `FAIL steps: refused, close-out check failed`, or `FAIL steps: refused, repo root is on <branch>, not main` (a detached root HEAD is named "detached HEAD"). The exit code is 1.
2. Then the steps, one line each:
   - `remove-worktree`: the runner worktree, then its registered children in path order (with `-x`, the reconcile worktree and its children after them). `OK remove-worktree: <path>`, or `OK remove-worktree: <path> absent` when the directory is gone. Removal uses `git worktree remove --force`.
   - `delete-branch-local`: the branch, with `branch -D` (and `reconcile-<x>` with `-x`). `OK delete-branch-local: <branch>`, or `... already gone` when the branch does not exist.
   - `delete-branch-origin`: the branch on origin, probed with ls-remote. `OK delete-branch-origin: <branch>`, or `... already gone` when origin does not have it. Nothing is pushed with --force.
   - `fast-forward`: root main to origin/main with `--ff-only`. `OK fast-forward: main at <first 7 characters of the sha>`.
3. Then three reads, one line each, in this order:
   - `issue`: `OK issue: #<issue number> <state>`.
   - `epic`, only with `-e`: the first line of the epic body that holds a checkbox (`- [x]`, `- [X]` or `- [ ]`) and names `#<issue number>` as a whole number prints `OK epic: #<epic> [x] #<issue>` or `[ ]`. When no such line exists it prints `FAIL epic: #<epic> has no line naming #<issue>`. The script only reads this line; it does not tick it.
   - `flaky`: `OK flaky: <count>`, the number of distinct head SHAs of the branch that have both a failure and a success run in `gh run list`.

A read whose gh call exits non-zero or prints invalid JSON prints `FAIL <read>: gh failed`. The other reads still run, and the exit code is 1.

A failing step prints `FAIL <step>: <first line of the git error>`, then `FAIL steps: stopped, later steps not run`. Nothing after it runs, and the exit code is 1.

The exit codes are 0 when every step and read is OK, 1 for a refusal, a failed step or a failed read, and 2 on a usage error. Branches are deleted with `branch -D` because a squash merge leaves the branch unmerged in git's view; the check has already compared the patches.

A re-run after a partial run reads the branch tip that still exists: the local branch without `-x`, or `origin/<branch>` with `-x`. The run deletes the local branch first and the branch on origin after it, and that push also removes `origin/<branch>`. So:

- While the tip exists, the re-run passes if the other checks pass, and it prints the absent and already gone lines for what the earlier run removed. Without `-x`, that is only a run that stopped before the local branch delete. With `-x`, it is a run that stopped before the origin delete, even after the local delete.
- Once the run has deleted the branch on origin, no tip remains. The check prints `FAIL patch: branch tip not found`, the re-run is refused (`FAIL steps: refused, close-out check failed`), and it changes nothing.

The `already gone` line for origin can also print on a first run: when the branch was removed on origin outside the run, the check still passes.

## What stays manual

- The lane_sum count (step 3) and the scorecard row (step 8), from `SCORECARD.md`.
- The checkbox tick of step 6. The script only reads the epic line.
- The reconcile of step 7, from `RECONCILE.md`.
- The ledger edit.
