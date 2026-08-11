---
name: defining-done
license: MIT
description: Use when ratifying or re-ratifying a repo's Definition of Done canon.
---

## Iron Law

```
YOU MUST ELICIT EVERY LAYER'S RULING FROM THE PRODUCT OWNER AND WRITE NOTHING BEFORE FINAL RATIFICATION.
No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

**Announce at start:** "I am using the defining-done skill to [ratify/re-ratify] this repo's Definition of Done canon."

---

## BEFORE PROCEEDING

1. `references/DOD_TAXONOMY.md` and `references/DOD_TEMPLATE.md` exist and parse (20 layers across 5 groups; the three ruling-line forms and the A15 write order are defined).
   [+] -> proceed
   [-] -> STOP. Do not run the interview against an unreadable taxonomy or template.
2. The product owner is present in this conversation and answering directly -- not a proxy, not inferred from prior text or other docs.
   [+] -> proceed
   [-] -> STOP. This skill requires a live owner exchange.
3. Check for an existing `docs/DOD.md`.
   [+] absent -> proceed with the fresh interview below
   [-] present -> STOP. A canon already exists; this is a re-ratification. Delta mode (loaded separately) handles it -- do not run the fresh group-by-group interview over an existing canon.

[+] All met -> proceed
[-] Any unmet -> resolve the failing condition's action above first

---

## Interview Procedure

Walk `references/DOD_TAXONOMY.md`'s 5 groups IN ORDER: Acceptance & Traceability, Test-Suite Integrity, Non-Functional Verification, Process & Static Gates, Release Readiness. One group at a time, in conversational prose -- never a form dump.

Within a group, one layer at a time:
1. Present the layer as INFORMATION ONLY: its name, Key, group, Verifies text, and example checkable triggers, verbatim from the taxonomy.
2. Ask the owner to rule it: ALWAYS, CONDITIONAL with a trigger, or N/A with a category.
3. NEVER pre-fill a ruling, suggest one as a default, or skip a layer -- silence is not a ruling. All 20 layers get an explicit owner ruling every interview.

**Checkability re-elicitation loop:** a CONDITIONAL ruling's trigger MUST be an objectively checkable predicate -- mechanically evaluable from a diff's changed-file list or content (path globs, file-type conditions, diff-content conditions). If the owner's proposed trigger is not checkable, explain why in plain terms and re-elicit.

> Context: every CONDITIONAL ruling, at first proposal and at each re-elicitation.
> Forces: a subjective trigger ("when it feels risky") is unusable by a mechanical gate later, but owners default to judgment-call language and endless refusal stalls the interview.
> Solution: re-elicit up to 3 attempts. On the 3rd failure, offer a binary choice: rule the layer ALWAYS, or N/A category `repo-ruled-N/A`. No default between the two. Never attempt a 4th trigger.
> Consequences: an owner who cannot state a checkable trigger loses the CONDITIONAL option -- an unenforceable trigger is worse than none.

**N/A category rule:** an N/A ruling MUST carry one of the three closed categories -- `target-absent`, `covered-elsewhere`, or `repo-ruled-N/A` -- plus optional free-text elaboration. Free-text-only rationale with no category is invalid; re-ask until a category is given.

---

## Canary

Before opening the final ratification pass, state the literal line:

`RULINGS ELICITED: 20/20, DEFAULTS USED: 0`

This must appear once, immediately before presenting the complete ruling set back to the owner. It proves every layer got an explicit ruling this pass; it does NOT prove any individual ruling is well-reasoned or that a CONDITIONAL trigger is actually checkable -- those are separate rules above.

---

## Ratification Pass

After all 5 groups: present the complete ruling set back to the owner in `DOD_TEMPLATE.md`'s index-line format (one line per layer), as one full review. The owner may amend any ruling; amendments re-run the checkability loop and N/A category rule above. Only explicit owner ratification of the full set triggers the write step. No amendment shortcuts a rule already stated above.

---

## Write Step (single, atomic, ratification-only)

> Context: once only, after the owner ratifies the complete ruling set. Never mid-interview -- not for "obviously final" partial answers, not to save state for a later resume.
> Forces: incremental writes let a partial, unratified ruling set leak onto disk as if it were canon; but holding everything only in conversation risks loss if the session ends first.
> Solution: `mkdir -p docs/` (and `docs/dod/<group-slug>/` per the template's group-slug transform, as needed), then write in exactly this order: detail files (only for layers whose elaboration needs one) -> `docs/DOD.md` -> `docs/INDEX.md` row for DOD.md. Formats per `references/DOD_TEMPLATE.md` exactly: cross-cutting frontmatter, ruling lines, `Stamp: vN` from the taxonomy's current stamp, and a `Content-hash:` line per `DOD_TEMPLATE.md` Section A.4 -- this skill defers the hash's computation to its delta/hash-mode addition; write the line's presence here, not its computed value.
> Consequences: an interruption between `docs/DOD.md` and `docs/INDEX.md` leaves a live canon with a stale index (inert catalog gap, not a live-canon defect); an interruption before `docs/DOD.md` leaves no canon at all -- the abandonment case below.

**Abandonment:** if the interview ends, is interrupted, or the owner stops before the ratification pass completes, NO file is created or modified. Nothing is written before the write step above -- there is no partial canon and no scratch canon file. Holding the ruling set in conversation is the only intermediate state.

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "The owner is busy, I'll fill the obvious rulings" | Every ruling comes from the owner. Filling one, however obvious, violates the Iron Law -- ask, wait, record. |
| "19 of 20 layers are ruled, I'll infer the last one" | 20/20 means 20 explicit owner rulings, not 19 plus an inference. Ask the 20th. |
| "This trigger is close enough to checkable" | Close-enough triggers fail silently at the consumer. Re-elicit, or fall back to the bounded ALWAYS/N/A choice. |
| "I'll write DOD.md incrementally as we go, it saves a step later" | Incremental writes create a partial canon on disk before ratification. Write nothing until the single atomic write step. |
| "A scratch file isn't really the canon, so drafting one is fine" | Any file on disk before ratification IS a canon artifact to anything that reads `docs/`. No scratch files, ever. |
| "The owner gave a reason for N/A, that's enough" | A reason is not a category. Re-ask until one of the three closed categories is named. |
| "We're on attempt 4 of the trigger, one more phrasing might land" | The loop is bounded at 3. Offer the binary choice now -- ALWAYS or N/A repo-ruled -- never a 4th attempt. |

---

## Red Flags -- STOP

- About to suggest a ruling before the owner states one -- STOP. Present the layer as information, then wait for the owner's ruling.
- A layer got skipped because it "obviously doesn't apply" -- STOP. N/A still requires an explicit owner ruling and a closed category.
- About to write any file before the ratification pass -- STOP. Nothing is written before the single atomic write step.
- A proposed trigger is a judgment call ("when it matters", "if it seems risky") -- STOP. Re-elicit; it is not mechanically checkable.
- Past 3 failed trigger attempts and still drafting a new phrasing -- STOP. Offer the bounded ALWAYS/N/A choice now.
- N/A ruling given with only free text, no category tag -- STOP. Re-ask for one of the three closed categories.
- Interview interrupted and a partial DOD.md or detail file already exists -- STOP. This skill's design makes that state impossible; do not compound it by continuing the write.

---

## Related Skills

`user-story-generator`, `verification-before-completion`, and `greenfield-discovery` are this canon's consumers -- each is wired to read and act on `docs/DOD.md` by its own separate implementation work, not by this skill. `documentation` owns the `docs/INDEX.md` and cross-cutting frontmatter conventions this skill's write step follows.

---

## References

- `references/DOD_TAXONOMY.md` -- the 20-layer, 5-group taxonomy this interview walks.
- `references/DOD_TEMPLATE.md` -- the canon index and detail-file authoring template this interview's write step produces output against.
- `references/INDEX.md` -- this skill's reference-file catalog.
