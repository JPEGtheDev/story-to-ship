---
name: versioning
description: Manage semantic versioning, conventional commits, PR title requirements, and release automation. Use when creating PRs, writing commit messages, understanding version bumps, or troubleshooting release issues.
license: MIT
compatibility: Designed for GitHub Copilot and similar AI coding agents
metadata:
  author: JPEGtheDev
  version: "1.0"
  category: versioning
  project: Particle-Viewer
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
- Individual commits within the PR should still use conventional format
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

## Reference

- Full commit format examples: [`docs/CONVENTIONAL_COMMITS.md`](../../../docs/CONVENTIONAL_COMMITS.md)
- Release pipeline details: [`docs/RELEASE_PROCESS.md`](../../../docs/RELEASE_PROCESS.md)
- CI workflow rules: `workflow` skill (`.github/skills/workflow/`)
