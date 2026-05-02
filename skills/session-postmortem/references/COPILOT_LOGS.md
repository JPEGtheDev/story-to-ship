# Copilot Session Logs — Reference

## Log File Locations

Copilot chat session logs are stored at:

```
~/.config/github-copilot/hosts.json       # auth/account info
~/.config/github-copilot/apps.json        # app registrations
~/.local/share/ghcopilot/logs/            # GitHub CLI extension logs (if using gh copilot)
```

Session state (checkpoints, persistent files) lives at:

```
~/.copilot/session-state/<session-id>/
  checkpoints/        # Checkpoint summaries (index.md has the full list)
  files/              # Persistent session artifacts (research, breakdowns, preferences)
```

## Using Logs in a Postmortem

When running `session-postmortem`, the agent can parse:
- `checkpoints/index.md` → list of checkpoints with titles and timestamps
- Individual checkpoint files → what was accomplished, what was committed, what was left unfinished
- `files/` contents → research corpus, task breakdowns, prior analysis

## Future Work

**Pending task:** Build a script in `scripts/` to parse copilot session history into
structured postmortem input. This would feed the `session-postmortem` skill with
actual agent turn data rather than reconstructed timelines. Output format should be:

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

This enables the session-postmortem agent to analyze actual behavior rather than
working from summaries that may omit subtle rationalization patterns.
