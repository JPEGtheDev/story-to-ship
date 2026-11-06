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

The launcher is the session that runs the sprint. A runner is a coordinator subagent (the `story-coordinator` template) that runs one story end to end, opens one pull request (PR) and hands it back unmerged. A hand-back is the runner's final message. The owner is the human. See `references/MOVED_RATIONALE.md`, Moved from SKILL.md: launcher role, the launcher plans nothing itself. A coordinator subagent never loads this skill and never launches coordinators; a coordinator that finds itself here STOPS and hands back.

---

## Intake

The stories come from an epic issue's checklist (if one exists). Read each story with `gh issue view <story> --json body` and look for its acceptance criteria.

A story with no acceptance criteria is NOT launched. Relay the gap to the owner with the recommendation to route the story through the `user-story-generator` skill, which validates it against INVEST (Independent, Negotiable, Valuable, Estimable, Small, Testable), and continue with the other stories. The story stays held until the owner answers its gap; on the answer the launcher runs intake again at once and launches the story if capacity and overlap allow, otherwise it waits. A runner never drafts acceptance criteria. The launcher does not run Discovery (the three-amigos requirements ceremony) for launched stories; the runner does.

---

## Capacity

Launch a story only while fewer than 3 runners are working; the owner may change the number. A runner counts as working from launch, or from any resume, until it hands back a kind other than "interim"; a runner with no hand-back, including one killed by a rate limit, still counts. A runner that handed back "PR ready", "owner question", "blocked" or "cap reached" is held for the owner and does not count. A runner resumed for a fix round, an owner answer or a reconcile counts as working again. A reconcile replacement runner (Close-out step 7) is the one launch the limit and the overlap rule do not gate. The limit gates launches only: a resume is never deferred by the limit, so the working count can pass the limit, and no story launches until it is below the limit again, except on an owner answer that names the new limit or that launch under `references/MOVED_RATIONALE.md`, Launch question owner text. Once a hand-back of one of those four kinds has passed the checks in its row of the hand-back routing table (`references/HANDBACK_ROUTING.md`), required lines included, and before the turn ends (or once the pilot line is released), the launcher launches each waiting story that the limit and the overlap rule allow.

The pilot is the first runner a new launcher session launches: the first ready story in plan order that has acceptance criteria and no file overlap with a working runner.
No other story launches until the pilot hands back PR ready and that hand-back passes the checks in its row of the hand-back routing table (`references/HANDBACK_ROUTING.md`), required lines included. The other pilot rules and the release rules are in `references/PILOT.md`.

Every launch question to the owner follows the wording in `references/MOVED_RATIONALE.md`, section Launch question owner text.

A story whose "Files to Create/Modify" list overlaps the list of a working runner, of a runner held for the owner, or of a sprint story with an open, unmerged pull request waits; it launches at Close-out step 8 after that overlapping story's pull request merges. When the list is absent, run that story alone: it launches only when no other runner is working or held for the owner and no other sprint story has an open, unmerged pull request, and no other story launches until the pull request of the story run alone is merged. See `references/MOVED_RATIONALE.md`, Moved from SKILL.md: skill stories, run one at a time. See `references/MOVED_RATIONALE.md`, Moved from SKILL.md: overlap comparison, Files list plus pull request files. The Files list is an overlap signal only: a story's scope is the work its acceptance criteria require, not a list of files.

---

## Launch

