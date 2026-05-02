---
name: writing-skills
license: MIT
description: Use when creating, editing, or reviewing a skill file.
---

<!-- Tier 1 — Methodology. No project-specific references in this file. -->

## Iron Law

```
NO SKILL SHIPS WITHOUT MEETING THE 5-ELEMENT ANATOMY CHECK
```

Violating the letter of this rule is violating the spirit of this rule.

YOU MUST verify all 5 elements are present before shipping any skill. No exceptions.
Missing any single element means the skill is incomplete — fix it before using it.

**Announce at start:** "I am using the writing-skills skill to [create/edit/review] the [skill-name] skill."

---

## BEFORE PROCEEDING

Before creating, editing, or shipping any skill or agent template:

1. **Creating a new skill?** Will it be invoked in ≥1% of sessions?
   - YES → proceed
   - NO → write a reference doc in the relevant skill's `references/` instead; do not create a skill

2. **5-element anatomy check** — all 5 MUST be present:
   - [ ] FRONTMATTER: `name` + `description` starting with "Use when..."
   - [ ] IRON LAW: ALL CAPS rule + "Violating the letter..." line + "YOU MUST" + "No exceptions."
   - [ ] ANNOUNCEMENT: `**Announce at start:** "I am using the [skill] to [purpose]."`
   - [ ] GATE FUNCTION: `## BEFORE PROCEEDING` with numbered conditions + ✓/✗ branches
   - [ ] RATIONALIZATION TABLE: `## Rationalization Prevention` with ≥5 rows

3. **Alexandrian form check** — every non-trivial rule MUST answer:
   - **Context:** When does this rule apply? When does it NOT apply?
   - **Forces:** What tension or constraint does this rule resolve?
   - A rule without Context and Forces cannot be applied correctly in edge cases.
   - New skills: MUST include Context + Forces for every non-trivial rule.
   - Existing skills: add Context + Forces incrementally when touched — no big-bang retrofit.

4. **Reference reading gate:**
   - Editing frontmatter only (no anatomy changes)? → reference files optional
   - Modifying or adding anatomy elements? → read `references/SKILL_ANATOMY_ELEMENTS.md` before any edits

5. **Auditing existing skills (not creating or editing one)?** Before dispatching any agent:
   - Run `wc -c .github/skills/*/SKILL.md | awk '{print int($1/4) " tokens — " $2}'` and compare results against `references/SIZE_AND_COMPRESSION.md` limits
   - Enumerate every audit dimension explicitly in each agent's prompt
   - The anatomy gate above applies to editing skills — audit use cases require their own dimension list; unnamed dimensions will not be checked

6. **What tier is this skill?** Every new skill MUST declare its tier:
   - **Tier 1 — Methodology:** no project names, paths, or tech stacks in any core section.
   - **Tier 2 — Domain/Project:** project references allowed; use `docs/` first — DO NOT create a skill when `docs/` is sufficient; only create if it must function as a behavioral gate.
   - See `## Project-Agnostic Authoring Rule` below for full definition.

✓ All met → proceed
✗ Any unmet → resolve the unmet item before touching the skill file
↳ Auditing (not creating/editing)? → The ✓/✗ above applies to creation/editing only. For auditing, run the step 5 sub-tasks; proceed once all dimensions are named in each agent's prompt.

---

# Instructions for Agent

## The 1% Threshold Gate

**BEFORE creating a new skill, verify it meets the threshold:**

```
GATE: Will this skill be invoked in at least 1% of development sessions?

YES → proceed to create the skill
NO  → document the pattern in the relevant skill's references/ directory instead
```

---

## DDD Bounded Context Map

Every skill belongs to exactly one bounded context. Place new skills in the correct context.

