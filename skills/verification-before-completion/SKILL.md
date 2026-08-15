---
name: verification-before-completion
license: MIT
description: Use when about to claim work is complete, fixed, or passing, before any completion claim, commit, or PR.
---


## Iron Law

```
YOU MUST RUN VERIFICATION COMMANDS IN THIS SESSION BEFORE ANY COMPLETION CLAIM.
EVIDENCE MUST BE INLINE. NEVER REFERENCED.
No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

**Announce at start:** "I am using the verification-before-completion skill to verify [work item] before claiming completion."

---

## BEFORE PROCEEDING

Apply this BEFORE any completion claim or expression of satisfaction:

```
BEFORE claiming any status or expressing satisfaction:
1. IDENTIFY: What command proves this claim?
2. RUN: Execute the FULL command (fresh, in this session, after the latest change)
3. READ: Full output -- check exit code, count failures, read warnings
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence inline
5. ONLY THEN: Make the claim

[+] All met -> proceed
[-] Any unmet -> return to step 1; do not make the claim
```

Skipping any step = lying, not verifying.

**For runtime behavior fixes** (the original bug report described what the user sees, hears, or experiences in the running application): Step 2 (RUN) MUST produce an observation artifact (a screenshot of the relevant user interface (UI) state or a log excerpt from the running process) that shows the reported symptom is absent. A pass/fail test result does not satisfy this step -- it verifies code logic, not observed runtime behavior. Show the observation artifact inline before claiming the fix is complete.

---

## The Done Definition Problem

**"Done" is the most overloaded word in software development.** Every misuse is a false completion claim.

| What you finished | Correct vocabulary | NOT "Done" |
|-------------------|--------------------|------------|
| Unit tests pass locally | "Verified locally, ready for pipeline" | ~~Done~~ |
| CI green on branch | "CI green, ready for acceptance review" | ~~Done~~ |
| Staging deployed and tested | "Staging verified, pending production" | ~~Done~~ |
| Production deployed, monitored, working | **"Done"** (the only correct use) | -- |

**Gate:** Marking a todo "done" when unit tests pass = wrong definition. Invisible work remains.

---

## New Gates: Gate-Can-Fail Proof Required

**Context:** Applies when shipping any NEW gate -- a test suite, fixture, CI check, hook, or lint rule meant to catch a class of defect going forward. Also applies when extending an existing gate to enforce a property it did not previously check -- the extension is a new detector for that property and carries the same vacuous-test risk. Does NOT apply to ordinary business-logic changes that are not themselves verification mechanisms.

**Forces:** A gate whose only evidence is a green run is unproven -- it can pass regardless of whether the mechanism it claims to enforce actually works (the vacuous-test class: a fixture that passes whether or not the property holds catches nothing). Without proof the gate CAN fail, a green run is indistinguishable from a gate that never runs the check at all. This pattern is established in this repo's own practice: RED-phase commits that intentionally leave a suite failing before the fix lands, and mutation proofs that name the exact fixtures expected to fail per broken property.

**Solution:** Shipping a new gate requires pasting proof the gate CAN FAIL, in addition to its green run:
- A mutation run: break the enforced property, run the gate, paste the named failing case(s) it produced, then restore the property.
- OR an equivalent failing-case run: a known-bad input the gate must reject, with the rejection pasted inline.

A green run alone is not sufficient evidence a new gate is correctly wired.

**Consequences:** Doubles the verification work for every new gate (a break-it run in addition to the pass-it run). This is the cost of ruling out the vacuous-test class; skipping it trades a small amount of upfront effort for an unproven detector that can silently do nothing.

**Enforcement scope:** No mechanical detector checks this rule. It is procedurally checkable in review -- the pasted mutation proof either exists in the message or it does not, and a reviewer can verify its presence directly.

---

See `references/VERIFICATION_THEORY.md` for defect removal efficiency data, trust ledger, and common failure modes.

---

## New Gates: Behavioral Evidence for Contract Fixes

**Context:** Applies when fixing a dispatched-agent contract, exception, or carve-out clause (e.g., agents/ templates, skill return-format contracts, gate trigger conditions in skills/) after review or post-merge catch. Does NOT apply to ordinary prose edits with no behavioral contract. If the fixed clause is itself a gate definition, the Gate-Can-Fail Proof Required entry above also applies -- the evidence composes, and the stricter bar (a run showing the previously-missed case is now caught) governs.

**Forces:** Textual review (Stage 1/2 PASS) verifies wording, not behavior; a fix can read correctly and still not change what a dispatched agent does. A "Fixed" claim for a contract clause that no fixture ever exercised is a completion claim without behavioral evidence.

**Solution:** A contract-clause fix may not close as DONE on textual review alone. Textual PASS plus a fixture run exercising the new sub-case (output pasted) = DONE. Without the fixture run, the maximum status is DONE_WITH_CONCERNS with the gap disclosed in the same message -- the word "Fixed" is not available for that change.

**Consequences:** Every contract fix costs one fixture dispatch; that is the price of ruling out text-only closure.

**Enforcement scope:** Reviewers and the coordinator check the fix todo's evidence for a fixture output specific to the new clause; procedurally checkable, no automated detector.

---

## New Gates: DoD Canon Check on Completion Claims

**Context:** Applies to every completion claim made in a repo that has a ratified Definition of Done (DoD) canon at `docs/DOD.md`, as produced by the `defining-done` skill's ratification interview. If `docs/DOD.md` does not exist, this section does not apply -- the canon-absent state is not in force, and the generic verification rules elsewhere in this skill govern the claim unchanged.

**Forces:** A repo with a ratified canon has already ruled, layer by layer, which verification is always required and which is conditional on the diff. A completion claim that ignores those rulings and falls back to generic verification silently discards a ratification the product owner did. But a canon can itself be stale, hand-edited, or corrupted -- treating a compromised canon as authoritative without surfacing that is its own failure mode, and refusing to evaluate any claim just because the canon looks imperfect throws out a real ratification over a warning-grade defect.

**Solution:** Before evaluating a completion claim against the canon:
- Read `docs/DOD.md`. If its structure cannot be parsed -- per the `defining-done` skill's malformed-canon rule -- REFUSE to evaluate the completion claim and emit a diagnostic naming exactly what failed to parse. Never proceed as if no canon existed; "present but unreadable" and "absent" are different states.
- Run `git status --porcelain docs/DOD.md` and `git diff -- docs/DOD.md`. If the output shows an uncommitted modification, state plainly that the canon carries uncommitted local edits and continue evaluating the claim against it (warn-and-consume -- no marker line is emitted for this case). If the status output shows the canon as untracked (`??` -- a freshly ratified canon not yet committed), state plainly that the canon is not yet tracked by git and continue consuming it (no marker line is emitted for this case either). If the canon file is not under git control (for example a test copy in a temporary directory), note that the check does not apply and continue.
- Compare the canon's `Stamp:` value against the `defining-done` skill's taxonomy's current stamp. If the canon is older, emit the literal line `DOD-STALE: canon v<N> behind taxonomy v<M>` and continue evaluating the claim against the canon. Emit the marker as a bare line: the line begins with the marker string itself, with no surrounding formatting (no backticks, no list markers, no quotation marks).

The gate check itself: for every layer ruled ALWAYS in the canon (unless the story's Definition of Done section carries a valid category-tagged N/A line for it) and every layer ruled CONDITIONAL whose trigger fired against the actual diff, the completion claim MUST carry that layer's evidence inline, meeting that layer's own verification standard -- not a lesser substitute. Example: a CONDITIONAL mutation-testing layer whose trigger fired requires a mutation run -- break the property, run the gate, paste the named failing case, then restore the property; a green suite run alone does not satisfy it. Missing or generic evidence for any such layer -> emit the literal line `DOD-GATE: FAIL <layer>`, using the layer's canonical Key. Emit the marker as a bare line: the line begins with the marker string itself, with no surrounding formatting (no backticks, no list markers, no quotation marks). The claim fails the gate observably; it is not marked DONE.

**Consequences:** A ratified canon adds up to four checks to every in-scope completion claim (malformed-refusal check, uncommitted-edit check, staleness check, per-layer evidence check) beyond this skill's generic verification rules. This is the cost of making the canon's rulings actually bind completion claims instead of remaining a document nobody consults.

**Enforcement scope:** Whether a CONDITIONAL layer's trigger fired against a given diff is evaluated by the Stage 1 spec-compliance reviewer and recorded in the review output -- this is reviewer judgment, not a mechanical detector (the trigger predicate is objectively checkable in principle, but no automated tool evaluates it here). The malformed-refusal, uncommitted-edit, and staleness checks are procedurally checkable: a reviewer can run the git commands and compare stamps directly. The `DOD-GATE: FAIL <layer>` marker itself is mechanically greppable once emitted.

---

## Pre-PR Checklist

Before creating any PR -- answer all 6 questions:

| # | Question | Why it matters |
|---|----------|----------------|
| 1 | **Blast radius:** Are the files touched the minimum necessary? | Excess scope = unintended side-effects |
| 2 | **Monitoring:** Does CI detect regressions in the new behavior? | New behavior with no test = invisible breakage |
| 3 | **Failure mode:** Does this fail loudly (error/exception) or silently? | Silent failures require active monitoring to catch |
| 4 | **Rollback path:** Can this be reverted with `git revert`? | Irreversible changes need extra review |
| 5 | **Dependency appropriateness:** Are you connecting to the right components? | Architectural violations that pass tests |
| 6 | **Open issues:** Are there P0 (Priority 0) / P1 (Priority 1) open action items in this area? | Shipping over an unresolved incident |

A "no" or "unknown" on any item = resolve it or document it explicitly in the PR description before opening.

---

### Banned Without Evidence

These words and phrases **cannot appear in any response** unless fresh verification output is shown inline:

| Phrase | Why it fails |
|--------|-------------|
| `"Done"` / `"Complete"` / `"Fixed"` | Completion claims without verification are false confidence |
| `"Works"` / `"Working"` | Shows output proving it works, or use process language |
| `"Tests pass"` / `"Build succeeds"` | Show the command output, not the claim |
| `"I'm confident"` / `"I'm sure"` | Confidence is not evidence |
| **`"Should work"`** | **BANNED. No substitute. Run the verification.** |
| `"That should do it"` | BANNED. Same reason. |

Evidence must be **inline**, not referenced:

[-] `"I ran the tests and they passed."`  
[+] `"Ran <project-test-runner>: **247 passed, 0 failures.** [exit 0]"`

See `references/HONESTY_PATTERNS.md` for why "should work" is banned, process language alternatives, and the 4-Cores final integrity check.

---

## Plausibility Baseline Check

**Context:** Applies to any green signal accepted as completion evidence -- exit 0, "N passed," "completed," or a similar success status. Does NOT apply when a claim is explicitly scoped as partial (for example, "12 of an unknown total ran clean") and stated as such. That carve-out does not survive the claim's scope changing: a partial-scoped claim may never later be treated as completion evidence without the baseline check being run at that point.

**Forces:** A green signal can be real and still fall short of the claim -- the mechanism produced a genuine exit 0 while covering less than the full scope, and nothing compared the result to what was expected. An unexamined count is a plausibility gap masquerading as verification.

**Solution:** A green signal MUST NOT be accepted as completion evidence without a plausibility check against a known baseline:
- State the expected number (count, total, or scope) BEFORE reading the result, then compare.
- OR name a known-bad case that must still fail, and confirm the gate still rejects it.
- OR compare against a prior-run reference count.

"Exit 0" with an unexamined count is not verification.

**Consequences:** Requires stating an expectation before looking at the result, which takes discipline under time pressure -- exactly when it is most tempting to skip. The alternative is the source postmortem's failure repeating: a run reporting 195/288 was accepted as complete because the signal was green, and nobody compared the count to the known total.

**Enforcement scope:** No mechanical detector checks this rule. It is self-checkable at generation time -- state the expected number before reading the result -- and procedurally checkable in review by asking what the baseline comparison was.

---

## Red Flags -- STOP

If you find yourself thinking any of the following, you are about to make an unverified claim. **STOP. Run the verification commands. Then state your claim.**

- "Should work now"
- "Probably passes"
- "I'm confident it's right"
- "I ran it earlier this session" -- earlier != after the current change
- "The build was clean before my change"
- "CI will catch anything I missed" -- CI is a safety net, not your verification
- "Just a small change, can't have broken anything"
- Expressing satisfaction ("Great!", "Done!", "That should do it!") before running commands
- About to write a commit message without having run the gate commands
- Claiming a runtime behavior fix is complete using only pass/fail test output -- **STOP. Produce an observation artifact (screenshot of the UI state or log excerpt from the running process) showing the reported symptom is absent.**
- Verified 1 of N parallel edits (N >= 3) -- **STOP. View at least 3 of the N edited files. "They all look the same" is an assumption, not evidence. A malformed edit still counts as a changed file.**
- "My new test/gate passed on the first run" -- **STOP. A green run alone does not prove the gate can fail. Paste a mutation run or an equivalent failing-case run too.**
- "Exit 0 means done" / "The count is probably fine" -- **STOP. Compare the result to a known baseline (an expected count, a known-bad case, or a prior-run reference) before accepting it as evidence.**
- "The contract fix reads correctly" -- **STOP. Textual review does not prove a dispatched agent's behavior changed; run a fixture exercising the new sub-case before claiming DONE.**
- "The canon is stale, so the gate doesn't bind" -- **STOP. A stale canon still gates the claim; emit `DOD-STALE: canon v<N> behind taxonomy v<M>` and evaluate the claim against it anyway.**
- "The canon has uncommitted edits, skip the gate" -- **STOP. Uncommitted edits are warn-and-consume; state plainly that the canon carries uncommitted local edits and continue evaluating the claim against it.**
- "The trigger didn't obviously fire, skip the layer" -- **STOP. Trigger firing is a recorded Stage 1 reviewer judgment, not a silent self-exemption -- the reviewer decides and records it, not the claimant.**
- "The canon is malformed, fall back to generic verification" -- **STOP. Malformed is not absent -- refuse to evaluate the claim and name exactly what failed to parse.**

**All of these mean: Run the verification commands NOW. Then state your claim.**

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification. |
| "I'm confident" | Confidence != evidence. |
| "Small change, can't break things" | Small changes cause subtle failures. |
| "I ran it earlier" | Earlier run does not cover current changes. |
| "CI will catch it" | CI is a safety net, not your job. |
| "Just this once" | This "once" becomes the precedent the next one cites. The gate has no exception path. |
| "I already manually verified" | Manual != automated. Results can't be reproduced or cited. |
| "Build passed, tests must be fine" | Build and tests are separate gates. |
| "The automated tests pass -- the runtime behavior fix is done" | Pass/fail tests verify code logic. They do not demonstrate what the user observes in the running application. Show an observation artifact demonstrating the reported symptom is absent. |
| "They all follow the same pattern" | If the pattern was wrong once, it was wrong for all N. For N >= 3 parallel edits of the same structure: view at least 3 of the edited files before committing -- not 1. |
| "My new test passed on the first run" | A green run alone does not prove the gate can fail. Paste a mutation run or a failing-case run too -- a fixture that passes regardless of the mechanism is worse than none. |
| "Exit 0 means done" / "The count is probably fine" | A green signal without a baseline comparison is not verification. State the expected count before reading the result, or name a known-bad case that must still fail. |
| "The fix looks right on review" | Textual PASS is not behavioral evidence for a contract clause; paste a fixture run for the new sub-case, or cap the claim at DONE_WITH_CONCERNS. |
| "The canon is stale so the gate doesn't bind" | A stale canon is still consumed and still gates the claim; emit `DOD-STALE: canon v<N> behind taxonomy v<M>` and evaluate anyway. |
| "The canon has uncommitted edits, skip the gate" | Uncommitted local edits are a warn-and-consume state, not a parse failure; state plainly that the canon carries uncommitted local edits and keep evaluating the claim against it. |
| "The trigger didn't obviously fire, skip the layer" | Trigger firing is recorded Stage 1 reviewer judgment, not a self-exemption the claimant grants itself. |
| "The canon is malformed, fall back to generic verification" | Malformed is not absent -- refuse to evaluate the claim and name exactly what failed to parse. |

---

## Related Skills

- After debugging: always verify with this skill before claiming the fix worked
- Before every commit: run the full pre-commit gate
- Before opening a PR: run the full verification gate and read the output
- See `systematic-debugging` skill for how to investigate failures found during verification

---

## Agent Delegation Verification

When a subagent reports completion, do not propagate its claim without verifying. Subagents can report success on partial work, fail silently, or write to the wrong path. See `references/DELEGATION_GATE.md` for the full delegation verification gate.

---

## Research and Evaluation Gate

For research and evaluation methodology, see `references/RESEARCH_GATE.md`. (Domain note: this gate covers test design and scientific method.)
