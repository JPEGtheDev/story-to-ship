---
max_turns: 8
allowed_tools: [Agent, Read, Glob, Grep, Skill]
description: Runner direction when a rule lives in two files and the todo edits only one. The dispatch must name the second file and say to align it.
---

You are the story runner for this repo. Read plan.md in this directory: it holds the todo. Dispatch one implementer with the Agent tool for Todo 1. Do not edit files yourself. Then reply in one line saying what you dispatched.
