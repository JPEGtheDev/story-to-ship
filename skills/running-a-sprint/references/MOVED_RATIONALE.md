# Moved Rationale

The Context and Forces blocks of four sections of `../SKILL.md`, moved here word for word so SKILL.md stays under the 5,000-token limit, with one exception: the Capacity Forces line was reworded in the move. It said the story's "Files to Create/Modify" list "is the only advance signal of overlap"; it now says that list is the primary signal and that, for a story with an open pull request, the files its pull request changes are a second.

## Capacity

**Context:** Two stories could touch the same file at the same time.
**Forces:** Parallel runners finish sooner, but two branches that edit one file conflict at merge, and the conflict costs a runner's whole fix cycle. The "Files to Create/Modify" list in the story is the primary advance signal of overlap; for a story with an open pull request, the files its pull request changes are a second.

## Launch

**Context:** The launch prompt is where the launcher is tempted to add the rules.
**Forces:** The template already carries every rule, and a second copy in the prompt drifts from it, so the runner follows whichever it read last. An omitted `model` makes the runner inherit the launcher's tier.

## Watch loop

**Context:** A hand-back reports green CI and clean counts.
**Forces:** A runner reads its own output and states it as fact; the launcher is the only party that can check it against the repository.

## Close-out

**Context:** The owner merged and the sprint feels finished.
**Forces:** Each step removes state the next one needs or could be mistaken for, so the order is fixed: the patch comparison needs the runner branch tip, and a deleted branch loses it. A skipped step leaves a stale branch, worktree or conflict that surfaces on a later merge.
