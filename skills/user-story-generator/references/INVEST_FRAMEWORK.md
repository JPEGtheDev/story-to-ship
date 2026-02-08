# INVEST Framework

**INVEST** is a checklist for well-formed user stories in Agile development. Each letter represents a principle:

## I – Independent

**What it means:** Stories should have minimal dependencies on other stories.

**Why it matters:** Independent stories can be:
- Picked up by any team member without waiting
- Tested in any order
- Released incrementally without blocking other work

**How to check:**
- [ ] This story doesn't require another story to be completed first
- [ ] Subtasks can be integrated back into the codebase independently
- [ ] External APIs/services are mocked or available

**Red flags:**
- "After Story #42 is done, we can start this"
- Dependencies on infrastructure not yet deployed
- Tightly coupled to another team's work

---

## N – Negotiable

**What it means:** Details are flexible until the story enters the sprint; the goal is fixed, but how to achieve it can be refined.

**Why it matters:**
- Leaves room for team input and creativity
- Avoids over-specifying solutions in advance
- Allows for scope adjustments based on learnings

**How to check:**
- [ ] Story title focuses on "what" not "how"
- [ ] Acceptance criteria describe outcomes, not implementation details
- [ ] There's room to discuss technical approach during sprint planning

**Red flags:**
- "Use React hooks to refactor this component"
- "Must use the XYZ library"
- Highly prescriptive step-by-step instructions

---

## V – Valuable

**What it means:** The story delivers clear value to the user, business, or codebase.

**Why it matters:**
- Prevents busywork that doesn't matter
- Justifies the effort and time spent
- Keeps the team aligned on priorities

**How to check:**
- [ ] User, business, or technical stakeholder can articulate the value
- [ ] "So that" clause is compelling and concrete
- [ ] Story doesn't exist just because "we should do it"

**Red flags:**
- "So that we follow best practices" (vague)
- "Because the tech debt backlog says so" (no real value)
- Story with no clear "why"

---

## E – Estimable

**What it means:** The team can roughly estimate how long the story will take.

**Why it matters:**
- Allows sprint planning and commitment
- Identifies stories that are too vague (can't estimate = need more info)
- Helps identify stories that are too large

**How to check:**
- [ ] Team has domain knowledge to estimate
- [ ] Acceptance criteria are clear enough to size
- [ ] Similar work has been done before (or spike is planned)

**Red flags:**
- "We've never done this before, total mystery"
- Acceptance criteria are vague ("improve performance")
- Dependencies on unknowns (waiting for vendor response)

---

## S – Small

**What it means:** Stories should be completable within one sprint (typically 1–2 weeks).

**Why it matters:**
- Fast feedback loops
- Easier to test and review
- Reduces risk of scope creep
- Multiple stories can be merged and released frequently

**How to check:**
- [ ] This story can be completed in 3–5 days max
- [ ] One developer (or small pair) can own it start-to-finish
- [ ] Fits comfortably in the sprint timeline

**Red flags:**
- Story is labeled "Epic" but not broken down
- Estimated at "M" or "L" size
- Multiple teams need to coordinate to complete it
- Timeline spans multiple sprints

---

## T – Testable

**What it means:** Acceptance criteria are concrete, measurable, and verifiable—not subjective.

**Why it matters:**
- Team knows when story is truly "done"
- Reduces ambiguity and rework
- Enables automated testing and CI/CD integration

**How to check:**
- [ ] Each acceptance criterion can be verified with a test (manual or automated)
- [ ] No vague language ("should be fast", "looks good")
- [ ] Definition of Done includes test coverage targets

**Red flags:**
- "Code should be clean"
- "UI should be user-friendly"
- "Performance should be better"
- No measurable metrics

---

## INVEST Validation Checklist

Use this checklist when creating or refining a user story:

```
Story: ____________________________________

Independence:
  [ ] No hard dependencies on unstarted stories
  [ ] Can be picked up by any available developer
  [ ] Subtasks integrate independently

Negotiable:
  [ ] Title focuses on outcome, not implementation
  [ ] Solution approach is not prescriptive
  [ ] Open to discussion during sprint planning

Valuable:
  [ ] Clear business or technical value
  [ ] "So that" clause is compelling
  [ ] Stakeholders agree on priority

Estimable:
  [ ] Team can rough-size the story
  [ ] Acceptance criteria are clear
  [ ] No hard blockers (unknowns) before starting

Small:
  [ ] Completable in one sprint (<2 weeks)
  [ ] One developer/pair can own it
  [ ] Not an Epic or large feature

Testable:
  [ ] All acceptance criteria are measurable
  [ ] Can be verified with tests (manual or automated)
  [ ] Definition of Done is clear
```

---

## Common Pitfalls

### ❌ Too Large (Not Small + Estimable)
**Bad:** "Refactor the entire authentication system"
**Good:** "Extract JWT validation into a reusable service class"

### ❌ Too Vague (Not Testable + Estimable)
**Bad:** "Improve the dashboard"
**Good:** "Add a real-time activity feed widget showing last 10 actions"

### ❌ Too Prescriptive (Not Negotiable)
**Bad:** "Use React Context API to manage global state"
**Good:** "Eliminate prop-drilling in the checkout flow"

### ❌ Low Value (Not Valuable)
**Bad:** "Upgrade Bootstrap from v4 to v5"
**Good:** "Upgrade Bootstrap to unlock new accessibility features and reduce bundle size by 15%"

### ❌ Dependent (Not Independent)
**Bad:** "Add user dashboard (waiting for API team to finish endpoints)"
**Good:** "Mock user API endpoints for dashboard development"

---

## References

- [Bill Wake's INVEST](https://xp123.com/articles/invest-in-good-stories-and-smart-tasks/)
- [Agile Alliance – User Stories](https://www.agilealliance.org/glossary/user-stories/)
