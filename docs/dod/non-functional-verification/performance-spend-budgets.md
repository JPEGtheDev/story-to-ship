---
title: "Performance/Spend Budgets Ruling"
description: "Why performance-spend-budgets is CONDITIONAL on skill-file changes: token size is this repo's real resource envelope, capped by standing skill and documentation size rules."
domain: dod
subdomain: non-functional-verification
tags: [dod, non-functional-verification, performance-spend-budgets]
related:
  - "../../DOD.md"
  - "../../../skills/defining-done/references/DOD_TAXONOMY.md"
---

# Performance/Spend Budgets Ruling

**Ruling:** `CONDITIONAL | trigger: diff modifies any file under skills/`

This repo has no latency or memory surface. Its real resource envelope is
context-window spend: every skill file is loaded into working context, so
file size is the budget. The repo carries standing rules and gates around
token size -- the documentation skill's 800-token per-file cap and the
writing-skills size targets (see `SIZE_AND_COMPRESSION.md` in that skill's
references) -- and a diff that touches a skill file is checked against
them.

Changes that touch no skill file (docs, tools, fixtures) do not fire this
layer; the documentation skill's own cap still governs `docs/` files
independently of this canon.

## Related

- [DOD.md](../../DOD.md) -- the canon index this detail file elaborates.
- [DOD_TAXONOMY.md](../../../skills/defining-done/references/DOD_TAXONOMY.md) -- the layer's taxonomy definition.
