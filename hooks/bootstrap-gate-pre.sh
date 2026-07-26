#!/usr/bin/env bash
# PreToolUse hook (matcher *): bootstrap-gate-pre.sh
#
# Blocks (deny mode) or nudges (warn mode) tool use in a session that has not
# yet completed Skill(session-bootstrap), as recorded by a
# .bootstrap-pending-<session_id> flag file that hooks/session-start.sh stamps
# on every SessionStart and hooks/bootstrap-gate-post.sh clears once the
# session-bootstrap Skill call completes.
#
# Fail-open philosophy: this hook NEVER exits nonzero. Missing jq, malformed
# stdin, an unresolved state dir, or any other ambiguity all resolve to a
# plain allow (exit 0, empty stdout, no log line) rather than blocking.
#
# State dir resolution: ${BOOTSTRAP_GATE_STATE_DIR:-$CLAUDE_PROJECT_DIR/.claude}.
# If neither variable is set, there is no safe place to look for a flag or
# write a log, so this hook allows silently.

# Guard against a TTY, and bound the read with timeout, so a manual or
# misbehaving invocation can never hang the hook.
if [ -t 0 ]; then
  RAW=""
else
  RAW="$(timeout 2 cat 2>/dev/null || true)"
fi

# No jq, no gate: fail open.
command -v jq &>/dev/null || exit 0
[[ -z "$RAW" ]] && exit 0
printf '%s' "$RAW" | jq empty 2>/dev/null || exit 0

# Subagents identify themselves via agent_id; the gate never applies to them.
AGENT_ID="$(printf '%s' "$RAW" | jq -r '.agent_id // empty' 2>/dev/null)"
if [[ -n "$AGENT_ID" ]]; then
  exit 0
fi

STATE_DIR="${BOOTSTRAP_GATE_STATE_DIR:-}"
if [[ -z "$STATE_DIR" ]]; then
  if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
    STATE_DIR="$CLAUDE_PROJECT_DIR/.claude"
  else
    exit 0
  fi
fi

SESSION_ID="$(printf '%s' "$RAW" | jq -r '.session_id // empty' 2>/dev/null)"
[[ -z "$SESSION_ID" ]] && exit 0

TOOL_NAME="$(printf '%s' "$RAW" | jq -r '.tool_name // empty' 2>/dev/null)"
SKILL_NAME="$(printf '%s' "$RAW" | jq -r '.tool_input.skill // empty' 2>/dev/null)"

FLAG_FILE="$STATE_DIR/.bootstrap-pending-$SESSION_ID"

IS_BOOTSTRAP_SKILL_CALL=0
if [[ "$TOOL_NAME" == "Skill" && "$SKILL_NAME" == "session-bootstrap" ]]; then
  IS_BOOTSTRAP_SKILL_CALL=1
fi

# No flag, or the very call that satisfies the gate: plain allow, no log.
if [[ ! -f "$FLAG_FILE" || "$IS_BOOTSTRAP_SKILL_CALL" -eq 1 ]]; then
  exit 0
fi

MODE="${BOOTSTRAP_GATE_MODE:-warn}"
LOG_FILE="$STATE_DIR/.bootstrap-gate-log.jsonl"
TS="$(date -u +%FT%TZ)"

mkdir -p "$STATE_DIR" 2>/dev/null || exit 0
jq -cn \
  --arg ts "$TS" \
  --arg sid "$SESSION_ID" \
  --arg tool "$TOOL_NAME" \
  --arg mode "$MODE" \
  '{timestamp:$ts, session_id:$sid, tool_name:$tool, mode:$mode}' \
  >>"$LOG_FILE" 2>/dev/null

if [[ "$MODE" == "deny" ]]; then
  REASON="bootstrap-gate: this session has not completed Skill(session-bootstrap) yet. Run Skill(session-bootstrap) before any other tool call."
  jq -cn \
    --arg reason "$REASON" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse", permissionDecision:"deny", permissionDecisionReason:$reason}}'
else
  CONTEXT="[bootstrap-gate] This session has not completed Skill(session-bootstrap) yet. Run Skill(session-bootstrap) before continuing."
  jq -cn \
    --arg context "$CONTEXT" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse", additionalContext:$context}}'
fi

exit 0
