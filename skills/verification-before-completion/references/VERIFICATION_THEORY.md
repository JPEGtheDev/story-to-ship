# Verification Theory

## Combine Verification Instruments

**No single verification technique removes more than ~70% of defects.** (Capers Jones research, cited in McConnell's *Code Complete*.)

| Technique | Defect removal efficiency |
|-----------|--------------------------|
| Unit testing alone | 30-40% |
| Code inspection/review | 45-70% |
| **Both combined** | **>90%** |

The IBM Cleanroom result: formal inspections achieved <0.1 defects/KLOC (thousands of lines of code) vs. industry average 15-50.

**The implication:** "Tests pass" with no additional review still has a statistically likely defect rate of 30-70%. Tests catch execution-time defects. Code review catches logical, requirements, and interface defects that tests cannot surface.

**Gate for this project:**

Before claiming any PR ready:
1. **Tests pass** -- execution-time defects caught
2. **Diff reviewed** -- logical and interface defects caught (`git diff` read hunk by hunk)
3. **Format verified** -- `clang-format --dry-run` clean
4. **Scope verified** -- changes touch only what the task required; no accidental changes

**Rationalization:** "Tests pass -- I'm done." Counter: no single technique removes >70% of defects. Tests + diff review is the minimum combined instrument set.

---

## The Trust Ledger

Every session has a trust balance. This determines whether the user can lean on your outputs without second-guessing them -- which determines speed.

| Deposits (earn trust -> enable speed) | Withdrawals (trust tax -> force verification overhead) |
|--------------------------------------|------------------------------------------------------|
| Verified claim with inline evidence | Any "should work" used without running the gate |
| Finding a failure before the user does | Fix that doesn't address root cause |
| `"I don't know -- dispatching subagent"` | Empty output treated as success |
| Delivering exactly what was committed | Completion claim followed by "oh, also there's X" |
| Inline output matches what was stated | Expressing satisfaction before running commands |

**High trust = user acts on outputs directly. Low trust = user re-runs every command themselves.**

Every withdrawal forces the user into verification mode for the rest of the session. It is not the individual mistake that costs -- it is losing the ability to move fast.

---

## Common Failure Modes

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| "Tests pass" | Test command output: 0 failures | Previous run, "should pass", CI green |
| "Build succeeds" | cmake output: exit 0 | Linter passing, "looks right" |
| "Formatted correctly" | `clang-format --dry-run`: 0 errors + `git diff` inspected | "I ran clang-format" without checking diff |
| "Bug is fixed" | Test reproducing original bug: passes | Code changed, assumed fixed |
| "PR is ready" | All three gate commands: pass | Tests passing only |
| "Feature complete" | Every acceptance criterion verified | Tests passing |

---

## Mutual Verification Is Agreement, Not Proof

A test written before the code, then turned green once the code exists, reads like a proof of correctness. What it actually demonstrates is narrower: the test and the implementation are separate write-ups of the same intent, produced independently of one another, and a passing run only confirms that the two write-ups line up. Lining up is not the same as either one being objectively correct.

Lining up can still be wrong together. If the same misconception shapes both the assertion and the code being checked, the two will match while sharing one flaw. The source treats this as an accepted, everyday risk rather than a paralyzing one -- present, but not something that undermines the practice as a whole. That framing keeps this compatible with "Combine Verification Instruments" above: a lone green test is one instrument confirming itself against its own assumptions, which is exactly why review or a second instrument is needed to catch what a matched pair cannot.

The reassurance a green suite provides is probabilistic and grounded in practice, not a guarantee in the formal sense. It also cannot reach one specific failure: a test only checks an implementation against what its author understood the requirement to be, never against what the person who asked for the feature actually wanted. When that understanding is wrong from the start, test and code agree with each other and miss the mark together.

Given that, the response is not to add a further layer of proof over the tests -- that just relocates the same limitation. It is to keep the test code itself plain enough that anyone reading it can see directly what it checks.

---

## Performance Claims Are Measurements, Not Reputations

Casual arguments blur two different statements together: "this technique is inherently slow" and "this particular implementation, running this particular workload, showed this much overhead in one benchmark." The first is a verdict about an idea; the second is a data point about one measurement. Treating the second as if it proved the first is where reputations get created and then outlive the evidence behind them.

Garbage collection carries exactly this kind of reputation. A 1993 study by Detlefs, Dosser, and Zorn measured a conservative collector adding roughly 20% to execution time, with heap size growing by a multiplier in the range of 1.2x-1.5x to 2.5x over a plain malloc/free baseline, the exact figure shifting with which allocator served as the comparison point. That result is explicitly an upper bound, not a general verdict on garbage collection: it came from an aging collector retrofitted onto a language never built with collection in mind, running programs that had received no tuning for that collector at all.

This discipline applies whenever garbage collection, or any memory-management strategy, gets called "too slow" or "cheap enough" without a benchmark run against the actual target program: measure it on the actual workload in question, using a controlled comparison like the allocator-versus-collector swap above, rather than leaning on a technique's reputation.

Reputation also ages differently than the underlying reality does. Decades of engineering can pass while the old number keeps circulating unchanged; a collector built into a language from the start typically clears the bar the old benchmark set by a wide margin. Carrying an outdated figure into a modern, well-tuned context is itself a measurement error -- the same mistake the discipline above is meant to prevent, just committed against a stale baseline instead of no baseline.
