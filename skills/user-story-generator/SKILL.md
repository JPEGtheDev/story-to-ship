---
name: user-story-generator
license: MIT
description: Use when creating or refining Independent, Negotiable, Valuable, Estimable, Small, Testable (INVEST)-aligned user stories.
---


## Iron Law

```
VALIDATE EVERY STORY AGAINST INVEST CRITERIA AND INCLUDE ACCEPTANCE CRITERIA BEFORE SHIPPING
YOU MUST validate every story against INVEST criteria and include acceptance criteria before shipping.
No exceptions.
```
Violating the letter of this rule is violating the spirit of this rule.

**Announce at start:** "I am using the user-story-generator skill to create/refine a story for [brief description]."

## BEFORE PROCEEDING

After you've had the conversation and before generating, mentally verify you have:
1. **Loaded the actual project context** (repo README, docs, or the user's description) BEFORE generating -- never infer scope or functionality from the project's NAME; if the request names functionality that does not exist in the project, ask a clarifying question before generating. Also check for a ratified Definition of Done (DoD) canon at docs/DOD.md: if present, read it before generating (see DoD Canon Consumption below); if absent, generate using the generic template and state in the generated story that no ratified canon exists.
2. **Confirmed the functionality/component actually exists** (didn't assume based on naming)
3. Clear understanding of what they want to accomplish
   [-] Ask: "What specifically do you want this story to enable?"
4. Context about why it matters (the value)
   [-] Ask: "What outcome or value does this deliver?"
5. Rough scope and size estimate (S/M/L)
   [-] Ask: "Is this small (hours), medium (days), or large (sprint)?"
6. Premium request estimate based on complexity
   [-] Estimate from scope; state the assumption
7. Model recommendation with reasoning
   [-] Default to Standard tier; state the assumption
8. Format preference (if they expressed one)
   [-] Default to Story Template format; state the assumption
9. Any specific constraints or requirements
   [-] Assume no constraints; state the assumption

[+] All 9 met -> proceed to generate the story
[-] Any unmet -> ask the missing questions or gather the missing information. Do not generate until all 9 conditions are met.

**RED FLAGS - Stop and ask for clarification:**
- Story mentions functionality not in project context
- Acceptance criteria test features that don't exist
- Technical notes reference non-existent architecture
- User story assumes capabilities the project doesn't have

## INVEST Checklist

Every generated story MUST be:
- **Independent** - no hard dependencies on unstarted work
- **Negotiable** - focus on "what" not "how"
- **Valuable** - clear benefit stated in "So that" clause
- **Estimable** - team can size it (provide S/M/L estimate)
- **Small** - doable in one sprint
- **Testable** - acceptance criteria are verifiable

If a story violates INVEST, fix it or break it down.

See `references/INVEST_GUIDE.md` for conversation principles and common edge cases.
See `references/INVEST_FRAMEWORK.md` for per-criterion elaboration and examples.

## Story Format

**As a** [role: developer, tester, user]  
**I want to** [action]  
**So that** [outcome/business value]

See `references/STORY_TEMPLATE.md` for the full story template with all sections.

## DoD Canon Consumption

The generated story's Definition of Done section depends on whether a ratified DoD
canon was found at docs/DOD.md during BEFORE PROCEEDING item 1.

**Canon present and parses:**
- Derive the Definition of Done section from the canon instead of the generic
  template checklist.
- Header annotation: `*(derived from docs/DOD.md, ratified v<N>)*` where `<N>` is the
  canon's `Stamp:` value.
- Every layer ruled ALWAYS in the canon (see the `defining-done` skill's taxonomy)
  becomes a checklist item tagged `(always-on)`.
- Every CONDITIONAL layer whose trigger fires against the story's anticipated diff
  scope becomes a checklist item stating the trigger and that it fired.
- Non-firing CONDITIONAL layers and canon-level N/A layers are ABSENT from the
  story's Definition of Done section -- no line, no stub.
- **Dropping an ALWAYS layer (Context/Forces/Solution/Consequence):** Context:
  applies only when the story's actual diff scope genuinely produces no surface the
  ALWAYS layer verifies -- never because a layer "feels" inapplicable. Forces: the
  owner ratified the layer ALWAYS for every change, but a specific story can have no
  surface for it; an unbounded drop right would gut the canon, while zero exit forces
  checklist noise; the closed-category N/A line plus the refusal default is the
  bound. Solution: a story MAY drop an ALWAYS layer only via a story-level N/A line
  carrying one of the three closed categories (target-absent | covered-elsewhere |
  repo-ruled-N/A) -- same form as the canon's own N/A ruling lines, e.g.
  `- coverage: N/A | category: target-absent | docs-only story, no code surface`.
  Consequence: every drop is auditable by its category tag.
- **Refusal:** if the story would omit an ALWAYS layer with no valid category-tagged
  N/A line, refuse to emit the story and emit the literal line
  `DOD-VIOLATION: <layer>` (the layer's canonical Key).
- **Staleness:** if the canon's `Stamp:` is older than the `defining-done` skill's
  taxonomy's current stamp, still consume the canon and emit the literal line
  `DOD-STALE: canon v<N> behind taxonomy v<M>`.
- **Hash check:** recompute the canon's content-hash per the `defining-done` skill's
  byte-range definition; on mismatch, emit the literal line `DOD-HASH: MISMATCH` and
  continue consuming the canon (warn-and-consume -- a trust flag, not a parse
  failure; distinct from the malformed-canon case below, which refuses instead of
  consuming).

**Canon present but malformed** (structurally unparseable per the `defining-done`
skill's malformed-canon rule): refuse to generate the story. State exactly what
failed to parse. Never silently fall back to the generic template as if no canon
existed -- "present but unreadable" is not "absent".

**Canon absent:** generate the Definition of Done section from the generic template
and state in the generated story that no ratified canon exists and the Definition of
Done section uses unratified template defaults.

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "The story is clear enough, INVEST is overkill" | INVEST catches scope creep and untestable requirements before sprint start. |
| "Acceptance criteria can be added later" | Stories without acceptance criteria can't be verified as done. Add them now. |
| "This story is too big but we'll split it in sprint" | Split it now. Big stories hide risk and block delivery. |
| "The story depends on another, but we'll handle it" | Dependent stories can't be independently delivered. Redesign the split. |
| "We can estimate it after starting" | Inestimable stories signal unclear scope. Clarify before committing. |
| "Good enough -- the team will figure out the details" | Vague stories produce vague implementations. Write precise acceptance criteria. |
| "AskUserQuestion covered the clarification, Discovery is redundant" | AskUserQuestion is informal Q&A. Discovery (the three-amigos skill's Ceremony 1) produces a Feature Specification (the structured spec Discovery writes to plan.md) that validates field optionality, invocation paths, and behavioral Acceptance Criteria under three personas (the three-amigos skill's Business, Developer, and Tester amigos). They are not equivalent. |
| "The canon is stale, I'll just use the generic template instead" | A stale canon is still consumed, with a `DOD-STALE` warning line -- never discard a ratified canon for staleness. |
| "Hash mismatch means the canon might be corrupt, refuse to use it" | Hash mismatch is a warn-and-consume trust flag, not a parse failure -- emit `DOD-HASH: MISMATCH` and keep consuming the canon. |
| "This always-on layer obviously doesn't apply here, I'll just drop it" | Only a category-tagged N/A line (or refusal) can drop an ALWAYS layer -- never drop it silently. |
| "The canon is malformed, fall back to the generic template like it's absent" | Malformed is not absent -- refuse with a diagnostic naming exactly what failed to parse. |

## Output Destination

See `references/OUTPUT_ROUTING.md` for the full routing rule with context and forces.

## Red Flags -- STOP

- Story has no acceptance criteria -> STOP. Write at least one testable acceptance criterion before generating.
- Story requires another story to be done first ("depends on #X") -> STOP. Redesign the split so this story can be delivered independently.
- Story spans multiple unrelated components or layers -> STOP. Split into separate stories, one per component or layer.
- "We'll know it's done when it feels right" -> STOP. Write a concrete, testable acceptance criterion before proceeding.
- Story takes more than one sprint to deliver -> STOP. Split the story until each piece fits in one sprint.
- Can't write a failing test for the acceptance criteria -> STOP. Rewrite the criterion until a failing test can be written for it.
- Generating 2+ stories with new Acceptance Criteria without running Three Amigos Discovery first -> STOP. Acceptance Criteria written before Discovery are unvalidated. Run `three-amigos` Ceremony 1 before finalizing any acceptance criterion.
- Canon present but fails to parse, tempted to fall back to the generic template -> STOP. "Present but unreadable" is not "absent" -- refuse and name what failed.
- About to omit an ALWAYS-ruled checklist item with no category-tagged N/A line -> STOP. Add the N/A line or refuse.

---

# Instructions for Agent

See `references/CONVERSATION_SCRIPTS.md` for story elicitation conversation scripts.

**Always include the Effort Estimate section** with:
- Total premium requests (range)
- Recommended model tier (Economy/Standard/Premium)
- One-sentence reasoning for the model choice

**Tier planning for decomposed stories:** Reserve Premium for stories that make architectural or design decisions. When decomposition front-loads those decisions into a Premium story, recommend Standard for the implementation stories that execute them, and Economy for mechanical, fully-specified changes. A breakdown where every story recommends Premium is a signal the decomposition did not separate deciding from executing.

## Related Skills

See the `user-story-estimation` skill for the full T-shirt size scale (XS-XL) and validated examples; this skill's own template (`references/STORY_TEMPLATE.md`) restricts generated stories to S/M/L. For model tier selection, load the `subagent-driven-development` skill (Model Selection, Tier Assignments table). Always include the Effort Estimate section in every generated story. The `defining-done` skill owns the DoD canon, its taxonomy, and the hash/malformed-canon definitions this skill consumes.
