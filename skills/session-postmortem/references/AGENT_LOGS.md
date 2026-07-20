# Claude Code Session Logs -- Reference

## Log File Locations

Claude Code session transcripts (full turn-by-turn JSON Lines (JSONL)) are stored at:

```
~/.claude/projects/<encoded-project-path>/<session-id>.jsonl
```

The encoded path is the absolute project path with `/` replaced by `-`.
Example: `/path/to/MyProject` -> `-path-to-MyProject`

Project memories (persistent facts written by the agent) live at:

```
~/.claude/projects/<encoded-project-path>/memory/
  MEMORY.md          # Index of all memories
  <slug>.md          # Individual memory files
```

## Scratch Artifacts

Sessions often write intermediate work (analysis, theory-testing files, research dumps) to a
gitignored scratch or session directory. These artifacts are not part of the committed repo and
may contain evidence of exploratory work not captured in the event log -- check them when
reconstructing what the agent actually tried.

## Using Logs in a Postmortem

When running `session-postmortem`, the agent can read the full JSONL transcript to reconstruct:
- Every tool call made (and whether it succeeded or was denied by the user)
- Iron Law check points (checklist items in AGENTS.md before every response)
- Actual decision sequence vs. stated rationale
- Rationalization patterns (gaps between what the model said it would do and what it did)

The session summary provided in a new session's context block references the JSONL path:
```
read the full transcript at: ~/.claude/projects/.../session-id.jsonl
```

## Future Work

**Pending task:** Build a script in `scripts/` to parse Claude Code session JSONL into
structured postmortem input for the `session-postmortem` skill. Output format:

```json
{
  "session_id": "...",
  "turns": [
    { "role": "user", "content": "..." },
    { "role": "assistant", "content": "...", "tools_used": [...] }
  ],
  "iron_law_violations": [],
  "rationalization_patterns": []
}
```
