---
max_turns: 8
allowed_tools: [Read, Glob, Grep, Edit, Skill]
description: Tests the plugin at session start (the hook text plus the session-bootstrap skill). A session in this repo loads session-bootstrap as its first tool call, before any task skill and before any code is written.
tags: [session-hooks]
---

Fix the one-word typo in README.md in this repo.
