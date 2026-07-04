---
name: user-story-estimation
license: MIT
description: Use when estimating effort for user stories or implementation tasks.
---


## Iron Law

```
YOU MUST INCLUDE AN EFFORT ESTIMATE IN EVERY STORY.
No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

**Announce at start:** "I am using the user-story-estimation skill to estimate effort for [story name]."

---

## Effort Estimate Block (Required in Every Story)

Every generated story must include this section:

```markdown
## Effort Estimate

**Size:** [XS | S | M | L | XL]
**Reasoning:** [One sentence explaining complexity level]
```

---

## T-Shirt Size Guide

### XS -- Trivial
- Single-line or single-function change
- No ambiguity; outcome is certain before starting
- No new tests required beyond existing coverage
- Examples: Rename a variable, update a config value, fix a typo in a message

### S -- Small
- Change contained in one or two files
- Simple utility, helper, or bug fix with clear root cause
- Minimal new test surface
- Examples: Add a helper method, fix a null check, update a schema field

### M -- Medium
- Multi-file feature or change
- Moderate integration work; requires new tests
- Reviewable in a single PR without scope concerns
- Examples: Add an API endpoint, implement a UI component, write a CI/CD workflow

### L -- Large
- Architectural impact or cross-cutting change
- Multiple subsystems involved; deep dependency changes
- Requires phased implementation or multiple PRs
- Examples: Introduce a new abstraction layer, migrate a data model, refactor for testability

### XL -- Too Large to Estimate
- Scope is too wide to estimate safely as written
- Must be decomposed into L or smaller stories before any work begins
- Examples: "Rewrite the auth system", "Migrate to a new framework"

---

## Factors That Increase Size

- Complex algorithms or unfamiliar domain
- Need for mocking or abstraction layers
- Tight integration with external APIs
- Performance requirements with unclear targets
- Legacy code with unclear dependencies

---

## Estimation Formula

| Component | % of Total Effort |
|-----------|------------------|
| Base implementation | 40-60% |
| Testing and validation | 20-30% |
| Iteration and fixes | 15-25% |
| Documentation | 5-10% |

---

## Red Flags -- STOP

- Generating a story without an effort estimate section
- "I'll add the estimate later" -- add it now
- Accepting an XL story without decomposing it first
- Sizing M as S because "it's probably quick"
- Estimating without accounting for testing and iteration overhead

---

## BEFORE PROCEEDING

1. The story has been validated against INVEST (Independent, Negotiable, Valuable, Estimable, Small, Testable)
2. All unknowns are identified and noted in the estimate
3. The task breakdown reflects actual work, not a best-case scenario
4. XL stories have been decomposed before any estimate is committed

[+] All met -> commit to the estimate
[-] Any unmet -> resolve unknowns and recheck INVEST compliance before estimating

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Estimates are just guesses anyway" | Calibrated estimates drive planning; T-shirt sizing forces early scope conversation |
| "I'll estimate after implementation" | Pre-estimation exposes scope uncertainty before it causes overruns |
| "The story is probably S" | Use the complexity indicators above. When uncertain, size up. |
| "I'll update the estimate after starting" | Estimates set expectations. Revise before beginning, not during. |
| "XL is fine, we can figure it out as we go" | XL means the estimate is undefined. Decompose first. |

---

## References

- `references/PV_ESTIMATION_EXAMPLES.md` -- validated real-world estimates from completed Particle-Viewer stories, for calibrating estimates against actual outcomes. If this session is NOT about the Particle-Viewer project, skip this file -- it is PV-specific.
