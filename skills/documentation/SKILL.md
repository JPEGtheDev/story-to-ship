---
name: documentation
license: MIT
description: Use when creating docs, updating guides, writing API references, or reviewing documentation for Particle-Viewer.
---

## Iron Law

```
EVERY DOC IS SMALL, TAGGED, AND LINKED — ONE CONCEPT PER FILE
```

Violating the letter of this rule is violating the spirit of this rule.

YOU MUST keep every doc file under 600 words, include YAML frontmatter on every doc, and add a Related section at the bottom. No exceptions.

**Announce at start:** "I am using the documentation skill to [write/update/review] [description]."

---

## BEFORE PROCEEDING — Domain Classification Gate

Before writing any documentation:

1. Identify the **domain** and **subdomain** from the taxonomy in `references/DOCUMENTATION_EXAMPLES.md`
2. Confirm the file belongs in `docs/<domain>/<subdomain>/` (not a flat root file unless it's a cross-cutting standard)
3. Confirm no existing file already covers this concept — link to it instead of duplicating

✓ All 3 met → proceed to write
✗ Any unmet → resolve before writing a single line

---

## Step 1: Determine Documentation Type

| Type | Location |
|------|----------|
| API/class reference | Header file comments (≤5 lines inline; longer → `docs/`) |
| Domain guides | `docs/<domain>/<subdomain>/` — one concept per file, ≤600 words |
| Cross-cutting standards | `docs/UPPERCASE.md` |
| Copilot skills | `.github/skills/<name>/SKILL.md` |
| Skill reference content | `.github/skills/<name>/references/*.md` |
| Agent onboarding | `.github/copilot-instructions.md` — summarize only |

---

## Step 2: Apply Frontmatter and Linking Rules

Every `docs/` file MUST begin with YAML frontmatter — schema in `references/DOCUMENTATION_EXAMPLES.md`.

Required fields: `title`, `description`, `domain`, `subdomain`, `tags`, `related`.

- `description` MUST be one concrete sentence that answers: what exactly does this file cover?
- `tags` MUST include domain and subdomain as the first two entries
- `related` uses relative paths from the file's own directory

Every doc file MUST end with a `## Related` section with at least one annotated link.

### Document Mode vs Thread Mode

All files in `docs/` MUST be **Document Mode** — readable independently, with no assumed conversational context. **Thread Mode** writing (responses that only make sense inside a conversation) belongs in chat, not in documentation. If a paragraph requires "as discussed above" or "in the previous message," it is Thread Mode. Rewrite it or cut it.

### Formatting Standards

1. Use markdown for all documentation
2. Include a Table of Contents for documents with 3+ sections
3. Use code blocks with language tags for all code examples
4. Use relative links — verify they resolve from the file's directory
5. Keep file ≤600 words; split at concept boundaries if longer

---

## Step 3: Update copilot-instructions.md When Adding a New Skill

Update all 4 locations:
1. **Skills Directory table** — add row with name, path, domain
2. **Before Every Response checklist** — add item if the skill has a HARD-GATE
3. **Minimum skill loads table** — add the row(s) for when this skill MUST be read
4. **Instruction Priority Hierarchy** — only if the skill introduces a new priority tier

Skipping any location makes the skill effectively invisible. For templates and code examples for each update location, see `references/DOCUMENTATION_EXAMPLES.md`.

---

## Step 4: Review Checklist

Before presenting documentation, verify:

- [ ] YAML frontmatter is present with all required fields
- [ ] File is in the correct domain/subdomain directory
- [ ] File is ≤600 words
- [ ] All relative links resolve correctly from the file's directory
- [ ] Code examples have language tags
- [ ] No content duplicated from another file — linked instead
- [ ] `## Related` section is present at the bottom
- [ ] Documentation matches current code state

✓ All pass → documentation is ready to present
✗ Any unmet → resolve all failing items before presenting

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "I'll add frontmatter later" | Without frontmatter the doc is invisible to search. |
| "One big file is easier to navigate" | Large files produce poor retrieval chunks. Split at concepts. |
| "The related section is optional" | Without it, the retrieval graph has no edges. Link or the doc is isolated. |
| "I'll document it after it's working" | Documentation written separately from code drifts immediately. Write with the code. |
| "A long comment will do for now" | Comments >5 lines belong in `docs/`. Move it. |
| "I'll update the docs in a follow-up" | Follow-up docs never match the implementation. Update alongside the change. |
| "The skill already covers this" | Check for duplication — if both a skill and a doc cover it, consolidate. |

---

## Red Flags — STOP

- Doc file over 600 words — **STOP. Split at the second concept.**
- Missing YAML frontmatter — **STOP. Add the full block before continuing.**
- Missing `## Related` section — **STOP. Add at least one annotated link.**
- Two files covering the same concept — **STOP. Delete one; link from the other.**
- Updating code without checking related docs — **STOP. Update stale docs first.**

---

## Related Skills

- `writing-skills` — skill authoring standards and anatomy gate
- `skill-reviewer` — validates completed skills

## Reference

For the domain taxonomy, frontmatter schema, and guide template, see [references/DOCUMENTATION_EXAMPLES.md](references/DOCUMENTATION_EXAMPLES.md).

**Documentation principles (Doc1–Doc5, SelfDocumentingCode, LiterateProgramming):** `.github/skills/documentation/references/DOCUMENTATION_PRINCIPLES.md`
