---
title: "Skill Reference Index Format"
description: "Required format for references/INDEX.md files in skill directories -- YAML frontmatter, file table, and Related section."
domain: skills
subdomain: writing-skills
tags: [skills, writing-skills, references, index-format]
related:
  - "../SKILL.md"
  - "TIERED_REFERENCE_MODEL.md"
---

# Skill Reference Index Format

Any skill whose `references/` directory has files added, removed, or renamed MUST have a `references/INDEX.md` updated to reflect the change.
Every `references/INDEX.md` file MUST follow this format exactly.

---

## When to Create or Update

- Create `references/INDEX.md` when a skill's `references/` directory is first created.
- Update `references/INDEX.md` any time a reference file is added, removed, or renamed.
- The INDEX.md is the canonical catalog -- a reference file not listed here is effectively invisible to agents loading the skill.

---

## Required Format

### YAML Frontmatter (mandatory)

Every `references/INDEX.md` MUST begin with this block:

```yaml
---
title: "<skill-name> References Index"
description: "One sentence describing what the reference files in this directory collectively cover."
domain: skills
subdomain: <skill-name>
tags: [skills, <skill-name>, references, index]
related:
  - "../SKILL.md"
---
```

**Field rules:**
- `title` -- `"<skill-name> References Index"` -- no variation.
- `description` -- one concrete sentence that names the key reference topics. Not "this directory contains files about X" -- name the topics: "Index of reference files for the code-quality skill -- universal smells and design principles, plus OOP tier dispatch table, checklists, and toolchain config."
- `domain` -- always `skills` for skill reference directories.
- `subdomain` -- the skill directory name (e.g., `code-quality`, `writing-skills`).
- `tags` -- MUST include `skills`, the skill name, `references`, and `index` as the first four entries.
- `related` -- relative paths from the `references/` directory. Always include `"../SKILL.md"`. DO NOT add paths to other skills' directories -- cross-skill references belong in prose inside the Related section, not as YAML paths.

---

### File Table (mandatory)

After the YAML frontmatter and a one-paragraph intro, list every file in a table:

```markdown
| File | Covers |
|------|--------|
| `filename.md` | One-line description of what this file covers. |
```

Rules:
- Every file in `references/` MUST appear in the table. No exceptions.
- Subdirectories (e.g., `oop/`) get their own section header before the table.
- The "Covers" column MUST be specific -- name what the file contains, not what it is for. "Universal smells from Fowler's _Refactoring_ -- Long Method, Duplicated Code..." not "smell definitions."
- One-liners only. Detail belongs in the referenced file.

---

### Related Section (mandatory)

Every `references/INDEX.md` MUST end with a `## Related` section:

```markdown
## Related

- [SKILL.md](../SKILL.md) -- enforcement gate that drives this skill
- [Other File](relative/path.md) -- one-line description of why it is related
```

Rules:
- Use relative paths from the `references/` directory.
- Verify every path exists before adding it.
- At least one link (to `../SKILL.md`) is required.
- One-line descriptions are mandatory -- naked links are not acceptable.

---

## Complete Template

```markdown
---
title: "<skill-name> References Index"
description: "Index of all reference files for the <skill-name> skill -- [key topics]."
domain: skills
subdomain: <skill-name>
tags: [skills, <skill-name>, references, index]
related:
  - "../SKILL.md"
---

# <skill-name> References Index

[One-sentence context: what these references collectively enable.]

---

## [Section heading if files are grouped; omit if ungrouped]

| File | Covers |
|------|--------|
| `file-a.md` | Specific description of content. |
| `file-b.md` | Specific description of content. |

---

## Related

- [SKILL.md](../SKILL.md) -- enforcement gate that drives this skill
```

---

## Related

- [SKILL.md](../SKILL.md) -- writing-skills enforcement gate; step 7 of BEFORE PROCEEDING references this file
- [TIERED_REFERENCE_MODEL.md](TIERED_REFERENCE_MODEL.md) -- how to structure skills with paradigm-specific tiers; INDEX.md is required at each tier level
