---
title: "Driftmark Definition of Done"
description: "Synthetic, ratified Definition of Done document for the fictional Driftmark parcel-routing backend service. Used only to exercise the verification-before-completion skill's Definition of Done completion-gate check."
domain: cross-cutting
tags: [cross-cutting, standards, dod, fixture]
---
This file is a synthetic test fixture for a fictional app, used only to exercise Definition of Done tooling; its content is invented.

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
