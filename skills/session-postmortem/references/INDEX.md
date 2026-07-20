---
title: "session-postmortem References Index"
description: Index of session-postmortem reference files covering postmortem report structure and verdicts, multi-session batch analysis commands, Claude Code session-log format, and the recurring-defect registry.
domain: skills
subdomain: session-postmortem
tags: [skills, session-postmortem, references, index]
related:
  - "../SKILL.md"
---

# session-postmortem References Index

Reference files supporting the `session-postmortem` skill; load the one relevant to the task at hand rather than the whole set.

| File | Covers |
|------|--------|
| `AGENT_LOGS.md` | Claude Code session transcript and memory file locations, and how to use the JSONL transcript to reconstruct tool calls and rationalization patterns during a postmortem. |
| `BATCH_ANALYSIS.md` | Commands to list unreviewed Claude Code sessions, and the priority order and parallel-dispatch pattern for running postmortems across a batch. |
| `POSTMORTEM_STRUCTURE.md` | The canonical report template, verdict definitions, blameless-language rules, external reviewer protocol, and the 5-part postmortem structure (Timeline through Action Items) with the Iron Law Compliance Check. |
| `RECURRING_DEFECTS.md` | Catalog of 46 recurring agent-behavior defects mined from user corrections, each mapped to its remedy. |

## Related

- [SKILL.md](../SKILL.md) -- the parent skill; load it first for the Iron Law, Red Flags, and the order these references are used in.
