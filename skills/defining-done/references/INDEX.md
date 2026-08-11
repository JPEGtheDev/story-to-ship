---
title: "defining-done References Index"
description: "Index of all reference files for the defining-done skill -- the repo-agnostic Definition of Done verification-layer taxonomy consumed by the ratification interview."
domain: skills
subdomain: defining-done
tags: [skills, defining-done, references, index]
related:
  - "../SKILL.md"
---

# defining-done References Index

These references define the repo-agnostic taxonomy the defining-done interview walks
group by group to produce a repo's ratified Definition of Done canon.

---

## Reference Files

| File | Covers |
|------|--------|
| `DOD_TAXONOMY.md` | 20 verification layers (Behavior-Driven Development (BDD) tests through Definition of Ready), grouped into 5 coherent groups, each with a canonical kebab-case Key, what-it-verifies text, and example checkable trigger predicates; file-level Stamp v1 and delta re-ratification rule. |

---

## Related

- [SKILL.md](../SKILL.md) -- enforcement gate that drives this skill (the ratification interview that walks DOD_TAXONOMY.md group by group)
- user-story-generator -- future consumer: derives a generated story's Definition of Done section from a repo's ratified canon instead of the hardcoded template
- verification-before-completion -- future consumer: checks a completion claim's evidence against the ratified canon's always-required and fired-conditional layers
