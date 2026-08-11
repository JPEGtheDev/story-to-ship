# DoD Canon Authoring Template

This is the authoring template for a repo's ratified Definition of Done (DoD) canon:
the flat index file `docs/DOD.md` and its optional per-layer detail files under
`docs/dod/<group-slug>/<layer-key>.md`. The defining-done ratification interview
(SKILL.md) and any future interview tooling MUST produce output conforming to this
template exactly. Nothing here is pre-filled content -- every ruling, trigger, and
elaboration below is illustrative only.

---

## A. Canon index format (docs/DOD.md)

`docs/DOD.md` is a cross-cutting standard file per the documentation skill's Step 1
type table (`docs/UPPERCASE.md`). It MUST stay under the documentation skill's
800-token Iron Law cap -- one line per taxonomy layer, no elaboration beyond a short
optional free-text tail on N/A lines. Longer rationale goes to a detail file (Section
B), never into the index.

### A.1 Frontmatter

`docs/DOD.md` MUST begin with YAML frontmatter matching the documentation skill's
**Cross-cutting standard files** template exactly -- this is the field
set for `docs/UPPERCASE.md` files, and `docs/DOD.md` is one: `title`, `description`,
`domain: cross-cutting`, `tags`, `related`. There is no `subdomain` field on this
template -- do not add one; the flat index has no taxonomy group of its own, and
cross-cutting files do not carry `subdomain`. There is also no `version` field --
that field is a dropped, deliberately absent artifact, unrelated to the `Stamp:`
mechanism below. `tags` MUST start `[cross-cutting, standards, ...]` (per the
template) followed by `dod` and any additional tags. `related` MUST link to
`docs/INDEX.md` and to each detail file this canon has.

### A.2 Machine-readable stamp

Exactly ONE machine-readable stamp field exists in the canon: a line of the exact
form

```
Stamp: vN
```

where `N` is a monotonic integer matching the taxonomy stamp the canon was last
ratified or delta-ratified against (assumption A10). `Stamp: vN` is the single
source of truth consumers read to detect staleness (Section C). A human-readable
narrative line such as `Ratified against DOD_TAXONOMY.md vN.` MAY also appear
immediately above the ruling lines as optional, non-normative prose -- it exists for
human readability only. No consumer (generator, completion gate, or any other
tooling) MUST ever parse the narrative line; `Stamp: vN` is authoritative and the
narrative line, if present, MUST agree with it or be treated as a documentation bug,
not a second source of truth.

### A.3 Ruling lines

The index carries exactly one ruling line per taxonomy layer, keyed by that layer's
canonical `Key` field from `DOD_TAXONOMY.md` (kebab-case). Every taxonomy layer MUST
have exactly one line in the index -- no omissions, no defaults, no layer left
unruled. There are exactly three ruling forms (assumption A9's closed category list;
no other form is valid):

```
- <key>: ALWAYS
- <key>: CONDITIONAL | trigger: <objectively checkable predicate>
- <key>: N/A | category: <target-absent|covered-elsewhere|repo-ruled-N/A> [| <optional free-text elaboration>]
```

Rules for each form:
- `ALWAYS` -- the layer is required on every change. No trigger, no category.
- `CONDITIONAL` -- the layer applies only when its trigger predicate fires against a
  given diff. The trigger MUST be objectively checkable (mechanically evaluable from
  the diff, per assumption A13's checkability re-elicitation loop) -- not a subjective
  judgment call.
- `N/A` -- the layer never applies in this repo. `category` MUST be one of the three
  closed values: `target-absent` (the repo has no surface this layer verifies),
  `covered-elsewhere` (another layer or repo mechanism already covers the same
  concern), or `repo-ruled-N/A` (the product owner ruled it out for a repo-specific
  reason not captured by the first two categories). An optional free-text
  elaboration MAY follow the category tag after a second `|`.

### A.4 Content-hash footer

The index ends with a content-hash footer of the exact form:

```
Content-hash: sha256:<64-hex>
```

**Hash input, defined unambiguously:** the hash input is every byte of `docs/DOD.md`
starting at byte offset 0 up to and including the newline character that terminates
the line immediately preceding the `Content-hash:` line. Concretely: locate the line
that begins with the literal text `Content-hash:`; the hash input is the file's byte
content from its start through the end of the previous line's trailing newline,
exclusive of the `Content-hash:` line itself and anything after it. This means the
frontmatter, the optional narrative line, every ruling line, and the `Stamp:` line
are ALL included in the hash input; only the `Content-hash:` line (and any content
after it) is excluded. Two independent implementations given the same file bytes
MUST compute the same digest under this rule, because the boundary is defined by a
literal, unambiguous string match (`Content-hash:` at the start of a line) rather
than by counting lines or bytes from either end.

The hash is a SHA-256 digest of that byte range, rendered as 64 lowercase hex
characters. Any consumer recomputing the hash MUST use this exact input definition.

### A.5 Worked example (canonical form)

The block below is a fully worked, non-normative example. It uses real taxonomy
Keys from `DOD_TAXONOMY.md` -- `coverage` for an ALWAYS ruling, `mutation-testing`
for a CONDITIONAL ruling (reusing the T1 falsification walkthrough's trigger
predicate), and `performance-spend-budgets` for an N/A ruling:

```
Ratified against DOD_TAXONOMY.md v1.
- coverage: ALWAYS
- mutation-testing: CONDITIONAL | trigger: diff touches tools/ or scripts with
  test suites
- performance-spend-budgets: N/A | category: target-absent | no perf-sensitive
  surface or metered API calls in this repo
Stamp: v1
Content-hash: sha256:4b6f1a2c9e3d7f0851c4a9d6e2b8f3701c5a9e4d2b7f6013c8a5e9d2f4b6a1c7
```

(The hex string above is illustrative, not a real digest of any file.)

---

## B. Detail-file format (docs/dod/<group-slug>/<layer-key>.md)

### B.1 When a detail file exists

Detail files are OPTIONAL per layer -- created only when a ruling's rationale or
elaboration exceeds what the index line's optional free-text tail can carry. The
index stays lean by design (Q2 ruling); anything longer belongs in a detail file
linked from the index's `related` frontmatter field.

### B.2 Path and the group-slug transform

Path shape: `docs/dod/<group-slug>/<layer-key>.md`, where `<layer-key>` is the
taxonomy layer's canonical `Key` (already kebab-case, taken verbatim from
`DOD_TAXONOMY.md`) and `<group-slug>` is derived from the layer's `Group` field by
this exact transform: lowercase the group name, drop every `&` character, collapse
any resulting run of whitespace to a single space, then replace each remaining
space with a hyphen (existing hyphens inside the group name, e.g. from
`Test-Suite`, are left untouched).

