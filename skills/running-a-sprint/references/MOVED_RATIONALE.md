# Moved Rationale

Context and Forces pairs from five sections of `../SKILL.md` (Capacity and Launch have two each), moved here word for word so SKILL.md stays under the 5,000-token limit, with one exception: the Capacity Forces line was reworded in the move. It said the story's "Files to Create/Modify" list "is the only advance signal of overlap"; it now says that list is the primary signal and that, for a story with an open pull request, the files its pull request changes are a second. The Launch question owner text section, at the end of this file, is also moved here word for word; it is an operative rule rather than a Context and Forces pair.

## Intake

**Context:** A story with no acceptance criteria reaches intake.
**Forces:** A runner that starts without criteria invents them, and the owner then reviews a PR built on criteria nobody agreed to. Holding back one story costs that story a delay; the other stories lose nothing.

## Capacity

**Context:** Two stories could touch the same file at the same time.
**Forces:** Parallel runners finish sooner, but two branches that edit one file conflict at merge, and the conflict costs a runner's whole fix cycle. The "Files to Create/Modify" list in the story is the primary advance signal of overlap; for a story with an open pull request, the files its pull request changes are a second.

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
