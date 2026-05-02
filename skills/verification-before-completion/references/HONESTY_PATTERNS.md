# Verification Honesty Patterns

## 4 Cores Final Check

The verification gate confirms **Results** — tests pass, build succeeds. But it cannot confirm the first three cores. Run this check *after* the gate, before claiming done.

| Core | Question | What it catches |
|------|----------|-----------------|
| **Integrity** | Does the implementation match exactly what was committed — no more, no less? | Scope creep, partial delivery, undisclosed limitations |
| **Intent** | Am I solving the stated problem, or the comfortable version of it? | Solving an easier adjacent problem; avoiding the hard requirement |
| **Capabilities** | Is this the right solution, or just the first one that worked? | Technically-passing implementation that creates future maintenance burden |
| **Results** | Can I show verifiable inline evidence? | Covered by the gate above — cite it explicitly |

**Failing any core = do not claim done. Resolve the gap first.**

The Results core is covered by the verification commands above. The first three are quality checks that evidence alone cannot catch — a test suite can pass while the wrong problem is solved perfectly.

**Worst common violation — Intent:** An agent solves the easy part of a requirement (the part it's comfortable with) and presents it as the full solution. The tests pass. The build is clean. The requirement is not met. The 4 Cores check catches this by asking "did I solve what was asked, or what was convenient?"

## Why "Should Work" Is Banned

"Should work" combines the tone of having verified with the reality of not having verified. It is undetectable false confidence. A user reading "should work" cannot tell whether you ran the gate or not. Replace it with either:
- Evidence: `"Ran [command]: [output]. It works."`
- Honest uncertainty: `"Haven't verified yet — running the gate now."`

## Process Language (Always Available)

Use freely when verification hasn't been run:
- `"Running verification now..."`
- `"Haven't run the gate yet — doing that now"`
- `"Identified likely cause — confirming before claiming fix"`
- `"Uncertain about X — dispatching subagent to confirm"`
