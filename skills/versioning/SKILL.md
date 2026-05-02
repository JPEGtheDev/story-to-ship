---
name: versioning
license: MIT
description: Use when creating PRs, writing commit messages, understanding version bumps, or troubleshooting release issues for Particle-Viewer.
---

## Iron Law

```
EVERY COMMIT AND PR TITLE MUST USE CONVENTIONAL FORMAT
```

Violating the letter of this rule is violating the spirit of this rule.

`<type>[scope]: <description>` — no exceptions. Wrong format breaks release automation.

**Announce at start:** "I am using the versioning skill to [create commit/PR for] [description]."

---

# Instructions for Agent

## How This Skill is Invoked

In VS Code, users will activate this skill by:
- Typing `@workspace /versioning [description]` in Copilot Chat
- Or asking: "What commit type should I use?", "Create a PR", "How does versioning work?"

When activated, ensure all commits and PR titles follow conventional commits format.

---

## Core Principle: Commit Messages Drive Releases

This project uses **zero-manual releases**. Every push to master triggers an automated release. The commit message (which comes from the squash-merged PR title) determines the version bump.

---

## Step 1: Conventional Commit Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer]
```

### Types and Version Bumps

| Type | Version Bump | Example |
|------|-------------|---------|
| `feat:` | MINOR (0.1.0 → 0.2.0) | `feat: add particle color picker` |
| `fix:` | PATCH (0.1.0 → 0.1.1) | `fix: resolve crash on startup` |
| `feat!:` / `fix!:` / `BREAKING CHANGE:` | MAJOR (0.1.0 → 1.0.0) | `feat!: redesign shader API` |
| `docs:`, `test:`, `chore:`, `refactor:`, `style:`, `perf:` | PATCH (default) | `docs: update README` |

Every commit type triggers at least a PATCH bump. The release workflow specifically detects `feat:` and `fix:` plus any `!` breaking marker.

---

## Step 2: PR Title Rules

**This project uses squash merging.** The PR title becomes the single commit message on master, which determines the version bump.

### Creating a New PR

The PR title **MUST** use conventional commits format:

**Valid:**
- `feat: add particle color customization`
- `fix(camera): correct rotation calculation in moveAround method`
- `docs: update build instructions for Flatpak`
- `feat!: redesign configuration API`

**Invalid:**
- ❌ "Add particle color customization" (missing type)
- ❌ "Update camera rotation" (missing type)

### Working on an Existing PR

**DO NOT modify the PR title** unless the user explicitly asks.

- The PR title represents the **overall feature or fix**, not individual subtasks
- Individual commits within the PR MUST still use conventional format
- Update the PR **description** (not title) to track subtask progress

---

## Step 3: PR Requirements Checklist

Before a PR can merge:

- [ ] PR title uses conventional commits format
- [ ] All commits use conventional commits format
- [ ] Code formatted with `clang-format` (see `code-quality` skill)
- [ ] Build succeeds on all platforms
- [ ] Unit tests pass
- [ ] CI formatting checks pass

✓ All met → PR is ready to merge
✗ Any unmet → resolve before opening or merging the PR

---

## Step 4: Version Resolution

At build time, version is resolved in this order:
1. `PROJECT_VERSION` CMake variable (e.g., `-DPROJECT_VERSION=1.2.3`)
2. Git tags (format: `v0.1.0`) — used by CI release workflow
3. Fallback: `0.0.0`

**DO NOT** manually create git tags, edit versions in CMakeLists.txt, or create manual releases.

---

## Troubleshooting

**Wrong version bump occurred:**
Verify the commit message/PR title uses the correct type. Manual override via `workflow_dispatch` if needed.

**Need a release:**
Just push conventional commits to master — it's automatic.

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "The commit type doesn't matter much" | Wrong type = wrong version bump. `fix` → patch, `feat` → minor, `feat!` → major. Automation parses this. |
| "I'll fix the commit message after the PR is merged" | Merged commit messages are permanent. The PR title IS the squash commit message. |
| "This feels like a feat but it's technically a fix" | Ask: does it add a new user-visible behavior? Yes → `feat`. No → `fix`. |
| "The PR title is close enough to conventional format" | Close enough = broken parsing. The format must be exact. |
| "I'll write a proper commit message once the work is done" | Write the commit type first — it clarifies scope and prevents scope creep. |
| "scope is optional so I'll skip it" | Scope makes large PRs navigable. Use it whenever the change is domain-specific. |

---

## Red Flags — STOP

If you catch yourself thinking any of these, stop and follow the rule:
- About to write a commit message without checking the type first
- "feat or fix, doesn't really matter"
- Commit message starts with a capital letter or ends with a period
- PR title doesn't start with `<type>[scope]:` format
- "I'll change the PR title later if needed"
- Working on a hotfix and tempted to use `feat` to "be safe"

**All of these mean: Check the type first. `feat` = new user-visible behavior, `fix` = corrects existing behavior, `docs` = documentation only. When in doubt, read the `versioning` skill.**

---

## Reference

- Full commit format examples: [`docs/CONVENTIONAL_COMMITS.md`](../../../docs/CONVENTIONAL_COMMITS.md)
- Release pipeline details: [`docs/RELEASE_PROCESS.md`](../../../docs/RELEASE_PROCESS.md)
- CI workflow rules: `workflow` skill (`.github/skills/workflow/`)
