# story-to-ship

Skills and agents for the developer-side SDLC -- from story through merged branch. Covers requirements, planning, implementation, testing, review, CI/CD, and retrospective. Does not cover deployment, monitoring, or security review.

## Install

```shell
/plugin marketplace add jpegthedev/story-to-ship
/plugin install story-to-ship@story-to-ship
```

## SDLC Coverage

### Discovery and Requirements
| Skill | Purpose |
|-------|---------|
| `brainstorming` | Unclear approach or design decisions |
| `three-amigos` | Acceptance criteria ceremony |
| `user-story-generator` | Creating INVEST-aligned user stories |
| `user-story-estimation` | Estimating effort and token budgets |

### Planning
| Skill | Purpose |
|-------|---------|
| `writing-plans` | Multi-step tasks and feature work |
| `brainstorming` | Design decisions before committing to an approach |

### Implementation
| Skill | Purpose |
|-------|---------|
| `execution` | Any non-trivial implementation work |
| `honesty` | Communication quality and trust enforcement -- always active |
| `code-quality` | Writing or reviewing code |
| `session-bootstrap` | Starting any new session |
| `subagent-driven-development` | Delegating tasks, parallel research, reviewing work |
| `dispatching-parallel-agents` | Fan-out investigation across multiple files |
| `using-git-worktrees` | Parallel agent work in isolation |

### Testing and Verification
| Skill | Purpose |
|-------|---------|
| `testing` | Writing or reviewing any test |
| `contract-testing` | Testing interfaces or abstract base classes |
| `systematic-debugging` | Any bug, failure, or unexpected behavior |
| `verification-before-completion` | Before claiming work is done |

### Code Review
| Skill | Purpose |
|-------|---------|
| `requesting-code-review` | Preparing a PR for review |
| `receiving-code-review` | Acting on review feedback |

### CI/CD and Release
| Skill | Purpose |
|-------|---------|
| `workflow` | GitHub Actions workflows and CI configuration |
| `versioning` | Commits, PRs, version bumps |
| `finishing-a-development-branch` | Branch ready to merge |

### Documentation and Knowledge
| Skill | Purpose |
|-------|---------|
| `documentation` | Creating or reviewing docs |
| `summarization` | Summarizing external resources |
| `writing-skills` | Authoring or editing skill files |

### Retrospective
| Skill | Purpose |
|-------|---------|
| `session-postmortem` | Behavioral retrospective on completed sessions |
| `self-evaluation` | Completing a session |

---

### Agents
| Agent | Role |
|-------|------|
| `implementer` | Feature implementation in a git worktree |
| `skeptic` | Plan gap analysis before implementation |
| `spec-compliance-reviewer` | Stage 1 post-todo review |
| `code-quality-reviewer` | Stage 2 post-todo review |
| `explorer` | Read-only multi-file research |
| `researcher` | Hypothesis confirmation or denial |
| `architecture-reviewer` | Layer boundary and interface compliance |
| `infrastructure-reviewer` | CI/CMake compliance |
| `postmortem-reviewer` | Session retrospective analysis |
| `amigo` | Three Amigos ceremony participant |
| `skill-reviewer` | Skill file quality audit |
| `summarization-quality` | Summary faithfulness evaluation |
| `synthesizer` | Multi-method summary synthesis |
| `claim-enrichment` | Analytical claim enrichment |

## How It Works

Installing this plugin adds:
- 26 skills to `.claude/skills/` -- invoked via the `Skill` tool or loaded on demand
- 14 agents to `.claude/agents/` -- dispatched via the `Agent` tool
- Two hooks: `SessionStart` (injects honesty and Iron Laws) and `UserPromptSubmit` (active per-turn enforcement)

Skills are loaded on demand, not injected at startup. The hooks enforce consistent communication standards across all sessions without loading all skill content at once.

## C++ Plugin

C++ and OpenGL-specific skills (`build`, `architecture-review`, `infrastructure-review`, `oop-principles`, `cpp-patterns`, `cpp-safety`, `flatpak`, `visual-regression-testing`) are published as a separate `story-to-ship-cpp` plugin. Install both for full C++ project coverage.

## License

MIT -- see [LICENSE](LICENSE)
