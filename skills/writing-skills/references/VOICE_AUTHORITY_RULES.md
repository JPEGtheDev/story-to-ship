# Voice Authority Rules

These rules apply to every line of a skill file or agent template. Apply all three sections.

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
- Use `[SESSION_ID]` and `~/.copilot/session-state/[SESSION_ID]/` for session workspace paths
- Use template variables (`{{REPO_PATH}}`, `{{SESSION_ID}}`) in agent prompt templates
- If a skill must reference a specific path, express it relative to a named variable, never as a literal absolute path

**Violation:** Any skill or agent template containing a literal absolute path is an automatic NEEDS WORK in skill review.

---

## Acronym Rule

**Spell out all terms on first use.** Do not introduce acronyms unless they are universally known (TDD, CI, PR, API). Project-specific and skill-specific abbreviations are forbidden — they require context the reader may not have, and lower-end models will silently misinterpret or skip them.

Examples:
- WRONG: "After the DDR is approved, hand off to writing-plans."
- RIGHT: "After the Design Decision Record is approved, hand off to writing-plans."
- WRONG: "See the VBC skill for the verification gate."
- RIGHT: "See the `verification-before-completion` skill for the verification gate."

Apply this rule to every sentence in every skill file, including rationalization tables, return formats, and quick reference blocks.
