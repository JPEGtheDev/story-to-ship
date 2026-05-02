---
name: self-evaluation
license: MIT
description: Use when completing any session.
---

## Iron Law

```
YOU MUST END EVERY SESSION WITH SELF-EVALUATION.
No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

YOU MUST complete all 7 steps and include the `### Session Self-Evaluation` block before your final message. No exceptions.

Read this skill BEFORE your final message. If you skip it: the session's lessons are lost. Every time.

**Announce at start:** "I am running the self-evaluation skill for this session."

---

## BEFORE PROCEEDING

- [ ] The session's primary task is complete — no further implementation work is planned for this session.
- [ ] All commits from this session have been pushed or are staged and ready.
- [ ] You have NOT yet sent the final message to the user.

✓ All met → proceed through all 7 steps in order
✗ Any unmet → complete remaining session work first; once no further work is planned, return here and execute all 7 steps

---

# Instructions for Agent

## How This Skill is Invoked

This skill is **mandatory** — `copilot-instructions.md` § Session Lifecycle requires it before every final message. You will also be invoked:
- When explicitly asked: "Run self-evaluation", "What did you learn?", "Improve skills"
- After addressing code review feedback that reveals a recurring pattern

---

## Core Principle: Learn From Every Session

Every session produces insights that can improve future agent effectiveness. Capture these systematically.

**Objectivity block:** Agents and humans are structurally poor at evaluating their own work. This is not a character flaw — it is a known bias. The explicit steps below exist to override it. Skipping steps because "it went well" is the bias asserting itself.

---

## Step 1: Review the Session

Examine what happened during this session:

1. **Code review feedback received** — What patterns did reviewers catch?
2. **Mistakes made and corrected** — What errors occurred during implementation?
3. **Owner/user feedback** — What preferences or corrections did the user provide?
4. **Patterns discovered** — What reusable patterns emerged from the work?

---

## Step 2: Categorize Lessons

Classify each lesson into one of these categories. For the full routing table with examples, see `references/LESSONS_LEARNED_PATTERNS.md`.

| Category | Update Target |
|----------|---------------|
| **Code quality** | `code-quality` skill |
| **Testing** | `testing` skill |
| **CI/CD** | `workflow` skill |
| **Documentation** | `documentation` skill |
| **Build** | `build` skill |
| **Versioning** | `versioning` skill |

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

## Step 5: Trust Audit

Before generating the session summary, complete this audit:

**Ask explicitly for each:**

1. **Did I make any false confidence claims?**
   - Used "should work", "done", "tests pass", or "I'm confident" without inline evidence?
   - Each instance is a trust withdrawal. Name them.

2. **Did I show evidence inline, or reference it?**
   - "I ran the tests and they passed" = referenced (does not count)
   - "Ran tests: 247 passed, 0 failures. [exit 0]" = inline (counts)

3. **Did I present any assumptions as facts?**
   - Claimed something about code behavior without reading the code or running the command?

4. **What is the trust balance for this session?**
   - More deposits than withdrawals = trust maintained
   - Any withdrawals = note them; they cost speed in future sessions

5. **Decision accountability:**
   - Did any decisions made during this session produce poor outcomes?
   - For each: name the decision, the evidence it was wrong, and the decision rule that MUST change.
   - "I followed the established pattern" is not accountability if the pattern was wrong.
   - Decisions are accountable regardless of whether they followed a rule. Rule adherence and outcome quality are separate.

6. **Consistency check (integrity under low scrutiny):**
   - Did I apply the same gates in low-visibility moments (single-line changes, quick responses, perceived-trivial tasks) as in high-visibility ones?
   - If I skipped any gate because the task "seemed small," name it. Consistency under low scrutiny is the definition of integrity.

**Report honestly.** If you made false confidence claims, name them. This is not a punishment — it is the calibration mechanism. A model that accurately reports its own false confidence claims is more trustworthy than one that doesn't.

---

## Step 6: Apply Updates (If Appropriate)

If changes are warranted and the session scope allows:

1. **Update the relevant skill** — Add the lesson to the appropriate section
2. **Increment the skill version** — Bump the version in YAML frontmatter
3. **Keep changes minimal** — Add only what's necessary, don't restructure
4. **Maintain skill boundaries** — Don't duplicate content across skills

---

## Step 7: Generate Session Summary

Produce a brief summary of lessons captured:

```markdown
### Session Self-Evaluation

**Lessons Captured:** [count]
**Skills Updated:** [list of skills modified, or "None"]
**Key Patterns Added:**
- [Pattern 1: brief description]
- [Pattern 2: brief description]

**Trust Audit:**
- False confidence claims: [count + what they were, or "None"]
- Evidence shown inline: [yes/mostly/no]
- Trust balance: [positive/neutral/negative]

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

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "I didn't make any mistakes, no need to evaluate" | Every session has lessons. No lessons found = evaluation wasn't thorough enough. |
| "I'll do the self-evaluation next session" | Lessons evaporate overnight. Capture them now while the context is live. |
| "The user seemed satisfied, so the session went well" | User satisfaction ≠ no lessons. Look for near-misses, slow spots, and subtle errors. |
| "Self-evaluation is for big failures only" | Small improvements compound. Consistent small lessons beat occasional big ones. |
| "I already updated one skill — that's enough" | Evaluate all active domains. One skill update is rarely complete coverage. |
| "There's no time — the session is over" | 5 minutes of self-evaluation saves hours in future sessions. Make time. |

---

## Objectivity Block Is Structural

Humans are structurally poor at evaluating their own work. The block is not a personal failing — it is an architectural constraint of human cognition. The response is not "try harder to be objective" but "use structural mechanisms that bypass the block":

- Dispatch a separate reviewer agent rather than self-reviewing
- Compare against the requirements written before the work began, not a remembered version
- Use a checklist created before the session, not reconstructed from memory after it

The corollary for session self-evaluation: the self-evaluation block applies here too. The evaluation in this section is imperfect by construction. Use it to surface what you can, knowing that a separate postmortem reviewer will catch what you cannot. Source: C2 Wiki "HumansAreLousyAtSelfEvaluation".

---

## Red Flags — STOP

If you catch yourself thinking any of these, stop and follow the rule:
- About to send a final message without having read the self-evaluation skill
- "No lessons learned this session"
- "The user is waiting, I'll skip self-eval"
- Updated code but haven't checked if any skills are now stale
- "I already know what I'd write — no need to actually write it"
- Closing a session without the Session Self-Evaluation block in the final message

**All of these mean: Read `.github/skills/self-evaluation/SKILL.md` and complete every step. Then include the `### Session Self-Evaluation` block before your final message.**

---

## Reference

For detailed examples of lessons learned and how they were incorporated, see [references/LESSONS_LEARNED_PATTERNS.md](references/LESSONS_LEARNED_PATTERNS.md).
