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
| `DOD_TEMPLATE.md` | Authoring template for a repo's ratified canon -- `docs/DOD.md` index format (three closed ruling forms, single `Stamp: vN` field, content-hash footer with an unambiguous hash-input definition), optional `docs/dod/<group-slug>/<layer-key>.md` detail-file format (group-slug transform worked for all 5 groups), the write-order rule, and the three consumer marker strings. |

---

## Related

- [SKILL.md](../SKILL.md) -- enforcement gate that drives this skill (the ratification interview that walks DOD_TAXONOMY.md group by group)
