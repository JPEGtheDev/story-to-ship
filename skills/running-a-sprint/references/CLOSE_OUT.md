# Close-out scripts

The steps are in `../../sprint-close-out/SKILL.md`. Two POSIX (Portable Operating System Interface) sh scripts in `../scripts/` run its steps 1 to 5 and the reads of step 6. The rules stay in SKILL.md, and the steps stay in the sprint-close-out skill; these scripts are the way to run its steps 1-5 and the reads of step 6. The lane_sum count and the scorecard row, the checkbox tick of step 6, the reconcile of step 7 and the ledger edit stay manual.

## closeout-check.sh (step 1, step 2 and the worktree part of step 3)

Run it with absolute paths from the launcher's session, with the working directory set to the repository root (the relative path below resolves only there):

`sh skills/running-a-sprint/scripts/closeout-check.sh -r <repo root> -n <PR number> -b <branch> -p <prefix> [-x <reconcile prefix>] [-P <plan file name>]`

- `-r` is the absolute path of the repository root. Trailing slashes are stripped; a relative path is a usage error (exit 2) before anything runs.
- `-n` is the pull request number.
- `-b` is the story branch name.
- `-p` is the runner worktree prefix. The runner worktree is `<root>/.worktrees/<prefix>`, and its children are the registered `<root>/.worktrees/<prefix>-*` worktrees.
- `-x` (optional) is the reconcile worktree prefix. The patch check then uses `origin/<branch>` as the branch tip, and the reconcile worktree and its children are checked too.
- `-P` (optional) is the plan file name a clean worktree may hold untracked at its top. The default is `plan.md`.

The check itself counts the parents of the pull request's merge commit S and prints the result as the `parents` line. `OK parents: <short sha> has 1 parent` is printed for one parent (a squash or a one-commit rebase). `FAIL parents: <short sha> has <n> parents; stop card for the owner.` is printed for two or more, and that stop card names step 1 of `../../sprint-close-out/SKILL.md`. `FAIL parents: cannot read the parent count of <short sha>; stop card for the owner.` is printed when git cannot read the count or the commit has no parent, and `FAIL parents: no merge commit` when the pull request has no merge commit. To read the count by hand, `gh pr view <PR number> --json mergeCommit` gives S, and `git -C <root> rev-list --parents -n 1 <S>` prints two fields for one parent and three fields for a merge commit.

The check prints one line per check, in this order:

1. `merged`: the PR state is MERGED and it has a merge commit (step 1). `FAIL merged: gh failed` when gh fails.
2. `NOTE fetch`: the fetch the check ran. It fetches origin main, and fetches the branch only when origin has it. This line is a note, not a check.
3. `ancestry`: the merge commit is in origin/main (step 1).
4. `parents`: the merge commit has one parent (step 1), with the lines described above.
5. `patch`: the squash diff equals the branch diff from the merge base (step 2).
6. `worktree`: each worktree is absent, or clean (only the plan file untracked), or it names each status line (step 3). An ignored file does not count: the check runs `git status --short`, the same status as step 3, which lists no ignored file, so an ignored file leaves the worktree clean.

Each check prints `OK <name>: <value>` or `FAIL <name>: <value>`. The exit codes are 0 when every line is OK, 1 when any line is FAIL, and 2 on a usage error (the usage message goes to stderr and nothing to stdout). The check changes no branch, worktree or file. Its fetch updates only remote-tracking refs.

## closeout-steps.sh (steps 3 to 5 and the reads of step 6)

Run `closeout-check.sh` first, with the same options. When every line is OK, read the plan file and run the lane_sum count (step 3 of `../../sprint-close-out/SKILL.md`), and only then run this script, whose worktree removal deletes the untracked plan file that holds the lane entries and the inline commit hashes. It takes the same options as the check, plus `-i <issue number>` (required) and `-e <epic issue number>` (optional). It runs in this order:

1. It runs closeout-check.sh with the same options and prints the check output unchanged. A FAIL line in the check, or a repo root that is not on main, refuses the run before any change: `FAIL steps: refused, close-out check failed`, or `FAIL steps: refused, repo root is on <branch>, not main` (a detached root HEAD is named "detached HEAD"). The exit code is 1.
2. Then the steps, one line each:
   - `remove-worktree`: the runner worktree, then its registered children in path order (with `-x`, the reconcile worktree and its children after them). `OK remove-worktree: <path>`, or `OK remove-worktree: <path> absent` when the directory is gone. Removal uses `git worktree remove --force`.
   - `delete-branch-local`: the branch, with `branch -D` (and `reconcile-<x>` with `-x`). `OK delete-branch-local: <branch>`, or `... already gone` when the branch does not exist.
   - `delete-branch-origin`: the branch on origin, probed with ls-remote. `OK delete-branch-origin: <branch>`, or `... already gone` when origin does not have it. Nothing is pushed with --force.
   - `fast-forward`: root main to origin/main with `--ff-only`. `OK fast-forward: main at <first 7 characters of the SHA>` (SHA: Secure Hash Algorithm, the commit hash that git prints).