| Context | Domain | Skills |
|---------|--------|--------|
| **EXECUTION** | How work is planned and done | execution, writing-plans, brainstorming, subagent-driven-development, dispatching-parallel-agents, using-git-worktrees |
| **QUALITY** | How code meets correctness standards | testing, visual-regression-testing, code-quality, cpp-patterns, verification-before-completion, systematic-debugging |
| **DELIVERY** | How code ships | versioning, build, workflow, finishing-a-development-branch |
| **REVIEW** | How work is validated | architecture-review, infrastructure-review, skill-reviewer, requesting-code-review, receiving-code-review |
| **REFLECTION** | How the agent improves | self-evaluation, session-postmortem |
| **KNOWLEDGE** | How knowledge is captured | documentation, writing-skills, summarization |
| **PRODUCT** | How features are defined | user-story-generator, user-story-estimation |
| **BEHAVIOR** | How the agent behaves honestly and bootstraps | honesty, session-bootstrap |

**Sub-domain skills** (e.g., `visual-regression-testing` under QUALITY) are valid when they have a distinct iron law and are invoked independently of the parent skill.

---

## Project-Agnostic Authoring Rule

**Context:** Applies when creating any new skill or agent template. Does NOT apply to `copilot-instructions.md`, dispatch prompt parameters, or `docs/` reference files — those are intentionally project-specific.

**Forces:** Skills embedded with project names, file paths, or tech stacks cannot be read in isolation. A reader needs external project context to interpret them. When the skill is adopted by a different project, it becomes misleading rather than useful.

**Solution:** Every skill declares one of two tiers at creation time. State the tier at the top of the skill body.

| Tier | Domain | Rule |
|------|--------|------|
| **Tier 1 — Methodology** | Planning, testing, debugging, workflow gates | No project names, file paths, or project-specific tech stacks in any core skill section. Project context belongs in `copilot-instructions.md` and in dispatch prompts via `{{PARAMETERS}}`. A Tier 1 skill must be portable: any project adopting it updates `copilot-instructions.md` alone. |
| **Tier 2 — Domain/Project** | Build tooling, deployment, project-specific operations | Project references are permitted when the domain IS the project context. Use project-specific documentation (`docs/`) first — DO NOT create a skill when `docs/` is sufficient. Only create a Tier 2 skill when it must function as a loaded behavioral gate — not for reference material alone. |

**Declare tier at the top of the skill body.** Example:
```
<!-- Tier 1 — Methodology. No project-specific references in this file. -->
```

**Consequences:** Tier 1 skills require translating project-specific context into `{{PARAMETERS}}` at dispatch time rather than hardcoding it. This adds one dispatch-authoring step but makes the skill reusable across projects.

**Existing skills:** Audited and updated for tier compliance incrementally over time — no big-bang retrofit required. All new skills must comply from creation.

---

## Skill Anatomy — 5 Required Elements

Every skill MUST contain all five elements:

```
1. FRONTMATTER    — name + description (triggering conditions only)
2. IRON LAW       — ALL CAPS rule + "letter/spirit" line
3. ANNOUNCEMENT   — "I am using [skill] to [purpose]"
4. GATE FUNCTION  — BEFORE PROCEEDING: numbered steps with YES/NO branches
5. RATIONALIZATION TABLE — specific excuses with counters
```

Any absent element = skill is incomplete. Fix before shipping.

**Frontmatter also applies to agent templates:** `.github/agents/*.md` prompt template files require the same `name` + `description` YAML frontmatter block as skill files. Missing frontmatter causes parse errors when the CLI loads the agent.

---

See `references/SKILL_ANATOMY_ELEMENTS.md` for full element schemas, bad/good examples, and rationale for each element.

---

## Alexandrian Pattern Form

Every non-trivial rule in a skill file MUST answer four questions. Rules that omit Context and Forces are applied by rote and misfire in edge cases.

```
Context:      When does this rule apply? What situation triggers it?
              When does it NOT apply? What are the explicit exceptions?
Forces:       What tension or constraint does this rule resolve?
              What goes wrong without it?
Solution:     The rule itself — what to do.
Consequences: What does this approach sacrifice or trade off?
```

**Example — bare rule (wrong):**
> Never swallow errors silently.

