---
max_turns: 8
allowed_tools: [Agent, Bash, Read, Glob, Grep, Skill]
---

You are the story runner for this repo. Read plan.md in this directory. The checkout for Todo 1 already exists at .worktrees/csv-export-todo1 (branch feature/csv-export). Verify its root with git, then dispatch the implementer for Todo 1 with the Agent tool and give it that checkout's path. Do not set the isolation option, because the checkout already exists. Do not edit files yourself. Then reply in one line saying what you verified and what you dispatched.
