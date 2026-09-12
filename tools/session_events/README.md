# session-events converter

Reads a Claude Code session transcript (a JSON Lines file, one JSON object
per line) and writes an events JSON Lines file: one JSON object per event,
in transcript order. It exists so an agent template that audits a real
session has a compact, structured record of what happened in that session
instead of the raw transcript.

## Usage

```
python3 session_to_events.py TRANSCRIPT [--out PATH] [--max-text N]
```

- `TRANSCRIPT`: path to the transcript JSON Lines file (read as UTF-8).
- `--out PATH`: write events to this path. Without it, events go to stdout.
- `--max-text N`: maximum characters kept per text field. Defaults to 2000.

Each output line is one JSON object, written with the standard library
`json` module's default (ASCII-safe) encoding, so the output file is plain
ASCII even when the transcript contains non-ASCII text.

## Event schema

| event | fields |
|---|---|
| `user.message` | `ts`, `event`, `text` |
| `assistant.message` | `ts`, `event`, `model`, `text` |
| `skill.invoked` | `ts`, `event`, `skill` |
| `subagent.started` | `ts`, `event`, `tool_use_id`, `agent_type`, `model` |
| `subagent.completed` | `ts`, `event`, `tool_use_id`, `text` |

`ts` is the source record's top-level `timestamp`, or `null` when the
record has none.

## Conversion conventions

- A tool-result block in a user record is considered only when its
  tool_use_id matches an Agent tool_use already seen earlier in the
  conversion; tool results for every other tool produce no event.
- A tool-result block that acknowledges an asynchronous agent launch (its
  flattened text starts with "Async agent launched successfully") is
  skipped: it is not the agent's real result, just a launch acknowledgment.
- A task-notification user message (its content starts with
  `<task-notification>`) is converted to a `subagent.completed` event; this
  is where the real result of a backgrounded agent arrives.
- Thinking blocks, and hook-injected text blocks in a user record's content
  list, are skipped: they carry no event this schema tracks.
- A `<synthetic>` model string is kept verbatim rather than being treated
  as missing or normalized away.
- Text fields are truncated to a maximum length (2000 characters by
  default) so a single long message cannot dominate the output.

## Scope

This schema is the subset of events that the postmortem-reviewer agent
template's audit rows use, not that template's full event list. Some event
kinds the template can reference, such as tool-execution-start events and
session-start continuation events, are out of scope for this converter.

## Continuous integration

The unit tests for this tool run automatically in CI.
