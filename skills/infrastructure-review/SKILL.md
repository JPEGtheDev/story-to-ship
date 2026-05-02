---
name: infrastructure-review
license: MIT
description: Use when adding workflows, modifying CMakeLists.txt, or updating Flatpak manifests for Particle-Viewer.
---

## Iron Law

```
PIPELINES MUST BE REPRODUCIBLE AND READ-ONLY — INFRASTRUCTURE CHANGES NEED REVIEW
```

Violating the letter of this rule is violating the spirit of this rule.

YOU MUST review every change to `.github/workflows/`, `CMakeLists.txt`, and `flatpak/` before merge. A pipeline that commits, pushes, or uses unpinned dependencies is NOT mergeable. No exceptions.

**Announce at start:** "I am using the infrastructure-review skill to review [workflow/CMake/Flatpak change]."

---

## Review Areas

### 1. CI/CD Pipeline Checks

Run every item for each changed `.github/workflows/*.yml` file:

- [ ] No `git commit` or `git push` in any workflow step — pipelines are read-only (see `workflow` skill)
- [ ] All `permissions:` blocks are minimal — read-only where possible; write only where explicitly justified
- [ ] Artifacts uploaded with correct retention — short for PRs (7 days), longer for releases (90 days)
- [ ] No secrets hardcoded — all sensitive values via `${{ secrets.X }}` only
- [ ] Workflow triggers are intentional — `push` and `pull_request` events correct; no unintended `workflow_run` chains
- [ ] Matrix builds cover required platforms (Linux at minimum; Windows/macOS if the project targets them)
- [ ] `actions/checkout` and other third-party actions pinned to a specific SHA, not a floating tag

✓ All pass → pipeline is safe to merge
✗ Any unmet → verdict: ISSUES FOUND — document in review report

### 2. CMake Build Checks

Run every item for each changed `CMakeLists.txt`:

- [ ] All dependencies declared explicitly (no reliance on ambient system packages not listed in the build file)
- [ ] `FetchContent` sources pinned to a specific tag or commit hash — never `main`, `master`, or `latest`
- [ ] Test targets (`ParticleViewerTests`) are separated from production targets (`Viewer`)
- [ ] Install rules present for release builds (`install(TARGETS ...)`)
- [ ] No hardcoded absolute paths — all paths relative or constructed via CMake variables

✓ All pass → build is reproducible
✗ Any unmet → verdict: ISSUES FOUND — document in review report

### 3. Flatpak Manifest Checks

Run every item for any changed file under `flatpak/`:

- [ ] OpenGL extension permissions declared — required for GPU access in Flatpak sandbox (see `flatpak` skill)
- [ ] SDL3 permissions correct for display and input device access
- [ ] App ID matches `com.jpegthedev.ParticleViewer` naming convention
- [ ] Runtime version pinned to a specific release (not a floating `latest`)
- [ ] `--share=network` absent from finish-args unless network access is explicitly required and documented

✓ All pass → Flatpak manifest is compliant
✗ Any unmet → verdict: ISSUES FOUND — document in review report

---

## Review Report Format

```markdown
## Infrastructure Review: [file]

### Pipeline Safety
| Check | Result | Notes |
|-------|--------|-------|
| No git commit/push in steps | ✅/❌ | ... |
| Minimal permissions | ✅/❌ | ... |
| Correct artifact retention | ✅/❌ | ... |
| No hardcoded secrets | ✅/❌ | ... |
| Correct triggers | ✅/❌ | ... |
| Pinned third-party actions | ✅/❌ | ... |

### Build Reproducibility
| Check | Result | Notes |
|-------|--------|-------|
| All dependencies declared | ✅/❌ | ... |
| FetchContent pinned | ✅/❌ | ... |
| Test/production targets separated | ✅/❌ | ... |
| Install rules present | ✅/❌ | ... |
| No hardcoded paths | ✅/❌ | ... |

### Flatpak Compliance
| Check | Result | Notes |
|-------|--------|-------|
| OpenGL permissions declared | ✅/❌ | ... |
| SDL3 permissions correct | ✅/❌ | ... |
| App ID correct | ✅/❌ | ... |
| Runtime pinned | ✅/❌ | ... |
| No unnecessary --share=network | ✅/❌ | ... |

### Critical Issues
[Any ❌ that must be resolved before merge, with file:line reference]

### Verdict: SAFE / ISSUES FOUND
```

A verdict of ISSUES FOUND means the PR is NOT mergeable until every critical issue is resolved.

---

## Dispatch Pattern

Run infrastructure-review on any PR that touches:
- `.github/workflows/` — any workflow file
- `CMakeLists.txt` — root or any subdirectory
- `flatpak/` — any manifest or build file

Dispatch 1 `infrastructure-reviewer.md` agent per changed file (parallel) — use `agent_type: "code-review"`. Provide: `{{FILE_PATH}}` and `{{DIFF}}`. Collect all reports before approving the PR.

---

## Red Flags — STOP

If you catch yourself thinking any of the following, STOP before writing your verdict:

- "The pipeline worked before, this change is minor" → Stop. Minor CI changes cause hard-to-debug failures. Review the full checklist anyway.
- "FetchContent branch is fine for now, I'll pin it later" → Stop. Branches move. Unpinned dependencies are not reproducible. Pin it now.
- "GL permissions probably aren't needed for this build" → Stop. GL access in Flatpak requires explicit permissions. See GOTCHAS doc. Assume it is needed until verified otherwise.
- "The permissions block is broad but I need it for this one step" → Stop. Identify the minimum permissions that step requires and use those only.
- "The secrets are only test keys, not production" → Stop. All secrets go in `${{ secrets.X }}`. Hardcoded keys are a violation regardless of their scope.

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "The pipeline worked before, this change is minor" | Minor CI changes cause hard-to-debug, intermittent failures. Review every change against the checklist. |
| "FetchContent branch is fine for now" | Branches can move at any commit. Pin to a tag or commit SHA for reproducible builds. |
| "Flatpak will work — it worked on other machines" | GL access in Flatpak requires explicit sandbox permissions. Missing permissions = silent runtime failure. See GOTCHAS doc. |
| "The permissions block is broad but I need it for X" | Identify the minimal permissions for X and use those. Broad permissions are a security risk even in CI. |
| "Secrets are only test keys, not production" | All secrets go in `${{ secrets.X }}`. No hardcoded values. No exceptions. |
| "Third-party action tags are stable enough" | Tags can be force-pushed. Pin to a commit SHA for supply chain security. |

---

## Related Skills

- `workflow` — owns CI/CD pipeline patterns; infrastructure-review enforces compliance with those patterns
- `build` — owns CMake and Flatpak authoring; infrastructure-review checks the output for correctness
- `architecture-review` — checks source-level structure; infrastructure-review checks build and pipeline structure
- `flatpak` skill — required reading for any Flatpak manifest change; owns MSAA, SDL3 module, NVIDIA GL, and setenv rules
