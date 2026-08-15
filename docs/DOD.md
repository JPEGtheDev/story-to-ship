---
title: "Definition of Done"
description: "This repo's ratified Definition of Done canon: one owner ruling per verification layer of the defining-done taxonomy, stamped."
domain: cross-cutting
tags: [cross-cutting, standards, dod]
related:
  - "INDEX.md"
  - "dod/non-functional-verification/performance-spend-budgets.md"
  - "dod/process-static-gates/lint-format-static-analysis.md"
  - "dod/process-static-gates/2-stage-review.md"
  - "dod/process-static-gates/versioning-conventional-commits.md"
  - "dod/process-static-gates/documentation-updates.md"
  - "dod/release-readiness/exploratory-testing.md"
  - "dod/release-readiness/definition-of-ready.md"
---

Ratified against DOD_TAXONOMY.md v1.
- bdd-tests: N/A | category: target-absent
- uat: N/A | category: target-absent | the repo's product is its skills and
  process files, exercised through real use in live working sessions; there
  is no separate user-facing surface to test
- automated-acceptance-tests: N/A | category: target-absent
- ac-to-test-traceability: N/A | category: target-absent
- mutation-testing: N/A | category: target-absent
- contract-tests: N/A | category: target-absent
- property-based-tests: N/A | category: target-absent
- integration-e2e-split: N/A | category: target-absent
- coverage: N/A | category: target-absent
- visual-regression: N/A | category: target-absent
- performance-spend-budgets: CONDITIONAL | trigger: diff modifies any file
  under skills/
- security-scanning: N/A | category: target-absent
- observability-diagnosability: N/A | category: target-absent
- lint-format-static-analysis: ALWAYS
- 2-stage-review: ALWAYS
- versioning-conventional-commits: ALWAYS
- documentation-updates: CONDITIONAL | trigger: diff modifies any file
  under skills/
- exploratory-testing: CONDITIONAL | trigger: the change's linked issue is
  a spike or research issue, named as such in its title or labels
- rollback-release-criteria: N/A | category: covered-elsewhere | git revert
  of individual files or commits is the standing rollback mechanism
- definition-of-ready: CONDITIONAL | trigger: the commit type is feat: or
  the change implements a linked GitHub issue
Stamp: v1
