#!/usr/bin/env bash
# Stop hook: SHADOW-mode passive verdict logging (B2 pilot).
#
# Reads the Stop hook's JSON payload from stdin and, only when explicitly enabled via
# B2_GATE=shadow, appends one JSONL record describing the turn to a log file for later
# offline judging. This hook NEVER judges verdicts and NEVER blocks -- it is pure
# passive logging. Default is OFF (inert) so headless/automation runs are unaffected
# unless B2_GATE is explicitly set.
#
# Fail-safe: any error here (missing jq, malformed stdin, unwritable log dir) must
# still fall through to `printf '{}'` + `exit 0` -- a Stop hook must never wedge a
# session on its own error.

RAW="$(cat 2>/dev/null || true)"

# Kill switch / opt-out: unset or "off" -> inert, no logging, no side effects.
if [[ -z "${B2_GATE:-}" || "${B2_GATE:-}" == "off" ]]; then
  printf '{}\n'
  exit 0
fi

log_line() {
  local raw="$1"
  local log="$2"

  command -v jq &>/dev/null || return 0
  printf '%s' "$raw" | jq empty 2>/dev/null || return 0

  local ts session_id stop_hook_active last_msg last_msg_head
  ts="$(date -u +%FT%TZ)"
  session_id="$(printf '%s' "$raw" | jq -r '.session_id // ""' 2>/dev/null)" || return 0
  stop_hook_active="$(printf '%s' "$raw" | jq -r 'if .stop_hook_active == true then "true" else "false" end' 2>/dev/null)" || stop_hook_active="false"
  last_msg="$(printf '%s' "$raw" | jq -r '.last_assistant_message // ""' 2>/dev/null)" || last_msg=""
  last_msg_head="${last_msg:0:200}"

  mkdir -p "$(dirname "$log")" 2>/dev/null || return 0

  jq -cn \
    --arg ts "$ts" \
    --arg session_id "$session_id" \
    --argjson stop_hook_active "$stop_hook_active" \
    --arg last_msg_head "$last_msg_head" \
    '{timestamp: $ts, session_id: $session_id, mode: "shadow", stop_hook_active: $stop_hook_active, last_msg_head: $last_msg_head}' \
    >>"$log" 2>/dev/null || return 0
}

LOG="${B2_GATE_LOG:-${CLAUDE_PROJECT_DIR:-.}/.claude/.b2-verdict-log.jsonl}"
log_line "$RAW" "$LOG" || true

printf '{}\n'
exit 0
