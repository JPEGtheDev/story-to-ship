---
name: self-evaluation
description: End-of-session self-evaluation for continuous improvement. Run before finalizing any session to capture lessons learned, identify skill updates, and improve agent effectiveness. Use when completing a task, reviewing work quality, or improving project skills.
license: MIT
compatibility: Designed for GitHub Copilot and similar AI coding agents
metadata:
  author: JPEGtheDev
  version: "1.0"
  category: meta
  project: Particle-Viewer
---

# Instructions for Agent

## How This Skill is Invoked

This skill should be invoked:
- **At the end of every coding session**, before the final `report_progress` call
- When explicitly asked: "Run self-evaluation", "What did you learn?", "Improve skills"
- After addressing code review feedback that reveals a recurring pattern

---

## Core Principle: Learn From Every Session

Every session produces insights that can improve future agent effectiveness. Capture these systematically.

---

## Step 1: Review the Session

Examine what happened during this session:

1. **Code review feedback received** — What patterns did reviewers catch?
2. **Mistakes made and corrected** — What errors occurred during implementation?
3. **Owner/user feedback** — What preferences or corrections did the user provide?
4. **Patterns discovered** — What reusable patterns emerged from the work?

---

## Step 2: Categorize Lessons

Classify each lesson into one of these categories:

| Category | Examples | Update Target |
|----------|----------|---------------|
| **Code quality** | Binary file modes, const refs, resource cleanup | `copilot-instructions.md` |
| **Testing** | AAA violations, missing directory setup, save checks | `testing` skill |
| **CI/CD** | Workflow structure, artifact patterns | `workflow` skill |
| **Documentation** | Link fixes, formatting, content standards | `documentation` skill |
| **Architecture** | Design patterns, struct grouping, DI | `copilot-instructions.md` |
| **Process** | PR title format, commit conventions | `copilot-instructions.md` |

---

## Step 3: Check Against Existing Knowledge

Before proposing updates, verify the lesson is not already documented:

1. Check `copilot-instructions.md` — Is this pattern already listed?
2. Check the relevant skill's `SKILL.md` — Is this rule already stated?
3. Check skill `references/` — Is there already an example?

**Only propose additions for genuinely new or underemphasized patterns.**

---

## Step 4: Propose Skill Updates

For each new lesson, propose a specific, minimal update:

### Format for Proposed Updates

```
**Lesson:** [One-line description]
**Source:** [PR #, review comment, or error that revealed this]
**Category:** [From Step 2 table]
**Target File:** [Exact file path to update]
**Proposed Change:** [Specific text to add or modify]
**Priority:** [High = caused bugs/rework, Medium = improved quality, Low = nice to have]
```

### Prioritization Rules

- **High priority:** Patterns that caused bugs, security issues, or significant rework
- **Medium priority:** Patterns that improve code quality or developer experience
- **Low priority:** Style preferences or minor improvements

**Only implement High and Medium priority changes.** Document Low priority for future reference.

---

## Step 5: Apply Updates (If Appropriate)

If changes are warranted and the session scope allows:

1. **Update the relevant skill** — Add the lesson to the appropriate section
2. **Increment the skill version** — Bump the version in YAML frontmatter
3. **Keep changes minimal** — Add only what's necessary, don't restructure
4. **Maintain skill boundaries** — Don't duplicate content across skills

---

## Step 6: Generate Session Summary

Produce a brief summary of lessons captured:

```markdown
### Session Self-Evaluation

**Lessons Captured:** [count]
**Skills Updated:** [list of skills modified, or "None"]
**Key Patterns Added:**
- [Pattern 1: brief description]
- [Pattern 2: brief description]

**Deferred (Low Priority):**
- [Pattern that was noted but not implemented]
```

---

## Anti-Patterns to Avoid

1. **Don't update skills for one-off situations** — Only add patterns that are likely to recur
2. **Don't duplicate across skills** — Each lesson goes in exactly one place
3. **Don't restructure existing skills** — Add to existing sections, don't reorganize
4. **Don't add lessons that are standard programming practice** — Focus on project-specific patterns
5. **Don't forget to check existing docs first** — Avoid adding what's already there

---

## Reference

For detailed examples of lessons learned and how they were incorporated, see [references/LESSONS_LEARNED_PATTERNS.md](references/LESSONS_LEARNED_PATTERNS.md).
