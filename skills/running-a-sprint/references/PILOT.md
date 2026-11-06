# Pilot runner

**Context:** The launcher starts a sprint and its first runner may be a template or launch prompt nobody has run yet.
**Forces:** A flaw in that runner costs every runner in the sprint if the others launch at once, while a hold that never ends stalls the sprint.

This file holds the pilot rules moved from the Capacity section and the Launch section of `SKILL.md`. In the text below, "the others" are the stories held behind the pilot, and "the launch check of this section" is the sentence beginning "Once a hand-back of one of those four kinds has passed" in the Capacity section of `SKILL.md`.

A new launcher session is one whose ledger has no launched runner yet; the pilot's state lives in the ledger, so a compaction or restart does not reset it.

The ledger also holds one pilot line, "Pilot: <story> <passed, failed, held or released>", written when the pilot launches.

An owner question, blocked or cap reached hand-back keeps the others held, and so does an interim hand-back. A pilot stopped by a usage limit, or never resumed, keeps the others held until it is resumed and hands back. A PR ready hand-back that is still a draft does not pass; the hold waits for a later PR ready hand-back with the draft flag off. The owner's answer to a pilot question is not a pass; the pilot must hand back again and pass. A pilot PR ready hand-back that fails a required-line check or a launcher check: no other story launches, and the failure goes on the owner questions page as a card. The table in "Pilot line changes" gives the pilot line's value after each hand-back and event. A hand-back over the cap is not a missing line and still passes. The pilot PR does not have to merge first. The hold covers only the session's launches until the pilot passes or a release rule in this file ends it: a reconcile replacement, an owner-answer launch and a launch after a merge also wait until then. After the pilot passes, every launch follows the Capacity rules. The pilot's result in the ledger is one of passed, failed, held or released. The launch check of this section (the sentence beginning "Once a hand-back of one of those four kinds has passed") is the step that launches the waiting stories after the pilot passes.

The pilot hold also ends when the owner drops the pilot story (the cap reached option) or merges it while its pilot line reads failed. After a failed launcher check, the hold ends when the owner answers that check's card. A resume alone releases nothing. A fresh runner that starts after a Discovery stop of the pilot (owner question row of HANDBACK_ROUTING.md) keeps the hold the same way a resume does and changes no pilot line value.

A failed launcher check governs a hand-back that also lacks a required line: the launcher adds a card that lists the missing lines and does not resume the pilot. A missing required line on a hand-back that passes every launcher check keeps its ruling: the launcher resumes with the missing-line text and also adds a card.

## Pilot line changes

This table is the one place the pilot line's changes are written. A launcher check is every check the PR ready row of `HANDBACK_ROUTING.md` runs except the Required lines list; a required-line check is a check against that list. The first row that matches the pilot line's current value and the event sets the new value; an event that no row names leaves the pilot line unchanged.

| current value | event | new value |
|---|---|---|
| no pilot line yet | the pilot launches | held |
| held, failed or released | a PR ready hand-back that is not a draft, passes every launcher check and fails only the required-line check | failed |
| held, failed or released | a PR ready hand-back that is not a draft and fails a launcher check, with or without missing required lines | failed |
| held, failed or released | a PR ready hand-back that is not a draft, passes every launcher check and passes every required-line check | passed; only this event writes passed from held, failed or released |
| passed | any event, including a drop, a merge and a hand-back that fails a check | passed; passed is final for the session, and every launch follows the Capacity rules |
| failed | the owner answers the card for a failed launcher check | released; a resume alone does not release |
| failed | the owner answers a card for missing required lines only; the answer is not a pass | failed; the pilot must hand back again and pass, and only a PR ready hand-back that passes writes passed |
| held or failed | the owner drops the pilot story (the cap reached option) | released |
| failed | the owner merges the pilot story | released |
| held | an owner question, blocked or cap reached hand-back from the pilot | held; the answer to it is not a pass |
| held, failed, passed or released | a PR ready hand-back that is a draft | unchanged |
| held, failed, passed or released | an interim, killed or usage-limit stop, and any other hand-back not named above | unchanged |
