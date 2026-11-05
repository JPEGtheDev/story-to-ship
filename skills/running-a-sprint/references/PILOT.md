# Pilot runner

**Context:** The launcher starts a sprint and its first runner may be a template or launch prompt nobody has run yet.
**Forces:** A flaw in that runner costs every runner in the sprint if the others launch at once, while a hold that never ends stalls the sprint.

This file holds the pilot rules moved from the Capacity section and the Launch section of `SKILL.md`. In the text below, "those checks" are the hand-back row checks and required-line checks in `references/HANDBACK_ROUTING.md`, "the others" are the stories held behind the pilot, and "the launch check of this section" is the sentence beginning "Once a hand-back of one of those four kinds has passed" in the Capacity section of `SKILL.md`.

A new launcher session is one whose ledger has no launched runner yet; the pilot's state lives in the ledger, so a compaction or restart does not reset it.

The ledger also holds one pilot line, "Pilot: <story> <passed, failed, held or released>", written when the pilot launches.

Only a PR ready hand-back that passes those checks passes the pilot; an owner question, blocked or cap reached hand-back keeps the others held, and so does an interim hand-back. A pilot stopped by a usage limit, or never resumed, keeps the others held until it is resumed and hands back. A PR ready hand-back that is still a draft does not pass; the hold waits for a later PR ready hand-back with the draft flag off. The owner's answer to a pilot question is not a pass; the pilot must hand back again and pass. A pilot PR ready hand-back that fails a required-line check or a launcher verification check: no other story launches, the failure goes on the owner questions page as a card, and the ledger's pilot result is failed until the owner answers that card (released) or a later hand-back passes. A hand-back over the cap is not a missing line and still passes. The pilot PR does not have to merge first. The hold covers only the session's launches until the pilot passes or a release rule in this file ends it: a reconcile replacement, an owner-answer launch and a launch after a merge also wait until then. After the pilot passes, every launch follows the Capacity rules. The pilot's result in the ledger is one of passed, failed, held or released. The launch check of this section (the sentence beginning "Once a hand-back of one of those four kinds has passed") is the step that launches the waiting stories after the pilot passes.

The pilot hold also ends when the owner drops the pilot story (the cap reached option) or merges it while its pilot line reads failed. After a failed launcher verification check, the hold ends when the owner answers that check's card, and the pilot line then reads released. A resume alone releases nothing.

A failed launcher verification check governs a hand-back that also lacks a required line: the launcher adds a card that lists the missing lines and does not resume the pilot. A missing required line on a hand-back that passes every launcher verification check keeps its ruling: the launcher resumes with the missing-line text and also adds a card.

Only a PR ready hand-back changes passed or failed on the pilot line; the owner's answer to a failed launcher-check card changes failed to released, and a later PR ready hand-back of the pilot replaces released. Owner question, blocked, cap reached, interim, draft and killed hand-backs leave the pilot line unchanged.

The pilot line starts as "held" when the pilot launches.
