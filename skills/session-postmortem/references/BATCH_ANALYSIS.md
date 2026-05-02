# Batch Analysis

To run postmortems on older sessions that were never reviewed:

```bash
# List all sessions, find those without an external postmortem
for dir in ~/.copilot/session-state/*/; do
  session_id=$(basename "$dir")
  if [ ! -f "$dir/postmortem-external.md" ] && [ -f "$dir/events.jsonl" ]; then
    echo "$session_id"
  fi
done
```

Dispatch up to 4 reviewer subagents in parallel, each pointed at a different `events.jsonl`. Use `postmortem-reviewer.md` for each. Collect results as they complete.

**Priority:**
1. Sessions with `postmortem.md` but no external review — direct comparison (highest value)
2. Sessions with `plan.md` but no postmortem — structured work, no retrospective
3. Sessions with only checkpoints — lower priority

**Batch patterns:** 2+ sessions with the same failure = STRONG action item. Single-session = note only; confirm before acting.
