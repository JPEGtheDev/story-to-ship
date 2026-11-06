# Owner questions page

This file defines the owner questions page: the one place where every question for the owner and every merge-ready PR waits during a sprint. The launcher reads this file whenever it adds, changes or removes a card or a Ready to merge entry, and whenever it compacts or restarts, so the page can be run from this file alone. The owner-reserved decisions (merge, fix-round cap override, scope change) and the routing of each hand-back kind stay in `HANDBACK_ROUTING.md`; this file says how a question or a merge-ready PR reaches the owner and how it is tracked until it is answered or merged.

**Context:** A runner hands back an owner question, a PR ready, a blocked or a cap reached hand-back while other runners are still working, and the owner is away from chat.
**Forces:** Questions scattered across chat messages get lost, answered twice, or answered out of order, while a single page the owner can open at any time keeps every open question in one place. The page must stay read-only for the owner so that every change to it passes through the launcher's checks.

## The page

- The page is one rolling, read-only page. The owner reads it and never edits it.
- Only the launcher writes the page, and only from runner hand-backs and from its own verified state. Runners never write it. Page content stays launcher-written, including when an answer arrives as a page comment.
- The owner answers a card by its number in chat, in the form "Q7 split", or by a comment on the card on the page. Both routes stay open.
- The page is republished in place after each change, so its address stays the same for the whole sprint.

## Which questions go on the page

Each of these question kinds gets a card:

- **owner question**: an owner question hand-back from a runner.
- **cap override**: a cap reached hand-back that needs the owner to continue, split, accept with a follow-up, or drop.
- **scope change**: a runner or the launcher needs a change to the work the story's acceptance criteria require (an acceptance criterion changed, or behavior the story does not name added). A file added for that work is not a scope change.
- **launch over the limit**: a launch the Capacity rules allow only when the owner names the new limit or that launch.
- **intake gap**: a story with no acceptance criteria, relayed under the intake rule.
- **blocked without criteria**: a blocked hand-back whose reason is a story with no acceptance criteria and that the owner must route.
- **reconcile question**: a reconcile that needs the owner's answer before it can run or finish.
- **pilot check card**: a card put on the page when a pilot runner's PR ready hand-back fails a launcher verification check or a required-line check, or any pilot hand-back that lacks a required line.

A merge-ready PR is a Ready to merge entry, not a card; see the Ready to merge section.

## Ready to merge

**Context:** A runner hands back a PR ready with nothing left for the owner to decide.
**Forces:** A merge card asks the owner to choose between merge and hold on a fact the launcher has already verified, while a statement costs the owner one line to read and keeps the cards for real decisions.

- **Placement.** The section has the heading "Ready to merge" and sits above the open question cards. Its entries are listed in the recommended merge order; the first entry is the PR next to merge.
- **Claim marks.** A card or Ready to merge entry keeps each runner claim's mark (`checked`, `shown by reading`, or `inferred`) and names the claims the launcher re-checked itself.
- **Entry.** One statement per merge-ready PR: the PR link, the story, one line on what the PR does, and the verification line. An entry has no question number, no options and no recommendation.
- **Position.** Each entry carries "Merge order: <n> of <N>" and one line of reason. The recommended order is: first, a PR whose story depends on an open story merges after that story's PR (the dependency rule); then, among the rest, the PR with the fewest changed files comes first (the fewest-files rule, counted from `gh pr diff <n> --name-only`). The reason line states which rule placed the entry, or that it is the only entry when N is 1. An entry waiting on a reconcile keeps its place in this order, and its reason line also carries the reconcile-pending reason.
- **Verification line.** One line, written by the launcher from its own `gh pr view <n> --json number,state,mergeable,headRefOid,statusCheckRollup,body` and its `gh pr view <n> --json isDraft`. It states the PR state, mergeable, the CI state on the head, whether the head equals the runner worktree head (`git -C <runner worktree> rev-parse HEAD` equals headRefOid), the closing keyword in the body, the footer in the body, that isDraft is false (the pull request is not a draft), the inline-edit comparison, and the reconcile checks in the PR ready row of `HANDBACK_ROUTING.md`.
- **Optional checks.** The inline-edit comparison applies only when the runner made inline commits. The reconcile checks apply only when a reconcile was queued or sent. Every other check is required.
- **Owner action.** The owner acts on an entry by saying "merged", either in chat or as a comment on the entry on the page. Entries have no number to answer by.
- **Stale.** Before each republish the launcher re-runs `gh pr view` for every entry. When CI is not green or the head differs from the head last checked, the entry is removed and returns only after the PR ready checks in `HANDBACK_ROUTING.md` pass again. The re-run includes `gh pr view <n> --json isDraft`. A pull request that is a draft again (isDraft true) is removed the same way.
- **Waiting.** A PR that also needs an owner decision (a scope change, a declined finding, a reconcile question) keeps a card for that decision only, and its entry is not on the page until the decision is made. A PR waiting on a reconcile keeps its entry and its place in the recommended order, marked with its reconcile-pending reason; a runner's PR ready hand-back is never held off the list by a queued reconcile, and the Reconcile text is sent when that PR is first. An entry's story counts as held for the owner, since it already has an open, unmerged PR.
- **Removal.** An entry is removed when the owner reports the merge and the Close-out section of `../SKILL.md` has run. Next to merge for the reconcile of a merged PR is the first entry on the list once the merged PR's entry is removed; the Close-out section removes the merged entry. The removal is a page change like any other: republish, re-read, one chat line, and it runs the merge-order rebuild under Editing the page.

