---
title: "writing-skills References Index"
description: "Index of all reference files for the writing-skills skill -- skill anatomy schemas, voice and authority rules, size constraints, model compatibility notes, review instructions, dispatch pattern, tiered reference model, and reference index format."
domain: skills
subdomain: writing-skills
tags: [skills, writing-skills, references, index]
related:
  - "../SKILL.md"
---

# writing-skills References Index

All files here are either injected into skill-reviewer agents at dispatch time or consulted during skill creation and editing. See `DISPATCH_PATTERN.md` for which files are injected and when.

---

## Reference Files

| File | Covers |
|------|--------|
| `SKILL_ANATOMY_ELEMENTS.md` | Full schemas and BAD/GOOD examples for all 5 required skill elements (FRONTMATTER, IRON LAW, ANNOUNCEMENT, GATE FUNCTION, RATIONALIZATION TABLE); Alexandrian Pattern Form guide |
| `VOICE_AUTHORITY_RULES.md` | Authority table, Absolute Path Rule, Acronym Rule; applies to every line of a skill file or agent template |
| `SIZE_AND_COMPRESSION.md` | Token count targets, compression rules, line limits, Skill Composition Model; baseline is GPT-4.1 |
| `MODEL_COMPATIBILITY.md` | Patterns most likely skipped or misapplied by lower-capability models; mitigations built into each skill |
| `REVIEW_INSTRUCTIONS.md` | Review checklist, qualitative questions, and return format; injected into `skill-reviewer` agent at dispatch time |
| `DISPATCH_PATTERN.md` | Step-by-step dispatch instructions for auditing skills; read before dispatching any skill-reviewer agent |
| `TIERED_REFERENCE_MODEL.md` | How to structure skills with universal + paradigm-specific reference tiers; read when a skill needs conditional reference loading |
| `REFERENCE_INDEX_FORMAT.md` | Required format for `references/INDEX.md` files -- YAML frontmatter template, file table rules, Related section rules, and complete template; read before creating or updating any INDEX.md |

---

## Related

- [SKILL.md](../SKILL.md) -- enforcement gate; drives skill creation and editing workflow; the `code-quality` skill's `references/oop/cpp/` directory is the reference implementation of the tiered model
