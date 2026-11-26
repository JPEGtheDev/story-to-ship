---
max_turns: 16
allowed_tools: [Read, Glob, Grep, Edit, Skill]
description: Tests that honesty and communication are each loaded exactly once per session, with no repeat load across the several small steps of one request.
tags: [session-hooks]
---

Three small additions to README.md in this repo, each as its own separate one-line edit. First, add a line under the title saying the tool runs on Python 3. Second, add a line saying receipts are read from the receipts/ folder. Third, add a line saying totals print to the terminal.
