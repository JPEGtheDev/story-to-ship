# Tiered Reference Model

Use this model when a skill applies universally but has paradigm-specific or domain-specific checks that fire conditionally.

This model is the skill-reference equivalent of the `documentation` skill's domain/subdomain directory structure. The structural pattern is the same: universal root + conditional subfolders with an index. The difference is purpose -- documentation domains organize for retrieval; reference tiers organize for conditional execution.

---

## Structural Parallel

| Documentation skill | Tiered reference model |
|---------------------|------------------------|
| `docs/<domain>/` | `references/<paradigm>/` |
| `docs/<domain>/INDEX.md` | `references/<paradigm>/index.md` |
| Cross-cutting standards (`docs/UPPERCASE.md`) | Universal references (`references/*.md`) |
| Domain guides (conditional by topic) | Paradigm references (conditional by file type) |

**Root `references/` = universal tier.** Loaded unconditionally for every task -- same as cross-cutting standards in docs.

**Paradigm subfolder = conditional tier.** Fires only when the triggering condition is true -- same as domain guides in docs.

---

## Directory Layout

```
references/
+-  <universal-ref-a>.md      <- fires unconditionally for every task
+-  <universal-ref-b>.md      <- fires unconditionally for every task
+-- <paradigm>/
    +-- index.md              <- dispatch table: conditions + ordered check list
    +-- <ref-a>.md
    +-- <ref-b>.md
```

---

## index.md Contract

`index.md` is a **dispatch table**, not a table of contents.

Each entry must be mechanically executable: a reader (human or agent) can follow every line without judgment.

### Required sections

**Trigger conditions** (at top) -- the `if` clause that fires this tier:
```markdown
Apply this tier when any of the following are true:
- Modified files include `.cpp` or `.hpp` extensions
- `git diff --cached --name-only | grep '\.py$' | xargs grep -l "^class "` returns results
```

**Ordered check list** -- numbered, action-first, reference-linked:
```markdown
1. **Formatting** -- `cpp-toolchain.md` -- run clang-format and clang-tidy before committing
2. **Naming** -- `naming-tables.md` -- verify all new identifiers follow OOP naming conventions
```

**Pass/fail gate** (at bottom):
```markdown
[+] All N pass -> [paradigm] tier complete; proceed to commit
[-] Any failing -> fix before committing
```

### What index.md must NOT contain

- Narrative explanation of why checks exist (belongs in the referenced `.md`)
- Enforcement logic (belongs in `SKILL.md`'s BEFORE PROCEEDING gate)
- Rationale tables or Anti-Pattern lists (belongs in `SKILL.md`)

---

## SKILL.md Integration

The BEFORE PROCEEDING gate in `SKILL.md` drives both tiers:

```markdown
### Step 1: Universal Tier (all code, no exceptions)

1. Check `references/<universal-ref-a>.md`
2. Check `references/<universal-ref-b>.md`

### Step 2: Identify Paradigm

Run in order; stop at first match:
1. <file extension check> -> <paradigm> tier
2. <grep check> -> <paradigm> tier
3. No match -> universal only (skip Step 3)

### Step 3: Paradigm Tier

Load `references/<paradigm>/index.md` and apply all checks listed there.
```

Enforcement stays in `SKILL.md`. Reference files are lookup material only.

---

## Adding a New Paradigm

1. Create `references/<paradigm>/` directory
2. Write `index.md` following the contract above
3. Add a paradigm detection rule to SKILL.md Step 2
4. Add a reference entry to SKILL.md Reference section

Do NOT add enforcement logic to the paradigm reference files. The `index.md` lists what to check; `SKILL.md` commands that it be checked.

---

## Example Paradigms

| Paradigm | Trigger | Subfolder |
|----------|---------|-----------|
| Object-Oriented Programming (OOP) / C++ | `.cpp` or `.hpp` extensions | `oop/cpp/` |
| OOP / Python | deferred -- `references/oop/python/` does not exist yet | `oop/python/` (deferred) |
| Scripting | `.sh`, `.ps1`, or `.bash` extensions | `scripting/` (deferred) |
| Functional | `.hs`, `.elm`, `.ex` extensions | `functional/` (deferred) |

---

## Related

- `documentation` skill -- domain/subdomain model this structure mirrors; read for retrieval-oriented hierarchy
- `code-quality` skill -- the primary consumer of this model; `references/oop/cpp/` is the reference implementation
