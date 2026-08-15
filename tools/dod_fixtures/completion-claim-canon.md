---
title: "Driftmark Definition of Done"
description: "Synthetic, ratified Definition of Done document for the fictional Driftmark parcel-routing backend service. Used only to exercise the verification-before-completion skill's Definition of Done completion-gate check."
domain: cross-cutting
tags: [cross-cutting, standards, dod, fixture]
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
Content-hash: sha256:9cb6f6ddc3ba353d9c50fe691081d2bfdbc0632aaa0de9d55a2b8162dee04c0e
