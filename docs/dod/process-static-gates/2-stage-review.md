---
title: "2-Stage Review Ruling"
description: "Why 2-stage-review is ALWAYS: every todo gets a spec-compliance review then an independent quality review by dispatched agents, and the product owner holds the merge gate."
domain: dod
subdomain: process-static-gates
tags: [dod, process-static-gates, 2-stage-review]
related:
  - "../../DOD.md"
  - "../../../skills/defining-done/references/DOD_TAXONOMY.md"
---

# 2-Stage Review Ruling

**Ruling:** `ALWAYS`

Every completed unit of work in this repo is reviewed twice by independent
dispatched reviewer agents before it advances: Stage 1 checks spec
compliance against the governing plan or story, Stage 2 checks quality
against the repo's standards (skill-reviewer for skill files,
code-quality-reviewer for code and config). The subagent-driven-development
skill defines the protocol; work does not advance until both stages pass.

On top of the two agent stages, merging a pull request into main is
reserved to the product owner -- a human gate that closes every change.

## Related

- [DOD.md](../../DOD.md) -- the canon index this detail file elaborates.
- [DOD_TAXONOMY.md](../../../skills/defining-done/references/DOD_TAXONOMY.md) -- the layer's taxonomy definition.
