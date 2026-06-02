# story-to-ship

A Claude Code plugin marketplace providing professional software development skills and agents. Drop the entire system into any project with two commands.

## Install

```shell
/plugin marketplace add jpegthedev/story-to-ship
/plugin install story-to-ship@story-to-ship
```

## What's Included

### Core Process Skills
| Skill | When to use |
|-------|-------------|
| `honesty` | Communication quality and trust enforcement -- always active |
| `execution` | Any non-trivial implementation work |
| `verification-before-completion` | Before claiming work is done |
| `systematic-debugging` | Any bug, failure, or unexpected behavior |

### Planning Skills
| Skill | When to use |
|-------|-------------|
| `writing-plans` | Multi-step tasks and feature work |
| `brainstorming` | Unclear approach or design decisions |
| `three-amigos` | Unclear acceptance criteria, ceremony facilitation |
| `user-story-generator` | Creating INVEST-aligned user stories |
| `user-story-estimation` | Estimating effort and token budgets |

### Development Workflow Skills
| Skill | When to use |
|-------|-------------|
| `session-bootstrap` | Starting any new session |
| `self-evaluation` | Completing a session |
| `session-postmortem` | Behavioral retrospective on completed sessions |
| `finishing-a-development-branch` | Branch ready to merge |

### Code Quality Skills
| Skill | When to use |
|-------|-------------|
| `code-quality` | Writing or reviewing code |
| `testing` | Writing or reviewing any test |
| `contract-testing` | Testing interfaces or abstract base classes |

### Collaboration Skills
| Skill | When to use |
|-------|-------------|
| `subagent-driven-development` | Delegating tasks, parallel research, reviewing work |
| `dispatching-parallel-agents` | Fan-out investigation across multiple files |
| `using-git-worktrees` | Parallel agent work in isolation |

### Review Skills
| Skill | When to use |
|-------|-------------|
| `requesting-code-review` | Preparing a PR for review |
| `receiving-code-review` | Acting on review feedback |

### Documentation and Knowledge Skills
| Skill | When to use |
|-------|-------------|
| `documentation` | Creating or reviewing docs |
| `writing-skills` | Authoring or editing skill files |
| `summarization` | Summarizing external resources |

### CI/CD and Release Skills
| Skill | When to use |
|-------|-------------|
| `workflow` | GitHub Actions workflows and CI configuration |
| `versioning` | Commits, PRs, version bumps |

### C++ Skills (cpp plugin -- coming soon)
`build`, `architecture-review`, `infrastructure-review`, `oop-principles`, `cpp-patterns`, `cpp-safety`, `flatpak`, `visual-regression-testing`

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
- 34 skills to `.claude/skills/` -- invoked via the `Skill` tool or loaded on demand
- 14 agents to `.claude/agents/` -- dispatched via the `Agent` tool
- Two hooks: `SessionStart` (injects honesty and Iron Laws) and `UserPromptSubmit` (active per-turn enforcement)

Skills are loaded on demand, not injected at startup. The hooks enforce consistent communication standards across all sessions without loading all skill content at once.

## C++ Plugin (coming soon)

C++ and OpenGL-specific skills will be published as a separate `story-to-ship-cpp` plugin. Install both for full C++ project coverage.

## License

MIT -- see [LICENSE](LICENSE)
