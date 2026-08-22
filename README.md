# story-to-ship

SDLC (Software Development Life Cycle) governance for Claude Code -- behavioral constraints, evidence gates, and ceremony systems covering the developer loop from story through merged branch.

Existing skill packages automate SDLC tasks: generate changelogs, scaffold pipelines, write PR descriptions. This governs behavior: blocks forward progress without inline evidence, enforces ceremony gates before implementation, requires root-cause analysis before any fix.

**Scope:** Requirements, planning, implementation, testing, code review, CI/CD (Continuous Delivery), documentation, retrospective. Does not cover deployment, monitoring, or security review.

## Table of Contents

- [Install](#install)
- [Skills by Phase](#skills-by-phase)
- [Agents](#agents)
- [How It Works](#how-it-works)
- [Repository Layout](#repository-layout)
- [C++ and OpenGL](#c-and-opengl)
- [License](#license)

## Install

### Claude Code

```shell
/plugin marketplace add jpegthedev/story-to-ship
/plugin install story-to-ship@story-to-ship
```

### OpenCode

```shell
opencode plugin https://github.com/jpgthedev/story-to-ship
```

or add to your project's `opencode.json`:

```json
{
  "plugin": ["https://github.com/jpgthedev/story-to-ship"]
}
```

OpenCode resolves the `opencode.json` manifest at the repository root and loads `index.js`. The same 33 skills and 16 agents ship as `Skill` tool definitions (via `skill()`), so every gate works identically in both runtimes. The hook-enforced enforcement (Iron Laws injection, bootstrap gate) is Claude Code only; in OpenCode the skills' own hard-stop language carries the enforcement.

## Skills by Phase

### Behavior (Always Active)
| Skill | Purpose |
|-------|---------|
| `honesty` | Evidence gate -- bans unverified completion claims, enforces inline verification |
| `communication` | Plain-language gate -- defines jargon in user-facing text, treats hedged agreement as unclear writing not approval, keeps reasoning terse, requires evidence before conceding to a correction, and keeps public PR/issue review comments factual and neutral in tone |
| `verification-before-completion` | Hard stop before any "done" claim |

### Requirements and Discovery
| Skill | Purpose |
|-------|---------|
| `brainstorming` | Design gate -- required before committing to any approach |
| `three-amigos` | Acceptance criteria ceremony -- blocks implementation until criteria are clear |
| `greenfield-discovery` | Domain model interview for new projects -- blocks code decisions until the domain is documented |
| `user-story-generator` | INVEST (Independent, Negotiable, Valuable, Estimable, Small, Testable)-aligned story authoring |
| `user-story-estimation` | T-shirt sizing and effort estimation |

### Planning
| Skill | Purpose |
|-------|---------|
| `writing-plans` | Scope gate -- builds todo list before any code is written |

### Implementation
| Skill | Purpose |
|-------|---------|
| `execution` | Commitment and right-wrongs protocol (acknowledge the mistake, state what was wrong and the correct answer, state its impact, and fix it without minimizing) for any non-trivial implementation |
| `code-quality` | Formatting, naming, and static analysis gates |
| `session-bootstrap` | Session initialization -- loads context and routing table |
| `subagent-driven-development` | Delegation protocol with mandatory post-todo review |
| `dispatching-parallel-agents` | Fan-out investigation across multiple files |
| `using-git-worktrees` | Parallel agent isolation via git worktrees |

### Testing and Verification
| Skill | Purpose |
|-------|---------|
| `testing` | TDD (Test-Driven Development) gate -- no production code without a failing test first |
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
| `architecture-review` | Layer boundary compliance and class hierarchy review |
| `infrastructure-review` | CI, build configuration, and packaging manifest compliance review |
| `oop-principles` | Is-A/Has-A (inheritance vs. composition) and SOLID (Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion) gate before any class hierarchy change |
| `cpp-patterns` | GL resource management and public interface documentation patterns |
| `cpp-safety` | RAII (Resource Acquisition Is Initialization) and destructor safety for resource-owning classes |
| `visual-regression-testing` | Visual baseline management and render regression testing |

---

## Agents

| Agent | Role |
|-------|------|
| `implementer` | Feature implementation in a git worktree |
| `skeptic` | Plan gap analysis before implementation begins |
| `plan-reviewer` | Plan soundness, sequencing, and enforceability review (paired with the Skeptic) |
| `spec-compliance-reviewer` | Stage 1 post-todo review: spec compliance |
| `code-quality-reviewer` | Stage 2 post-todo review: code quality |
| `explorer` | Read-only multi-file research |
| `researcher` | Hypothesis confirmation or denial |
| `architecture-reviewer` | Architecture and design principle compliance review |
| `infrastructure-reviewer` | CI/build/packaging compliance |
| `postmortem-reviewer` | Session retrospective analysis |
| `amigo` | Three Amigos ceremony participant |
| `skill-reviewer` | Skill file quality audit |
| `summarization-method` | One of three parallel summarization methods (Abstractive, Extractive, or SAAC) |
| `summarization-quality` | Summary faithfulness evaluation |
| `synthesizer` | Multi-method summary synthesis |
| `claim-enrichment` | Analytical claim enrichment |

## How It Works

Installing this plugin adds:
- 35 skills to `.claude/skills/` (Claude Code) or as `Skill` tool definitions (OpenCode) -- invoked via the `Skill` tool or loaded on demand
- 16 agents to `.claude/agents/` (Claude Code only; OpenCode has no agent-dispatch tool in the plugin API yet)
- Hooks from `hooks/hooks.json` (the shipped plugin wiring), registering four events: `SessionStart` (injects the Honesty Gate and Iron Laws at every startup), `UserPromptSubmit` (active per-turn enforcement), and `PreToolUse`/`PostToolUse` (bootstrap-gate and workflow-model-guard checks)

Skills load on demand. The hooks enforce behavioral standards across all sessions without injecting all skill content at startup. The Iron Laws -- TDD gate, evidence gate, root-cause gate, ceremony gates -- are always active. This repo's own dogfood config, `.claude/settings.json`, additionally registers a `Stop` hook that logs each turn.

### OpenCode adapter

The repository doubles as an OpenCode plugin. `opencode.json` at the root declares the package (name, version, and a `runtime` field that satisfies OpenCode's `runtime`-or-`main` validation). `index.js` loads every `skills/<name>/SKILL.md`, strips the YAML frontmatter, and registers each as an OpenCode `skill()` tool whose description and instructions are sourced from the same files Claude Code uses, so both runtimes share one skill corpus. Claude-specific paths (`.claude/...`) in skill bodies are rewritten to OpenCode paths (`.opencode/...`) at load time. The `hooks/` system is not available in the OpenCode plugin API, so hook-only enforcement is Claude Code only.

## Repository Layout

- **Source of truth:** the root `skills/`, `agents/`, and `hooks/` directories are canonical. Edit these.
- **Self-hosted dogfooding:** `.claude/` wires this repo to run on its own framework. `.claude/skills` is a symlink to `../skills` and `.claude/agents` is a symlink to `../agents`. `.claude/hooks/` contains per-file symlinks -- both the `.md` docs and the `.sh` scripts point to `../../hooks/*`. There are no real files inside `.claude/hooks/`.
- **Plugin distribution:** `.claude-plugin/` packages the framework for the Claude Code plugin marketplace. Consumers who install the plugin get their own `.claude/` wiring and never see this repo's symlink internals.

Dual-wiring hazard: editing a skill while this repo is itself installed as a plugin writes into `~/.claude/plugins/cache/...`, a frozen snapshot outside this git repo that is not reflected in the source files. Contributors must edit this repo's files directly, not the plugin cache.

See CONTRIBUTING.md for how to add a skill and the CI gates.

## C++ and OpenGL

C++ and OpenGL-specific skills (`architecture-review`, `infrastructure-review`, `oop-principles`, `cpp-patterns`, `cpp-safety`, `visual-regression-testing`) are bundled in this plugin. No separate install required.

## License

MIT -- see [LICENSE](LICENSE)
