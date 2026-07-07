# story-to-ship

SDLC governance for Claude Code -- behavioral constraints, evidence gates, and ceremony systems covering the developer loop from story through merged branch.

Existing skill packages automate SDLC tasks: generate changelogs, scaffold pipelines, write PR descriptions. This governs behavior: blocks forward progress without inline evidence, enforces ceremony gates before implementation, requires root-cause analysis before any fix.

**Scope:** Requirements, planning, implementation, testing, code review, CI/CD, documentation, retrospective. Does not cover deployment, monitoring, or security review.

## Install

```shell
/plugin marketplace add jpegthedev/story-to-ship
/plugin install story-to-ship@story-to-ship
```

## Skills by Phase

### Behavior (Always Active)
| Skill | Purpose |
|-------|---------|
| `honesty` | Evidence gate -- bans unverified completion claims, enforces inline verification |
| `verification-before-completion` | Hard stop before any "done" claim |

### Requirements and Discovery
| Skill | Purpose |
|-------|---------|
| `brainstorming` | Design gate -- required before committing to any approach |
| `three-amigos` | Acceptance criteria ceremony -- blocks implementation until criteria are clear |
| `greenfield-discovery` | Domain model interview for new projects -- blocks code decisions until the domain is documented |
| `user-story-generator` | INVEST-aligned story authoring |
| `user-story-estimation` | T-shirt sizing and effort estimation |

### Planning
| Skill | Purpose |
|-------|---------|
| `writing-plans` | Scope gate -- builds todo list before any code is written |

### Implementation
| Skill | Purpose |
|-------|---------|
| `execution` | Commitment and right-wrongs protocol for any non-trivial implementation |
| `code-quality` | Formatting, naming, and static analysis gates |
| `session-bootstrap` | Session initialization -- loads context and routing table |
| `subagent-driven-development` | Delegation protocol with mandatory post-todo review |
| `dispatching-parallel-agents` | Fan-out investigation across multiple files |
| `using-git-worktrees` | Parallel agent isolation via git worktrees |

### Testing and Verification
| Skill | Purpose |
|-------|---------|
| `testing` | TDD gate -- no production code without a failing test first |
| `contract-testing` | Interface and abstract base class test coverage |
| `systematic-debugging` | Root-cause protocol -- no patches without tracing to root |

### Code Review
| Skill | Purpose |
|-------|---------|
| `requesting-code-review` | PR preparation and review request protocol |
| `receiving-code-review` | Acting on feedback without rationalization |

### CI/CD and Release
| Skill | Purpose |
|-------|---------|
| `workflow` | GitHub Actions and CI configuration standards |
| `versioning` | Conventional commit enforcement, version bumps, PR protocol |
| `finishing-a-development-branch` | Branch-ready-to-merge checklist |

### Documentation and Knowledge
| Skill | Purpose |
|-------|---------|
| `documentation` | Creating and reviewing project documentation |
| `summarization` | Structured summarization of external resources |
| `writing-skills` | Skill file authoring standards |

### Retrospective
| Skill | Purpose |
|-------|---------|
| `session-postmortem` | Behavioral retrospective -- audits agent behavior for rationalization patterns |
| `self-evaluation` | Session close checklist |

### C++ and OpenGL
| Skill | Purpose |
|-------|---------|
| `build` | CMake build, dependency, and Flatpak packaging gates |
| `architecture-review` | Layer boundary compliance and class hierarchy review |
| `infrastructure-review` | CI/CMake/Flatpak manifest compliance review |
| `oop-principles` | Is-A/Has-A and SOLID gate before any class hierarchy change |
| `cpp-patterns` | GL resource management and public interface documentation patterns |
| `cpp-safety` | RAII and destructor safety for resource-owning classes |
| `flatpak` | Sandbox-aware Flatpak packaging and debugging |
| `visual-regression-testing` | Visual baseline management and render regression testing |

---

## Agents

| Agent | Role |
|-------|------|
| `implementer` | Feature implementation in a git worktree |
| `skeptic` | Plan gap analysis before implementation begins |
| `spec-compliance-reviewer` | Stage 1 post-todo review: spec compliance |
| `code-quality-reviewer` | Stage 2 post-todo review: code quality |
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
- 35 skills to `.claude/skills/` -- invoked via the `Skill` tool or loaded on demand
- 14 agents to `.claude/agents/` -- dispatched via the `Agent` tool
- Two hooks: `SessionStart` (injects the Honesty Gate and Iron Laws at every startup) and `UserPromptSubmit` (active per-turn enforcement)

Skills load on demand. The hooks enforce behavioral standards across all sessions without injecting all skill content at startup. The Iron Laws -- TDD gate, evidence gate, root-cause gate, ceremony gates -- are always active.

## Repository Layout

- **Source of truth:** the root `skills/`, `agents/`, and `hooks/` directories are canonical. Edit these.
- **Self-hosted dogfooding:** `.claude/` wires this repo to run on its own framework. `.claude/skills` is a symlink to `../skills` and `.claude/agents` is a symlink to `../agents`. `.claude/hooks/` contains per-file symlinks -- both the `.md` docs and the `.sh` scripts point to `../../hooks/*`. There are no real files inside `.claude/hooks/`.
- **Plugin distribution:** `.claude-plugin/` packages the framework for the Claude Code plugin marketplace. Consumers who install the plugin get their own `.claude/` wiring and never see this repo's symlink internals.

Dual-wiring hazard: editing a skill while this repo is itself installed as a plugin writes into `~/.claude/plugins/cache/...`, a frozen snapshot outside this git repo that is not reflected in the source files. Contributors must edit this repo's files directly, not the plugin cache.

See CONTRIBUTING.md for how to add a skill and the CI gates.

## C++ and OpenGL

C++ and OpenGL-specific skills (`build`, `architecture-review`, `infrastructure-review`, `oop-principles`, `cpp-patterns`, `cpp-safety`, `flatpak`, `visual-regression-testing`) are bundled in this plugin. No separate install required.

## License

MIT -- see [LICENSE](LICENSE)
