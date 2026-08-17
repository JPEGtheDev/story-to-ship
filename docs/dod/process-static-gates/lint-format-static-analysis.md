---
title: "Lint/Format/Static Analysis Ruling"
description: "Why lint-format-static-analysis is ALWAYS: invoked skills mechanically check content rules (ASCII-only output, required skill-file structure, code-quality checklists) on every change."
domain: dod
subdomain: process-static-gates
tags: [dod, process-static-gates, lint-format-static-analysis]
related:
  - "../../DOD.md"
---

# Lint/Format/Static Analysis Ruling

**Ruling:** `ALWAYS`

Every change in this repo is checked by automatically invoked skills
rather than a standalone linter binary. The standing mechanical checks:

- the communication skill's ASCII-only rule on all output and tracked text;
- the writing-skills skill's check that a skill file has all five required
  structural sections (frontmatter, an iron-law statement, an announcement
  line, a gate-check section, and a rationalization table) in the right
  form and voice;
- the code-quality skill's universal checks on any code file;
- the documentation skill's frontmatter, size, and linking rules on docs.

These fire on all files, so the layer is required on every change with no
trigger condition.

## Related

- [DOD.md](../../DOD.md) -- the canon index this detail file elaborates.
- The defining-done skill's taxonomy defines this layer.
