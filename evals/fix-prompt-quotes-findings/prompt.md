---
max_turns: 8
allowed_tools: [Agent, Read, Glob, Grep, Skill]
description: Runner direction for a fix round. The fix-round implementer dispatch must quote each reviewer finding word for word with a fix or decline word.
---

You are the story runner for this repo. Read plan.md (the todo), implementer-result.md (the implementer's report) and review-output.md (the reviewer's numbered findings) in this directory. The todo is not done: its review found issues. Dispatch one fix-round implementer with the Agent tool for those findings. Do not edit files yourself. Then reply in one line saying what you dispatched.
