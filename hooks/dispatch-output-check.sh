#!/usr/bin/env bash
# dispatch-output-check.sh -- PostToolUse (Agent) and SubagentStop hook.
#
# Joins the two events of one subagent dispatch by agent id and appends one
# JSON record line per pairing to $STATE/dispatch-check-records.jsonl, where
# STATE is $DISPATCH_CHECK_STATE_DIR (default $CLAUDE_PROJECT_DIR/.claude).
# PostToolUse carries the agent id as tool_response.agentId and SubagentStop
# as agent_id. Either event can arrive first: the first one is parked as
# $STATE/.dispatch-check-pending/<agent id>; the second claims it with an
# atomic mv and writes the record. A SubagentStop with no PostToolUse never
# produces a record. Parked files older than 1 hour are swept on every run.
#
# The dispatch message lines `Dispatch id:` and `Output path:` are read from
# tool_input.prompt (each optional). The verdict is always pass with an empty
# failed list until the checks are added.
#
# Fail closed, never block: the hook always exits 0 with empty stdout. Missing
# jq or unparseable stdin writes a message to stderr and a fail record.

STATE="${DISPATCH_CHECK_STATE_DIR:-${CLAUDE_PROJECT_DIR:-.}/.claude}"
RECORDS="$STATE/dispatch-check-records.jsonl"
PENDING="$STATE/.dispatch-check-pending"
now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

payload="$(cat)"
mkdir -p "$PENDING" 2>/dev/null
find "$PENDING" -type f -mmin +60 -delete 2>/dev/null

if ! command -v jq >/dev/null 2>&1; then
  echo "dispatch-output-check: jq not found; cannot check dispatch" >&2
  printf '{"verdict":"fail","failed":["jq missing"],"time":"%s"}\n' "$now" >>"$RECORDS" 2>/dev/null
  exit 0
fi
if ! jq -e . >/dev/null 2>&1 <<<"$payload"; then
  echo "dispatch-output-check: stdin is not valid JSON" >&2
  jq -n -c --arg t "$now" '{verdict:"fail",failed:["bad json"],time:$t}' >>"$RECORDS" 2>/dev/null
  exit 0
fi

event="$(jq -r '.hook_event_name // empty' <<<"$payload")"
id=""
if [[ "$event" == "SubagentStop" ]]; then
  id="$(jq -r '.agent_id // empty' <<<"$payload")"
elif [[ "$event" == "PostToolUse" && "$(jq -r '.tool_name // empty' <<<"$payload")" == "Agent" ]]; then
  id="$(jq -r '.tool_response.agentId // empty' <<<"$payload")"
fi
[[ -z "$id" || "$id" == */* ]] && exit 0

# Claim the parked event. With none parked, or one of the same kind (a
# duplicate), park ours and stop; otherwise the pair is complete.
post="$payload"
claim="$PENDING/$id.claim.$$"
if mv "$PENDING/$id" "$claim" 2>/dev/null; then
  parked="$(cat "$claim")"
  if [[ "$(jq -r '.hook_event_name // empty' <<<"$parked")" == "$event" ]]; then
    printf '%s' "$payload" >"$claim" && mv "$claim" "$PENDING/$id"
    exit 0
  fi
  rm -f "$claim"
  [[ "$event" == "SubagentStop" ]] && post="$parked"
else
  printf '%s' "$payload" >"$claim" && mv "$claim" "$PENDING/$id"
  exit 0
fi

prompt="$(jq -r '.tool_input.prompt // empty' <<<"$post")"
dispatch_id="$(sed -n 's/^Dispatch id: *//p' <<<"$prompt" | head -n 1 | tr -d '\r')"
output_path="$(sed -n 's/^Output path: *//p' <<<"$prompt" | head -n 1 | tr -d '\r')"
type="$(jq -r '.tool_input.subagent_type // "unknown"' <<<"$post")"

record="$(jq -n -c --arg d "$dispatch_id" --arg a "$id" --arg s "$type" \
  --arg o "$output_path" --arg t "$now" \
  '{dispatch_id:$d,agent_id:$a,subagent_type:$s,verdict:"pass",failed:[],time:$t}
   | if $o == "" then . else .output_path = $o end')"
printf '%s\n' "$record" >>"$RECORDS"
exit 0
