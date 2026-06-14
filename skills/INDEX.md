# Skills Index

One entry per skill. Load via the session-bootstrap "On Start" table before acting on any task.

---

## Core Workflow

- [session-bootstrap](session-bootstrap/SKILL.md) -- Use when opening a new conversation to load required skills, identify task type, and restore session context before acting.
- [execution](execution/SKILL.md) -- Use when executing any non-trivial implementation work.
- [honesty](honesty/SKILL.md) -- Use when communication quality or trust is in question. Always active -- applies to every session, every turn, every task.
- [verification-before-completion](verification-before-completion/SKILL.md) -- Use when about to claim work is complete, fixed, or passing, before any completion claim, commit, or PR.
- [self-evaluation](self-evaluation/SKILL.md) -- Use when completing any session.

---

## Planning and Design

- [writing-plans](writing-plans/SKILL.md) -- Use when starting any multi-step task, story, or feature work.
- [brainstorming](brainstorming/SKILL.md) -- Use when a task needs design exploration before any implementation begins. Required for any task with unclear approach, significant architecture impact, or multiple valid solutions.
- [three-amigos](three-amigos/SKILL.md) -- Use when a feature has new or unclear acceptance criteria, a plan has 2+ todos and Discovery ran, or an implementer signals BLOCKED or DONE_WITH_CONCERNS.
- [user-story-generator](user-story-generator/SKILL.md) -- Use when creating or refining INVEST-aligned user stories.
- [user-story-estimation](user-story-estimation/SKILL.md) -- Use when estimating effort for user stories or implementation tasks.

---

## Code Quality and Review

- [code-quality](code-quality/SKILL.md) -- Use when writing or reviewing code in any paradigm.
- [testing](testing/SKILL.md) -- Use when writing or reviewing any test.
- [contract-testing](contract-testing/SKILL.md) -- Use when writing tests for any interface, abstract base class, or type with multiple implementations.
- [visual-regression-testing](visual-regression-testing/SKILL.md) -- Use when writing or maintaining visual regression tests, approving visual baselines, or deciding whether something belongs in a VR test vs a MockOpenGL unit test.
- [systematic-debugging](systematic-debugging/SKILL.md) -- Use when encountering any bug, test failure, build error, or unexpected behavior.
- [receiving-code-review](receiving-code-review/SKILL.md) -- Use when receiving code review feedback on a PR or code change.
- [requesting-code-review](requesting-code-review/SKILL.md) -- Use when preparing to request a code review on a PR or change.
- [verification-before-completion](verification-before-completion/SKILL.md) -- Use when about to claim work is complete, fixed, or passing, before any completion claim, commit, or PR.

---

## Subagent Workflow

- [subagent-driven-development](subagent-driven-development/SKILL.md) -- Use when delegating implementation tasks, confirming theories, running parallel research, or reviewing completed work.
- [using-git-worktrees](using-git-worktrees/SKILL.md) -- Use when running parallel agent work, testing an approach in isolation, or keeping the main branch clean while a subagent operates on a separate branch.
- [dispatching-parallel-agents](dispatching-parallel-agents/SKILL.md) -- Use when multiple independent read-only research tasks can run simultaneously, or when you need to fan out investigation across many files or hypotheses.

---

## Skill Authoring

- [writing-skills](writing-skills/SKILL.md) -- Use when creating, editing, or reviewing a skill file.
- [session-postmortem](session-postmortem/SKILL.md) -- Use when a completed session needs behavioral retrospective analysis.

---

## C++ / Particle-Viewer Specific

- [cpp-patterns](cpp-patterns/SKILL.md) -- Use when implementing C++ code for Particle-Viewer, handling GL resources, working with SDL3, or applying DRY/deprecation/docs-commit patterns.
- [cpp-safety](cpp-safety/SKILL.md) -- Use when writing or reviewing any C++ class that owns resources, has a destructor, or acquires in a constructor.
- [oop-principles](oop-principles/SKILL.md) -- Use when adding inheritance, designing interfaces, or reviewing any class hierarchy for Particle-Viewer.
- [architecture-review](architecture-review/SKILL.md) -- Use when adding new classes, refactoring code, or reviewing PRs for Particle-Viewer.
- [infrastructure-review](infrastructure-review/SKILL.md) -- Use when adding workflows, modifying CMakeLists.txt, or updating Flatpak manifests for Particle-Viewer.
- [build](build/SKILL.md) -- Use when building, adding dependencies, configuring CMake options, troubleshooting build failures, or managing Flatpak packaging for Particle-Viewer.
- [flatpak](flatpak/SKILL.md) -- Use when packaging, running, or debugging a Flatpak application with OpenGL and SDL3.

---

## Documentation and Versioning

- [documentation](documentation/SKILL.md) -- Use when creating docs, updating guides, writing API references, or reviewing documentation.
- [versioning](versioning/SKILL.md) -- Use when creating PRs, writing commit messages, understanding version bumps, or troubleshooting release issues.
- [workflow](workflow/SKILL.md) -- Use when creating GitHub Actions workflows, adding CI jobs, configuring artifact uploads, or reviewing pipeline configuration.
- [finishing-a-development-branch](finishing-a-development-branch/SKILL.md) -- Use when a development branch is complete and ready to merge.

---

## Greenfield Workflow

- [greenfield-discovery](greenfield-discovery/SKILL.md) -- Use when the user describes a new project to build from scratch and no `## Domain Model` block yet exists in the conversation.

---

## Knowledge Extraction

- [summarization](summarization/SKILL.md) -- Use when summarizing external resources (articles, web pages, local files) to extract knowledge and lessons.
