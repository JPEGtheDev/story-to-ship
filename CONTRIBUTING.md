# Contributing to story-to-ship

Thanks for contributing to story-to-ship. This guide covers the repository layout, how to add a skill, commit conventions, and the automated checks your pull request (PR) must pass.

## Table of Contents

- [Overview](#overview)
- [Repository Structure](#repository-structure)
- [How to Add a Skill](#how-to-add-a-skill)
- [Conventional Commits and Auto-Tagging](#conventional-commits-and-auto-tagging)
- [Continuous Integration (CI) Checks](#continuous-integration-ci-checks)
- [After Your Pull Request (PR) Merges](#after-your-pull-request-pr-merges)
- [Questions](#questions)

## Overview

story-to-ship ships 35 skills, 14 agents, and two behavioral hook events (three scripts). Skills are invoked via the `Skill` tool or loaded on demand; agents are dispatched via the `Agent` tool. The two hook events are `SessionStart` (one script: injects the Honesty Gate and Iron Laws at every startup) and `UserPromptSubmit` (two scripts: active per-turn enforcement) -- three scripts total across the two events. Skills load on demand rather than all at once, so behavioral standards are enforced without paying the context cost of injecting every skill at startup.

## Repository Structure

The root `skills/`, `agents/`, and `hooks/` directories are the source of truth -- always edit these, never generated or symlinked copies.

This repo dogfoods its own framework: `.claude/skills` and `.claude/agents` are symlinks to `../skills` and `../agents`, and every entry under `.claude/hooks/` -- both the `.md` docs and the `.sh` scripts -- is a symlink back to `../../hooks/*`. There are no real files inside `.claude/hooks/`; it exists only to wire this repo to run on its own framework.

`.claude-plugin/` packages the framework for the Claude Code plugin marketplace. Consumers who install the plugin get their own `.claude/` wiring and never see this repo's symlink internals -- and editing a skill while this repo is itself installed as a plugin writes into the plugin cache (a frozen snapshot outside this git repo), not into the source files. Always edit the root `skills/`, `agents/`, and `hooks/` files directly.

See README.md's "Repository Layout" section for the full picture.

## How to Add a Skill

Every skill lives at `skills/<name>/SKILL.md`. A skill MUST contain all five anatomy elements before it ships:

1. **FRONTMATTER** -- a `name` field plus a `description` that starts with "Use when ...".
2. **IRON LAW** -- an ALL-CAPS rule, followed (outside the backtick fence) by the line "Violating the letter of this rule is violating the spirit of this rule.", plus the phrases "YOU MUST" and "No exceptions."
3. **ANNOUNCEMENT** -- the line `**Announce at start:** "I am using the [skill] skill to [purpose]."`
4. **GATE FUNCTION** -- a `## BEFORE PROCEEDING` section with numbered conditions, each with `[+]`/`[-]` branches.
5. **RATIONALIZATION TABLE** -- a `## Rationalization Prevention` table with 5 or more rows.

The `writing-skills` skill governs skill authoring, and the `skill-reviewer` agent validates new and edited skills against these elements.

## Conventional Commits and Auto-Tagging

Commit messages and PR titles use the format `<type>[scope]: <description>`. The type determines the automatic version bump when the change reaches main:

- `feat:` -> minor version bump
- `fix:` -> patch version bump
- `feat!:` or a `BREAKING CHANGE:` footer -> major version bump
- Any other type (`docs:`, `chore:`, `refactor:`, `test:`, `style:`, `perf:`) -> patch version bump

Every push to main triggers `.github/workflows/release.yml`, which tags a new version automatically based on the most recent commit message.

## Continuous Integration (CI) Checks

`.github/workflows/validate.yml` runs on every PR. Its steps, in order:

1. `actions/checkout@v4`
2. Validate hooks.json
3. Validate .claude-plugin JSON files
4. Shellcheck hook scripts
5. Enforce pre-message hook word budget
6. Check for broken references in skill files
7. Validate SKILL.md frontmatter
8. Check agent template contracts
9. Hook script smoke test

All steps must pass before a PR can merge.

## After Your Pull Request (PR) Merges

Merging uses a squash merge, so your PR title becomes the commit message on main -- make sure it follows the Conventional Commits format above, since `.github/workflows/release.yml` reads that commit message to decide the version bump. That workflow then tags the new version automatically and creates a GitHub Release. Plugin consumers pick up the update the next time they check for updates through the Claude Code plugin manager.

## Questions

If you're unsure how to structure a skill, split work across worktrees, or restore session context, check the `writing-skills`, `using-git-worktrees`, and `session-bootstrap` skills before asking -- they cover the most common contributor questions directly.
