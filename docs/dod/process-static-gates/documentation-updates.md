---
title: "Documentation Updates Ruling"
description: "Why documentation-updates is CONDITIONAL on skill-file changes: skills are themselves the documentation of the process, and skill changes must keep README and index rows current."
domain: dod
subdomain: process-static-gates
tags: [dod, process-static-gates, documentation-updates]
related:
  - "../../DOD.md"
  - "../../../skills/defining-done/references/DOD_TAXONOMY.md"
---

# Documentation Updates Ruling

**Ruling:** `CONDITIONAL | trigger: diff modifies any file under skills/`

In this repo the skills are themselves the documentation of the process --
a skill file change is a documentation change. When a diff touches a skill
file, this layer requires the surrounding documentation to move with it:
the README where behavior is described there, reference INDEX.md rows for
added or renamed reference files (per the writing-skills skill), and
`docs/INDEX.md` rows for any new `docs/` file the change introduces (per
the documentation skill).

## Related

- [DOD.md](../../DOD.md) -- the canon index this detail file elaborates.
- [DOD_TAXONOMY.md](../../../skills/defining-done/references/DOD_TAXONOMY.md) -- the layer's taxonomy definition.
