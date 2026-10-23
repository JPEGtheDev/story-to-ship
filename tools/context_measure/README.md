# context_measure

Shows what fills the main thread of a Claude Code session, by source, from one
transcript. A transcript is the JSON Lines file (one JSON object per line) that
Claude Code writes for a session. The tool reads it and reports how many
characters each source contributed, per turn. It can also report a behaviour
baseline: banned phrases, Skill calls and a reload check after each compaction.

The tool is read-only. It does not change the transcript.

## Usage

```
python3 tools/context_measure/context_measure.py TRANSCRIPT [--top N] [--json] [--behaviour]
```

- `TRANSCRIPT`: path to one transcript file.
- `--top N`: how many turns to list by size. Default 5. Must be a positive integer.
- `--json`: print the full measurement as one JSON object instead of the text report.
- `--behaviour`: add the behaviour baseline (see below). With `--json`, it is added under the key `behaviour`.

Exit codes:

- `0`: the report was written.
- `2`: an error. The message is written to stderr. Errors are: the path is not an
  existing regular file; the file is empty; the file cannot be read; no line of the
  file is a JSON object. Bad command-line arguments also exit with `2`.

Lines that are not JSON objects are skipped and counted as "Malformed lines" in the
report. They do not stop the run.

The text report has four parts: the record and turn counts, a table of characters
by source with a percentage of the grand total, a table of tool-result characters
by tool, and the largest turns with their top three sources.

## Turns

A turn starts at a human prompt. Turn 0 holds everything before the first human
prompt, such as the session-start hook text. Turn N starts at the Nth human prompt.

A launcher session that is driven by sub-agent hand-backs has few turns, because
the hand-backs are not human prompts. Read the totals first, then the turn list.

## Sources

Each source is one bucket in the report.

- `hook_session_start`: text injected by SessionStart hooks (the `content` strings of `hook_additional_context` attachments).
- `hook_user_prompt`: text injected by UserPromptSubmit hooks (same record type).
- `hook_other`: text injected by any other hook event, or by a hook with no event name.
- `other_harness`: meta user records that are not skill bodies, and other attachment records. A record with a `rendered` list counts the rendered text; without one, the string values of the attachment count, except for the metadata-only subtypes listed below.
- `tool_results`: the content of each tool result, by tool name. A result whose tool use cannot be matched counts under `unknown_tool`.
- `handbacks`: sub-agent hand-backs, from peer-origin user records and peer-origin queued-command attachments. Each hand-back counts once; see the counting rules.
- `notifications`: task-notification user records (background-task completions).
- `assistant_text`: text blocks of assistant messages.
- `assistant_thinking`: thinking blocks of assistant messages (see the blind spots).
- `assistant_tool_use_input`: the JSON length of each tool-use input.
- `user_text`: the text of each human prompt.
- `skill_bodies`: meta user records whose text starts with "Base directory for this skill", that is, a loaded skill body.
- `compaction_summary`: the summary record written at a compaction.

The metadata-only attachment subtypes are `hook_success`, `prompt_snapshot`,
`command_permissions`, `deferred_tools_record` and `thinking_drop`. They count 0
unless the record carries a `rendered` list.

## Counting rules

- Units are characters, not tokens. The tool does not run a tokenizer.
- Sub-agent records (`isSidechain` true) are excluded from every count.
- Assistant blocks are counted once per (message id, block content). A block that is
  written again under the same message id is not counted twice.
- User and attachment records are counted once per `uuid`.
- A hand-back can arrive in two forms: a peer-origin user record, or a peer-origin
  queued-command attachment. It is counted once per (sender, hash of the body). The
  sender is the text between `from="` and the next quote. The body is the text after
  the `[Subagent hand-back]` marker, or the whole text when the marker is missing.
  The characters counted are those of the first arrival.

## Behaviour baseline

`--behaviour` reads the main thread only (sub-agent records excluded).

- Banned phrases. The list is a fixed constant in the module. The first six phrases come
  from the honesty skill; the rest come from the communication skill. Matching is
  case-insensitive,
  a straight or curly apostrophe matches, and a hit must not touch a letter or digit
  on either side. Fenced code blocks are removed before matching.
- Rate. Banned hits per 10 000 characters of assistant text (text blocks only).
- Skill calls. The number of Skill tool calls, and the top three skills by count.
- Reload check. Each compaction boundary starts a check. The check scans the following
  assistant tool calls until the first Edit, Write, NotebookEdit or Agent call, or the
  end of the transcript. It records whether the honesty and communication skills were
  invoked before that point. The report prints `first_gated_tool` for each check.
- Reload miss. A check where the honesty skill or the communication skill was not
  invoked before the first gated tool call (or before the end of the transcript).

## Blind spots

- A banned phrase quoted outside a fenced code block is counted. The tool cannot tell a quotation from a use.
- Thinking text is stored empty in the transcripts seen so far, so `assistant_thinking` reads 0 there.
- Only the compaction reload trigger is checked. The "new todo" and "after a correction" triggers cannot be detected from a transcript.
- Two sessions are an anecdote, not a statistic. Do not draw a rate from them.

## Tests

From the repository root:

```
python3 -m unittest discover -s tools/context_measure -p 'test_*.py'
```
