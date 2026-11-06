# Moved Rationale

This file holds moved rationale and moved operative passages from `../SKILL.md`, and each heading says which kind it holds. Context and Forces pairs from five sections (Capacity and Launch have two each) are rationale, moved here word for word so SKILL.md stays under the 5,000-token limit, with one exception: the Capacity Forces line was reworded in the move. It said the story's "Files to Create/Modify" list "is the only advance signal of overlap"; it now says that list is an optional, informational field that never holds a launch, so file overlap is no reason to wait. The Launch question owner text section, at the end of this file, is also moved here word for word; the Launch question owner text was later reworded from file overlap to the Depends On dependency. It is an operative rule rather than a Context and Forces pair. Passages moved word for word from SKILL.md (operative passages) sit under headings that start with "Moved from SKILL.md:", except "Moved from SKILL.md: rationale", which holds the rationale clauses moved out of SKILL.md sentences, and the related skills and reference descriptions headings below it, which hold navigation (the Related Skills list and the reference descriptions), not a rule.

## Intake

**Context:** A story with no acceptance criteria reaches intake.
**Forces:** A runner that starts without criteria invents them, and the owner then reviews a PR built on criteria nobody agreed to. Holding back one story costs that story a delay; the other stories lose nothing.

## Capacity

**Context:** Two stories could touch the same file at the same time.
**Forces:** Parallel runners finish sooner, but two branches that edit one file conflict at merge, and the conflict costs a runner's whole fix cycle. The "Files to Create/Modify" list is an optional, informational field that never holds a launch, so file overlap is no reason to wait.

**Context:** The owner answers a launch question with a short "go".
**Forces:** A question that omits the counts makes the "go" an approval the launcher must interpret, and an over-limit launch then rests on the launcher's reading, not on the owner's decision. While N is below L the launch needs no named answer.

## Launch

**Context:** The launch prompt is where the launcher is tempted to add the rules.
**Forces:** The template already carries every rule, and a second copy in the prompt drifts from it, so the runner follows whichever it read last. An omitted `model` makes the runner inherit the launcher's tier.

**Context:** The launcher compacts or restarts mid-sprint.
**Forces:** The runners keep working while the launcher forgets, and a lost runner id means a runner nobody can resume. The plan file survives; the launcher's memory does not.

## Watch loop

**Context:** A hand-back reports green CI and clean counts.
**Forces:** A runner reads its own output and states it as fact; the launcher is the only party that can check it against the repository.

## Close-out

**Context:** The owner merged and the sprint feels finished.
**Forces:** Each step removes state the next one needs or could be mistaken for, so the order is fixed: the patch comparison needs the runner branch tip, and a deleted branch loses it. A skipped step leaves a stale branch, worktree or conflict that surfaces on a later merge.

## Launch question owner text

Note: "the rule below" in the paragraph that follows means the dependency paragraph in the Capacity section of `../SKILL.md`, which stayed in SKILL.md.

Every launch question to the owner states, for each story it names, "working N of L" (N the working runners counted from the ledger re-read this turn, L the limit now in force), "held for the owner M (open PRs)" (M the sprint stories held for the owner or with an open, unmerged pull request, each counted once), and the story's dependency under the rule below (the open story its Depends On line names, or "none"). A launch while N is at or above L happens only when the owner's answer names the new limit or names that over-limit launch for that story; "go", "launch it", silence and an answer to an intake gap do not. A named new limit is a ceiling, not a count of launches; record it in the ledger and state it as L in later questions.

## Moved from SKILL.md: launcher role

The launcher plans nothing itself: it launches runners, relays and verifies their hand-backs, and closes out each merge.

## Moved from SKILL.md: worktree

The launcher creates no worktree for a runner, because the runner creates the tree named by its own `WORKTREE_PREFIX`.

## Moved from SKILL.md: waiting stories

A story that is not yet running (waiting for a slot, waiting on a dependency, or held at intake) also gets an entry with its reason, because it has no runner and a reload would lose it.

## Moved from SKILL.md: reconcile state

State value `reconciling <merged PR number>` means a Reconcile text is out; a reconcile waiting to be sent (for the runner to hand back or for the owner to answer) is recorded in the pending question field as `reconcile pending after PR <merged PR number>`.

## Moved from SKILL.md: rationale

Each clause below was cut from the SKILL.md sentence named in its line, after the words given; the rule in that sentence stays in SKILL.md.

- Capacity, after "does not count": ", so the next story launches while the owner reviews"
- Launch, after "is true": ", so the launcher receives completion notices"
- Watch loop, after "(every skill the compaction hook lists)": ", so the launcher's rules are back before it acts"
- Close-out step 4, after "for a reconcile replacement": "; the squash leaves it unmerged in git's view"
- Close-out step 6, after "(unverified)": "; the shell-write guard denies a body file written inside the repository"

## Moved from SKILL.md: related skills

- `subagent-driven-development` -- Model Selection holds the tier table; the runner's children follow its dispatch rules
- `two-stage-review` -- the review stages and fix-round cap the runner runs
- `using-git-worktrees` -- every runner and child works in its own worktree
- `user-story-generator` -- the route for a story with no acceptance criteria
- `three-amigos` -- Discovery, which the runner runs for launched stories
- `session-bootstrap` -- the launcher re-invokes it alone when its gate prompts again

## Moved from SKILL.md: reference descriptions

- `references/HANDBACK_ROUTING.md` -- the 11-row routing table, required lines, size contract and resume texts
- `references/OWNER_QUESTIONS.md` -- the owner questions page: cards, layout, numbering, ledger fields, failure handling, worked example
- `references/RECONCILE.md` -- Close-out step 7: reconciling open sprint PRs after a merge
- `references/SCORECARD.md` -- predictions, measures, transcript audit, scorecard row
- `references/REHEARSAL.md` -- coordinator rehearsal, repeated when its template changes
- `references/MOVED_RATIONALE.md` -- moved pairs and passages, and the Launch question owner text section
- `references/PILOT.md` -- the pilot runner and its release rules
- `references/INDEX.md` -- index of the reference files
