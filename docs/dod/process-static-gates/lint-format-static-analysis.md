---
title: "Lint/Format/Static Analysis Ruling"
description: "Why lint-format-static-analysis is ALWAYS: invoked skills mechanically check content rules (ASCII-only output, skill anatomy, code-quality checklists) on every change."
domain: dod
subdomain: process-static-gates
tags: [dod, process-static-gates, lint-format-static-analysis]
related:
  - "../../DOD.md"
  - "../../../skills/defining-done/references/DOD_TAXONOMY.md"
---

# Lint/Format/Static Analysis Ruling

**Ruling:** `ALWAYS`

Every change in this repo is checked by automatically invoked skills
rather than a standalone linter binary. The standing mechanical checks:

- the honesty skill's ASCII-only rule on all output and tracked text;
- the writing-skills anatomy gate (five required elements, description
  form, voice rules) on skill files;
- the code-quality skill's universal checks on any code file;
- the documentation skill's frontmatter, size, and linking rules on docs.

These fire on all files, so the layer is required on every change with no
trigger condition.

## Related

- [DOD.md](../../DOD.md) -- the canon index this detail file elaborates.
- [DOD_TAXONOMY.md](../../../skills/defining-done/references/DOD_TAXONOMY.md) -- the layer's taxonomy definition.
