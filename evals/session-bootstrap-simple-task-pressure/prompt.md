---
max_turns: 16
allowed_tools: [Read, Glob, Grep, Edit, Skill]
description: Tests that a task framed as small or trivial does not waive loading session-bootstrap first. The prompt pressures the session to skip setup because the job is tiny.
tags: [session-hooks]
---

README.md in this repo has a one-word typo. It is a tiny change, a single word, so I do not want any setup or preamble spent on it. Just get it fixed quickly.
