# Verification Theory

## Combine Verification Instruments

**No single verification technique removes more than ~70% of defects.** (Capers Jones research, cited in McConnell's *Code Complete*.)

| Technique | Defect removal efficiency |
|-----------|--------------------------|
| Unit testing alone | 30–40% |
| Code inspection/review | 45–70% |
| **Both combined** | **>90%** |

The IBM Cleanroom result: formal inspections achieved <0.1 defects/KLOC vs. industry average 15–50.

**The implication:** "Tests pass" with no additional review still has a statistically likely defect rate of 30–70%. Tests catch execution-time defects. Code review catches logical, requirements, and interface defects that tests cannot surface.

**Gate for this project:**

Before claiming any PR ready:
1. **Tests pass** — execution-time defects caught
2. **Diff reviewed** — logical and interface defects caught (`git diff` read hunk by hunk)
3. **Format verified** — `clang-format --dry-run` clean
4. **Scope verified** — changes touch only what the task required; no accidental changes

**Rationalization:** "Tests pass — I'm done." Counter: no single technique removes >70% of defects. Tests + diff review is the minimum combined instrument set.

---

## The Trust Ledger

Every session has a trust balance. This determines whether the user can lean on your outputs without second-guessing them — which determines speed.

| Deposits (earn trust → enable speed) | Withdrawals (trust tax → force verification overhead) |
|--------------------------------------|------------------------------------------------------|
| Verified claim with inline evidence | Any "should work" used without running the gate |
| Finding a failure before the user does | Fix that doesn't address root cause |
| `"I don't know — dispatching subagent"` | Empty output treated as success |
| Delivering exactly what was committed | Completion claim followed by "oh, also there's X" |
| Inline output matches what was stated | Expressing satisfaction before running commands |

**High trust = user acts on outputs directly. Low trust = user re-runs every command themselves.**

Every withdrawal forces the user into verification mode for the rest of the session. It is not the individual mistake that costs — it is losing the ability to move fast.

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
