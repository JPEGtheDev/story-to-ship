---
name: infrastructure-review
license: MIT
description: Use when adding CI/CD workflows, modifying build configuration, or updating sandboxed/packaging manifests.
---


## Iron Law

```
PIPELINES MUST BE REPRODUCIBLE AND READ-ONLY -- INFRASTRUCTURE CHANGES NEED REVIEW
YOU MUST review every change to CI/CD workflow files, build configuration files, and sandboxed/packaging manifests before merge. A pipeline that commits, pushes, or uses unpinned dependencies is NOT mergeable. No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

**Announce at start:** "I am using the infrastructure-review skill to review [workflow/build/packaging change]."

---

## BEFORE PROCEEDING

Before reviewing any infrastructure change:

1. The diff has been obtained -- `git diff main...HEAD` covers all changed files in the PR
2. At least one of these is present in the diff: a CI/CD workflow file (e.g. `.github/workflows/*.yml`), a build configuration file (e.g. `CMakeLists.txt`, `package.json`, `Cargo.toml`, `pyproject.toml`), or a sandboxed/packaging manifest (e.g. a Flatpak manifest, `Dockerfile`, `snapcraft.yaml`)
3. Every review area below is applied -- no section skipped because a change "looks small"
4. Every checklist item in all three review areas is answered YES or NO -- no items left unanswered
5. Any item answered NO produces a row in the violations table before the verdict is written

[+] All met -> proceed through the three review areas
[-] Any unmet -> resolve the unmet item before writing a verdict

---

## Review Areas

### 1. CI/CD (Continuous Delivery) Pipeline Checks

Run every item for each changed `.github/workflows/*.yml` file:

1. No `git commit` or `git push` in any workflow step -- pipelines are read-only (see `workflow` skill)
2. All `permissions:` blocks are minimal -- read-only where possible; write only where explicitly justified
3. Artifacts uploaded with correct retention -- short for PRs (7 days), longer for releases (90 days)
4. No secrets hardcoded -- all sensitive values via `${{ secrets.X }}` only
5. Workflow triggers are intentional -- `push` and `pull_request` events correct; no unintended `workflow_run` chains
6. Matrix builds cover required platforms (Linux at minimum; Windows/macOS if the project targets them)
7. `actions/checkout` and other third-party actions pinned to a specific Secure Hash Algorithm (SHA), not a floating tag

[+] All pass -> pipeline is safe to merge
[-] Any unmet -> verdict: ISSUES FOUND -- document in review report

### 2. Reproducible Build Review

Run every item for each changed build configuration file:

1. All dependencies declared explicitly (no reliance on ambient system packages or tools not listed in the build file)
2. Every third-party dependency pinned to an immutable reference -- a lockfile entry, exact version tag, commit hash, or content digest; never a moving pointer (`main`, `master`, `latest`, or an unpinned version range)
3. Test targets are separated from production targets
4. Install/packaging rules present for release builds
5. No hardcoded absolute paths -- all paths relative or constructed via build-tool variables

[+] All pass -> build is reproducible
[-] Any unmet -> verdict: ISSUES FOUND -- document in review report

### 3. Sandboxed/Least-Privilege Packaging Review

Run every item for any changed sandboxed/packaging manifest:

1. Every capability the application functionally requires at runtime is declared -- omissions cause silent runtime failure, not a build error
2. Manifest declares only the capabilities/permissions the application actually needs -- no broad grants "just in case"
3. Any broad or unusual permission grant is justified in writing (comment or PR description) explaining why the minimum isn't sufficient
4. Package/application identifier matches the project's naming convention
5. Runtime/base image pinned to a specific release (not a floating `latest`)
6. Network access absent from the manifest unless explicitly required and documented

[+] All pass -> packaging manifest is compliant
[-] Any unmet -> verdict: ISSUES FOUND -- document in review report

---

## Review Report Format and Dispatch Pattern

For the full report table template (Pipeline Safety, Build Reproducibility, Packaging Compliance sections) and dispatch instructions, see `references/INFRA_REVIEW_TEMPLATES.md`.

A verdict of ISSUES FOUND means the PR is NOT mergeable until every critical issue is resolved.

---

## Red Flags -- STOP

If you catch yourself thinking any of the following, STOP before writing your verdict:

- "The pipeline worked before, this change is minor" -> Stop. Minor CI changes cause hard-to-debug failures. Review the full checklist anyway.
- "This dependency on a branch/latest is fine for now, I'll pin it later" -> Stop. Branches and floating tags move. Unpinned dependencies are not reproducible. Pin it now to a lockfile entry, exact tag, commit hash, or digest.
- "This capability probably isn't needed for this build" -> Stop. Sandboxed packaging requires an explicit grant for anything the application functionally needs -- an omission fails silently at runtime, not at build time. Assume it is needed until verified otherwise.
- "The permissions block is broad but I need it for this one step" -> Stop. Identify the minimum permissions that step requires and use those only.
- "The secrets are only test keys, not production" -> Stop. All secrets go in `${{ secrets.X }}`. Hardcoded keys are a violation regardless of their scope.

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "The pipeline worked before, this change is minor" | Minor CI changes cause hard-to-debug, intermittent failures. Review every change against the checklist. |
| "A dependency on a branch or latest tag is fine for now" | Branches and floating tags can move at any commit. Pin to a lockfile entry, exact tag, commit hash, or digest for reproducible builds. |
| "The packaging manifest will work -- it worked on other machines" | Sandboxed packaging requires an explicit grant for every capability the application functionally needs. A missing grant fails silently at runtime, not at build time. |
| "The permissions block is broad but I need it for X" | Identify the minimal permissions for X and use those. Broad permissions are a security risk even in CI. |
| "Secrets are only test keys, not production" | All secrets go in `${{ secrets.X }}`. No hardcoded values. No exceptions. |
| "Third-party action tags are stable enough" | Tags can be force-pushed. Pin to a commit SHA for supply chain security. |

---

## Related Skills

- `workflow` -- owns CI/CD pipeline patterns; infrastructure-review enforces compliance with those patterns
- `architecture-review` -- checks source-level structure; infrastructure-review checks build and pipeline structure
