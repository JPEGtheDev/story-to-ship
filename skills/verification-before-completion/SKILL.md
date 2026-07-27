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

## The Done Definition Problem

**"Done" is the most overloaded word in software development.** Every misuse is a false completion claim.

| What you finished | Correct vocabulary | NOT "Done" |
|-------------------|--------------------|------------|
| Unit tests pass locally | "Verified locally, ready for pipeline" | ~~Done~~ |
| CI green on branch | "CI green, ready for acceptance review" | ~~Done~~ |
| Staging deployed and tested | "Staging verified, pending production" | ~~Done~~ |
| Production deployed, monitored, working | **"Done"** (the only correct use) | -- |

**Gate:** Marking a todo "done" when unit tests pass = wrong definition. Invisible work remains.

For Particle-Viewer-specific Done stages, see `references/PV_DONE_DEFINITION.md`. If this session is NOT about the Particle-Viewer project, skip this file -- it is PV-specific.

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

## New Gates: Gate-Can-Fail Proof Required

**Context:** Applies when shipping any NEW gate -- a test suite, fixture, CI check, hook, or lint rule meant to catch a class of defect going forward. Does NOT apply to ordinary business-logic changes that are not themselves verification mechanisms.

**Forces:** A gate whose only evidence is a green run is unproven -- it can pass regardless of whether the mechanism it claims to enforce actually works (the vacuous-test class: a fixture that passes whether or not the property holds catches nothing). Without proof the gate CAN fail, a green run is indistinguishable from a gate that never runs the check at all.

**Solution:** Shipping a new gate requires pasting proof the gate CAN FAIL, in addition to its green run:
- A mutation run: break the enforced property, run the gate, paste the named failing case(s) it produced, then restore the property.
- OR an equivalent failing-case run: a known-bad input the gate must reject, with the rejection pasted inline.

A green run alone is not sufficient evidence a new gate is correctly wired.

**Consequences:** Doubles the verification work for every new gate (a break-it run in addition to the pass-it run). This is the cost of ruling out the vacuous-test class; skipping it trades a small amount of upfront effort for an unproven detector that can silently do nothing.

This pattern is established in this repo's own practice: RED-phase commits that intentionally leave a suite failing before the fix lands, and mutation proofs that name the exact fixtures expected to fail per broken property.

**Enforcement scope:** No mechanical detector checks this rule. It is procedurally checkable in review -- the pasted mutation proof either exists in the message or it does not, and a reviewer can verify its presence directly.

---

See `references/VERIFICATION_THEORY.md` for defect removal efficiency data, trust ledger, and common failure modes.

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

For Particle-Viewer build and test commands, see `references/PV_VERIFICATION_COMMANDS.md`. If this session is NOT about the Particle-Viewer project, skip this file -- it is PV-specific.

---

## Plausibility Baseline Check

**Context:** Applies to any green signal accepted as completion evidence -- exit 0, "N passed," "completed," or a similar success status. Does NOT apply when a claim is explicitly scoped as partial (for example, "12 of an unknown total ran clean") and stated as such.

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
| "Just this once" | No exceptions. |
| "I already manually verified" | Manual != automated. Results can't be reproduced or cited. |
| "Build passed, tests must be fine" | Build and tests are separate gates. |
| "The automated tests pass -- the runtime behavior fix is done" | Pass/fail tests verify code logic. They do not demonstrate what the user observes in the running application. Show an observation artifact demonstrating the reported symptom is absent. |
| "They all follow the same pattern" | If the pattern was wrong once, it was wrong for all N. For N >= 3 parallel edits of the same structure: view at least 3 of the edited files before committing -- not 1. |
| "My new test passed on the first run" | A green run alone does not prove the gate can fail. Paste a mutation run or a failing-case run too -- a fixture that passes regardless of the mechanism is worse than none. |
| "Exit 0 means done" / "The count is probably fine" | A green signal without a baseline comparison is not verification. State the expected count before reading the result, or name a known-bad case that must still fail. |

---

## Related Skills

- After debugging: always verify with this skill before claiming the fix worked
- Before every commit: run the full pre-commit gate
- Before opening a PR: run all three verification commands and read the output
- See `systematic-debugging` skill for how to investigate failures found during verification

---

## Agent Delegation Verification

When a subagent reports completion, do not propagate its claim without verifying. Subagents can report success on partial work, fail silently, or write to the wrong path. See `references/DELEGATION_GATE.md` for the full delegation verification gate.

---

## Research and Evaluation Gate

For research and evaluation methodology, see `references/RESEARCH_GATE.md`. (Domain note: this gate covers test design and scientific method.)
