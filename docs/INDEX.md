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
documentation skill's taxonomy. It catalogs cross-cutting standards files
stored directly under `docs/` and links to domain-level
`docs/<domain>/INDEX.md` files as they are created. Every `docs/` directory
level owns its own INDEX.md; this one owns the root.

## Definition of Done canon

A repo may ratify a Definition of Done (DoD) canon: rulings on which
quality-gate layers apply here, and when. When ratified, the canon lives at
`docs/DOD.md` (a flat cross-cutting index, one line per layer), with
optional longer rationale in per-layer detail files at
`docs/dod/<group-slug>/<layer-key>.md`.

The canon is written and updated only by the `defining-done` skill's
ratification interview, which defines the authoring format -- no other
process creates or edits it.
The write order at ratification is: detail files, then their per-level index
chain under `docs/dod/` (subdomain `INDEX.md` files, then `docs/dod/INDEX.md`),
then `docs/DOD.md`, then this file's update. `docs/DOD.md` is written after
everything under `docs/dod/` and before this file's update, so its presence
is the reliable canon signal: if `docs/DOD.md` does not exist, no canon has
been ratified yet in this repo, and any DoD-aware tooling should fall back to
its canon-less default behavior. Once ratified, `docs/DOD.md` is catalogued
in the table below; detail files are catalogued by the `docs/dod/` index
chain (linked from the table), not listed here.

## Files

| File | Domain | Subdomain | Description |
|------|--------|-----------|-------------|
| [DOD.md](DOD.md) | cross-cutting | -- | Ratified Definition of Done canon: one owner ruling per taxonomy layer, stamped and hashed. |
| [dod/INDEX.md](dod/INDEX.md) | dod | -- | Domain index for the DoD canon's per-layer detail files. |

## Related

- [../README.md](../README.md) -- repo entry point and project overview.
- [../CONTRIBUTING.md](../CONTRIBUTING.md) -- contribution guidelines for
  this repo.