## Card fields

Every card carries these fields, with these exact names:

- `number`: the card's question number, written as Q followed by the number (for example Q7).
- `story or topic`: the story number and a short name in words, or the topic in words when no story applies.
- `question`: the question itself, in one line.
- `options`: the answers the owner may give.
- `recommendation`: the runner's recommendation. For a question the launcher raises itself (a launch over the limit, an intake gap), the launcher's recommendation. Write "none given" when there is none.
- `status`: only when relevant, for example the CI state of a PR. Leave the field out when it does not apply.

Required: `number`, `story or topic`, `question`, `options` and `recommendation`. Optional: `status`.

A launch card also states, for each story it names:

- "working N of L", where N is the number of working runners counted from the ledger re-read this turn and L is the limit now in force.
- "held for the owner M (open PRs)", where M is the number of sprint stories held for the owner or with an open, unmerged PR, each counted once.
- The story's dependency: the story its "Depends On" line names that is still open, or "none".

**Context:** A card is a launch card or any other kind of question, and each kind carries a different set of required fields.
**Forces:** A launch card without its counts turns the owner's "go" into an approval the launcher has to interpret, while extra counts on any other card bury the one decision the owner has to make.

## Pilot check card

- **Fields.** A pilot check card carries the usual required fields. Its question names the pilot story and its pull request number when one exists, the failed launcher check, the missing required lines, or both, and the decision the owner needs. Its options are the owner's answers, and its recommendation is the launcher's.
- **Release.** The pilot line value that follows the owner's answer to a pilot check card is in the table in [PILOT.md](PILOT.md).
- **Removal.** The card is removed from the page when the owner's answer has been acted on, or when a later PR ready hand-back of the pilot passes its checks. The pilot line value that follows is in the table in [PILOT.md](PILOT.md). This overrides the rule below for this card kind.

## Context section

- The page has one context section per card, placed at the bottom of the page.
- The card's number links to its context section, and the section links back to the card.
- A context section carries the PR link, or the issue link when no PR exists yet.

## Layout

- A new page starts from `owner-questions-template.html` in this directory. When the template and the prose rules in this file differ, the prose rules govern.
- The Ready to merge section sits above the open question cards, and its entries are listed in the recommended merge order.
- Cards are listed newest first.
- A "waiting on runners, not you" list sits below the cards. It names each story whose runner is still working or whose launch waits on capacity or a dependency, with no question number, so the owner sees that nothing is needed from them.
- A card is removed once its question is answered and the answer is acted on. Removing it before the action is done is a defect.
- Question numbers start at Q1. The owner may ask for numbering to restart; when it does, the page says when numbering restarted, and the ledger records the restart and the highest number used since.
- The top of the page has two status lines, labeled Working and Needs you. Each element carries `data-status` with that label. Working holds a short count and summary of the runners at work. Needs you holds a short count and summary of what waits on the owner: the cards and the Ready to merge entries. These lines hold counts and summaries only; the "waiting on runners, not you" list names each story. The launcher replaces each line with the editor's `status` op (an operation of `page-edit.sh`, listed under Editing the page) after every change.
- Each Ready to merge entry carries `data-pr` with its pull request number, which the editor uses to find it. A page built before this template, without the `data-status` or `data-pr` markers, makes the `status` op fail with "label ... not found" and the `ready-remove` op fail with "pr ... not found" for an older entry. The launcher then starts a new page from the current template instead of editing an old page by hand.

## Editing the page

The launcher edits its local copy of the page file with this command:

`sh skills/running-a-sprint/scripts/page-edit.sh <op> <page file> <input file>`

The input file holds key=value lines, each split at its first "=". The input must use line feed line endings only: a carriage return (for example from a Windows line ending, carriage return then line feed) fails the op with `input has a carriage return`, and any other byte outside printable ASCII and tab fails with `input has a non-ASCII character`. After the edit, the launcher republishes and re-reads the page as Failure handling says. Publishing the page stays one call of the publishing tool, and the ledger stays an Edit-tool edit; the script does neither.

