---
title: "TaskFlow Definition of Done"
description: "Synthetic, ratified Definition of Done document for the fictional TaskFlow to-do list web app. Used only to exercise the defining-done skill's delta re-ratification path, where a newer taxonomy version is interviewed for only the layers it added or changed."
domain: cross-cutting
tags: [cross-cutting, standards, dod, fixture]
related:
  - "delta-reratification-taxonomy-v1.md"
  - "delta-reratification-taxonomy-v2.md"
---

Ratified against fs4-taxonomy-v1.md v1.
- idempotency-checks: CONDITIONAL | trigger: diff adds or modifies a POST/PUT
  handler under api/ with no dedup or idempotency-key check
- schema-migration-safety: ALWAYS
- changelog-entry: CONDITIONAL | trigger: diff modifies a file under
  web/routes/ or web/components/ with no CHANGELOG.md entry in the same
  commit
- feature-flag-cleanup: N/A | category: target-absent | TaskFlow has no
  feature-flag system; nothing for this layer to verify
Stamp: v1
Content-hash: sha256:a0d047d06e87ab8c525588c7b76f3c2ef6a833a879b5007d427ada0b372d5f20
