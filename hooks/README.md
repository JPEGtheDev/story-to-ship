# Hooks

Hook scripts and the text they inject into Claude Code sessions. This README documents the directory; it is never injected.

`session-start.sh` inspects the SessionStart `source` on stdin and, on `compact`/`resume`, prepends a continuation re-grounding banner before its paired `session-start.md`.

## Files

| File | Event | Injected |
|------|-------|----------|
| `session-start.sh` + `session-start.md` | SessionStart | Once per session |
| `pre-message-gates.sh` + `pre-message-gates.md` | UserPromptSubmit | Every turn |
| `pre-message.sh` + `pre-message.md` | UserPromptSubmit | Every turn |
| `stop-turn-log.sh` | Stop | Never -- passive log, no injection |
| `bootstrap-gate-pre.sh` | PreToolUse | Only in warn mode, only when the session is un-bootstrapped |
| `bootstrap-gate-post.sh` | PostToolUse | Never -- clears state, no injection |

Each `.sh` script wraps its paired `.md` file in the hook JSON envelope (`additionalContext`), except the bootstrap-gate pair, whose warn/deny text is generated inline by the scripts themselves. Registration lives in `hooks.json` (plugin path) and `.claude/settings.json` (this repo's own checkout).

## Provenance of the injected text

The per-turn files are tripwires, not rule bodies:

- `pre-message-gates.md` derives from the `session-bootstrap` skill. It checks for a completed `Skill(session-bootstrap)` call and lists the reload triggers.
- `pre-message.md` derives from the `honesty` skill. It checks for a completed `Skill(honesty)` call and carries a minimal banned-vocabulary reminder.

The full rules live in `skills/session-bootstrap/SKILL.md` and `skills/honesty/SKILL.md`. Hook text reminds; only a `Skill` tool call loads the rules. When a skill changes, update the derived hook text to match -- the hook must never contradict its source skill.

## Word budget

The two per-turn files are injected on every user prompt, so their size is a recurring token cost. CI (`.github/workflows/validate.yml`) enforces a combined budget of 400 words for `pre-message-gates.md` + `pre-message.md`. `session-start.md` fires once per session and is outside the budget.

## Mirror in .claude/hooks

`.claude/hooks/` contains only relative symlinks into this directory: the eight shipped `.md` and `.sh` injector/gate files, plus the repo-local `stop-turn-log.sh`, for nine entries total. The eight shipped files mean this repo dogfoods the same hooks it ships as a plugin; `stop-turn-log.sh` is the one repo-local exception (see below). Edit files here; never edit through the mirror.

## stop-turn-log.sh

A Stop hook that appends one JSONL line per turn to a local log, unconditionally (no enable flag). It is repo-local: registered in `.claude/settings.json` only, and is deliberately not shipped via `hooks/hooks.json`. It never blocks and never judges the turn -- pure passive logging.

## bootstrap-gate-pre.sh + bootstrap-gate-post.sh

A PreToolUse/PostToolUse pair that gates tool use in a session that has not yet completed `Skill(session-bootstrap)`. `session-start.sh` stamps a `.bootstrap-pending-<session_id>` flag file on every SessionStart; `bootstrap-gate-post.sh` (matcher `Skill`) clears it once a `Skill(session-bootstrap)` call completes; `bootstrap-gate-pre.sh` (matcher: all tools, no matcher key) checks the flag on every other tool call.

Mode contract, via `BOOTSTRAP_GATE_MODE`:

- `deny` (exact string) -- a user-flipped promotion, never the shipped default. Blocks the tool call with a `permissionDecision: deny` reason instead of injecting context.
- anything else -- **warn**, including unset and any value that isn't exactly `deny`. Allows the tool call, injects an `additionalContext` nudge to run `Skill(session-bootstrap)`, and appends a line to the JSONL log.

Unset already resolves to warn (`MODE="${BOOTSTRAP_GATE_MODE:-warn}"`); the explicit `BOOTSTRAP_GATE_MODE=warn` prefix in both configs documents the default, it doesn't activate it. There is no gate-off value -- disabling the gate means removing (or commenting out) its `PreToolUse`/`PostToolUse` entries in `.claude/settings.json` / `hooks/hooks.json`. To promote to deny, change `BOOTSTRAP_GATE_MODE=warn` to `=deny` in the hook command lines for `bootstrap-gate-pre.sh` in both `.claude/settings.json` and `hooks/hooks.json`.

State lives under `${BOOTSTRAP_GATE_STATE_DIR:-$CLAUDE_PROJECT_DIR/.claude}`: the flag file `.bootstrap-pending-<session_id>` and, in warn mode, the log `.bootstrap-gate-log.jsonl` (default path: `.claude/.bootstrap-gate-log.jsonl`).

Subagents identify themselves via an `agent_id` field on the hook payload; `bootstrap-gate-pre.sh` exempts any call carrying one, so the gate only ever applies to the main-thread session.

Both scripts are fail-open: missing `jq`, malformed stdin, an unresolved state dir, or an invalid `session_id` all resolve to a plain allow (or, for the post-hook, a no-op) rather than blocking or guessing. Neither script ever exits nonzero.