- `add-card`: keys `before` (the id of the card to go above), `card` (one line of HTML holding one id) and, optionally, `context` (one line of HTML). The new card goes directly above the named card, and its context section goes directly above the named card's context section. The script rejects a card with no id (`card has no id`), an empty id or more than one id. `context` is optional; when given, it holds exactly one id, and that id must be exactly `c-<card id>`. No id, an empty id, two or more ids or any other id fails with the page unchanged. The card id must not already be on the page, and when `context` is given the `c-<card id>` anchor must not be on it either. A card added without `context` has no context section, and `hide` still removes it (see `hide`).
- `hide`: key `hide`, repeatable, one card id each. Removes each named card and its context section. A block ends on the line that closes its opening element: the first later line equal to the opening line's indent plus its closing tag, or the opening line itself when it holds as many closing tags as opening tags. A card with no `c-<id>` line is removed alone, and the output prints `NOTE hide: <id> has no context section` after its OK line.
- `status`: keys `status` (the label, for example Working) and `text`. Replaces the text of the line that carries that `data-status` label with "label: text".
- `ready-add`: keys `pr` (digits only) and `entry` (one line of HTML). The new entry goes first in the Ready to merge list. The list is the first `ul` element after the line that holds `id="ready"`, whether it is written as `<ul>` or with attributes; the search stops at the first later line that holds `<section` or `<h2`, and with no list before that line the op fails with `no list after anchor ready`.
- `ready-remove`: key `pr`. Removes that pull request's Ready to merge entry.
- Merge-order rebuild: any `ready-add`, any `ready-remove` (including a stale removal and a merge removal) and any change of recommended order runs the full rebuild, because each change alters N, and n on the other entries. The rebuild renumbers every entry's "Merge order: <n> of <N>" line and its reason line, then makes one `ready-remove` for every entry on the list, then one `ready-add` for each entry in reverse recommended order (the last place first, the next-to-merge PR last). The chat line for that change names the count of `ready-remove` and `ready-add` calls.

Each run prints one OK line per op (for `hide`, one per distinct id), or one FAIL line; the one other line is `NOTE hide: <id> has no context section`, printed after the OK line of a card with no context section. Exit codes: 0 when all ops are OK, 1 on a FAIL, 2 on a usage error. When a required anchor (the `id` attribute value or `data-status` or `data-pr` attribute value the script finds a line by) is missing or occurs more than once, a key is missing, or the input has any character other than printable ASCII and tab, the script fails and leaves the page file byte-identical. Two anchors are exceptions: the `c-<id>` anchor of `hide` may be absent (see `hide`), and `ready-add` requires that the new `pr` is not already on the page. The launcher reads the FAIL line, fixes the input and runs the script again. It does not edit the page file by hand to get around a FAIL.

## Numbering restart

- A card that is open at the restart keeps its number, and a new card never takes a number held by an open card.

**Context:** The owner may restart numbering while cards are still open, and a restarted counter would otherwise reuse a number a card already shows.
**Forces:** Two cards with one number make "Q12 split" ambiguous, while keeping open numbers fixed costs only a gap in the sequence.

## Chat

- Each change to the page gets one chat line. An entry added to or removed from Ready to merge gets one chat line, which names the PR and the story.
- When a question is added, the chat line is the question number, the topic and a pointer to the page. The question text is not repeated in chat, except in the fallback under Failure handling.
- Removing a card after its answer is acted on is a change too, and gets one chat line that confirms the action.

## Ledger

