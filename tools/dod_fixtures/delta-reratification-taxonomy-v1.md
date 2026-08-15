# Verification layer taxonomy (delta-reratification fixture, v1)

This is a synthetic, repo-agnostic taxonomy of verification layers used only
to exercise the defining-done skill's delta re-ratification path (where a
re-ratification interview against a newer taxonomy version only asks about
the layers that changed). It mirrors the structure of the real Definition of
Done taxonomy -- same group/layer shape, same field names -- but every group,
layer, and trigger below is invented for this fixture and MUST NOT be read as
real canon content or copied into any live taxonomy.

Stamp: v1
Delta rule: a re-ratification interview against a newer stamp elicits ONLY the
layers added or changed since the canon's recorded stamp; every other prior
ruling is left untouched.

Key transform: each layer's `Key` is the layer name lowercased, with spaces and
slashes converted to hyphens, and any parenthetical suffix dropped.

---

## Data Integrity

### Idempotency Checks

**Key:** idempotency-checks
**Group:** Data Integrity
**Verifies:** that repeated execution of the same write operation (retry,
duplicate delivery) produces the same end state rather than a duplicated or
corrupted record.
**Example checkable triggers:**
- diff adds or modifies a POST/PUT handler with no dedup or idempotency-key
  check
- diff touches a queue consumer with no at-least-once-delivery guard

### Schema Migration Safety

**Key:** schema-migration-safety
**Group:** Data Integrity
**Verifies:** that a change to a persisted data shape ships with a safe,
reversible migration path rather than relying on an in-place assumption.
**Example checkable triggers:**
- diff modifies a model/schema file with no paired migration file in the same
  commit
- diff adds a new required field with no default value or backfill strategy

---

## Release Hygiene

### Changelog Entry

**Key:** changelog-entry
**Group:** Release Hygiene
**Verifies:** that a user-visible change is recorded in the project's
changelog, so the release history stays a reliable record of what shipped.
**Example checkable triggers:**
- diff modifies a user-facing route or component with no CHANGELOG.md entry in
  the same commit
- diff bumps the package version with no corresponding changelog section

### Feature Flag Cleanup

**Key:** feature-flag-cleanup
**Group:** Release Hygiene
**Verifies:** that a feature flag is removed once the feature it gates is
fully rolled out, preventing flag debt from accumulating in the codebase.
**Example checkable triggers:**
- diff references a flag key that has been present in the flag registry for
  more than two releases
- diff removes a flag's gated code path with no corresponding flag-registry
  deletion
