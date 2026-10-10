---
title: "defining-done References Index"
description: "Index of all reference files for the defining-done skill -- the repo-agnostic Definition of Done verification-layer taxonomy consumed by the ratification interview, `DOD_TEMPLATE.md` (the authoring template for the canon index and detail files), and the guide to re-running the fixture harness after a marker change."
domain: skills
subdomain: defining-done
tags: [skills, defining-done, references, index]
related:
  - "../SKILL.md"
---

# defining-done References Index

These references define the repo-agnostic taxonomy the defining-done interview walks
group by group to produce a repo's ratified Definition of Done canon.
Two further references cover the authoring template for the canon index and detail
files (`DOD_TEMPLATE.md`) and re-running the fixture harness after a marker change.

---

## Reference Files

| File | Covers |
|------|--------|
| `DOD_TAXONOMY.md` | 20 verification layers (Behavior-Driven Development (BDD) tests through Definition of Ready), grouped into 5 coherent groups, each with a canonical kebab-case Key, what-it-verifies text, and example checkable trigger predicates; file-level Stamp v1 and delta re-ratification rule. |
| `DOD_TEMPLATE.md` | Authoring template for a repo's ratified canon -- `docs/DOD.md` index format (three closed ruling forms, single `Stamp: vN` field), optional `docs/dod/<group-slug>/<layer-key>.md` detail-file format (group-slug transform worked for all 5 groups), the write-order rule, and the three consumer marker strings. |
| `DOD_FIXTURE_HARNESS.md` | Guide to the fixture harness in `tools/dod_fixtures/`: when to re-run it (a change to a marker string, a marker's emit condition, the canon parse rules, or a rule the harness scenarios also prove), the commands to run from the repository root, and how to read a pass per scenario type; each model-backed run needs the owner's consent. |

---

## Related

- [SKILL.md](../SKILL.md) -- enforcement gate that drives this skill (the ratification interview that walks DOD_TAXONOMY.md group by group)
