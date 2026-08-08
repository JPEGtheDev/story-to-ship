# Infrastructure Review -- Templates and Dispatch

## Review Report Format

```markdown
## Infrastructure Review: [file]

### Pipeline Safety
| Check | Result | Notes |
|-------|--------|-------|
| No git commit/push in steps | [+]/[-] | ... |
| Minimal permissions | [+]/[-] | ... |
| Correct artifact retention | [+]/[-] | ... |
| No hardcoded secrets | [+]/[-] | ... |
| Correct triggers | [+]/[-] | ... |
| Pinned third-party actions | [+]/[-] | ... |

### Build Reproducibility
| Check | Result | Notes |
|-------|--------|-------|
| All dependencies declared | [+]/[-] | ... |
| Dependencies pinned to immutable ref | [+]/[-] | ... |
| Test/production targets separated | [+]/[-] | ... |
| Install rules present | [+]/[-] | ... |
| No hardcoded paths | [+]/[-] | ... |

### Packaging Compliance
| Check | Result | Notes |
|-------|--------|-------|
| Required capabilities declared | [+]/[-] | ... |
| Only needed capabilities declared | [+]/[-] | ... |
| Broad grants justified in writing | [+]/[-] | ... |
| Package/application identifier correct | [+]/[-] | ... |
| Runtime/base image pinned | [+]/[-] | ... |
| No unnecessary network access | [+]/[-] | ... |

### Critical Issues
[Any [-] that must be resolved before merge, with file:line reference]

### Verdict: SAFE / ISSUES FOUND
```

---

## Dispatch Pattern

Run infrastructure-review on any PR that touches:
- `.github/workflows/` -- any workflow file
- a build configuration file -- root or any subdirectory (e.g. `CMakeLists.txt`, `package.json`, `Cargo.toml`, `pyproject.toml`)
- a sandboxed/packaging manifest -- any manifest or build file (e.g. a Flatpak manifest, `Dockerfile`, `snapcraft.yaml`)

Dispatch 1 `infrastructure-reviewer.md` agent per changed file (parallel) -- use `agent_type: "infrastructure-reviewer"`. Provide: `{{FILE_PATH}}` and `{{DIFF}}`. Collect all reports before approving the PR.
