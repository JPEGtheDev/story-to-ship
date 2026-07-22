# Batch Analysis

To run postmortems on older sessions that were never reviewed:

**Claude Code sessions:**
```bash
# List all Claude Code sessions for this project
# Path: ~/.claude/projects/<encoded-project-path>/
# Encoded path = absolute path with / replaced by -
ls ~/.claude/projects/<encoded-project-path>/*.jsonl 2>/dev/null
```

See `references/AGENT_LOGS.md` for Claude Code session log structure.

Dispatch up to 4 reviewer subagents in parallel, each pointed at a different session. Use `postmortem-reviewer.md` for each. Collect results as they complete.

**Priority:**
1. Sessions with a `postmortem.md` in the session directory but no external review -- direct comparison (highest value)
2. Sessions with `plan.md` but no postmortem -- structured work, no retrospective
3. Sessions with only checkpoints -- lower priority

**Batch patterns:** 2+ sessions with the same failure = STRONG action item. Single-session = note only; confirm before acting.
