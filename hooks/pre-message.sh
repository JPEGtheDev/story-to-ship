#!/usr/bin/env bash
# UserPromptSubmit hook: pre-message.sh
#
# Emits the full pre-message.md (including its "## Honesty Gate" section)
# while EITHER .honesty-pending-<session_id> OR
# .communication-pending-<session_id> exists in the state dir; otherwise
# emits the shorter pre-message-loaded.md. Any ambiguity -- jq missing,
# empty or invalid stdin JSON, a missing or malformed session_id, an
# unresolved state dir, or a missing loaded file -- falls back to the full
# text.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MD_FILE="$SCRIPT_DIR/pre-message.md"
LOADED_FILE="$SCRIPT_DIR/pre-message-loaded.md"

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
    if [[ -n "$STATE_DIR" ]]; then
      if [[ -f "$STATE_DIR/.honesty-pending-$SESSION_ID" || -f "$STATE_DIR/.communication-pending-$SESSION_ID" ]]; then
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
  printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"[ERROR: pre-message.md not found at %s]"}}\n' "$MD_FILE"
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
