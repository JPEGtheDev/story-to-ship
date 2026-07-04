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
1. **Loaded `references/PV_PROJECT_CONTEXT.md`** if this is a Particle-Viewer session. If this session is NOT about the Particle-Viewer project, skip this file -- it is PV-specific. Use the actual project context from the repo README or the user's description instead.
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

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "The story is clear enough, INVEST is overkill" | INVEST catches scope creep and untestable requirements before sprint start. |
| "Acceptance criteria can be added later" | Stories without acceptance criteria can't be verified as done. Add them now. |
| "This story is too big but we'll split it in sprint" | Split it now. Big stories hide risk and block delivery. |
| "The story depends on another, but we'll handle it" | Dependent stories can't be independently delivered. Redesign the split. |
| "We can estimate it after starting" | Inestimable stories signal unclear scope. Clarify before committing. |
| "Good enough -- the team will figure out the details" | Vague stories produce vague implementations. Write precise acceptance criteria. |
| "AskUserQuestion covered the clarification, Discovery is redundant" | AskUserQuestion is informal Q&A. Discovery produces a Feature Specification that validates field optionality, invocation paths, and behavioral Acceptance Criteria under three personas. They are not equivalent. |

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

---

# Instructions for Agent

See `references/CONVERSATION_SCRIPTS.md` for story elicitation conversation scripts.
See `references/PV_PROJECT_CONTEXT.md` for project scope verification and reference loading guide (Particle-Viewer sessions only).

**Always include the Effort Estimate section** with:
- Total premium requests (range)
- Recommended model tier (Economy/Standard/Premium)
- One-sentence reasoning for the model choice

## Related Skills

See the `user-story-estimation` skill for S/M/L size breakdown, premium request ranges, and validated examples. For model tier selection, see `../subagent-driven-development/references/MODEL_SELECTION.md` (Tier Assignments section). Always include the Effort Estimate section in every generated story.
