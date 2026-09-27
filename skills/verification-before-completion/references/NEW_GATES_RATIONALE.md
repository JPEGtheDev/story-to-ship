# New Gates: Consequences and Enforcement Scope

Consequences and enforcement scope for the three New Gates sections of `../SKILL.md`. The Context, Forces, and Solution of each gate stay in `../SKILL.md`.

---

## New Gates: Gate-Can-Fail Proof Required

**Consequences:** Doubles the verification work for every new gate (a break-it run in addition to the pass-it run). This is the cost of ruling out the vacuous-test class; skipping it trades a small amount of upfront effort for an unproven detector that can silently do nothing.

**Enforcement scope:** No mechanical detector checks this rule. It is procedurally checkable in review -- the pasted mutation proof either exists in the message or it does not, and a reviewer can verify its presence directly.

---

## New Gates: Behavioral Evidence for Contract Fixes

**Consequences:** Every contract fix costs one fixture dispatch; that is the price of ruling out text-only closure.

**Enforcement scope:** Reviewers and the coordinator check the fix todo's evidence for a fixture output specific to the new clause; procedurally checkable, no automated detector.

---

## New Gates: DoD Canon Check on Completion Claims

**Consequences:** A ratified canon adds up to four checks to every in-scope completion claim (malformed-refusal check, uncommitted-edit check, staleness check, per-layer evidence check) beyond this skill's generic verification rules. This is the cost of making the canon's rulings actually bind completion claims instead of remaining a document nobody consults.

**Enforcement scope:** Whether a CONDITIONAL layer's trigger fired against a given diff is evaluated by the Stage 1 spec-compliance reviewer and recorded in the review output -- this is reviewer judgment, not a mechanical detector (the trigger predicate is objectively checkable in principle, but no automated tool evaluates it here). The uncommitted-edit and staleness checks are procedurally checkable: a reviewer can run the git commands and compare stamps directly. The malformed-refusal check is mechanically greppable once emitted, like the completion gate's failure marker: consumers emit the literal `DOD-MALFORMED: <reason>` line, and the `DOD-GATE: FAIL <layer>` marker is likewise mechanically greppable once emitted.
