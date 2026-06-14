# writing-skills References Index

All files in this directory are injected into skill-reviewer agents at dispatch time or consulted during skill creation. See `DISPATCH_PATTERN.md` for which files are injected and when.

---

## Reference Files

- `SKILL_ANATOMY_ELEMENTS.md` -- full schemas and BAD/GOOD examples for all 5 required skill elements (FRONTMATTER, IRON LAW, ANNOUNCEMENT, GATE FUNCTION, RATIONALIZATION TABLE); Alexandrian Pattern Form guide
- `VOICE_AUTHORITY_RULES.md` -- authority table, Absolute Path Rule, Acronym Rule; applies to every line of a skill file or agent template
- `SIZE_AND_COMPRESSION.md` -- token count targets, compression rules, line limits, Skill Composition Model; baseline is GPT-4.1
- `MODEL_COMPATIBILITY.md` -- patterns most likely skipped or misapplied by lower-capability models; mitigations built into each skill
- `REVIEW_INSTRUCTIONS.md` -- review checklist, qualitative questions, and return format; injected into `skill-reviewer` agent at dispatch time
- `DISPATCH_PATTERN.md` -- step-by-step dispatch instructions for auditing skills; read before dispatching any skill-reviewer agent
- `TIERED_REFERENCE_MODEL.md` -- how to structure skills with universal + paradigm-specific reference tiers; read when a skill needs conditional reference loading

---

## Related

- `SKILL.md` -- enforcement gate; drives skill creation and editing workflow
- `../.claude/agents/skill-reviewer.md` -- agent template; uses SKILL_ANATOMY_ELEMENTS, VOICE_AUTHORITY_RULES, SIZE_AND_COMPRESSION, REVIEW_INSTRUCTIONS as injected criteria
- `code-quality/references/INDEX.md` -- reference implementation of the tiered model described in TIERED_REFERENCE_MODEL.md
