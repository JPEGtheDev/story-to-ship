# Owner questions page

This file defines the owner questions page: the one place where every question for the owner waits during a sprint. The launcher reads this file whenever it adds, changes or removes a card, and whenever it compacts or restarts, so the page can be run from this file alone. The owner-reserved decisions (merge, fix-round cap override, scope change) and the routing of each hand-back kind stay in `HANDBACK_ROUTING.md`; this file says how a question reaches the owner and how it is tracked until it is answered.

**Context:** A runner hands back an owner question, a PR ready, a blocked or a cap reached hand-back while other runners are still working, and the owner is away from chat.
**Forces:** Questions scattered across chat messages get lost, answered twice, or answered out of order, while a single page the owner can open at any time keeps every open question in one place. The page must stay read-only for the owner so that every change to it passes through the launcher's checks.

## The page

- The page is one rolling, read-only page. The owner reads it and never edits it.
- Only the launcher writes the page, and only from runner hand-backs and from its own verified state. Runners never write it.
- The owner answers by card number in chat, in the form "Q7 merge". The page does not accept answers.
- The page is republished in place after each change, so its address stays the same for the whole sprint.

## Which questions go on the page

Each of these question kinds gets a card:

- **merge**: a PR ready hand-back whose PR the owner must merge or hold.
- **owner question**: an owner question hand-back from a runner.
- **cap override**: a cap reached hand-back that needs the owner to continue, split, accept with a follow-up, or drop.
- **scope change**: a runner or the launcher needs a change to a story's scope.
- **launch over the limit**: a launch the Capacity rules allow only when the owner names the new limit or that launch.
- **intake gap**: a story with no acceptance criteria, relayed under the intake rule.
- **blocked without criteria**: a blocked hand-back whose reason is a story with no acceptance criteria and that the owner must route.
- **reconcile question**: a reconcile that needs the owner's answer before it can run or finish.

## Card fields

Every card carries these fields, with these exact names:

- `number`: the card's question number, written as Q followed by the number (for example Q7).
- `story or topic`: the story number and a short name in words, or the topic in words when no story applies.
- `question`: the question itself, in one line.
- `options`: the answers the owner may give. A merge card's options are exactly merge or hold.
- `recommendation`: the runner's recommendation. For a question the launcher raises itself (a launch over the limit, an intake gap), the launcher's recommendation. Write "none given" when there is none.
- `status`: only when relevant, for example the CI state of a PR. Leave the field out when it does not apply.

Required: `number`, `story or topic`, `question`, `options` and `recommendation`. Optional: `status`.

A launch card also states, for each story it names:

- "working N of L", where N is the number of working runners counted from the ledger re-read this turn and L is the limit now in force.
- "held for the owner M (open PRs)", where M is the number of sprint stories held for the owner or with an open, unmerged PR, each counted once.
- The story's file overlap under the Capacity section of `../SKILL.md`: the working runner, held runner or open-PR story it overlaps, "none", or "list absent, run alone".

**Context:** A card is a merge card, a launch card, or any other kind of question, and each kind carries a different set of required fields.
**Forces:** A launch card without its counts turns the owner's "go" into an approval the launcher has to interpret, while a merge card with extra counts buries the one decision the owner has to make.

## Context section

- The page has one context section per card, placed at the bottom of the page.
- The card's number links to its context section, and the section links back to the card.
- A context section carries the PR link, or the issue link when no PR exists yet.

## Layout

- Cards are listed newest first.
- A "waiting on runners, not you" list sits below the cards. It names each story whose runner is still working or whose launch waits on capacity or overlap, with no question number, so the owner sees that nothing is needed from them.
- A card is removed once its question is answered and the answer is acted on. Removing it before the action is done is a defect.
- Question numbers start at Q1 and are never reused, even after a card is removed.

## Chat

- Each change to the page gets one chat line.
- When a question is added, the chat line is the question number, the topic and a pointer to the page. The question text is not repeated in chat, except in the fallback under Failure handling.
- Removing a card after its answer is acted on is a change too, and gets one chat line that confirms the action.

## Ledger

The sprint ledger (the launcher's plan file, see the Launch section of `../SKILL.md`) holds:

- the page address,
- the name of the tool that publishes the page,
- the highest question number used so far.

Each card's number is also recorded in the pending question field of the runner entry it belongs to, next to any reconcile entry that is already there.

If the question counter is missing from the ledger, the launcher takes the highest number on the page and in the pending question fields, and continues from the next number after it.

**Context:** The launcher compacts or restarts while cards are open.
**Forces:** The page survives in the publishing tool and the ledger survives in the plan file, but the launcher's memory does not. The counter and the pending question fields are the only record of which numbers are already used.

## Failure handling

**Context:** The publishing tool is unavailable, a republish fails, or the page shows a different state from the one just published.
**Forces:** A question that exists only on a page the owner cannot reach is a question the owner never sees, while a question sent to chat in full is seen at once. Each failure needs a rule that keeps the questions visible.

- **No page yet.** The launcher publishes the first page with the tool named in the ledger. When the ledger names no tool, the launcher keeps the questions in chat and asks the owner for a tool.
- **Failed republish.** The question that could not be published goes to chat in full, with its number and the options. It stays in chat until the page works, and the launcher republishes the page before its next change.
- **Silent failure.** After each republish, the launcher re-reads the page and checks that the newest card number is on it. When the newest number is missing, the republish counts as failed. After a removal, it also checks that the removed card is gone.
- **Stale page.** The page carries a line "as of Q<n>", where n is the highest question number published on it, so the owner can see how current it is.

## Comments

- Comments on the page may not reach the launcher session.
- The page tells the owner to answer in chat, by card number.
- The launcher reads a card's comment thread only when the owner says in chat that they answered there.
- The launcher then quotes the answer from the thread in chat and acts only after the owner replies in chat with the card number and the answer, for example "Q8 merge".
- An answer given only outside chat is never acted on.

**Context:** The owner answers on the page, where the launcher cannot see who wrote the comment.
**Forces:** A page comment alone does not show that the owner decided, while chat is the one channel the launcher can attribute to the owner. Quoting the answer back and waiting for the owner's reply costs one message and keeps every decision attributable.

## Worked example

The values below run through the main steps of this file.

1. Runner for story 120 hands back "PR ready" with PR 131. The launcher re-runs `gh pr view` for PR 131 and confirms the CI state is green.
2. The launcher adds card Q7 to the page: story or topic "story 120, scope check of the new skill", question "merge PR 131?", options "merge" or "hold", recommendation "merge", status "CI green", and a context section with the PR 131 link and no issue link, since a PR exists.
3. The launcher writes the card's number into the runner entry's pending question field and sets the ledger's highest question number to 7.
4. The launcher republishes the page, re-reads it, and finds Q7 as the newest card.
5. Chat line: "Q7 added: story 120, scope check of the new skill. See the page."
6. The owner replies in chat: "Q7 merge".
7. The owner merges PR 131 and says so in chat. The launcher runs the Close-out section of `../SKILL.md`, then removes card Q7 from the page, republishes the page, re-reads it, and sends the chat line "Q7 done: PR 131 merged, card removed."
8. The next card the launcher adds is Q8, because Q7 is used and the counter stands at 7.

## Related

- [HANDBACK_ROUTING.md](HANDBACK_ROUTING.md) -- the hand-back kinds that produce these questions
- [SCORECARD.md](SCORECARD.md) -- the scorecard the ledger also holds
- [SKILL.md](../SKILL.md) -- the Capacity, Launch and Close-out sections this file relies on
