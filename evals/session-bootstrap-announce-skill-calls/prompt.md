---
max_turns: 16
allowed_tools: [Read, Glob, Grep, Edit, Skill]
description: Tests the rule that every Skill call is announced in the same turn with the sentence "I am using the <skill> skill to <purpose>." The task is a small README.md edit.
tags: [session-hooks]
---

README.md in this repo has no usage section. Add a "## Usage" section at the end that shows the command `python3 src/app.py receipts.csv`.
