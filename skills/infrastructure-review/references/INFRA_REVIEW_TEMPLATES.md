# Infrastructure Review -- Templates and Dispatch

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

---

## Dispatch Pattern

Run infrastructure-review on any PR that touches:
- `.github/workflows/` -- any workflow file
- `CMakeLists.txt` -- root or any subdirectory
- `flatpak/` -- any manifest or build file

Dispatch 1 `infrastructure-reviewer.md` agent per changed file (parallel) -- use `agent_type: "code-review"`. Provide: `{{FILE_PATH}}` and `{{DIFF}}`. Collect all reports before approving the PR.
