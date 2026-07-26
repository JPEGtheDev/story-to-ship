#!/usr/bin/env bash
# PreToolUse hook (matcher Workflow): workflow-model-guard.sh
#
# Denies a Workflow tool invocation whose inline script dispatches one or
# more agent( ) calls with no model: pin, unless the script carries the
# literal WORKFLOW-MODEL-INHERIT-OK marker -- a script-level, deliberate
# opt-out documenting that inheriting the dispatching session's model tier
# is intentional.
#
# Fail-open philosophy: this hook NEVER exits nonzero. Missing jq, malformed
# stdin, a subagent-originated call (non-empty agent_id), or a Workflow
# invocation with no inline tool_input.script (e.g. a scriptPath-only
# invocation) all resolve to a plain allow (exit 0, empty stdout) rather
# than blocking or guessing. There is no mode env var and no warn mode: the
# marker above is the only sanctioned escape hatch (mechanical precision is
# the point; see hooks/README.md).
#
# Block-extraction rule: an agent( call block runs from the line containing
# the literal substring "agent(" through the first subsequent line
# containing the literal two-character substring "})" (which may be the
# same line). The model: pin check is a plain substring search scoped to
# that block only -- text before the agent( line (e.g. a comment mentioning
# model:) does not count and must not satisfy the pin requirement.

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

# Subagents identify themselves via agent_id; this gate never applies to
# them. Checked BEFORE any script parsing, per the dispatch-exemption
# contract shared with bootstrap-gate-pre.sh.
AGENT_ID="$(printf '%s' "$RAW" | jq -r '.agent_id // empty' 2>/dev/null)"
if [[ -n "$AGENT_ID" ]]; then
  exit 0
fi

# This guard only inspects inline scripts (tool_input.script). A
# scriptPath-only or name-only invocation has no inline text to scan for
# agent( calls, so it fails open (allow) -- a known, deliberate coverage
# gap, not a bug.
SCRIPT="$(printf '%s' "$RAW" | jq -r '.tool_input.script // empty' 2>/dev/null)"
[[ -z "$SCRIPT" ]] && exit 0

# Script-level opt-out: a literal marker anywhere in the script means the
# caller has deliberately chosen to inherit the dispatching session's model
# tier. This is a whole-script substring search, not scoped per-call.
if [[ "$SCRIPT" == *"WORKFLOW-MODEL-INHERIT-OK"* ]]; then
  exit 0
fi

# Scan the script for agent( call blocks lacking a model: pin. AWK performs
# the line-oriented block extraction described in the header comment above;
# it prints one line (the offending call's prompt fragment, or a fallback
# note) per unpinned block it finds. Any output at all means at least one
# unpinned call exists.
UNPINNED="$(awk '
  BEGIN { in_block = 0; block = "" }
  {
    line = $0
    if (!in_block) {
      if (index(line, "agent(") > 0) {
        in_block = 1
        block = line
      } else {
        next
      }
    } else {
      block = block "\n" line
    }
    if (in_block && index(line, "})") > 0) {
      if (index(block, "model:") == 0) {
        frag = block
        if (match(frag, /prompt:[ \t]*"[^"]*"/)) {
          seg = substr(frag, RSTART, RLENGTH)
          sub(/^prompt:[ \t]*"/, "", seg)
          sub(/"$/, "", seg)
          print seg
        } else {
          print "(unpinned agent( call, prompt text not found)"
        }
      }
      in_block = 0
      block = ""
    }
  }
' <<<"$SCRIPT")"

[[ -z "$UNPINNED" ]] && exit 0

FIRST_FRAG="$(head -n1 <<<"$UNPINNED")"
REASON="workflow-model-guard: this Workflow script dispatches an agent( ) call with no model: pin (offending call: \"$FIRST_FRAG\"). Add an explicit model: tier to every agent( ) call in the script, or add the WORKFLOW-MODEL-INHERIT-OK marker if inheriting the caller's model tier is intentional."

jq -cn \
  --arg reason "$REASON" \
  '{hookSpecificOutput:{hookEventName:"PreToolUse", permissionDecision:"deny", permissionDecisionReason:$reason}}'

exit 0
