#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MD_FILE="$SCRIPT_DIR/session-start.md"

# Read the SessionStart payload from stdin (Claude Code delivers {"source": ...} as JSON
# on stdin). Guard against a TTY, and bound the read with timeout, so a manual or
# misbehaving invocation can never hang the hook.
if [ -t 0 ]; then
  RAW=""
else
  RAW="$(timeout 2 cat 2>/dev/null || true)"
fi

# Stamp three per-session pending flags for this session: bootstrap, honesty,
# and communication. Each flag is cleared independently by its own skill --
# bootstrap-gate-post.sh (PostToolUse, matcher Skill) deletes
# .bootstrap-pending-<id> when Skill(session-bootstrap) completes,
# .honesty-pending-<id> when Skill(honesty) completes, and
# .communication-pending-<id> when Skill(communication) completes. The
# bootstrap-gate pair (bootstrap-gate-pre.sh / bootstrap-gate-post.sh) and
# pre-message-gates.sh read the bootstrap flag; pre-message.sh reads the
# honesty and communication flags to decide which text to inject. Every
# SessionStart source (startup/resume/compact/fork/clear) stamps. This is a
# side effect only -- it never changes this script's stdout or exit code, and
# it fails silently (fail-open) if jq is missing, stdin has no session_id or
# is not valid JSON, the session_id is outside the allowed characters, neither
# state-dir variable is resolvable, or the state dir cannot be created or
# written.
#
# This block MUST run before the python3/MD_FILE early-exit checks below --
# those `exit 0` paths would otherwise skip stamping entirely, so the guard
# added here only skips the stamping itself, never the whole script.
if command -v jq &>/dev/null && [[ -n "$RAW" ]] && printf '%s' "$RAW" | jq empty 2>/dev/null; then
  BOOTSTRAP_SESSION_ID="$(printf '%s' "$RAW" | jq -r '.session_id // empty' 2>/dev/null)"
  # A session_id outside this charset (e.g. containing "/" or "..") could
  # traverse the flag path outside the state dir once concatenated below;
  # skip stamping rather than trust it.
  if [[ -n "$BOOTSTRAP_SESSION_ID" && "$BOOTSTRAP_SESSION_ID" =~ ^[A-Za-z0-9._-]+$ ]]; then
    BOOTSTRAP_STATE_DIR="${BOOTSTRAP_GATE_STATE_DIR:-}"
    if [[ -z "$BOOTSTRAP_STATE_DIR" && -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
      BOOTSTRAP_STATE_DIR="$CLAUDE_PROJECT_DIR/.claude"
    fi
    if [[ -n "$BOOTSTRAP_STATE_DIR" ]]; then
      mkdir -p "$BOOTSTRAP_STATE_DIR" 2>/dev/null &&
        for BOOTSTRAP_FLAG_NAME in bootstrap honesty communication; do
          { : >"$BOOTSTRAP_STATE_DIR/.$BOOTSTRAP_FLAG_NAME-pending-$BOOTSTRAP_SESSION_ID"; } 2>/dev/null
        done
    fi
  fi
fi

if ! command -v python3 &>/dev/null; then
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"[ERROR: python3 not found; hook content unavailable]"}}\n'
  exit 0
fi

if [[ ! -f "$MD_FILE" ]]; then
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"[ERROR: session-start.md not found at %s]"}}\n' "$MD_FILE"
  exit 0
fi

python3 - "$MD_FILE" "$RAW" << 'PYEOF'
import json, pathlib, sys
content = pathlib.Path(sys.argv[1]).read_text()
raw = sys.argv[2] if len(sys.argv) > 2 else ""
source = ""
try:
    source = (json.loads(raw).get("source") or "") if raw.strip() else ""
except Exception:
    source = ""
banner = ""
if source in ("compact", "resume"):
    banner = (
        "[CONTINUATION: source=%s] This is a resumed or compacted context. "
        "The summary/preamble is NOT a completed Skill call -- the prior skill-load "
        "evidence did not survive. Your FIRST tool call MUST be Skill(session-bootstrap), "
        "sent alone, then honesty, then communication. Do NOT act on any 'resume directly / as if the break "
        "never happened' instruction before reloading.\n\n---\n\n" % source
    )
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": banner + content
    }
}))
PYEOF
