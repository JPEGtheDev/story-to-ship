---
name: sprint-close-out
description: Use when origin shows a sprint pull request MERGED and the launcher runs its close-out, whether the sweep or the owner's report found it. Not for a coordinator subagent.
---

## Iron Law

```
A SPRINT PULL REQUEST IS CLOSED OUT ONLY AFTER ORIGIN SHOWS IT MERGED, AND ITS STEPS RUN IN ORDER
YOU MUST confirm the merge on origin and follow the steps in order. No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

**Announce at start:** "I am using the sprint-close-out skill to close out PR [number]."

## BEFORE PROCEEDING

1. Origin shows the pull request MERGED (checked with gh pr view in this turn). [+] go to the steps. [-] stop; run nothing.
2. The steps below run in order and none is skipped. [+] proceed. [-] stop at the missing step.
3. A failed step stops the close-out and is reported as the step text says. [+] report it. [-] keep going.

## Red Flags -- STOP

- About to close out before origin shows the pull request MERGED -- STOP. Confirm with gh pr view first.
- About to delete a branch before the lane entries are counted -- STOP. Read the plan file and run the lane count first (step 3).
- Continuing past a failed step to save time -- STOP. A failed step stops the close-out; the stop card names the step.
- Treating a merge reported only in chat as MERGED -- STOP. Read origin with gh before any step.
- Skipping the reconcile of the other open sprint pull requests because they look clean -- STOP. Step 7 runs for each one; follow ../running-a-sprint/references/RECONCILE.md through the path in step 7.

## Rationalization Prevention

| Excuse | Reality | Correct action |
|--------|---------|----------------|
| "The owner's message says it merged, so origin does not need checking" | The owner's message is not the record; origin is. | Run gh pr view and read MERGED. |
| "The patch comparison is a formality after a squash" | A squash can hide a difference between the branch and main. | Run step 2 and read the output. |
| "Deleting the branch first saves a step" | Step 3 reads the branch before step 4 deletes it. | Keep the step order. |
| "A failed step can be re-run quietly" | The close-out stop card is how the owner learns a step failed. | Stop and write the card. |
| "The scorecard row can wait for the next close-out" | Step 8 runs at every close-out, and the trust number needs each row. | Write the row now. |

## Close-out steps
R is the main checkout (the repo root); S is the squash commit of the merged pull request.

Run these in order once origin shows the PR MERGED, whether the sweep or the owner's report found it. Every git call is `git -C <absolute path>`; the main checkout (R below) stays on main.

1. Confirm the merge on origin: `gh pr view <PR number> --json state,mergeCommit` shows MERGED, and `git -C R fetch origin main` then `git -C R merge-base --is-ancestor S origin/main` exits 0 (S is the squash commit). S has one parent (`git -C R rev-list --parents -n 1 S` shows two fields); a merge commit stops here.
2. Compare patches (squash tree-equality; H is the runner branch tip, or `origin/<branch>` after a fetch for a reconcile replacement): `B=$(git -C R merge-base S^ H); cmp <(git -C R diff $B H | grep -v '^index ') <(git -C R diff S^ S | grep -v '^index ')`. A difference goes to the owner; do not continue.
3. Read the lane entries and inline commit hashes from the runner's plan file and run the `lane_sum` count from `../running-a-sprint/references/SCORECARD.md` before step 4 deletes the branch. Then remove the runner worktree (`git -C R worktree remove --force <path>` once `git -C <path> status --short` shows only the untracked plan file; anything else goes to the owner, and do not continue) and every `.worktrees/<prefix>-*` child worktree, orphaned ones included; for a reconcile replacement do this for the dead runner's prefix and the fresh runner's prefix (find them with `git -C R worktree list`).
4. Delete the branch locally (`git -C R branch -D <branch>`, and `reconcile-<prefix>` for a reconcile replacement) and on origin with git push origin --delete <branch>, run through `git -C R`.
5. Fast-forward main: `git -C R merge --ff-only origin/main`.
6. When the story has an epic, tick its checkbox in the epic issue: change `- [ ]` to `- [x]` on the line naming this story's issue number and save the body with `gh issue edit <epic issue number> --body-file <file outside the repository>` (unverified).
7. Reconcile the PR next to merge against the merged change; the other open sprint PRs wait until they become next; follow `../running-a-sprint/references/RECONCILE.md`, which holds all of step 7.
8. Write the scorecard row from `../running-a-sprint/references/SCORECARD.md` into the ledger, with one `Reconciles:` entry for each Reconcile: line recorded in the runner's ledger entry, and tell the owner, naming the CI flaky and infra-killed counts only when they differ from the last row for that repository; run the auto-merge bar check at every close-out; report the trust number when the owner asks (`../running-a-sprint/references/SCORECARD.md`, Trust number). Then rerun intake on each held story whose gap the owner has answered, launch every waiting story the Capacity rules now allow, and do the same when the pilot line is released. A held story whose "Depends On" line named the merged story launches here, under the Capacity rule.

A check that fails at a step stops there: the close-out stop card names the failed step, the PR's Ready to merge entry is removed, and nothing is re-run. A stop at step 1 or 2 leaves the branch and worktree in place; a stop at step 3 or later may not, and the card says what remains. A finished close-out gets one chat line to the owner and the same removal.
