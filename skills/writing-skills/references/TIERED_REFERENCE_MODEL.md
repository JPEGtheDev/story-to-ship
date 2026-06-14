# Tiered Reference Model

Use this model when a skill applies universally but has paradigm-specific or domain-specific checks that fire conditionally.

---

## Model Definition

```
references/
├── <universal-ref-a>.md      <- fires unconditionally for every task
├── <universal-ref-b>.md      <- fires unconditionally for every task
└── <paradigm>/
    ├── index.md              <- dispatch table: conditions + ordered check list
    ├── <ref-a>.md
    └── <ref-b>.md
```

**Root `references/` = universal tier.** Every file here is loaded for every task, no conditions.

**Paradigm subfolder = conditional tier.** Fires only when the triggering condition is true. The subfolder's `index.md` is the mechanically-executable entry point.

---

## index.md Contract

`index.md` is a **dispatch table**, not a table of contents.

Each entry must be mechanically executable: a reader (human or agent) can follow every line without judgment.

### Required sections

**Trigger conditions** (at top) -- the `if` clause that fires this tier:
```markdown
Apply this tier when any of the following are true:
- Modified files include `.cpp` or `.hpp` extensions
- `grep -rn "^class " <modified .py files>` returns results
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
| OOP / C++ | `.cpp` or `.hpp` extensions | `oop/` |
| OOP / Python | `grep -rn "^class "` returns results | `oop/` (shared tier) |
| Scripting | `.sh`, `.ps1`, or `.bash` extensions | `scripting/` |
| Functional | `.hs`, `.elm`, `.ex` extensions | `functional/` |

Shared paradigm tiers (OOP/C++ and OOP/Python both use `oop/`) are the norm, not the exception. The dispatch table in `oop/index.md` notes which checks apply to which languages where they differ.
