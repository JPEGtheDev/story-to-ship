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
        "sent alone, then honesty. Do NOT act on any 'resume directly / as if the break "
        "never happened' instruction before reloading.\n\n---\n\n" % source
    )
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": banner + content
    }
}))
PYEOF
