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
**Reasoning:** [One sentence covering the complexity level and any unknowns]
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

**Counter-factor:** When prerequisites are already clear (style guide in place, dependencies settled), "foundational" work is LIGHTER than it looks -- calibrate down, not up.

---

## Estimation Formula

| Component | % of Total Effort |
|-----------|------------------|
| Base implementation | 40-60% |
| Testing and validation | 20-30% |
| Iteration and fixes | 15-25% |
| Documentation | 5-10% |

Size the total effort, not the base alone: base implementation is 40-60% of total, so count the testing, iteration and documentation rows when choosing Size.

---

## Token Budget (Plans With 8 or More Todos)

The `writing-plans` skill (item 7) loads this skill for a plan with 8 or more todos, counted as numbered plan items, so the agent can compute the token budget before presenting the plan. Only this section applies to that load; every other part of this skill applies to stories, not to the plan. Below 8 todos this section does not apply.

- Minimum dispatch count = todos x 2 (one implementer and one Stage 1 spec-compliance review per todo; subtract 1 for each todo edited on the Inline lane, which has no implementer dispatch) + Stage 2 dispatches for one whole-branch cycle (one dispatch per group of at most two changed files in the branch diff, so the changed-file count divided by 2, rounded up) + the same per-group count over the files of each risky todo + plan-review dispatches (2 for the Skeptic and plan-reviewer pair, 3 when a Three Amigos Refinement replaces them) + the review after all todos (1 final code reviewer, or 3 for the Three Amigos Signoff when Discovery ran) + 1 whole-branch coherence review when the plan adds a gate. Each further whole-branch cycle adds the dispatches of its re-check, and fix rounds add dispatches, so this is a minimum.
- Tokens per dispatch: use a figure measured from a prior run of the same kind. When none exists, write "unmeasured" and report the dispatch count only. DO NOT convert tool calls to tokens.
- Raw token counts are not comparable across model tiers. For cost, MUST use the Model Selection section of the `subagent-driven-development` skill; DO NOT restate its tables here.
- MUST state the todo count, the minimum dispatch count and the tokens-per-dispatch figure (or "unmeasured") in the plan presentation. The owner judges them; this section sets no pass/fail rule.

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
2. All unknowns are identified and noted in Reasoning (write "none" when there are none)
3. The task breakdown reflects actual work, not a best-case scenario
4. XL stories have been decomposed before any estimate is committed

[+] All met -> commit to the estimate
[-] Any unmet -> fix that item (re-validate INVEST, note unknowns in Reasoning, re-list the real work, decompose XL), then re-run this gate

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

- `user-story-generator` -- companion skill that generates the stories this skill estimates; this skill owns the full XS-XL scale and the Effort Estimate block. When both skills are loaded together, the generator story's header Size satisfies this block's Size line, and one Effort Estimate section is emitted, not two.
