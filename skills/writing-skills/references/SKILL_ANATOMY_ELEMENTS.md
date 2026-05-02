#Skill Anatomy — Element Reference

Full schemas and examples for each of the 5 required skill elements.

---

## Element 1: Frontmatter

```yaml
---
name: skill-name-with-hyphens
description: Use when [triggering conditions and symptoms only]
---
```

**Rules:**
- `description` = triggering conditions ONLY. Never summarize what the skill does.
- If the description summarizes workflow, the model will follow the description instead of reading the skill body.
- Start with "Use when..." in third person
- Keep under 200 characters

**Bad (workflow summary):**
```yaml
description: Use when writing tests. Follows AAA pattern, naming conventions, covers Google Test patterns.
```

**Good (triggering conditions):**
```yaml
description: Use when writing or reviewing any test for Particle-Viewer.
```

---

## Element 2: Iron Law

```markdown
## Iron Law

​```
[ALL CAPS RULE — no exceptions language]
​```

Violating the letter of this rule is violating the spirit of this rule.
```

The "letter/spirit" line is mandatory. It closes the rationalization gap where agents argue "technically I followed the rule" while violating its intent.

---

## Element 3: Announcement

```markdown
**Announce at start:** "I am using the [skill-name] skill to [purpose]."
```

This is the commitment mechanism. Public commitment to a behavior increases follow-through.

---

## Element 4: Gate Function

Every skill must have at least one BEFORE PROCEEDING gate:

```markdown
BEFORE [action], verify:
1. [Condition one]
2. [Condition two]
3. [Condition three]

✓ All met → proceed
✗ Any unmet → [specific required action before proceeding]
```

Gates must specify what happens on FAIL — not just list conditions.

---

## Element 5: Rationalization Table

```markdown
## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "[specific rationalization]" | [direct counter] |
```

Rationalization tables are the most powerful element — they preemptively name the excuses and counter them before the agent reaches for them.

---

## Optional Element: Canary

```markdown
## Canary

[Required output — the specific line the agent must state, in exact format]
[When — before which specific action must this appear]
[Note — what it proves and what it does not prove; do not overclaim]
```

**When to add:** Include a `## Canary` section when the skill's most-missable rule produces no visible artefact when skipped and can be expressed as a specific, behavioral output. Not every skill needs one — sparse deployment is what gives it signal value.

**Placement:** Mid-document. NOT at the top, NOT inside the Iron Law, NOT inside BEFORE PROCEEDING. Buried placement is intentional: an agent that skims section headers will miss it.

**Required fields:**
1. The exact output format (what to state, verbatim or templated)
2. When it must appear (before which specific action)
3. What it signals — and honestly, what it does not prove (no overclaiming the mechanism)

**Prohibited fields:**
- Multiple required outputs (one observable signal per Canary — more than one dilutes verification)
- Reproduction of Iron Law text (the Canary is a behavioral signal, not a rule restatement)
- Claims of cryptographic proof of execution (the Canary raises cost, not certainty)

**When to omit:**
- The rule is already enforced structurally (a failing test, a build error — the system is the canary)
- No single step in the skill is both critical and leaves no visible artefact when skipped
- The skill's most-missable rule cannot be expressed as a uniquely verifiable output

**Example (from `subagent-driven-development`):**
> Before dispatching any agent, state: `` `Worktree: [output of: git -C .worktrees/agent-<name> rev-parse --show-toplevel]` ``
> This is the observable signal that BEFORE PROCEEDING step 3 was executed, not skipped. The canary raises the cost of skipping for compliant agents — it is not cryptographically bound to execution.
