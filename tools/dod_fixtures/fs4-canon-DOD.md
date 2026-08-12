---
title: "TaskFlow Definition of Done (FS4 fixture)"
description: "Synthetic, ratified Definition of Done canon for the fictional TaskFlow todo-list web app, used only to exercise the defining-done skill's delta re-ratification path (FS4 fixture, issue #66)."
domain: cross-cutting
tags: [cross-cutting, standards, dod, fixture]
related:
  - "fs4-taxonomy-v1.md"
  - "fs4-taxonomy-v2.md"
---

Ratified against fs4-taxonomy-v1.md v1.
- idempotency-checks: CONDITIONAL | trigger: diff adds or modifies a POST/PUT
  handler under api/ with no dedup or idempotency-key check
- schema-migration-safety: ALWAYS
- changelog-entry: CONDITIONAL | trigger: diff modifies a file under
  web/routes/ or web/components/ with no CHANGELOG.md entry in the same
  commit
- feature-flag-cleanup: N/A | category: repo-ruled-N/A | TaskFlow has no
  feature-flag system as of this ratification; the product owner ruled the
  layer out rather than leaving it unconsidered
Stamp: v1
Content-hash: sha256:68b28c35aed6f27f85c39d7e6e02addb9f95fe998451a6929bf695eeb79ccc7c
