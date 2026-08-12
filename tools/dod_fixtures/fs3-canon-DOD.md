---
title: "Driftmark Definition of Done (FS3 fixture)"
description: "Synthetic, ratified Definition of Done canon for the fictional Driftmark parcel-routing backend service, used only to exercise the verification-before-completion skill's DoD canon completion-gate check (FS3 fixture, issue #66)."
domain: cross-cutting
tags: [cross-cutting, standards, dod, fixture]
related:
  - "../../docs/INDEX.md"
---

Ratified against DOD_TAXONOMY.md v1.
- coverage: ALWAYS
- lint-format-static-analysis: ALWAYS
- mutation-testing: CONDITIONAL | trigger: diff touches any path under
  tools/ or touches any path with a co-located test suite (*_test.*,
  test_*.*, *.spec.* in the same directory or an adjacent tests/ directory)
- visual-regression: N/A | category: target-absent | Driftmark is a
  backend parcel-routing service with no UI, image-generation, or
  graphics-rendering surface
Stamp: v1
Content-hash: sha256:9d1845512105fa30d299aff2e1fe0d87459b3a1770ce1e9a08bed584c32b6473
