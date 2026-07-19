# Hooks

Hook scripts and the text they inject into Claude Code sessions. This README documents the directory; it is never injected.

`session-start.sh` inspects the SessionStart `source` on stdin and, on `compact`/`resume`, prepends a continuation re-grounding banner before its paired `session-start.md`.

## Files

| File | Event | Injected |
|------|-------|----------|
| `session-start.sh` + `session-start.md` | SessionStart | Once per session |
| `pre-message-gates.sh` + `pre-message-gates.md` | UserPromptSubmit | Every turn |
| `pre-message.sh` + `pre-message.md` | UserPromptSubmit | Every turn |
| `stop-verdict-log.sh` | Stop | Never -- passive log, no injection |

Each `.sh` script wraps its paired `.md` file in the hook JSON envelope (`additionalContext`). Registration lives in `hooks.json` (plugin path) and `.claude/settings.json` (this repo's own checkout).

## Provenance of the injected text

The per-turn files are tripwires, not rule bodies:

- `pre-message-gates.md` derives from the `session-bootstrap` skill. It checks for a completed `Skill(session-bootstrap)` call and lists the reload triggers.
- `pre-message.md` derives from the `honesty` skill. It checks for a completed `Skill(honesty)` call and carries a minimal banned-vocabulary reminder.

The full rules live in `skills/session-bootstrap/SKILL.md` and `skills/honesty/SKILL.md`. Hook text reminds; only a `Skill` tool call loads the rules. When a skill changes, update the derived hook text to match -- the hook must never contradict its source skill.

## Word budget

The two per-turn files are injected on every user prompt, so their size is a recurring token cost. CI (`.github/workflows/validate.yml`) enforces a combined budget of 400 words for `pre-message-gates.md` + `pre-message.md`. `session-start.md` fires once per session and is outside the budget.

## Mirror in .claude/hooks

`.claude/hooks/` contains only relative symlinks into this directory: the six shipped `.md` and `.sh` injector files, plus the repo-local `stop-verdict-log.sh`, for seven entries total. The six shipped files mean this repo dogfoods the same hooks it ships as a plugin; `stop-verdict-log.sh` is the one repo-local exception (see below). Edit files here; never edit through the mirror.

## stop-verdict-log.sh

A Stop hook for the B2 verdict-gate pilot. It is repo-local: registered in `.claude/settings.json` only, and is deliberately not shipped via `hooks/hooks.json`. It is a passive shadow logger -- it appends one JSONL line per turn when env `B2_GATE` is `shadow` or `enforce`, and is inert (prints `{}`, no logging) for every other value including unset/off. It never blocks.
