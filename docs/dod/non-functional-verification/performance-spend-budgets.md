---
title: "Performance/Spend Budgets Ruling"
description: "Why performance-spend-budgets is CONDITIONAL on skill-file changes: token size is this repo's real resource envelope, capped by standing skill and documentation size rules."
domain: dod
subdomain: non-functional-verification
tags: [dod, non-functional-verification, performance-spend-budgets]
related:
  - "../../DOD.md"
---

# Performance/Spend Budgets Ruling

**Ruling:** `CONDITIONAL | trigger: diff modifies any file under skills/`

This repo has no latency or memory surface. Its real resource envelope is
context-window spend: every skill file is loaded into working context, so
file size is the budget. The repo carries standing rules and gates around
token size -- the documentation skill's 800-token per-file cap and the
writing-skills skill's size guidance -- and a diff that touches a skill
file is checked against them.

Changes that touch no skill file (docs, tools, fixtures) do not fire this
layer; the documentation skill's own cap still governs `docs/` files
independently of this canon.

## Related

- [DOD.md](../../DOD.md) -- the canon index this detail file elaborates.
- The defining-done skill's taxonomy defines this layer.
