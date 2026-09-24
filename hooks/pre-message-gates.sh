#!/usr/bin/env bash
# UserPromptSubmit hook: pre-message-gates.sh
#
# Emits the full pre-message-gates.md (including its "## Bootstrap Gate"
# section) while .bootstrap-pending-<session_id> exists in the state dir;
# otherwise emits the shorter pre-message-gates-loaded.md. The state dir is
# resolved as ${BOOTSTRAP_GATE_STATE_DIR:-$CLAUDE_PROJECT_DIR/.claude}. Any
# ambiguity -- jq missing, empty or invalid stdin JSON, a missing or
# malformed session_id, an unresolved state dir, a state dir that does not
# exist, or a missing loaded file -- falls back to the full text. One case
# goes the other way: a state dir that exists but cannot be written gets no
# flag from session-start.sh, so this hook emits the loaded text from the
# first turn.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MD_FILE="$SCRIPT_DIR/pre-message-gates.md"
LOADED_FILE="$SCRIPT_DIR/pre-message-gates-loaded.md"

# Guard against a TTY, and bound the read with timeout, so a manual or
# misbehaving invocation can never hang the hook.
if [ -t 0 ]; then
  RAW=""
else
  RAW="$(timeout 2 cat 2>/dev/null || true)"
fi

# Default to the full text; only PENDING=0 (below) switches to the loaded
# variant, and only once every check below succeeds.
PENDING=1

if command -v jq &>/dev/null && [[ -n "$RAW" ]] && printf '%s' "$RAW" | jq empty 2>/dev/null; then
  SESSION_ID="$(printf '%s' "$RAW" | jq -r '.session_id // empty' 2>/dev/null)"
  if [[ -n "$SESSION_ID" && "$SESSION_ID" =~ ^[A-Za-z0-9._-]+$ ]]; then
    STATE_DIR="${BOOTSTRAP_GATE_STATE_DIR:-}"
    if [[ -z "$STATE_DIR" && -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
      STATE_DIR="$CLAUDE_PROJECT_DIR/.claude"
    fi
    if [[ -n "$STATE_DIR" && -d "$STATE_DIR" ]]; then
      if [[ -f "$STATE_DIR/.bootstrap-pending-$SESSION_ID" ]]; then
        PENDING=1
      else
        PENDING=0
      fi
    fi
  fi
fi

TARGET_FILE="$MD_FILE"
if [[ "$PENDING" -eq 0 && -f "$LOADED_FILE" ]]; then
  TARGET_FILE="$LOADED_FILE"
fi

if ! command -v python3 &>/dev/null; then
  printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"[ERROR: python3 not found; hook content unavailable]"}}\n'
  exit 0
fi

if [[ ! -f "$MD_FILE" ]]; then
  printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"[ERROR: pre-message-gates.md not found at %s]"}}\n' "$MD_FILE"
  exit 0
fi

python3 - "$TARGET_FILE" << 'PYEOF'
import json, pathlib, sys
content = pathlib.Path(sys.argv[1]).read_text()
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": content
    }
}))
PYEOF
