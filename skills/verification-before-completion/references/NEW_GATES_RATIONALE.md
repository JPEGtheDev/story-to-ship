# New Gates: Consequences and Enforcement Scope

Consequences and enforcement scope for the two New Gates sections and the Plausibility Baseline Check section of `../SKILL.md`. The Context, Forces, and Solution of each gate stay in `../SKILL.md`.

---

## New Gates: Gate-Can-Fail Proof Required

**Consequences:** Doubles the verification work for every new gate (a break-it run in addition to the pass-it run). This is the cost of ruling out the vacuous-test class; skipping it trades a small amount of upfront effort for an unproven detector that can silently do nothing.

**Enforcement scope:** No mechanical detector checks this rule. It is procedurally checkable in review -- the pasted mutation proof either exists in the message or it does not, and a reviewer can verify its presence directly.

---

## New Gates: Behavioral Evidence for Contract Fixes

**Consequences:** Every contract fix costs one fixture dispatch; that is the price of ruling out text-only closure.

**Enforcement scope:** Reviewers and the coordinator check the fix todo's evidence for a fixture output specific to the new clause; procedurally checkable, no automated detector.

---

## Plausibility Baseline Check

**Consequences:** Requires stating an expectation before looking at the result, which takes discipline under time pressure -- exactly when it is most tempting to skip. The alternative is the source postmortem's failure repeating: a run reporting 195/288 was accepted as complete because the signal was green, and nobody compared the count to the known total.

**Enforcement scope:** No mechanical detector checks this rule. It is self-checkable at generation time -- state the expected number before reading the result -- and procedurally checkable in review by asking what the baseline comparison was.