3. Then three reads, one line each, in this order:
   - `issue`: `OK issue: #<issue number> <state>`.
   - `epic`, only with `-e`: the first line of the epic body that holds a checkbox (`- [x]`, `- [X]` or `- [ ]`) and names `#<issue number>` as a whole number prints `OK epic: #<epic> [x] #<issue>` or `[ ]`. When no such line exists it prints `FAIL epic: #<epic> has no line naming #<issue>`. The checkbox must start the line (after optional leading spaces), and the line counts only when the first `#<number>` after the checkbox is `#<issue>`. The script only reads this line; it does not tick it.
   - `flaky`: `OK flaky: <count>`, the number of distinct head SHAs of the branch that have both a run with the conclusion `failure` and a run with the conclusion `success` in `gh run list`; other conclusions, such as `startup_failure`, do not count.

A read whose gh call exits non-zero or prints invalid JSON prints `FAIL <read>: gh failed`. The other reads still run, and the exit code is 1.

A failing step prints `FAIL <step>: <first line of the git error>`, then `FAIL steps: stopped, later steps not run`. Nothing after it runs, and the exit code is 1.

The exit codes are 0 when every step and read is OK, 1 for a refusal, a failed step or a failed read, and 2 on a usage error. Branches are deleted with `branch -D` because a squash merge leaves the branch unmerged in git's view; the check has already compared the patches.

The run deletes the local branch first and the branch on origin after it, and that push also removes `origin/<branch>`. An unplanned re-run, one the launcher never ordered, would print the lines described below; none of them orders or permits running the script again. Without `-x` the remaining tip is the local branch, gone once the local delete has run; with `-x` it is `origin/<branch>`, gone once the origin delete has run.

A run that stops partway, a step that printed FAIL after earlier steps printed OK, is not re-run, and is not finished before the owner answers its stop card. Its close-out stop card names the failed step, as `../../sprint-close-out/SKILL.md` says. A run refused at the start, after a partial run, gets the same card.

After a partial run, the steps the script printed OK for are done, and the rest are `../../sprint-close-out/SKILL.md` step 4 (delete the branch locally and on origin), step 5 (fast-forward main) and step 6 (tick the epic checkbox), then the reads of step 6 (the issue state, the epic line and the flaky count). When `remove-worktree` is the step that failed, the rest of step 3 remains too: the runner and child worktrees not yet removed (with `-x`, the reconcile worktree and its children as well).

Once the tip is gone (without -x after the local delete, with -x after the origin delete), the check prints `FAIL patch: branch tip not found`, and the run is refused. With `-x`, once the origin delete has run, no tip remains: the check prints `FAIL patch: branch tip not found`, the run is refused (`FAIL steps: refused, close-out check failed`), and it changes nothing. A refused run prints the check's lines and the refusal line, and no step line: its `OK worktree: <path> absent` lines name what the earlier run removed, and no `already gone` line prints, because no step runs.

The root-not-on-main refusal is not a partial run: it exits before any step runs, so the launcher puts the root checkout back on main and runs the script again. That re-run applies only to a first run (no earlier run for this pull request printed a step line); a run that stopped partway is not re-run.

A FAIL on merged, ancestry or parents (step 1), patch (step 2) or worktree (step 3) goes to the owner as `../../sprint-close-out/SKILL.md` says.

The `already gone` line for origin can also print on a first run: when the branch was removed on origin outside the run, the check still passes.

## What stays manual

- The lane_sum count (step 3) and the scorecard row (step 8), from `SCORECARD.md`.
- The checkbox tick of step 6. The script only reads the epic line.
- The reconcile of step 7, from `RECONCILE.md`.
- The ledger edit.
- An unregistered directory under `<root>/.worktrees/` with a runner or reconcile prefix: the scripts list only registered worktrees, so the launcher finds such a directory by hand (for example with `ls`) and removes it by hand, as step 3 of `../../sprint-close-out/SKILL.md` says.