Applied to all five current `DOD_TAXONOMY.md` groups, this transform produces:

| Group (DOD_TAXONOMY.md) | group-slug |
|---|---|
| `Acceptance & Traceability` | `acceptance-traceability` |
| `Test-Suite Integrity` | `test-suite-integrity` |
| `Non-Functional Verification` | `non-functional-verification` |
| `Process & Static Gates` | `process-static-gates` |
| `Release Readiness` | `release-readiness` |

Example full paths: `docs/dod/test-suite-integrity/mutation-testing.md`,
`docs/dod/process-static-gates/documentation-updates.md`.

### B.3 Frontmatter and content rules

Detail-file frontmatter follows the documentation skill's Step 2 schema: `title`,
`description`, `domain: dod`, `subdomain: <group-slug>`, `tags` starting
`[dod, <group-slug>, <layer-key>]`, and `related` linking back to `docs/DOD.md` and
to `DOD_TAXONOMY.md`. A `## Related` section is required at the bottom (documentation
skill Step 2). The per-file 800-token cap applies -- one concept (one layer's
rationale) per file.

### B.4 Write order (assumption A15)

Canon writes happen in exactly this order, as a single atomic write step performed
only at ratification (or delta re-ratification): detail files first, then
`docs/DOD.md`, then `docs/INDEX.md`. Nothing is written before this step -- an
interview abandoned before the final ratification pass leaves no file changed.
Because `docs/DOD.md` is written before `docs/INDEX.md`, an interruption between
those two steps leaves detail files and/or an index that `docs/INDEX.md` does not
yet catalog (inert, not live); an interruption before `docs/DOD.md` is written means
no canon exists yet at all (its absence is the "no canon" state consumers check for).

---

## C. Consumer notes

Downstream todos (generator consumption, completion-gate consumption) MUST quote
these four literal marker strings verbatim -- they are the canonical source for all
four:

- `DOD-VIOLATION: <layer>` -- the generator's refusal marker, emitted when a story
  omits an ALWAYS layer with no category-tagged N/A line.
- `DOD-GATE: FAIL <layer>` -- the completion gate's failure marker, emitted when a
  completion claim lacks evidence for an ALWAYS layer or a CONDITIONAL layer whose
  trigger fired.
- `DOD-HASH: MISMATCH` -- emitted by either consumer when the recomputed content-hash
  (Section A.4) does not match the canon's `Content-hash:` footer. This is a
  warn-and-consume oracle (assumption A14): the canon is still read and used: the
  mismatch is a trust flag about possible hand-editing, not a parse failure, so
  consumption does not stop.
- `DOD-STALE: canon v<N> behind taxonomy v<M>` -- emitted by either consumer when the
  canon's `Stamp: vN` is older than `DOD_TAXONOMY.md`'s current stamp. The canon is
  STILL consumed: staleness is a currency warning, not a refusal trigger. Never
  silently consume a stale canon as if it were current.

One additional non-marker rule applies to every consumer:

- **Malformed-canon rule:** if `docs/DOD.md` exists but its structure cannot be
  parsed (missing `Stamp:` line, a ruling line matching none of the three forms in
  Section A.3, missing `Content-hash:` line), consumers MUST refuse with a diagnostic
  naming what failed to parse. Never silently fall back to the canon-less default as
  if no canon existed at all (assumption A8) -- "present but unreadable" and "absent"
  are different states and MUST produce different, observable behavior.

---

## Related

- [DOD_TAXONOMY.md](DOD_TAXONOMY.md) -- the repo-agnostic layer list this template's
  index and detail files instantiate; supplies each layer's `Key` and `Group`.
- [INDEX.md](INDEX.md) -- this skill's reference-file catalog.
- [../SKILL.md](../SKILL.md) -- the ratification interview that produces canon
  conforming to this template.
