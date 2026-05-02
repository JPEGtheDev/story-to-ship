---
name: verification-before-completion
license: MIT
description: Use when about to claim work is complete, fixed, or passing, before any completion claim, commit, or PR.
---

# Instructions for Agent

When activated, announce: **"I am using the verification-before-completion skill. Running verification now."**

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
| Production deployed, monitored, working | **"Done"** (the only correct use) | — |

**Gate:** Marking a todo "done" when unit tests pass = wrong definition. Invisible work remains.

For Particle-Viewer–specific Done stages, see `references/PV_DONE_DEFINITION.md`.

---

## The Gate Function

Apply this BEFORE any completion claim or expression of satisfaction:

```
BEFORE claiming any status or expressing satisfaction:
1. IDENTIFY: What command proves this claim?
2. RUN: Execute the FULL command (fresh, in this session, after the latest change)
3. READ: Full output — check exit code, count failures, read warnings
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence inline
5. ONLY THEN: Make the claim

✓ All met → proceed
✗ Any unmet → return to step 1; do not make the claim
```

Skipping any step = lying, not verifying.

---

See `references/VERIFICATION_THEORY.md` for defect removal efficiency data, trust ledger, and common failure modes.

---

## Pre-PR Checklist (PRR)

Before creating any PR — answer all 6 questions:

| # | Question | Why it matters |
|---|----------|----------------|
| 1 | **Blast radius:** Are the files touched the minimum necessary? | Excess scope = unintended side-effects |
| 2 | **Monitoring:** Does CI detect regressions in the new behavior? | New behavior with no test = invisible breakage |
| 3 | **Failure mode:** Does this fail loudly (error/exception) or silently? | Silent failures require active monitoring to catch |
| 4 | **Rollback path:** Can this be reverted with `git revert`? | Irreversible changes need extra review |
| 5 | **Dependency appropriateness:** Are you connecting to the right components? | Architectural violations that pass tests |
| 6 | **Open issues:** Are there P0/P1 open action items in this area? | Shipping over an unresolved incident |

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

❌ `"I ran the tests and they passed."`  
✅ `"Ran <project-test-runner>: **247 passed, 0 failures.** [exit 0]"`

See `references/HONESTY_PATTERNS.md` for why "should work" is banned, process language alternatives, and the 4-Cores final integrity check.

---

For Particle-Viewer build and test commands, see `references/PV_VERIFICATION_COMMANDS.md`.

---

## Red Flags — STOP

If you find yourself thinking any of the following, you are about to make an unverified claim. **STOP. Run the verification commands. Then state your claim.**

- "Should work now"
- "Probably passes"
- "I'm confident it's right"
- "I ran it earlier this session" — earlier ≠ after the current change
- "The build was clean before my change"
- "CI will catch anything I missed" — CI is a safety net, not your verification
- "Just a small change, can't have broken anything"
- Expressing satisfaction ("Great!", "Done!", "That should do it!") before running commands
- About to write a commit message without having run the gate commands
- Verified 1 of N parallel edits (N ≥ 3) — **STOP. View at least 3 of the N edited files. "They all look the same" is an assumption, not evidence. A malformed edit still counts as a changed file.**

**All of these mean: Run the verification commands NOW. Then state your claim.**

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification. |
| "I'm confident" | Confidence ≠ evidence. |
| "Small change, can't break things" | Small changes cause subtle failures. |
| "I ran it earlier" | Earlier run does not cover current changes. |
| "CI will catch it" | CI is a safety net, not your job. |
| "Just this once" | No exceptions. |
| "I already manually verified" | Manual ≠ automated. Results can't be reproduced or cited. |
| "Build passed, tests must be fine" | Build and tests are separate gates. |
| "They all follow the same pattern" | If the pattern was wrong once, it was wrong for all N. For N ≥ 3 parallel edits of the same structure: view at least 3 of the edited files before committing — not 1. |

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
