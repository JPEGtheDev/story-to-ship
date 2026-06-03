---
name: versioning
license: MIT
description: Use when creating PRs, writing commit messages, understanding version bumps, or troubleshooting release issues.
---


## Iron Law

```
EVERY COMMIT AND PR TITLE MUST USE CONVENTIONAL FORMAT
YOU MUST use conventional format for every commit message and PR title.
No exceptions. Wrong format breaks release automation.
```

Violating the letter of this rule is violating the spirit of this rule.

`<type>[scope]: <description>`

**Announce at start:** "I am using the versioning skill to [create commit/PR for] [description]."

---

## Core Principle: Commit Messages Drive Releases

This project uses **zero-manual releases**. Every push to main triggers an automated release. The commit message (which comes from the squash-merged PR title) determines the version bump.

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
| `feat:` | MINOR (0.1.0 -> 0.2.0) | `feat: add particle color picker` |
| `fix:` | PATCH (0.1.0 -> 0.1.1) | `fix: resolve crash on startup` |
| `feat!:` / `fix!:` / `BREAKING CHANGE:` | MAJOR (0.1.0 -> 1.0.0) | `feat!: redesign shader API` |
| `docs:`, `test:`, `chore:`, `refactor:`, `style:`, `perf:` | PATCH (default) | `docs: update README` |

Every commit type triggers at least a PATCH bump. The release workflow specifically detects `feat:` and `fix:` plus any `!` breaking marker.

---

## Step 2: PR Title Rules

**This project uses squash merging.** The PR title becomes the single commit message on main, which determines the version bump.

### Creating a New PR

The PR title **MUST** use conventional commits format:

**Valid:**
- `feat: add user authentication`
- `fix(auth): correct token expiry calculation`
- `docs: update installation instructions`
- `chore: upgrade dependency versions`
- `feat!: redesign public API`

**Invalid:**
- [-] "Add particle color customization" (missing type)
- [-] "Update camera rotation" (missing type)

### Working on an Existing PR

**DO NOT modify the PR title** unless the user explicitly asks.

- The PR title represents the **overall feature or fix**, not individual subtasks
- Individual commits within the PR MUST still use conventional format
- Update the PR **description** (not title) to track subtask progress

---

## BEFORE PROCEEDING

Before opening or merging a PR:

1. PR title uses conventional commits format
2. All commits use conventional commits format
3. Code formatted (run your project's formatter)
4. Tests pass
5. CI checks pass

[+] All met -> PR is ready to merge
[-] Any unmet -> resolve before opening or merging the PR

---

## Step 4: Version Resolution

Tag format: `v1.2.3`. Apply the bump rules using your project's release automation, or
create semver tags manually when no automation exists:

```shell
git tag v1.2.3 -m "Release v1.2.3" && git push origin v1.2.3
```

The mapping: `feat!` / `BREAKING CHANGE` -> MAJOR, `feat:` -> MINOR, all else -> PATCH.

---

## Troubleshooting

**Wrong version bump occurred:**
Verify the commit message/PR title uses the correct type. Check your project's release automation for manual override options.

**Need a release:**
Just push conventional commits to main -- it's automatic.

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "The commit type doesn't matter much" | Wrong type = wrong version bump. `fix` -> patch, `feat` -> minor, `feat!` -> major. Automation parses this. |
| "I'll fix the commit message after the PR is merged" | Merged commit messages are permanent. The PR title IS the squash commit message. |
| "This feels like a feat but it's technically a fix" | Ask: does it add a new user-visible behavior? Yes -> `feat`. No -> `fix`. |
| "The PR title is close enough to conventional format" | Close enough = broken parsing. The format must be exact. |
| "I'll write a proper commit message once the work is done" | Write the commit type first -- it clarifies scope and prevents scope creep. |
| "scope is optional so I'll skip it" | Scope makes large PRs navigable. Use it whenever the change is domain-specific. |

---

## Red Flags -- STOP

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

- [Conventional Commits specification](https://www.conventionalcommits.org)
- Release pipeline: [`.github/workflows/release.yml`](../../../.github/workflows/release.yml)
- CI workflow rules: `workflow` skill
