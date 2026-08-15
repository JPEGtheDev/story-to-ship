# Voice Authority Rules

These rules apply to every line of a skill file or agent template. Apply all five sections.

---

## Voice Authority Table

Replace soft language with authoritative language:

| Soft (forbidden) | Authority (required) |
|-----------------|---------------------|
| "should" | MUST |
| "prefer X" | "Use X" or give an explicit decision rule |
| "consider" | "Check" / "Verify" / specific action |
| "try to" | absolute rule or explicit condition |
| "often / usually / typically" | always / never / explicit condition |
| "it might be worth" | state the rule directly |
| "you could potentially" | state the action directly |

**The test:** Can the agent rationalize past this sentence? If yes, make it a rule.

---

## Absolute Path Rule

**Never write absolute paths in skill files or agent templates.** Absolute paths (anything beginning with `/home/`, `/usr/`, `/root/`, or any machine-specific prefix) break portability and embed environment assumptions into skills that must work across machines.

Rules:
- Use `[REPO]` or `git rev-parse --show-toplevel` to refer to the repository root
- Use `scratch/` (project session workspace) or a named template variable for session-scoped paths
- Use template variables (`{{REPO_PATH}}`, `{{SKILL_PATH}}`) in agent prompt templates
- If a skill must reference a specific path, express it relative to a named variable, never as a literal absolute path

**Violation:** Any skill or agent template containing a literal absolute path is an automatic NEEDS WORK in skill review.

---

## Acronym Rule

**Spell out all acronyms on first use.** Do not introduce acronyms unless they fall into an exempt category. Project-specific and skill-specific abbreviations are forbidden -- they require context the reader may not have, and lower-end models will silently misinterpret or skip them.

Exempt categories (no expansion required):
- Universally known: CI, PR, API
- File formats: YAML, JSON, CSV, XML -- these are the format name, not an acronym; expanding them adds no clarity
- Encoding/character standards: ASCII -- explain the constraint in context (e.g., "ASCII-only text (no Unicode characters)") rather than expanding the initialism

Non-exempt -- MUST expand on first use:
- Technical concepts: TDD (Test-Driven Development), UML (Unified Modeling Language), DDD (Domain-Driven Design)
- Project-specific or skill-specific abbreviations (DDR, VBC, SDD, etc.)

Examples:
- WRONG: "After the DDR is approved, hand off to writing-plans."
- RIGHT: "After the Design Decision Record (DDR) is approved, hand off to writing-plans."
- WRONG: "See the VBC skill for the verification gate."
- RIGHT: "See the `verification-before-completion` skill for the verification gate."
- WRONG: "Use TDD to drive the implementation."
- RIGHT: "Use Test-Driven Development (TDD) to drive the implementation."
- WRONG: "Use ASCII-only text."
- RIGHT: "Use ASCII-only text (no Unicode characters)."
- OK: "Use YAML frontmatter." (file format -- no expansion needed)

Apply this rule to every sentence in every skill file, including rationalization tables, return formats, and quick reference blocks.

---

## Jargon Rule

**Define every term of art on first use.** The Acronym Rule above covers initialisms and abbreviations (form); this rule covers meaning -- words whose sense in the skill is narrower than or shifted from their everyday or general-programming sense.

Test (the bright line): would another agent with no project context, reading this file alone, know what this term means here? If not, the first use must carry one of:
1. A parenthetical gloss -- `the canary (the observable line proving the gate ran)`.
2. A one-sentence inline definition.
3. A concrete example immediately after the abstract statement.

For a term whose meaning is narrower than or shifted from its general sense, a parenthetical gloss or one-sentence definition alone does not satisfy first use -- the first use must also carry a concrete example (mechanism 3), alone or alongside the gloss. This constraint is scoped to shifted meanings only; a term already glossed at first use in its plain, unshifted sense is unaffected.

Exempt categories (scoped narrowly):
- Terms defined earlier in the same file.
- Skill names in backticks (`verification-before-completion`) -- the name is the pointer.
- Terms used in their ordinary general-programming sense (function, commit, branch). The exemption fails -- and the rule applies -- the moment the skill assigns the term a narrower or shifted meaning ("class" as defect-class, "register" as prose style, "canary" as proof-of-execution line).
- A term that appears only inside a pointer sentence naming its defining location (`See references/X.md for A, B, C`) is exempt. The exemption fails -- and the rule applies -- when the named file does not actually define the term; a pointer to a file that does not define it is not a definition.
- Tool and mechanism names of the agent platform that are self-identifying in context (TaskList, TaskCreate -- the name states what it is), and platform-runtime concepts every reading agent directly experiences (context compaction). The exemption fails -- and the rule applies -- when the name is a project-local abstraction that an agent with no project context cannot resolve compositionally from the words alone; that name needs a gloss on first use.

Examples:
- WRONG: "An instance fixed is not evidence the class is gone." ("class" undefined)
- RIGHT: "An instance fixed is not evidence the class is gone. Example: fixing an em-dash (the instance) and grepping for em-dashes returns 0, but the class is 'non-ASCII characters' -- curly quotes and Unicode arrows belong to the same class, and the em-dash grep structurally cannot find them."

Enforcement is procedural/self-check: the checkable signal is the Jargon Rule row in the skill-review return format carrying a file:line citation for every flagged term. No automated detector exists -- no grep can implement the first-use test. The rule is advisory (findings reported with evidence, not NEEDS WORK-eligible) until its precision is measured on a hand-adjudicated sample and it is explicitly promoted.

---

## Cross-Skill Reference Rule

**Reference another skill by name in prose. Never cite another skill's file paths or bare internal filenames.** A shipped skill must stand alone -- another skill's internal files are private implementation detail that can be renamed, split, or reorganized without notice, and a file that points to them by path breaks the moment that reorganization happens.

Rules:
- Covers slash paths into another skill's tree (`skills/x/references/Y.md`, `../../skills/x/SKILL.md`)
- Covers bare internal filenames belonging to another skill (`Y.md`, `SKILL.md`) cited outside prose that names the skill
- Files inside the SAME skill may reference each other by path (a skill's own `references/` files, or its own `SKILL.md`)
- Machine-executed paths in commands or scripts are governed by the Absolute Path Rule above, not this rule

**Violation:** Any skill or agent template that cites another skill's internal file by path or bare filename, outside that skill's own tree, is an automatic NEEDS WORK in skill review.

Examples:
- WRONG: "See skills/writing-skills/references/VOICE_AUTHORITY_RULES.md for the authority table."
- RIGHT: "See the writing-skills skill for the authority table."
- WRONG: "Run the check described in DISPATCH_PATTERN.md."
- RIGHT: "Run the check described in the writing-skills skill's dispatch pattern."
- WRONG: "This follows the same gate as ../../skills/verification-before-completion/SKILL.md."
- RIGHT: "This follows the same gate as the verification-before-completion skill."
