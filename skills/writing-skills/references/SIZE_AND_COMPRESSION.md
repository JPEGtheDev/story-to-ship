# Size and Token Efficiency

**Why this matters:** Skills are written for GPT-4.1 as the baseline. Every instruction must be mechanically precise and literally executable — no nested conditionals, no implied reasoning chains. Verbose skills evict iron law content from the context window.

---

## Token Count Targets

| Skill type | Target | Hard limit |
|------------|--------|------------|
| EXECUTION / QUALITY (frequently loaded) | ≤ 650 tokens | 1,000 tokens |
| DELIVERY / REVIEW / KNOWLEDGE | ≤ 800 tokens | 1,300 tokens |
| Sub-domain skills | ≤ 300 tokens | 600 tokens |
| Reference files (not SKILL.md) | No limit — loaded on demand |
| All types (agentskills.io spec cap) | — | 5,000 tokens |

Token estimate: `chars / 4` is a reliable approximation for technical Markdown.

**Check before shipping:**
```bash
wc -c .github/skills/<skill-name>/SKILL.md | awk '{print int($1/4) " tokens"}'
```

---

## Writing for Mechanical Execution (GPT-4.1 Baseline)

Every line in every skill MUST satisfy this test: **Can a GPT-4.1 class model execute this instruction literally without inferring intent?**

Rules:
- Use imperative sentences. Not "you should check" — "Check. Stop if not met."
- Flatten all conditional logic into sequential steps. No "if X then Y else Z" — write two separate rules.
- No implicit dependencies. If a gate requires loading another skill, say: "Load `[skill]` now. Do not proceed until loaded."
- Iron law comes FIRST — before explanation, before context.
- Announcement comes SECOND — it is a commitment mechanism, not a courtesy.
- Gate function comes THIRD — step-by-step with explicit STOP conditions.

---

## Compression Rules

1. **Move heavy reference to a `references/` file — never delete it.**

   GOOD: Skill file has one pointer: `See references/NAMING_RULES.md for full naming tables.`
   BAD: Naming tables deleted to save lines — the same naming mistakes now recur with no documented reason why the rule exists.

2. **Never delete content when compressing — move it.** Move excess to `references/`. Decision rationale, examples, and "why we did this" explanations belong in references even if not loaded every session. A deleted "why" gets rediscovered the hard way.

   GOOD: References file states: "We use `m_` prefix because clang-tidy rule `readability-identifier-naming` enforces it — removing the prefix silently breaks CI."
   BAD: Rationale removed to save lines. Next engineer removes `m_` prefixes not knowing why. CI breaks.

3. **Never repeat content another skill owns.** Cross-reference with a one-line pointer.

   GOOD: `execution` skill says: "For commit format, see the `versioning` skill."
   BAD: `execution` skill copies the full conventional commit table from `versioning` — both diverge over time.

4. **One example per pattern.** Delete redundant examples.

   GOOD: One test name example showing `ClassName_Action_ExpectedResult`.
   BAD: Six variations of the same pattern — models pick the last example seen, not the rule.

5. **Description field never summarizes workflow.** See `references/SKILL_ANATOMY_ELEMENTS.md` Element 1.

   GOOD: `description: Use when writing or reviewing any test.`
   BAD: `description: Use when writing tests. Follows AAA pattern, enforces naming, handles Google Test patterns.` — models followed the description instead of reading the skill body.

---

## Skill Composition Model

Skills compose by name, never by cross-skill file path.

**Rules:**
- Reference files are **private** to their owning skill. A reference file in `skill-A/references/FOO.md` is owned by `skill-A`. Other skills must not link directly to it.
- Cross-skill composition uses prose naming only: `"See the \`versioning\` skill"` or `"Load the \`testing\` skill"`.
- Never write: `See [OOP_PRINCIPLES.md](../oop-principles/references/OOP_PRINCIPLES.md)` — this creates a brittle cross-skill file path dependency.

**Why:** Direct cross-skill file path references break when skills are reorganized, renamed, or composed in a different context. Naming the owning skill is stable — the agent loads the skill and navigates from there.

GOOD: `"For commit format, see the \`versioning\` skill."`
BAD: `"See [CONVENTIONAL_COMMITS.md](../versioning/references/CONVENTIONAL_COMMITS.md)"` — cross-skill path, brittle.

---

## Size Limits (Lines — secondary; token count above is primary)

| Skill type | Target | Hard limit |
|------------|--------|------------|
| Frequently loaded (EXECUTION, QUALITY) | ≤300 lines | 500 lines |
| Reference skills (DELIVERY, REVIEW) | ≤250 lines | 400 lines |
| Sub-domain skills | ≤150 lines | 200 lines |

When a skill exceeds its hard limit, split by domain. Each split must have a distinct iron law.
