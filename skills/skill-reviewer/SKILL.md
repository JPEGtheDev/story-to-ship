---
name: skill-reviewer
license: MIT
description: Use when authoring or updating skill files.
---

## Iron Law

```
YOU MUST ENSURE EVERY SKILL HAS ALL FIVE GATE ELEMENTS.
No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

YOU MUST ensure every skill has all five gate elements. Missing any one = incomplete skill. No exceptions.

**Announce at start:** "I am using the skill-reviewer skill to review [skill-name]."

---

## The Five Gate Elements

Every skill MUST contain ALL of the following. Missing any one element is an automatic FAIL.

1. **Iron Law** — `## Iron Law` section with backtick-wrapped law statement, "No exceptions" language, and "YOU MUST" phrasing
2. **Announcement requirement** — explicit line: "Announce at start: I am using [skill] to [purpose]"
3. **Gate Function** — at least one BEFORE PROCEEDING gate with numbered conditions and explicit YES/NO branches
4. **Rationalization Prevention table** — minimum 5 rows, each naming a specific excuse with a specific counter
5. **Red Flags→STOP section** — minimum 5 trigger thoughts, each with a concrete action to take

---

## Review Checklist

Run every item for each skill file under review:

- [ ] Iron Law block present and uses hard language ("YOU MUST", "No exceptions", bright-line rule)?
- [ ] Announcement requirement is explicit (exact wording required, not implied)?
- [ ] Gate Function present (at least one BEFORE PROCEEDING gate with numbered conditions and YES/NO branches)?
- [ ] Rationalization Prevention table present with ≥5 rows?
- [ ] Red Flags→STOP section present with ≥5 trigger thoughts?
- [ ] Skill-specific commands present (not generic placeholder examples)?
- [ ] Cross-references to at least 1 related skill?
- [ ] No cross-skill file path references (other skills referenced by skill name, not by `../other-skill/references/FILE.md` paths)?
- [ ] If any cross-skill path was fixed during this review: replacement text itself checked for embedded path fragments (`/references/`, `../`, `.md` filename referencing another skill's content)?
- [ ] Domain language matches skill scope — language-specific skills use appropriate conventions; generic skills use language-agnostic terminology?
- [ ] No absolute paths (no machine-specific prefixes — use `[REPO_ROOT]`, template variables, or relative references only)?

✓ All pass → verdict: PASS
✗ Any unmet → verdict: NEEDS WORK — list every failing item in the Issues Found section

---

## Dispatch Pattern

For every skill file being reviewed:

1. Dispatch one agent per file — parallel, don't wait.
2. Give each agent: file path, recent changes, and the five-element checklist.
3. Collect all reports before acting.
4. For each FAIL: update the skill and re-dispatch a review of that element.

---

## Review Report Format

Each skill-reviewer agent MUST return findings in this exact structure:

```markdown
## Skill Review: [skill-name]

### Gate Elements
| Element | Present | Quality | Notes |
|---------|---------|---------|-------|
| Iron Law | ✅/❌ | Strong/Weak | ... |
| Announcement | ✅/❌ | Clear/Vague | ... |
| Gate Function | ✅/❌ | Present/Absent | ... |
| Rationalization Table | ✅/❌ | N rows | ... |
| Red Flags→STOP | ✅/❌ | N items | ... |

### Issues Found
[List each issue with file:line reference]

### Verdict: PASS / NEEDS WORK
```

NEEDS WORK means the skill MUST be updated before production dispatch.

---

## Red Flags — STOP

If you catch yourself thinking any of the following, STOP and re-examine before filing your verdict:

- "It has most of the required elements" → Stop. Count every element. Partial is FAIL.
- "The iron law is present but mild" → Stop. Re-read the law. Does it use "YOU MUST" or "No exceptions"? If not, mark Weak.
- "There are only 4 rows in the rationalization table, close enough" → Stop. Count them. ≥5 is the rule. 4 is a FAIL.
- "The announcement is implied by the skill description" → Stop. It must be an explicit line. Implied is a FAIL.
- "I'll note the issues but still give PASS" → Stop. There is no PASS with open issues. Verdict is NEEDS WORK.
- "The path looks fine, it's just an example" → Stop. Any machine-specific absolute path is a FAIL regardless of context.

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "It has some enforcement language, close enough" | All five elements are required. Partial is FAIL. No exceptions. |
| "The rationalization table is implied by the red flags" | They serve different cognitive functions. Both are required independently. |
| "This skill is simple, it doesn't need all elements" | All skills need all elements. Consistency is the point. |
| "I'll add the missing table later" | Later never comes. A skill without all five elements is incomplete. Add it now. |
| "The iron law is already stated in the announcement" | They are separate sections with separate functions. Both are required. |
| "The cross-skill path reference is just for convenience, it's fine" | Cross-skill file paths break when skills are reorganized. Name the owning skill in prose; let the agent navigate. See SIZE_AND_COMPRESSION.md Skill Composition Model. |
| "The domain language seems fine, I won't check closely" | Wrong-language examples (e.g., npm/pip in a C++/CMake skill, or C++ specifics in a language-agnostic skill) are a FAIL. Check every command and example. |
| "I can review inline — the file is small" | Inline review is biased. Dispatch task(agent_type="code-review"). Producing a review table inline = this violation. |
| "I replaced the cross-skill path with prose — the fix is good" | The replacement text may still contain a path fragment. Re-read the edited line: does it contain `/references/`, `../`, or a `.md` filename from another skill? If yes, the fix is incomplete — replace with skill-name prose only. |
| "Stage 1 FAIL is stale — my edits made it correct; I verified with bash" | A bash `ls` or self-inspection is not equivalent to an independent Stage 1 review. Re-dispatch the reviewer pointed at the current on-disk state. Self-verification does not satisfy the review gate. |

---

## Related Skills

- `self-evaluation` — uses this skill's checklist when reviewing skills updated during a session
- `documentation` — governs how skills are structured, linked, and formatted
