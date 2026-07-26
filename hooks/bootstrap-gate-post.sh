#!/usr/bin/env bash
# PostToolUse hook (matcher Skill): bootstrap-gate-post.sh
#
# Clears the .bootstrap-pending-<session_id> flag for the current session
# once a Skill(session-bootstrap) call completes, so bootstrap-gate-pre.sh
# stops gating further tool calls in this session. Any other Skill (or any
# other tool) is a no-op. Never blocks: always exits 0.

# Guard against a TTY, and bound the read with timeout, so a manual or
# misbehaving invocation can never hang the hook.
if [ -t 0 ]; then
  RAW=""
else
  RAW="$(timeout 2 cat 2>/dev/null || true)"
fi

command -v jq &>/dev/null || exit 0
[[ -z "$RAW" ]] && exit 0
printf '%s' "$RAW" | jq empty 2>/dev/null || exit 0

TOOL_NAME="$(printf '%s' "$RAW" | jq -r '.tool_name // empty' 2>/dev/null)"
SKILL_NAME="$(printf '%s' "$RAW" | jq -r '.tool_input.skill // empty' 2>/dev/null)"

if [[ "$TOOL_NAME" != "Skill" || "$SKILL_NAME" != "session-bootstrap" ]]; then
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

FLAG_FILE="$STATE_DIR/.bootstrap-pending-$SESSION_ID"
rm -f -- "$FLAG_FILE" 2>/dev/null

exit 0
