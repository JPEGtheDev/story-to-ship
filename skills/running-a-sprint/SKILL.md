---
name: running-a-sprint
description: Use when a launcher session must run a list of story issues through coordinator subagents; a coordinator subagent never loads this skill and never launches coordinators.
---

## Iron Law

```
YOU MUST LAUNCH ONE RUNNER PER STORY THAT HAS ACCEPTANCE CRITERIA, VERIFY EVERY HAND-BACK BEFORE RELAYING IT, AND DECIDE NOTHING FOR THE OWNER.
No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

**Announce at start:** "I am using the running-a-sprint skill to run a sprint of story issues through runners."

The launcher is the session that runs the sprint. A runner is a coordinator subagent (the `story-coordinator` template) that runs one story end to end, opens one pull request (PR) and hands it back unmerged. A hand-back is the runner's final message. The owner is the human. The launcher plans nothing itself: it launches runners, relays and verifies their hand-backs, and closes out each merge. A coordinator subagent never loads this skill and never launches coordinators; a coordinator that finds itself here STOPS and hands back.

---

## Intake

The stories come from an epic issue's checklist (if one exists). Read each story with `gh issue view <story> --json body` and look for its acceptance criteria.

**Context:** A story with no acceptance criteria reaches intake.
**Forces:** A runner that starts without criteria invents them, and the owner then reviews a PR built on criteria nobody agreed to. Holding back one story costs that story a delay; the other stories lose nothing.

A story with no acceptance criteria is NOT launched. Relay the gap to the owner with the recommendation to route the story through the `user-story-generator` skill, which validates it against INVEST (Independent, Negotiable, Valuable, Estimable, Small, Testable), and continue with the other stories. A runner never drafts acceptance criteria. The launcher does not run Discovery (the three-amigos requirements ceremony) for launched stories; the runner does.

---

## Capacity

Run at most 3 runners at once; the owner may change the number.

**Context:** Two stories could touch the same file at the same time.
**Forces:** Parallel runners finish sooner, but two branches that edit one file conflict at merge, and the conflict costs a runner's whole fix cycle. The "Files to Create/Modify" list in the story is the only advance signal of overlap.

A story whose "Files to Create/Modify" list overlaps a running story's list waits. When the list is absent, run that story alone. Stories that add a skill all edit the README and CONTRIBUTING count lines and their lists overlap, so the launcher runs them one at a time. A story counts as running, for capacity and overlap, until Close-out step 5 completes.

---

## Launch

Keep the sprint ledger (the launcher's record of every runner) in the launcher's plan file (plan.md at the top level of the main checkout). That file is untracked and never committed. Fields per runner: runner id, story, worktree prefix, branch, PR number, state, pending question. Before the first launch, copy the predictions from `references/SCORECARD.md` into the ledger. Re-read it after every reload and before every dispatch.

**Context:** The launcher compacts or restarts mid-sprint.
**Forces:** The runners keep working while the launcher forgets, and a lost runner id means a runner nobody can resume. The plan file survives; the launcher's memory does not.

Launch with one Agent call per story:

- `subagent_type` is `story-coordinator`.
- `model` is passed explicitly at the Standard tier; the Model Selection section of the `subagent-driven-development` skill holds the tier table and the model it names. Name no vendor model anywhere else.
- `run_in_background` is true, so the launcher receives completion notices. The runner's own children run in the foreground inside it.
- The prompt names `STORY_NUMBER = <n>; REPO_ROOT = <absolute main checkout path>; WORKTREE_PREFIX = <unique stem>` and the scope in one or two sentences. It carries NO rule text.

**Context:** The launch prompt is where the launcher is tempted to add the rules.
**Forces:** The template already carries every rule, and a second copy in the prompt drifts from it, so the runner follows whichever it read last. An omitted `model` makes the runner inherit the launcher's tier.

The launcher creates no worktree for a runner, because the runner creates the tree named by its own `WORKTREE_PREFIX`. Record the runner in the ledger at launch.

---

## Babysit loop

End the turn while runners work. When a hand-back or event arrives, look it up in `references/HANDBACK_ROUTING.md` and do what its row says. Never answer from memory.

Verify before relaying anything to the owner:

- Re-run `gh pr view <PR number> --json number,state,statusCheckRollup` and report the PR number and continuous integration (CI) state from that output, not from the hand-back.
- Compare the runner's inline-edit count (the number of lines it edited itself rather than through a child) with `git diff --numstat` of its inline commits against the lane entries in its plan file (its per-todo lane lines); `references/SCORECARD.md` carries the counting command. Report any mismatch.
- While a runner is live, run the child visibility count (`missing_children`) from `references/SCORECARD.md`.

**Context:** A hand-back reports green CI and clean counts.
**Forces:** A runner reads its own output and states it as fact; the launcher is the only party that can check it against the repository.

The owner decides three things: merge, fix-round cap override, scope change. The launcher never decides them, never merges, and never treats silence as consent.

When the session-bootstrap gate prompts again (after a compaction or restart has dropped the launcher's loaded skills), re-invoke session-bootstrap alone, then honesty, communication and the reload set (every skill the compaction hook lists), so the launcher's rules are back before it acts.

---

## Close-out

Run these in order after the owner says a PR is merged. Every git call is `git -C <absolute path>`; the main checkout (R below) stays on main.

1. Confirm the merge on origin: `gh pr view <PR number> --json state,mergeCommit` shows MERGED, and `git -C R fetch origin main` then `git -C R merge-base --is-ancestor S origin/main` exits 0 (S is the squash commit).
2. Compare patches (squash tree-equality; H is the runner branch tip): `B=$(git -C R merge-base S^ H); cmp <(git -C R diff $B H | grep -v '^index ') <(git -C R diff S^ S | grep -v '^index ')`. A difference goes to the owner; do not continue.
3. Read the lane entries and inline commit hashes from the runner's plan file and run the `lane_sum` count from `references/SCORECARD.md` before step 4 deletes the branch. Then remove the runner worktree (`git -C R worktree remove --force <path>` once `git -C <path> status --short` shows only the untracked plan file; anything else goes to the owner, and do not continue) and every `.worktrees/<prefix>-*` child worktree, orphaned child worktrees included (find them with `git -C R worktree list`).
4. Delete the branch locally (`git -C R branch -D <branch>`; the squash leaves it unmerged in git's view) and on origin with git push origin --delete <branch>, run through `git -C R`.
5. Fast-forward main: `git -C R merge --ff-only origin/main`.
6. When the story has an epic, tick its checkbox in the epic issue: change `- [ ]` to `- [x]` in its body and save it with `gh issue edit --body-file` (unverified).
7. Check every other open PR for mergeability (`gh pr view <PR number> --json mergeable`). For each PR that conflicts, resume its runner to fetch origin main and rebase, then send PR ready again.
8. Write the scorecard row from `references/SCORECARD.md` into the ledger and tell the owner.

**Context:** The owner merged and the sprint feels finished.
**Forces:** Each step removes state the next one needs or could be mistaken for, so the order is fixed: the patch comparison needs the runner branch tip, and a deleted branch loses it. A skipped step leaves a stale branch, worktree or conflict that surfaces on a later merge.

---

## BEFORE PROCEEDING

Before dispatching any runner, answering any hand-back, or closing out any merge:

1. The ledger was re-read this turn and the runner or story is in it.
2. A launch names `STORY_NUMBER`, `REPO_ROOT` and `WORKTREE_PREFIX`, passes `model` at the Standard tier, sets `run_in_background` true and carries no rule text; the story has acceptance criteria and no overlap with a running story.
3. A hand-back has been looked up in `references/HANDBACK_ROUTING.md`, the row's action is the only action taken, and the PR number and CI state were re-checked with `gh pr view`.
4. A close-out starts only after the owner reported the merge, and runs in the order of the Close-out section.

[+] All 4 met -> proceed
[-] Any unmet -> fix it first: re-read the ledger, look up the row, or relay the question to the owner

---

## Red Flags -- STOP

- About to launch a story with no acceptance criteria, or draft the criteria myself -- STOP. Relay the gap to the owner and route the story through `user-story-generator`.
- About to answer a runner's question, or a child's result, myself -- STOP. Look up the row in `references/HANDBACK_ROUTING.md`; owner-reserved questions go to the owner.
- About to merge, override the fix-round cap or change a story's scope -- STOP. These are the owner's: relay the question with the runner's recommendation and end the turn.
- About to relay a hand-back's PR number, CI state or edit count I did not re-check -- STOP. Run `gh pr view` and the numstat comparison first.
- About to launch a runner past the capacity limit, or one whose file list overlaps a running story's -- STOP. Wait for a runner to finish, or run it alone when the list is absent.
- About to close out before the owner reported the merge, or in a different order -- STOP. Confirm the merge on origin and follow the Close-out steps in order.
- About to put rule text, a vendor model name or a worktree path for the runner into the launch prompt -- STOP. Name the three inputs and the scope only.

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "The story is obvious; I will write its acceptance criteria and launch." | A runner and a launcher both inventing criteria is the failure intake exists to stop. Relay the gap and continue with the other stories. |
| "The runner's recommendation is clearly right; I will approve it." | The owner reserves merge, fix-round cap override and scope change. The recommendation goes to the owner, not past them. |
| "The hand-back says CI is green; re-running `gh pr view` is redundant." | The runner reports its own output. The launcher's check is the only independent one. |
| "A child's result arrived; I will answer the child and save a turn." | The result belongs to the runner's plan. Resume the runner with the child-result text and never act on it. |
| "The overlap is small; both stories can run at once." | Small overlaps still conflict at merge. Wait for the running story to finish. |
| "The PR merged, so the worktree and branch can wait." | A stale worktree or branch resurfaces as a failed merge or a wrong base later. Close out in order now. |
| "I already know the routing table; I will skip the lookup." | A row names what the launcher must NOT do, and memory drops those cells first. Look it up. |

---

## Related Skills

- `subagent-driven-development` -- Model Selection holds the tier table; the runner's children follow its dispatch rules
- `two-stage-review` -- the review stages and fix-round cap the runner runs
- `using-git-worktrees` -- every runner and child works in its own worktree
- `user-story-generator` -- the route for a story with no acceptance criteria
- `three-amigos` -- Discovery, which the runner runs for launched stories
- `session-bootstrap` -- the launcher re-invokes it alone when its gate prompts again

---

## References

- [references/HANDBACK_ROUTING.md](references/HANDBACK_ROUTING.md) -- the 11-row routing table, the required hand-back lines and the resume texts
- [references/SCORECARD.md](references/SCORECARD.md) -- predictions, measures with counting commands, subagent-transcript audit and the scorecard row
- [references/INDEX.md](references/INDEX.md) -- index of the reference files
