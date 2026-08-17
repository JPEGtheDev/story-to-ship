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
| `bootstrap-gate-pre.sh` | PreToolUse | No context injection in deny mode (shipped default) -- it denies the call instead; in warn fallback, a nudge only when the session is un-bootstrapped |
| `bootstrap-gate-post.sh` | PostToolUse | Never -- clears state, no injection |
| `workflow-model-guard.sh` | PreToolUse (matcher `Workflow`) | Only when a Workflow script has an unpinned `agent(` call, and only as a deny reason -- never as injected context |

Each text-injecting `.sh` script wraps its paired `.md` file in the hook JSON envelope (`additionalContext`), except the bootstrap-gate pair and `workflow-model-guard.sh`, whose deny/warn text is generated inline by the scripts themselves. Four `.sh` files have no paired `.md` file: `bootstrap-gate-pre.sh`, `bootstrap-gate-post.sh`, and `workflow-model-guard.sh` (inline-generated text, as above), plus `stop-turn-log.sh` -- which is not a text-injecting script at all, but a passive logger that injects nothing (see its own section below). Registration lives in `hooks.json` (plugin path) and `.claude/settings.json` (this repo's own checkout).

## Provenance of the injected text

The per-turn files are tripwires, not rule bodies:

- `pre-message-gates.md` derives from the `session-bootstrap` skill. It checks for a completed `Skill(session-bootstrap)` call and lists the reload triggers.
- `pre-message.md` derives from the `honesty` and `communication` skills. It checks for completed `Skill(honesty)` and `Skill(communication)` calls and carries a minimal banned-vocabulary reminder.

The full rules live in `skills/session-bootstrap/SKILL.md`, `skills/honesty/SKILL.md`, and `skills/communication/SKILL.md`. Hook text reminds; only a `Skill` tool call loads the rules. When a skill changes, update the derived hook text to match -- the hook must never contradict its source skill.

## Word budget

The two per-turn files are injected on every user prompt, so their size is a recurring token cost. CI (`.github/workflows/validate.yml`) enforces a combined budget of 495 words for `pre-message-gates.md` + `pre-message.md`. `session-start.md` fires once per session and is outside the budget.

## Mirror in .claude/hooks

`.claude/hooks/` contains only relative symlinks into this directory: the nine shipped `.md` and `.sh` injector/gate files, plus the repo-local `stop-turn-log.sh`, for ten entries total. The nine shipped files mean this repo dogfoods the same hooks it ships as a plugin; `stop-turn-log.sh` is the one repo-local exception (see below). Edit files here; never edit through the mirror.

## stop-turn-log.sh

A Stop hook that appends one JSONL line per turn to a local log, unconditionally (no enable flag). It is repo-local: registered in `.claude/settings.json` only, and is deliberately not shipped via `hooks/hooks.json`. It never blocks and never judges the turn -- pure passive logging.

## bootstrap-gate-pre.sh + bootstrap-gate-post.sh

A PreToolUse/PostToolUse pair that gates tool use in a session that has not yet completed `Skill(session-bootstrap)`. `session-start.sh` stamps a `.bootstrap-pending-<session_id>` flag file on every SessionStart; `bootstrap-gate-post.sh` (matcher `Skill`) clears it once a `Skill(session-bootstrap)` call completes; `bootstrap-gate-pre.sh` (matcher: all tools, no matcher key) checks the flag on every other tool call.

Mode contract, via `BOOTSTRAP_GATE_MODE`:

- `deny` (exact string) -- the shipped default, pinned by the `BOOTSTRAP_GATE_MODE=deny` prefix in both registration files. Blocks the tool call with a `permissionDecision: deny` reason instead of injecting context.
- anything else -- **warn**, the fallback: any value that isn't exactly `deny`, including unset. Allows the tool call and injects an `additionalContext` nudge to run `Skill(session-bootstrap)`.

The script's own unset default is warn (`MODE="${BOOTSTRAP_GATE_MODE:-warn}"`); the shipped default is deny only because the registration lines in both configs pin `BOOTSTRAP_GATE_MODE=deny` -- the prefix activates the mode, it isn't just documentation. There is no gate-off value -- disabling the gate means removing (or commenting out) its `PreToolUse`/`PostToolUse` entries in `.claude/settings.json` / `hooks/hooks.json`. To fall back to warn, change `BOOTSTRAP_GATE_MODE=deny` to `=warn` in the hook command lines for `bootstrap-gate-pre.sh` in both `.claude/settings.json` and `hooks/hooks.json`.

State lives under `${BOOTSTRAP_GATE_STATE_DIR:-$CLAUDE_PROJECT_DIR/.claude}`: the flag file `.bootstrap-pending-<session_id>` and the log `.bootstrap-gate-log.jsonl` (default path: `.claude/.bootstrap-gate-log.jsonl`), which is appended in both modes -- the JSONL write happens before the mode branch, and each logged line carries its own `mode` field.

Subagents identify themselves via an `agent_id` field on the hook payload; `bootstrap-gate-pre.sh` exempts any call carrying one, so the gate only ever applies to the main-thread session.

Both scripts are fail-open: missing `jq`, malformed stdin, an unresolved state dir, or an invalid `session_id` all resolve to a plain allow (or, for the post-hook, a no-op) rather than blocking or guessing. Neither script ever exits nonzero.

Documented limitation: on an auto-resumed continuation, the model's first tool calls can execute before the SessionStart hook stamps the pending flag file, in which case the gate fails open (no flag file yet means a plain allow, deny mode included) for that window. The `UserPromptSubmit` reload gates (`pre-message-gates.sh`, `pre-message.sh`) remain the backup enforcement for a session that slips through this gap.

## workflow-model-guard.sh

A PreToolUse hook (matcher `Workflow`) that denies a Workflow tool invocation whose inline script (`tool_input.script`) dispatches an `agent(` call with no `model:` pin. Unlike bootstrap-gate, this guard is deny-only: there is no mode env var and no warn mode, because the escape hatch is the marker below, not a softer failure mode.

Block-extraction rule: a call block starts at each occurrence of the literal substring `agent(` -- per occurrence, not per line, so two calls on one line are two separate blocks -- and ends when parenthesis depth (tracked character-by-character from that occurrence's opening `(`) returns to 0 at the call's own closing paren; a nested call argument's own parens no longer terminate the block early. An unterminated block at EOF is flushed and evaluated rather than discarded. The `model:` pin check is a plain substring search scoped to that block only, so a `model:` mention in a comment line above the `agent(` occurrence, or in a preceding call on the same line, does not count. Disclosed residual: the scanner is not string-literal-aware, so literal `agent(` text or unbalanced parentheses inside a string value can shift block boundaries and produce a wrong verdict in either direction -- the marker below is the sanctioned escape hatch for a script the scanner misjudges.

Script-level opt-out: a script that carries the literal marker `WORKFLOW-MODEL-INHERIT-OK` anywhere in its text is allowed unconditionally, regardless of any unpinned calls -- this is a whole-script substring search, not scoped per-call, documenting a deliberate choice to inherit the dispatching session's model tier.

Subagents identify themselves via an `agent_id` field on the hook payload; this guard exempts any call carrying one, checked before any script parsing, matching the same exemption contract as `bootstrap-gate-pre.sh`.

This guard is fail-open: missing `jq`, malformed stdin, and a Workflow invocation with no inline `tool_input.script` (e.g. a `scriptPath`-only invocation -- out of scope for this hook by design) all resolve to a plain allow. It never exits nonzero; deny is communicated only via `permissionDecision: deny` on stdout.
