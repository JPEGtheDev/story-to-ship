#!/usr/bin/env bash
# Stop hook: SHADOW-mode passive verdict logging (B2 pilot).
#
# Reads the Stop hook's JSON payload from stdin and appends one JSONL record describing
# the turn to a log file for later offline judging, but ONLY when B2_GATE is exactly
# `shadow` or `enforce`. This hook NEVER judges verdicts and NEVER blocks -- it is pure
# passive logging. Every other value -- unset, `off`, or anything unrecognized -- is
# inert (no logging), so headless/automation runs are unaffected by default.
# (`enforce` is the planned next-phase state; the passive log runs in both.)
#
# Fail-safe: any error here (missing jq, malformed stdin, unwritable log dir) must
# still fall through to `printf '{}'` + `exit 0` -- a Stop hook must never wedge a
# session on its own error.

# Guard against a TTY, and bound the read with timeout, so a manual or misbehaving
# invocation can never hang the hook.
if [ -t 0 ]; then
  RAW=""
else
  RAW="$(timeout 2 cat 2>/dev/null || true)"
fi

# Kill switch / allowlist: logging is active ONLY for shadow or enforce. Any other
# value -- unset, "off", or unrecognized -- is inert, no logging, no side effects.
case "${B2_GATE:-}" in
  shadow|enforce) ;;   # active
  *) printf '{}\n'; exit 0 ;;  # inert: unset/off/unrecognized
esac

log_line() {
  local raw="$1"
  local log="$2"
  local mode="$3"

  command -v jq &>/dev/null || return 0
  printf '%s' "$raw" | jq empty 2>/dev/null || return 0

  local ts
  ts="$(date -u +%FT%TZ)"

  mkdir -p "$(dirname "$log")" 2>/dev/null || return 0

  printf '%s' "$raw" | jq -c \
    --arg ts "$ts" --arg mode "$mode" \
    '{timestamp:$ts, session_id:(.session_id // ""), mode:$mode, stop_hook_active:(.stop_hook_active == true), last_msg_head:((.last_assistant_message // "") | .[0:200])}' \
    >>"$log" 2>/dev/null || return 0
}

LOG="${B2_GATE_LOG:-${CLAUDE_PROJECT_DIR:-.}/.claude/.b2-verdict-log.jsonl}"
log_line "$RAW" "$LOG" "${B2_GATE:-}" || true

printf '{}\n'
exit 0
