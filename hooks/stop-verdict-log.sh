#!/usr/bin/env bash
# Stop hook: unconditional passive per-turn logging.
#
# Reads the Stop hook's JSON payload from stdin and appends one JSONL record describing
# the turn to a log file, unconditionally, on every invocation. This hook makes no
# judgement of any kind and NEVER blocks -- it is pure passive logging with no flag or
# mode gating it on or off.
#
# Fail-safe: any error here (missing jq, empty stdin, malformed stdin, unwritable log
# dir) must still fall through to `printf '{}'` + `exit 0` -- a Stop hook must never
# wedge a session on its own error.

# Guard against a TTY, and bound the read with timeout, so a manual or misbehaving
# invocation can never hang the hook.
if [ -t 0 ]; then
  RAW=""
else
  RAW="$(timeout 2 cat 2>/dev/null || true)"
fi

log_line() {
  local raw="$1"
  local log="$2"

  [[ "$raw" =~ ^[[:space:]]*$ ]] && return 0

  command -v jq &>/dev/null || return 0
  printf '%s' "$raw" | jq empty 2>/dev/null || return 0

  local ts
  ts="$(date -u +%FT%TZ)"

  mkdir -p "$(dirname "$log")" 2>/dev/null || return 0

  printf '%s' "$raw" | jq -c \
    --arg ts "$ts" \
    '{timestamp:$ts, session_id:(.session_id // ""), stop_hook_active:(.stop_hook_active == true), last_msg_head:((.last_assistant_message // "") | .[0:200])}' \
    >>"$log" 2>/dev/null || return 0
}

LOG="${B2_GATE_LOG:-${CLAUDE_PROJECT_DIR:-.}/.claude/.b2-verdict-log.jsonl}"
log_line "$RAW" "$LOG" || true

printf '{}\n'
exit 0
