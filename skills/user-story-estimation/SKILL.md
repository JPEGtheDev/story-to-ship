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

Size tokens (XS, S, M, L, XL) are defined in the T-Shirt Size Guide below.

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
- Examples: Add an API endpoint, implement a user interface component, write a CI/CD (continuous integration and continuous delivery) workflow

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

**Counter-factor:** When prerequisites are already clear (style guide in place, dependencies settled), "foundational" work is LIGHTER than it looks -- calibrate down, not up.

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

- Generating a story without an effort estimate section -- **STOP.** Add the Effort Estimate block (Size and Reasoning) from the Effort Estimate Block section to the story before presenting it.
- "I'll add the estimate later" -- **STOP.** Write the Effort Estimate block now, choosing Size from the T-Shirt Size Guide; the Iron Law requires an estimate in every story.
- Accepting an XL story without decomposing it first -- **STOP.** Split the story into L-or-smaller stories, as the XL entry of the T-Shirt Size Guide requires, then size each one.
- Sizing M as S because "it's probably quick" -- **STOP.** Re-check the story against every criterion in the S entry of the T-Shirt Size Guide; if you cannot confirm all of them, size up, as the "The story is probably S" row of Rationalization Prevention directs (when uncertain, size up).
- Estimating without accounting for testing and iteration overhead -- **STOP.** Re-size using the Estimation Formula table, adding its Testing and validation and Iteration and fixes components to base implementation.

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

## Related Skills

- `user-story-generator` -- companion skill for generating the stories this skill estimates; its generated stories carry **Size:** S | M | L in the story header (the restricted subset of this skill's XS-XL scale) plus an Effort Estimate block with **Recommended Model Tier:** Economy | Standard | Premium and a one-sentence **Reasoning:**; this skill owns the full XS-XL scale and the **Size** + **Reasoning** estimate block
