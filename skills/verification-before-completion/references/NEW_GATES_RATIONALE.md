# New Gates: Consequences and Enforcement Scope

Consequences and enforcement scope for the two New Gates sections of `../SKILL.md`. The Context, Forces, and Solution of each gate stay in `../SKILL.md`.

---

## New Gates: Gate-Can-Fail Proof Required

**Consequences:** Doubles the verification work for every new gate (a break-it run in addition to the pass-it run). This is the cost of ruling out the vacuous-test class; skipping it trades a small amount of upfront effort for an unproven detector that can silently do nothing.

**Enforcement scope:** No mechanical detector checks this rule. It is procedurally checkable in review -- the pasted mutation proof either exists in the message or it does not, and a reviewer can verify its presence directly.

---

## New Gates: Behavioral Evidence for Contract Fixes

**Consequences:** Every contract fix costs one fixture dispatch; that is the price of ruling out text-only closure.

**Enforcement scope:** Reviewers and the coordinator check the fix todo's evidence for a fixture output specific to the new clause; procedurally checkable, no automated detector.
