---
name: dod-canon-check
license: MIT
description: Use when a completion claim is about to be made in a repo that has a ratified Definition of Done canon at docs/DOD.md.
---

## Iron Law

```
YOU MUST NOT PASS A COMPLETION CLAIM IN A REPO WITH docs/DOD.md WITHOUT INLINE EVIDENCE
FOR EVERY ALWAYS LAYER (UNLESS A VALID CATEGORY-TAGGED N/A LINE COVERS IT) AND FOR EVERY
CONDITIONAL LAYER WHOSE TRIGGER FIRED. A CANON THAT CANNOT BE PARSED REFUSES THE CLAIM.
No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

**Announce at start:** "I am using the dod-canon-check skill to check [claim] against the Definition of Done canon before it is made."

---

## BEFORE PROCEEDING

1. `docs/DOD.md` exists in the repo under evaluation.
   [+] -> proceed
   [-] -> This skill does not apply. Say so in one sentence, stop, and let the generic rules of the verification-before-completion skill govern the claim.
2. `docs/DOD.md` parses (see the Solution below for the malformed-canon refusal).
   [+] -> proceed
   [-] -> REFUSE to evaluate the claim and name exactly what failed to parse, as the Solution below states.
3. The canon's git state is read (see the Solution below for the uncommitted and untracked cases).
   [+] -> proceed
   [-] -> Read it now; do not evaluate the claim on an unread git state.
4. The canon's `Stamp:` value is compared with the current taxonomy stamp (see the Solution below).
   [+] -> proceed
   [-] -> Compare it now; do not evaluate the claim on an uncompared stamp.

[+] All met -> evaluate the claim as the section below states
[-] Any unmet -> resolve the failing condition's action above first

---

## New Gates: Definition of Done (DoD) Canon Check on Completion Claims

**Context:** Applies to every completion claim made in a repo that has a ratified Definition of Done (DoD) canon at `docs/DOD.md`, as produced by the `defining-done` skill's ratification interview. If `docs/DOD.md` does not exist, this section does not apply -- the canon-absent state is not in force, and the generic verification rules elsewhere in the verification-before-completion skill govern the claim unchanged.

**Forces:** A repo with a ratified canon has already ruled, layer by layer, which verification is always required and which is conditional on the diff. A completion claim that ignores those rulings and falls back to generic verification silently discards a ratification the product owner did. But a canon can itself be stale, hand-edited, or corrupted -- treating a compromised canon as authoritative without surfacing that is its own failure mode, and refusing to evaluate any claim just because the canon looks imperfect throws out a real ratification over a warning-grade defect.

**Solution:** Before evaluating a completion claim against the canon:
- Read `docs/DOD.md`. If its structure cannot be parsed -- per the `defining-done` skill's malformed-canon rule -- REFUSE to evaluate the completion claim, emit the literal line `DOD-MALFORMED: <reason>` naming exactly what failed to parse, and state that diagnostic in the refusal. Emit the marker as a bare line: the line begins with the marker string itself, with no surrounding formatting (no backticks, no list markers, no quotation marks). Never proceed as if no canon existed; "present but unreadable" and "absent" are different states.
- Run `git status --porcelain docs/DOD.md` and `git diff -- docs/DOD.md`. If the output shows an uncommitted modification, state plainly that the canon carries uncommitted local edits and continue evaluating the claim against it (warn-and-consume -- no marker line is emitted for this case). If the status output shows the canon as untracked (`??` -- a freshly ratified canon not yet committed), state plainly that the canon is not yet tracked by git and continue consuming it (no marker line is emitted for this case either). If the canon file is not under git control (for example a test copy in a temporary directory), note that the check does not apply and continue.
- Compare the canon's `Stamp:` value against the `defining-done` skill's taxonomy's current stamp. If the canon is older, emit the literal line `DOD-STALE: canon v<N> behind taxonomy v<M>` and continue evaluating the claim against the canon. Emit the marker as a bare line: the line begins with the marker string itself, with no surrounding formatting (no backticks, no list markers, no quotation marks).

The gate check itself: for every layer ruled ALWAYS in the canon (unless the story's Definition of Done section carries a valid category-tagged N/A line for it) and every layer ruled CONDITIONAL whose trigger fired against the actual diff, the completion claim MUST carry that layer's evidence inline, meeting that layer's own verification standard -- not a lesser substitute. Example: a CONDITIONAL mutation-testing layer whose trigger fired requires a mutation run -- break the property, run the gate, paste the named failing case, then restore the property; a green suite run alone does not satisfy it. Missing or generic evidence for any such layer -> emit the literal line `DOD-GATE: FAIL <layer>`, using the layer's canonical Key. Emit the marker as a bare line: the line begins with the marker string itself, with no surrounding formatting (no backticks, no list markers, no quotation marks). The claim fails the gate observably; it is not marked DONE. Consumers are permitted, but not required, to additionally ground cited evidence against the repo under evaluation; when that grounding shows the cited evidence does not hold there (for example, a cited diff or file that is absent from the repo), the same `DOD-GATE: FAIL <layer>` marker MAY be emitted -- a grounding-driven failure is a legitimate gate outcome, not a defect in the consumer or in the claim-checking process.

Consequences and enforcement scope: references/CANON_CHECK_RATIONALE.md

---

## Red Flags -- STOP

- "The canon is stale, so the gate doesn't bind" -- **STOP. A stale canon still gates the claim; emit `DOD-STALE: canon v<N> behind taxonomy v<M>` and evaluate the claim against it anyway.**
- "The canon has uncommitted edits, skip the gate" -- **STOP. Uncommitted edits are warn-and-consume; state plainly that the canon carries uncommitted local edits and continue evaluating the claim against it.**
- "The trigger didn't obviously fire, skip the layer" -- **STOP. The story's canon-derived Definition of Done section (`user-story-generator` skill) records firing for the anticipated diff; a layer it omits did not fire unless the actual diff triggers it. With no such section the trigger counts as fired and the claimant supplies the evidence.**
- "The canon is malformed, fall back to generic verification" -- **STOP. Malformed is not absent -- refuse to evaluate the claim and name exactly what failed to parse.**
- "A green suite run is the evidence for the conditional layer" -- **STOP. A CONDITIONAL layer whose trigger fired is met only by that layer's own verification standard (a mutation-testing layer needs a mutation run: break the property, paste the named failing case, restore it). Produce that evidence or emit `DOD-GATE: FAIL <layer>`.**
- "That ALWAYS layer is not worth a line in the claim" -- **STOP. An ALWAYS layer needs inline evidence or a valid category-tagged N/A line in the story's Definition of Done section. Add one of the two, or emit `DOD-GATE: FAIL <layer>`.**

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "The canon is stale so the gate doesn't bind" | A stale canon is still consumed and still gates the claim; emit `DOD-STALE: canon v<N> behind taxonomy v<M>` and evaluate anyway. |
| "The canon has uncommitted edits, skip the gate" | Uncommitted local edits are a warn-and-consume state, not a parse failure; state plainly that the canon carries uncommitted local edits and keep evaluating the claim against it. |
| "The trigger didn't obviously fire, skip the layer" | The story's canon-derived Definition of Done section (`user-story-generator` skill) records firing for the anticipated diff; a layer it omits did not fire unless the actual diff triggers it. With no such section the trigger counts as fired and the claimant supplies the evidence. |
| "The canon is malformed, fall back to generic verification" | Malformed is not absent -- refuse to evaluate the claim and name exactly what failed to parse. |
| "The suite is green, so the conditional layer is covered" | A green suite is generic evidence. A fired CONDITIONAL layer needs its own standard met -- for mutation testing, break the property, paste the named failing case, restore it. Without that, emit `DOD-GATE: FAIL <layer>`. |
| "That ALWAYS layer does not matter for this change" | The owner ruled it ALWAYS. Paste its evidence inline, or cite a valid category-tagged N/A line (`target-absent`, `covered-elsewhere`, or `repo-ruled-N/A`). With neither, emit `DOD-GATE: FAIL <layer>`. |

---

## Related Skills

- `defining-done` -- ratifies the canon and owns the malformed-canon rule and the taxonomy stamp
- `user-story-generator` -- writes the story's Definition of Done section that records which conditional layers fired
- `verification-before-completion` -- the generic gate that routes here

---

## References

- `references/CANON_CHECK_RATIONALE.md` -- the consequences and enforcement scope of the canon check
