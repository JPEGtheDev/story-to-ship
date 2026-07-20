---
title: "session-postmortem References Index"
description: Index of session-postmortem reference files covering postmortem report structure and verdicts, multi-session batch analysis commands, Claude Code and Copilot session-log formats, Particle-Viewer session path conventions, and the recurring-defect registry.
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
| [AGENT_LOGS.md](AGENT_LOGS.md) | Claude Code session transcript and memory file locations, and how to use the JSONL transcript to reconstruct tool calls and rationalization patterns during a postmortem. |
| [BATCH_ANALYSIS.md](BATCH_ANALYSIS.md) | Commands to list unreviewed Claude Code and legacy GitHub Copilot sessions, and the priority order and parallel-dispatch pattern for running postmortems across a batch. |
| [COPILOT_LOGS.md](COPILOT_LOGS.md) | GitHub Copilot session log and checkpoint file locations, and how to parse checkpoint/file artifacts into postmortem input. |
| [POSTMORTEM_STRUCTURE.md](POSTMORTEM_STRUCTURE.md) | The canonical report template, verdict definitions, blameless-language rules, external reviewer protocol, and the 5-part postmortem structure (Timeline through Action Items) with the Iron Law Compliance Check. |
| [PV_SESSION_PATHS.md](PV_SESSION_PATHS.md) | Path conventions for locating Particle-Viewer Claude Code and legacy Copilot session directories, event logs, and scratch artifacts. |
| [RECURRING_DEFECTS.md](RECURRING_DEFECTS.md) | Catalog of 46 recurring agent-behavior defects mined from user corrections, each mapped to its remedy. |

## Related

- [SKILL.md](../SKILL.md) -- the parent skill; load it first for the Iron Law, Red Flags, and the order these references are used in.
