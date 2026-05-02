---
name: user-story-generator
license: MIT
description: Use when creating or refining INVEST-aligned user stories.
---

## Iron Law

```
YOU MUST VALIDATE EVERY STORY AGAINST INVEST AND INCLUDE ACCEPTANCE CRITERIA BEFORE SHIPPING.
No exceptions.
```
Violating the letter of this rule is violating the spirit of this rule.

YOU MUST validate every story against all six INVEST criteria (Independent, Negotiable, Valuable, Estimable, Small, Testable) and include at least one acceptance criterion before shipping. No exceptions.

**Announce at start:** "I am using the user-story-generator skill to create/refine a story for [brief description]."

## BEFORE PROCEEDING

After you've had the conversation and before generating, mentally verify you have:
- [ ] **Verified this aligns with actual project purpose** (loaded project context)
- [ ] **Confirmed the functionality/component actually exists** (didn't assume based on naming)
- [ ] Clear understanding of what they want to accomplish
- [ ] Context about why it matters (the value)
- [ ] Rough scope and size estimate (S/M/L)
- [ ] Premium request estimate based on complexity
- [ ] Model recommendation with reasoning
- [ ] Format preference (if they expressed one)
- [ ] Any specific constraints or requirements

**If any of these are unclear, ask one more clarifying question before generating.**

**RED FLAGS - Stop and ask for clarification:**
- Story mentions functionality not in project context
- Acceptance criteria test features that don't exist
- Technical notes reference non-existent architecture
- User story assumes capabilities the project doesn't have

## INVEST Checklist

Every generated story MUST be:
- **Independent** – no hard dependencies on unstarted work
- **Negotiable** – focus on "what" not "how"
- **Valuable** – clear benefit stated in "So that" clause
- **Estimable** – team can size it (provide S/M/L estimate)
- **Small** – doable in one sprint
- **Testable** – acceptance criteria are verifiable

If a story violates INVEST, fix it or suggest breaking it down.

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
| "Good enough — the team will figure out the details" | Vague stories produce vague implementations. Write precise acceptance criteria. |

## Red Flags — STOP

- Story has no acceptance criteria
- Story requires another story to be done first ("depends on #X")
- Story spans multiple unrelated components or layers
- "We'll know it's done when it feels right"
- Story takes more than one sprint to deliver
- Can't write a failing test for the acceptance criteria

**All of these mean: split the story, clarify the criteria, or restructure the work.**

---

# Instructions for Agent

See `references/CONVERSATION_SCRIPTS.md` for story elicitation conversation scripts.
See `references/PV_PROJECT_CONTEXT.md` for project scope verification and reference loading guide.

**Always load `references/PV_PROJECT_CONTEXT.md` FIRST before generating any story.**

**Always include the Effort Estimate section** with:
- Total premium requests (range)
- Recommended model tier (Small/Standard/Advanced)
- One-sentence reasoning for the model choice

## Related Skills

See the `user-story-estimation` skill for S/M/L size breakdown, premium request ranges, model tier selection, and validated examples. Always include the Effort Estimate section in every generated story.
