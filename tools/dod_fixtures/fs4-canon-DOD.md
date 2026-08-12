---
title: "TaskFlow Definition of Done (FS4 fixture)"
description: "Synthetic, ratified Definition of Done canon for the fictional TaskFlow todo-list web app, used only to exercise the defining-done skill's delta re-ratification path (FS4 fixture, issue #66)."
domain: cross-cutting
tags: [cross-cutting, standards, dod, fixture]
related:
  - "../../docs/INDEX.md"
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
- feature-flag-cleanup: N/A | category: target-absent | TaskFlow has no
  feature-flag system; nothing for this layer to verify
Stamp: v1
Content-hash: sha256:a0d047d06e87ab8c525588c7b76f3c2ef6a833a879b5007d427ada0b372d5f20
