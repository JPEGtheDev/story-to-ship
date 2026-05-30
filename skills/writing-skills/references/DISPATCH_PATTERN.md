# Dispatch Pattern -- Skill Review

How to dispatch the `skill-reviewer` agent to audit one or more skills in parallel.
One agent per skill directory -- the agent reviews `SKILL.md` and every file in `references/`.

---

## Steps

1. Read these four files from `writing-skills/references/`:
   - `SKILL_ANATOMY_ELEMENTS.md` → `{{SKILL_ANATOMY_ELEMENTS}}`
   - `VOICE_AUTHORITY_RULES.md` → `{{VOICE_AUTHORITY_RULES}}`
   - `SIZE_AND_COMPRESSION.md` → `{{SIZE_AND_COMPRESSION}}`
   - `REVIEW_INSTRUCTIONS.md` → `{{REVIEW_INSTRUCTIONS}}`
2. For each skill: substitute all four placeholders in `agents/skill-reviewer.md`, set `{{SKILL_PATH}}` (absolute path to the skill's `SKILL.md` inside the worktree), `{{RECENT_CHANGES}}`, and `{{WORKTREE_PATH}}` (the pre-created worktree path, e.g. `<repo_root>/.worktrees/<agent-name>`), dispatch. The agent derives `references/` from `dirname({{SKILL_PATH}})` at runtime.
3. Collect all reports before acting on any result.
4. For each NEEDS WORK verdict: update the skill and re-dispatch a review of that file.

---

## Why 4 Placeholders

| Placeholder | Source file | What it provides |
|-------------|-------------|------------------|
| `{{SKILL_ANATOMY_ELEMENTS}}` | `SKILL_ANATOMY_ELEMENTS.md` | 5-element schemas, Alexandrian Pattern Form guide |
| `{{VOICE_AUTHORITY_RULES}}` | `VOICE_AUTHORITY_RULES.md` | Authority table, Absolute Path Rule, Acronym Rule |
| `{{SIZE_AND_COMPRESSION}}` | `SIZE_AND_COMPRESSION.md` | Token limits, compression rules, Skill Composition Model |
| `{{REVIEW_INSTRUCTIONS}}` | `REVIEW_INSTRUCTIONS.md` | Review process, checklist, return format |

Injecting at dispatch time means the reviewer has current criteria without any runtime file reads. It also means the same agent template works for external skills that do not share a file system with this repo -- no cross-skill file path dependencies.
