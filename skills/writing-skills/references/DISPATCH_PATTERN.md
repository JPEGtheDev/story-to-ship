# Dispatch Pattern -- Skill Review

How to dispatch the `skill-reviewer` agent to audit one or more skills in parallel.
One agent per skill directory -- the agent reviews `SKILL.md` and every file in `references/`.

---

## Steps

1. Read these four files from `writing-skills/references/`:
   - `SKILL_ANATOMY_ELEMENTS.md` -> `{{SKILL_ANATOMY_ELEMENTS}}`
   - `VOICE_AUTHORITY_RULES.md` -> `{{VOICE_AUTHORITY_RULES}}`
   - `SIZE_AND_COMPRESSION.md` -> `{{SIZE_AND_COMPRESSION}}`
   - `REVIEW_INSTRUCTIONS.md` -> `{{REVIEW_INSTRUCTIONS}}`
2. For each skill: substitute all four reference placeholders for the `skill-reviewer` agent, set the five dispatch placeholders, then dispatch. The agent derives `references/` from `dirname({{SKILL_PATH}})` at runtime.
   - `{{SKILL_PATH}}` -- absolute path to the skill's `SKILL.md` inside the worktree
   - `{{RECENT_CHANGES}}` -- the changes that prompted the audit
   - `{{WORKTREE_PATH}}` -- the pre-created worktree path, e.g. `<repo_root>/.worktrees/<agent-name>`
   - `{{SECOND_PATH}}` -- `none` in this flow; pairing two files that implement one change into one dispatch is the Stage 2 change review the `two-stage-review` skill defines, not an audit
   - `{{IMPLEMENTER_EVIDENCE}}` -- the implementer's pasted verification output, or a statement that no implementer ran for this audit
3. For each modified reference file listed in `{{RECENT_CHANGES}}`: dispatch a SEPARATE skill-reviewer agent with that file as `{{SKILL_PATH}}` and `{{SECOND_PATH}}` again `none`. Include the file path explicitly in the prompt. The agent applies the full Step 2 quality checklist (weak language, acronym rule, jargon rule, absolute paths, cross-skill refs, enforcement co-location) adapted for a reference file -- skip anatomy element checks (Iron Law, Announcement, Gate Function, Rationalization Table) since those only apply to SKILL.md.
4. Collect all reports before acting on any result.
5. For each NEEDS WORK verdict: update the skill and re-dispatch a review of that file.

---

## Why 4 Reference Placeholders

| Placeholder | Source file | What it provides |
|-------------|-------------|------------------|
| `{{SKILL_ANATOMY_ELEMENTS}}` | `SKILL_ANATOMY_ELEMENTS.md` | 5-element schemas, Alexandrian Pattern Form guide |
| `{{VOICE_AUTHORITY_RULES}}` | `VOICE_AUTHORITY_RULES.md` | Authority table, Absolute Path Rule, Acronym Rule, Jargon Rule |
| `{{SIZE_AND_COMPRESSION}}` | `SIZE_AND_COMPRESSION.md` | Token limits, compression rules, Skill Composition Model |
| `{{REVIEW_INSTRUCTIONS}}` | `REVIEW_INSTRUCTIONS.md` | Review process, checklist, return format |

Injecting at dispatch time means the reviewer has current criteria without any runtime file reads. It also means the same agent template works for external skills that do not share a file system with this repo -- no cross-skill file path dependencies.

---

## Reference Files

- `SKILL_ANATOMY_ELEMENTS.md` -- element schemas, bad/good examples, Alexandrian Pattern Form guide
- `SIZE_AND_COMPRESSION.md` -- token targets, compression rules including enforcement co-location gate, line limits
- `VOICE_AUTHORITY_RULES.md` -- authority table, Absolute Path Rule, Acronym Rule, Jargon Rule
- `MODEL_COMPATIBILITY.md` -- patterns most likely skipped by lower-end models
- `REVIEW_INSTRUCTIONS.md` -- review checklist and return format; injected into `skill-reviewer` at dispatch time
- `DISPATCH_PATTERN.md` -- this file; dispatch instructions for auditing skills

## Related Skills

- `skill-reviewer` agent template -- dispatches review agents using this skill's reference files as injected criteria
- `documentation` -- governs how skill reference docs are structured, formatted, and linked
- `self-evaluation` -- reviews skills updated during a session using this checklist
