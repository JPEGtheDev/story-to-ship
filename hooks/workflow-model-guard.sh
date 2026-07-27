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
# Block-extraction rule: a block STARTS at each occurrence of the literal
# substring "agent(" -- per occurrence, not per line, so two calls on one
# line are two separate blocks. From that occurrence's opening "(", the
# scanner tracks parenthesis depth character-by-character (only "(" and
# ")" count; "{" and "}" do not) and the block ENDS when depth returns to
# 0 at the call's own closing paren. A nested call argument's parens
# (including a "}" immediately followed by a ")") no longer terminate the
# block early -- only the outermost agent( call's own closing paren does.
# If EOF is reached with an open block (depth never returns to 0), the
# collected text is flushed and evaluated as-is rather than discarded, so
# a truncated/unterminated call is still checked for a pin. The model:
# pin check is a plain substring search scoped to that block only -- text
# before the agent( occurrence (e.g. a comment mentioning model:, or a
# preceding call on the same line) does not count and must not satisfy the
# pin requirement.
#
# Known residual (disclosed, not silent): this scanner is not string-
# literal-aware. Literal text matching "agent(" inside a string value, or
# unbalanced parentheses inside a string value, can shift block boundaries
# and produce a wrong verdict in either direction. The
# WORKFLOW-MODEL-INHERIT-OK marker is the sanctioned escape hatch for a
# script the scanner misjudges, not a silent fallback.

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

# No awk, no scan: fail open (mirrors the jq guard above).
command -v awk &>/dev/null || exit 0

# Scan the script for agent( call blocks lacking a model: pin. AWK performs
# the per-occurrence, paren-depth block extraction described in the header
# comment above; it prints one line (the offending call's prompt fragment,
# or a fallback note) per unpinned block it finds. Any output at all means
# at least one unpinned call exists.
UNPINNED="$(awk '
  { text = text $0 "\n" }
  END {
    n = length(text)
    i = 1
    while (i <= n) {
      rest = substr(text, i)
      idx = index(rest, "agent(")
      if (idx == 0) { break }
      start = i + idx - 1
      paren = start + 5
      depth = 1
      j = paren + 1
      while (j <= n && depth > 0) {
        c = substr(text, j, 1)
        if (c == "(") { depth++ }
        else if (c == ")") { depth-- }
        j++
      }
      block = substr(text, start, j - start)
      if (index(block, "model:") == 0) {
        frag = ""
        if (match(block, /prompt:[ \t]*"[^"]*"/)) {
          seg = substr(block, RSTART, RLENGTH)
          sub(/^prompt:[ \t]*"/, "", seg)
          sub(/"$/, "", seg)
          frag = seg
        } else if (match(block, /agent\([ \t]*"[^"]*"/)) {
          seg = substr(block, RSTART, RLENGTH)
          sub(/^agent\([ \t]*"/, "", seg)
          sub(/"$/, "", seg)
          frag = seg
        } else {
          frag = "(unpinned agent( call, prompt text not found)"
        }
        print frag
      }
      i = j
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
