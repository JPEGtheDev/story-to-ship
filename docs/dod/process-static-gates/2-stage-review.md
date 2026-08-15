---
title: "2-Stage Review Ruling"
description: "Why 2-stage-review is ALWAYS: every todo gets a spec-compliance review then an independent quality review by dispatched agents, and the product owner holds the merge gate."
domain: dod
subdomain: process-static-gates
tags: [dod, process-static-gates, 2-stage-review]
related:
  - "../../DOD.md"
---

# 2-Stage Review Ruling

**Ruling:** `ALWAYS`

Every completed unit of work in this repo is reviewed twice by independent
dispatched reviewer agents before it advances: a specification-compliance
reviewer checks the work against the governing plan or story, then a
code-quality reviewer checks it against the repo's standards for the kind
of file changed. The subagent-driven-development skill defines the
protocol; work does not advance until both reviews pass.

On top of the two agent stages, merging a pull request into main is
reserved to the product owner -- a human gate that closes every change.

## Related

- [DOD.md](../../DOD.md) -- the canon index this detail file elaborates.
- The defining-done skill's taxonomy defines this layer.
