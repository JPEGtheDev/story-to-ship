# On Start — Skill Dispatch Table

| If the task involves…                        | MUST read these skills BEFORE acting               |
|----------------------------------------------|----------------------------------------------------|
| Any implementation work                      | `execution`                                        |
| Planning a multi-step task                   | `writing-plans`                                    |
| Any new plan with 2+ todos or an architectural decision | `writing-plans`; if `## Feature Specification` present in plan.md: dispatch `three-amigos` Refinement; otherwise dispatch Skeptic, before first implementation step |
| Unclear approach or design choices           | `brainstorming`                                    |
| Writing or editing code                      | `execution`, `code-quality`                        |
| Writing code with rendering/runtime patterns | `execution`, `code-quality`, `cpp-patterns`        |
| Writing or editing tests                     | `execution`, `code-quality`, `testing`             |
| Writing visual regression tests              | `execution`, `code-quality`, `testing`, `visual-regression-testing` |
| Creating a PR or commit                      | `versioning`, `verification-before-completion`     |
| Finishing / closing a branch                 | `finishing-a-development-branch`                   |
| Requesting code review                       | `requesting-code-review`                           |
| Receiving code review feedback               | `receiving-code-review`                            |
| CI/CD or workflow changes                    | `workflow`                                         |
| Flatpak packaging or GL runtime              | `flatpak`                                          |
| Build system or dependency changes           | `build`                                            |
| Writing or editing documentation             | `documentation`                                    |
| Bug fixes or error resolution                | `execution`, `systematic-debugging`                |
| Any failure or unexpected behavior           | `systematic-debugging`, `verification-before-completion` |
| Dispatching subagents                        | `subagent-driven-development`                      |
| Parallel agent work / A/B testing            | `subagent-driven-development`, `using-git-worktrees` |
| Creating user stories                        | `user-story-generator`, `user-story-estimation`    |
| Creating or editing a skill file             | `writing-skills`, `skill-reviewer`                 |
| Resuming from a prior session with pending SQL todos | `writing-plans`; if `## Feature Specification` present in plan.md: dispatch `three-amigos` Refinement; otherwise dispatch Skeptic, before first implementation step |
| Schema design, new data structure, or plan with ≥5 implementation items | `brainstorming`, `writing-plans` |
| Auditing communication quality or postmortem | `honesty`, `session-postmortem`                    |
| Auditing or reorganizing a collection of files, tasks, or artifacts with multiple valid structural approaches | `brainstorming`, `writing-plans` |
| Summarizing external resources (articles, web pages, files) for knowledge extraction | `summarization` |