The sprint ledger (the launcher's plan file, see the Launch section of `../SKILL.md`) holds:

- the page address,
- the name of the tool that publishes the page,
- the highest question number used so far,
- the numbering restart, when one has happened, and the highest question number used since it (after a restart this is the question counter),
- each Ready to merge entry's PR number with the head last checked, its merge order ("<n> of <N>") and its reason line, so a restarted launcher can rebuild the list and its order.

Each card's number is also recorded in the pending question field of the runner entry it belongs to, next to any reconcile entry that is already there.

If the question counter is missing from the ledger, the launcher takes the highest number on the page and in the pending question fields, and continues from the next number after it. When the ledger holds a restart record, the counter is the highest question number used since that record: the launcher takes the highest number that the page and the pending question fields hold for cards added since the restart (the page shows where numbering restarted), never counts a pre-restart number, and continues from the next number after it, skipping any number an open card holds.

**Context:** The launcher compacts or restarts while cards are open or entries are listed.
**Forces:** The page survives in the publishing tool and the ledger survives in the plan file, but the launcher's memory does not. The counter, the restart record and the pending question fields are the only record of which numbers are already used, and the entry list is the only record of which PRs are on the page.

## Failure handling

**Context:** The publishing tool is unavailable, a republish fails, or the page shows a different state from the one just published.
**Forces:** A question that exists only on a page the owner cannot reach is a question the owner never sees, while a question sent to chat in full is seen at once. Each failure needs a rule that keeps the questions visible.

- **No page yet.** The launcher publishes the first page with the tool named in the ledger. When the ledger names no tool, the launcher keeps the questions in chat and asks the owner for a tool.
- **Failed republish.** The question that could not be published goes to chat in full, with its number and the options. A Ready to merge entry that could not be published goes to chat in full as a statement: the PR link, the story, the line on what the PR does and the verification line. It stays in chat until the page works, and the launcher republishes the page before its next change.
- **Silent failure.** After each republish, the launcher re-reads the page and checks that the newest card number is on it and that the PR link of each added entry is on it. When the newest number or an added PR link is missing, the republish counts as failed. After a removal, it also checks that the removed card is gone and that the removed entry's PR link is gone.
- **Stale page.** The page carries a line "as of Q<n>", where n is the highest question number published on it since the last restart of numbering (the highest published number when numbering has not been restarted), so the owner can see how current it is.

## Comments

- The owner may answer a question in chat by its number, or in a comment on the card on the page. Both routes stay open.
- The page tells the owner to answer by card number in chat, or in a comment on the card's thread.
- The launcher reads the page's comments on each re-read, and when the owner says in chat that they commented.
- The launcher acts only on a comment the page tool attributes to the owner. A comment from anyone else is not an answer.
- After it acts on an owner comment, the launcher replies on the thread and resolves it. A comment on a Ready to merge entry that says "merged" is handled the same way.
- An answer given only outside chat and the page is never acted on.

**Context:** The owner may answer on the page as well as in chat, and a page comment does not always show who wrote it.
**Forces:** A comment from someone other than the owner must not count as a decision, while a comment the page tool attributes to the owner is as good as a chat answer. Acting on attributed comments directly saves the owner a message on every answer.

## Worked example

The values below run through the main steps of this file.

1. Runner for story 120 hands back "PR ready" with PR 131. The launcher re-runs `gh pr view` for PR 131 and confirms the PR is open and mergeable, the CI state on the head is green, and the head equals the runner worktree head. The runner made no inline commits, so the inline-edit comparison does not apply, and no reconcile was queued or sent.
2. The launcher adds a Ready to merge entry for PR 131: the PR link, "story 120, scope check of the new skill", one line on what the PR does, and the verification line "open, mergeable, CI green on head 9d41e7b, head equals runner worktree, closing keyword and footer present". The entry carries the line "Merge order: 1 of 1" and the reason "only entry on the list". The entry has no question number, no options and no recommendation.
3. Runner for story 124 hands back an owner question: the story covers two concerns. The launcher adds card Q7: story or topic "story 124, usage column in the ledger", question "split story 124 or keep it whole?", options "split" or "keep", recommendation "split", and a context section with the issue link, since no PR exists yet.
4. The launcher writes Q7 into the runner entry's pending question field, sets the ledger's highest question number to 7, and records PR 131 with head 9d41e7b, merge order 1 of 1 and its reason line in the ledger's entry list.
5. The launcher republishes the page, re-reads it, and finds Q7 as the newest card and the PR 131 link in Ready to merge.
6. Chat lines: "Ready to merge added: PR 131, story 120. See the page." and "Q7 added: story 124, usage column. See the page."
7. The owner replies in chat: "Q7 split".
8. The launcher runs the split, then removes card Q7 from the page, republishes the page, re-reads it, and sends the chat line "Q7 done: story 124 split, card removed."
9. The owner says "merged" for PR 131 in chat. The launcher runs the Close-out section of `../SKILL.md`, then removes the PR 131 entry from Ready to merge, republishes the page, re-reads it and checks that the PR 131 link is gone. Chat line: "Ready to merge removed: PR 131 merged, story 120." If the owner had said "merged" as a comment on the entry, the launcher would also reply on that thread and resolve it.
10. The next card the launcher adds is Q8, because Q7 is used and the counter stands at 7.

## Related

- [HANDBACK_ROUTING.md](HANDBACK_ROUTING.md) -- the hand-back kinds that produce these questions and entries, and the PR ready row that holds the PR ready checks and the reconcile checks
- [RECONCILE.md](RECONCILE.md) -- the reconcile of other open sprint PRs (Close-out step 7) that a PR waiting on a reconcile goes through before its entry is listed
- [SCORECARD.md](SCORECARD.md) -- the scorecard the ledger also holds
- [SKILL.md](../SKILL.md) -- the Capacity, Launch and Close-out sections this file relies on