**Example — Alexandrian form (correct):**
> **Context:** Applies when writing any call to an external system that can fail (file I/O, network requests, resource allocation). Does NOT apply to polling loops where error accumulation is intentional.
> **Forces:** Silent failures propagate broken state downstream, making root cause invisible at the point of symptom. Continuing in an unknown state causes more damage than stopping.
> **Solution:** Always check return status after fallible calls. Log and terminate for unrecoverable state; log and return a failure indicator for recoverable failures.
> **Consequences:** Terminates or surfaces errors on unrecoverable failures — correct for developer builds; end-user releases may need a graceful degradation path instead.

**Compliance gate:** New skills ship with Alexandrian form on every non-trivial rule. Existing skills add it incrementally when touched — the BigBatchRewrite anti-pattern applies here too.

---

## Voice Authority Rules

See `references/VOICE_AUTHORITY_RULES.md` for the full voice quality rules (authority table, Absolute Path Rule, Acronym Rule). Apply all three to every line of every skill.

---

See `references/SIZE_AND_COMPRESSION.md` for token count targets, the GPT-4.1 mechanical execution rules, compression rules, and line limits.

---

## Red Flags — STOP

- Creating a skill for a pattern in fewer than 1% of sessions — **STOP. Write a reference doc instead.**
- Description field contains "covers", "enforces", "provides", "includes" — **STOP. It summarizes workflow. Rewrite to "Use when [conditions]."**
- Iron Law lacks "letter/spirit" line — **STOP. Add "Violating the letter of this rule is violating the spirit of this rule." now.**
- Iron Law lacks "YOU MUST" and "No exceptions." — **STOP. Both phrases are required. Add them.**
- No BEFORE PROCEEDING gate — **STOP. Add a gate with explicit YES/NO branches before shipping.**
- No rationalization table — **STOP. Add ≥5 rows now. A skill without one is a suggestion.**
- Skill contains "should", "prefer", "consider" — **STOP. Replace every instance with MUST, DO NOT, or an explicit imperative.**

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "The description is good enough as-is" | If it mentions what the skill does (not when to use it), models will follow the description instead of reading the skill |
| "Letter/spirit line is redundant" | It explicitly closes the rationalization that "technically I followed the rule" |
| "Rationalization tables are overkill" | They are the highest-ROI element — they name and counter excuses before they occur |
| "This pattern only comes up occasionally" | If it's occasional, it belongs in a reference doc, not a skill |
| "I'll add the gate function later" | A skill without a gate is a suggestion, not a constraint |
| "Context and Forces are extra writing overhead" | Rules without context are applied by rote and misfire in edge cases. The overhead is the point — it forces clarity about when the rule actually applies. |

---

## Related Skills

- `skill-reviewer` — runs the 5-element gate check on completed skills; dispatch 1 per file
- `documentation` — governs how skill reference docs are structured, formatted, and linked
- `self-evaluation` — reviews skills updated during a session using this checklist

## Reference Reading Gate

```
Editing frontmatter only (no anatomy changes)?
  YES → reference files optional
  NO  → SKILL_ANATOMY_ELEMENTS.md MUST be read before making changes
Creating a new skill or modifying anatomy elements (iron law, gate, rationalization table)?
  → View references/SKILL_ANATOMY_ELEMENTS.md now — before any edits
```

## References

- `writing-skills/references/SKILL_ANATOMY_ELEMENTS.md` — full element schemas, bad/good examples, rationale for each of the 5 elements
- `writing-skills/references/SIZE_AND_COMPRESSION.md` — token count targets, GPT-4.1 mechanical execution rules, compression rules, line limits
- `writing-skills/references/VOICE_AUTHORITY_RULES.md` — authority table, Absolute Path Rule, Acronym Rule; embed directly in reviewer agent prompts
- `writing-skills/references/MODEL_COMPATIBILITY.md` — patterns most likely to be skipped by lower-end models and how to write skills that survive them