Keep the sprint ledger (the launcher's record of every runner) in the launcher's plan file (plan.md at the top level of the main checkout). That file is untracked and never committed. Fields per runner: runner id, story, worktree prefix, branch, PR number, state, pending question. See `references/MOVED_RATIONALE.md`, Moved from SKILL.md: reconcile state, ledger state values. A story that is not yet running (waiting for a slot, waiting on an overlap, or held at intake) also gets an entry with its reason (`references/MOVED_RATIONALE.md`, Moved from SKILL.md: waiting stories, an entry with its reason). Before the first launch, copy the predictions from `references/SCORECARD.md` into the ledger. Re-read it after every reload and before every dispatch. The ledger also holds one pilot line (`references/PILOT.md`).

The owner questions page adds five ledger fields, including the Ready to merge entries (one statement per merge-ready PR); `references/OWNER_QUESTIONS.md` (Ledger) defines them.

Launch with one Agent call per story:

- `subagent_type` is `story-coordinator`.
- `model` is passed explicitly at the Standard tier; the Model Selection section of the `subagent-driven-development` skill holds the tier table and the model it names. Name no vendor model anywhere else.
- `run_in_background` is true. The runner's own children run in the foreground inside it.
- The prompt names `STORY_NUMBER = <n>; REPO_ROOT = <absolute main checkout path>; WORKTREE_PREFIX = <unique stem>` and the scope in one or two sentences. It carries NO rule text.
- The prompt also names `PARALLEL_LIMIT = <n>`, with n = floor((20 - L) / L), L being the sprint limit now in force and 20 the cap on subagents running at once in one session (L = 6 gives 2); a result below 1 is passed as 1.

See `references/MOVED_RATIONALE.md`, Moved from SKILL.md: worktree, the launcher creates no runner worktree. Record the runner in the ledger at launch.

---

## Watch loop

End the turn while runners work. Before the row lookup, every owner message, hand-back, restart or page comment runs a sweep: `gh pr view <PR number> --json state` for each open sprint PR in the ledger, and any PR origin shows MERGED is closed out, one at a time in ledger order, after any runner still on it finishes. When a hand-back or event arrives, look it up in `references/HANDBACK_ROUTING.md` and do what its row says. Never answer from memory.

An owner's "merged" message gets the same check and skips a PR whose state is `closed out` or `stopped`: MERGED on origin runs the close-out; OPEN or CLOSED runs nothing and the owner is told. A failed gh read is never a merge and waits for the next sweep. A sprint PR that origin shows CLOSED without a merge holds its runner and tells the owner. Squash is the only merge method the close-out accepts; a PR merged another way stops at step 1 or step 2 and goes to the owner. The pilot line release (`references/PILOT.md`) also runs on the sweep path.

The ledger keeps one state per PR: `closed out` when a close-out finishes, `stopped` when one stops. The sweep skips a PR whose state is `closed out` or `stopped`, so no close-out repeats. A stopped PR waits for the owner's answer to the stop, which decides the next step; when the owner's answer leads to the remaining steps being finished, the state becomes `closed out`.

Verify before relaying anything to the owner:

- Re-run `gh pr view <PR number> --json number,state,mergeable,headRefOid,statusCheckRollup` and report the PR number and continuous integration (CI) state from that output, not from the hand-back.
- Compare the runner's inline-edit count (the number of lines it edited itself rather than through a child) with `git diff --numstat` of its inline commits against the lane entries in its plan file (its per-todo lane lines); `references/SCORECARD.md` carries the counting command. Report any mismatch.
- While a runner is live, run the child visibility count (`missing_children`) from `references/SCORECARD.md`.
- For a PR ready hand-back, relay only its decision sentence (its kind line when it has none), plus the pull request number, CI state and review verdicts from your own `gh pr view`; never paste a hand-back body to the owner. An owner question, blocked or cap reached hand-back becomes a card on the owner questions page (`references/OWNER_QUESTIONS.md`), as its row in `references/HANDBACK_ROUTING.md` says. Read the hand-back's Detail target only when a decision needs it, and note an over-cap hand-back (Hand-back size contract in that file) in the ledger.
- Add every question for the owner to the owner questions page as a card: an owner question, a cap override, a scope change, a launch over the limit, an intake gap, a blocked-without-criteria question, a reconcile question, a pilot check card and a close-out stop card. A merge-ready PR is a Ready to merge entry on the same page, not a card (see `references/OWNER_QUESTIONS.md`). Only the launcher writes the page. Chat carries one line per change, plus a pointer to the page when a question is added. The card is the relay.

The owner decides three things: merge, fix-round cap override, scope change. A scope change is a change to the work the story's acceptance criteria require, such as changing an acceptance criterion or adding behavior the story does not name; a runner adding a file that work needs is not one and needs no owner question. The launcher never decides them, never merges, and never treats silence as consent.

When the session-bootstrap gate prompts again (after a compaction or restart has dropped the launcher's loaded skills), re-invoke session-bootstrap alone, then honesty, communication and the reload set (every skill the compaction hook lists).

---

## Close-out

Run these in order once origin shows the PR MERGED, whether the sweep or the owner's report found it. Every git call is `git -C <absolute path>`; the main checkout (R below) stays on main.

1. Confirm the merge on origin: `gh pr view <PR number> --json state,mergeCommit` shows MERGED, and `git -C R fetch origin main` then `git -C R merge-base --is-ancestor S origin/main` exits 0 (S is the squash commit). S has one parent (`git -C R rev-list --parents -n 1 S` shows two fields); a merge commit stops here.
2. Compare patches (squash tree-equality; H is the runner branch tip, or `origin/<branch>` after a fetch for a reconcile replacement): `B=$(git -C R merge-base S^ H); cmp <(git -C R diff $B H | grep -v '^index ') <(git -C R diff S^ S | grep -v '^index ')`. A difference goes to the owner; do not continue.
3. Read the lane entries and inline commit hashes from the runner's plan file and run the `lane_sum` count from `references/SCORECARD.md` before step 4 deletes the branch. Then remove the runner worktree (`git -C R worktree remove --force <path>` once `git -C <path> status --short` shows only the untracked plan file; anything else goes to the owner, and do not continue) and every `.worktrees/<prefix>-*` child worktree, orphaned child worktrees included; for a reconcile replacement do this for the dead runner's prefix and the fresh runner's prefix (find them with `git -C R worktree list`).
4. Delete the branch locally (`git -C R branch -D <branch>`, and `reconcile-<prefix>` for a reconcile replacement) and on origin with git push origin --delete <branch>, run through `git -C R`.
5. Fast-forward main: `git -C R merge --ff-only origin/main`.
6. When the story has an epic, tick its checkbox in the epic issue: change `- [ ]` to `- [x]` on the line naming this story's issue number and save the body with `gh issue edit <epic issue number> --body-file <file outside the repository>` (unverified).
7. Reconcile the other open sprint PRs against the merged change: follow `references/RECONCILE.md`, which holds all of step 7.
8. Write the scorecard row from `references/SCORECARD.md` into the ledger, with one `Reconciles:` entry for each Reconcile: line recorded in the runner's ledger entry, and tell the owner, naming the CI flaky and infra-killed counts only when they differ from the last row for that repository; run the auto-merge bar check at every close-out; report the trust number when the owner asks (`references/SCORECARD.md`, Trust number). Then run intake again on each held story whose gap the owner has answered, and launch every waiting story the Capacity rules now allow, and do the same when the pilot line is released.

A check that fails at a step stops there: the close-out stop card names the failed step, the PR's Ready to merge entry is removed, and nothing is re-run. A stop at step 1 or 2 leaves the branch and worktree in place; a stop at step 3 or later may not, and the card says what remains. A finished close-out gets one chat line to the owner and the same removal.

---

## BEFORE PROCEEDING

Before dispatching any runner, answering any hand-back, or closing out any merge:

1. The ledger was re-read this turn and the runner or story is in it.
2. A launch names `STORY_NUMBER`, `REPO_ROOT`, `WORKTREE_PREFIX` and `PARALLEL_LIMIT`, passes `model` at the Standard tier, sets `run_in_background` true and carries no rule text; the story has acceptance criteria and no overlap with a working runner, a runner held for the owner, or a sprint story with an open, unmerged pull request. A reconcile replacement is exempt from the overlap check (Close-out step 7). Until the pilot passes or a release rule in `references/PILOT.md` ends the hold, only the pilot launches.
3. A hand-back has been looked up in `references/HANDBACK_ROUTING.md`, the row's action, then, for a hand-back of one of the four kinds named in the Capacity section, the launch check, are the only actions taken, apart from the ledger note for an over-cap hand-back, and the PR number and CI state were re-checked with `gh pr view`.
4. A close-out starts only after origin shows the PR MERGED (by the sweep or an owner report), and runs in the order of the Close-out section.

[+] All 4 met -> proceed
[-] Any unmet -> fix it first: re-read the ledger, look up the row, or relay the question to the owner

---

## Red Flags -- STOP

- About to launch a story with no acceptance criteria, or draft the criteria myself -- STOP. Relay the gap to the owner and route the story through `user-story-generator`.
- About to answer a runner's question, or a child's result, myself -- STOP. Look up the row in `references/HANDBACK_ROUTING.md`; owner-reserved questions go to the owner.
- About to merge, override the fix-round cap or make a scope change (a change to an acceptance criterion or added behavior the story does not name) -- STOP. These are the owner's. For a merge, the owner decides from the Ready to merge entry and the launcher never merges; for a cap override or scope change, relay the question with the runner's recommendation and end the turn.
- About to relay a hand-back's PR number, CI state or edit count I did not re-check -- STOP. Run `gh pr view` and the numstat comparison first.
- About to launch a story while the working count is at or above the limit (3 unless the owner changed it), or one whose file list overlaps a working runner, a runner held for the owner, or a sprint story with an open, unmerged pull request -- STOP. Wait until the working count is below the limit (or an owner answer names the new limit or that launch, under the rule on launch questions in Capacity) or the overlapping story's pull request merges, or run it alone when the list is absent. A reconcile replacement (Close-out step 7) is exempt.
- About to launch a story while the working count is at or above the limit on a go that named neither the new limit nor that over-limit launch ("launch it", "go", a reply to a question that carried no counts, an intake-gap answer) -- STOP. Ask again with "working N of L", "held for the owner M (open PRs)" and the overlap, and launch only on an answer that names the new limit or that launch.
- About to close out before origin shows the PR MERGED, or in a different order -- STOP. Confirm the merge with `gh pr view` and follow the Close-out steps in order.
- About to resolve a reconcile conflict myself, merge a reconciled PR, or resume a runner held on an owner question, blocked or cap reached before the owner answers -- STOP. The runner resolves, the owner merges, and a held runner waits; check the PR state with `gh pr view` and the ledger state before acting.
- About to put rule text, a vendor model name or a worktree path for the runner into the launch prompt -- STOP. Name the four inputs and the scope only.
- About to launch a story while the pilot line is held or failed (released allows launches), other than the pilot itself, or about to release the hold by resuming the pilot alone -- STOP. The hold ends only by the release rules in `references/PILOT.md`; read the ledger's pilot line first.

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "The story is obvious; I will write its acceptance criteria and launch." | Invented criteria are the failure intake exists to stop. Relay the gap and continue with the other stories. |
| "The runner's recommendation is clearly right; I will approve it." | The owner reserves merge, fix-round cap override and scope change. The recommendation goes to the owner, not past them. |
| "The hand-back says CI is green; re-running `gh pr view` is redundant." | The runner reports its own output. The launcher's check is the only independent one. |
| "A child's result arrived; I will answer the child and save a turn." | The result belongs to the runner's plan. Resume the runner with the child-result text and never act on it. |
| "The overlap is small; both stories can run at once." | Small overlaps still conflict at merge. Wait until the overlapping story's pull request merges. |
| "The PR merged, so the worktree and branch can wait." | A stale worktree or branch resurfaces as a failed merge or a wrong base later. Close out in order now. |
| "The owner said go, so the over-limit launch is approved." | A go answers only the question asked. Only an answer that names the new limit or that launch passes the limit. |
| "I already know the routing table; I will skip the lookup." | A row names what the launcher must NOT do, and memory drops those cells first. Look it up. |

---

## Related Skills

Related skills: `references/MOVED_RATIONALE.md`, Moved from SKILL.md: related skills.

---

## References

- [references/HANDBACK_ROUTING.md](references/HANDBACK_ROUTING.md) -- the 11-row routing table, required lines, size contract and resume texts
- [references/OWNER_QUESTIONS.md](references/OWNER_QUESTIONS.md) -- the owner questions page: cards, layout, numbering, ledger fields, failure handling, worked example
- [references/RECONCILE.md](references/RECONCILE.md) -- Close-out step 7: reconciling open sprint PRs after a merge
- [references/SCORECARD.md](references/SCORECARD.md) -- predictions, measures, transcript audit, scorecard row
- [references/REHEARSAL.md](references/REHEARSAL.md) -- coordinator rehearsal, repeated when its template changes
- [references/MOVED_RATIONALE.md](references/MOVED_RATIONALE.md) -- moved pairs and passages, and the Launch question owner text section
- [references/PILOT.md](references/PILOT.md) -- the pilot runner and its release rules
- [references/INDEX.md](references/INDEX.md) -- index of the reference files
