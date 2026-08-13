---
title: "Documentation Index"
description: "Top-level cross-cutting index of docs/ files, including the standing pointer to this repo's optional Definition of Done canon."
domain: cross-cutting
tags: [cross-cutting, standards, index, dod]
related:
  - "../README.md"
  - "../CONTRIBUTING.md"
---

# Documentation Index

This is the top-level index for `docs/`, the cross-cutting level in the
documentation skill's taxonomy (see
`skills/documentation/references/DOCUMENTATION_PRINCIPLES.md`, Documentation
Index section). It catalogs cross-cutting standards files stored directly
under `docs/` and links to domain-level `docs/<domain>/INDEX.md` files as
they are created. Every `docs/` directory level owns its own INDEX.md; this
one owns the root.

## Definition of Done canon

A repo may ratify a Definition of Done (DoD) canon: rulings on which
quality-gate layers apply here, and when. When ratified, the canon lives at
`docs/DOD.md` (a flat cross-cutting index, one line per layer), with
optional longer rationale in per-layer detail files at
`docs/dod/<group-slug>/<layer-key>.md`.

The canon is written and updated only by the `defining-done` skill's
ratification interview (see `skills/defining-done/references/DOD_TEMPLATE.md`
for the authoring format) -- no other process creates or edits it.
The write order at ratification is: detail files, then `docs/DOD.md`, then
this file's row for it. `docs/DOD.md` is written after any detail files, so
its presence is the reliable canon signal: if `docs/DOD.md` does not exist,
no canon has been ratified yet in this repo, and any DoD-aware tooling
should fall back to its canon-less default behavior. Once ratified,
`docs/DOD.md` and any detail files are catalogued in the table below like
any other `docs/` file.

## Files

| File | Domain | Subdomain | Description |
|------|--------|-----------|-------------|
| [DOD.md](DOD.md) | cross-cutting | -- | Ratified Definition of Done canon: one owner ruling per taxonomy layer, stamped and hashed. |
| [performance-spend-budgets](dod/non-functional-verification/performance-spend-budgets.md) | dod | non-functional-verification | Token-size budgets on skill files. |
| [lint-format-static-analysis](dod/process-static-gates/lint-format-static-analysis.md) | dod | process-static-gates | Skill-driven content checks. |
| [2-stage-review](dod/process-static-gates/2-stage-review.md) | dod | process-static-gates | Two agent review stages plus the owner merge gate. |
| [versioning-conventional-commits](dod/process-static-gates/versioning-conventional-commits.md) | dod | process-static-gates | Conventional commit format on every commit. |
| [documentation-updates](dod/process-static-gates/documentation-updates.md) | dod | process-static-gates | Skills are the process documentation. |
| [exploratory-testing](dod/release-readiness/exploratory-testing.md) | dod | release-readiness | Spike issues; findings live on the issue. |
| [definition-of-ready](dod/release-readiness/definition-of-ready.md) | dod | release-readiness | Ready bar for feature work; balloon rule. |

## Related

- [../README.md](../README.md) -- repo entry point and project overview.
- [../CONTRIBUTING.md](../CONTRIBUTING.md) -- contribution guidelines for
  this repo.
