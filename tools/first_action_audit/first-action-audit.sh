#!/usr/bin/env bash
# first-action-audit.sh -- audits a Claude Code session transcript JSONL for
# bootstrap-first compliance after the latest context compaction.
#
# Built after a 2026-08-09 incident where a preserved-segment replay
# (pre-compaction tool calls carried into a continuation context) was
# misread as a first-action miss: this script excludes any candidate
# message whose timestamp is not strictly AFTER the last compact_boundary,
# even if that message appears later in file order. Verified CLI transcript
# schema version: 2.1.220.
#
# Fail LOUD by design: this is an audit tool, the deliberate inverse of this
# repo's fail-open hooks (see hooks/bootstrap-gate-pre.sh). Usage and
# environment problems (missing argument, unreadable/nonexistent file,
# missing jq) exit 2. Content problems (malformed lines, a real miss) never
# exit 2 -- they are reported on stdout/stderr with exit 0 or 1.
#
# Usage: first-action-audit.sh TRANSCRIPT_JSONL [N]
#   N = max first-calls listing lines, default 3.

usage() {
  echo "Usage: $(basename "$0") TRANSCRIPT_JSONL [N]" >&2
}

if [[ $# -lt 1 ]]; then
  usage
  exit 2
fi

TRANSCRIPT="$1"
N="${2:-3}"

# Argument-syntax errors precede environment checks: validate N before
# touching jq or the filesystem, so a bad N never leaks internal detail.
if [[ ! "$N" =~ ^[0-9]+$ ]]; then
  usage
  exit 2
fi

if ! command -v jq &>/dev/null; then
  echo "$(basename "$0"): jq is required but not found in PATH" >&2
  exit 2
fi

# Require a readable REGULAR file: -r alone also passes for directories
# (readable/searchable), which would otherwise fall through jq into a
# fabricated NO_TOOL_CALLS verdict.
if [[ ! -f "$TRANSCRIPT" || ! -r "$TRANSCRIPT" ]]; then
  echo "$(basename "$0"): cannot read transcript file (not a readable regular file): $TRANSCRIPT" >&2
  exit 2
fi

# An audit tool must never fall through a failed jq call into a fabricated
# verdict: every jq invocation's exit status is checked via check_rc.
check_rc() {
  local rc="$1"
  if [[ "$rc" -ne 0 ]]; then
    echo "$(basename "$0"): internal jq failure (exit $rc) -- aborting" >&2
    exit 2
  fi
}

# Pass 1: parse each line as JSON, skipping (and counting) lines that fail
# to parse. Also drops candidate assistant messages missing .timestamp
# (they cannot be ordered against the boundary) into the same bad count.
# Boundary is the LAST system/compact_boundary line's .timestamp, or the
# literal string "none". Candidates are main-thread assistant messages
# containing at least one tool_use item, strictly after the boundary.
readonly PARSE_PROG='
reduce inputs as $line (
  {parsed: [], bad: 0};
  ($line | try fromjson catch {"__malformed": true}) as $v
  | if ($v|type)=="object" and ($v.__malformed // false) then
      .bad += 1
    else
      .parsed += [$v]
    end
) as $p1
| ($p1.parsed) as $all
| ( [ $all[] | select(.type=="system" and .subtype=="compact_boundary") ] ) as $boundaries
| ( if ($boundaries|length) > 0 then ($boundaries[-1].timestamp // null) else null end ) as $braw
| ( if $braw == null then "none" else $braw end ) as $boundary
| reduce $all[] as $line (
    {cands: [], bad: $p1.bad};
    if ($line.type=="assistant") and ($line.isSidechain != true)
       and (($line.message.content // []) | any(.type=="tool_use")) then
      if ($line.timestamp|type) != "string" then
        .bad += 1
      elif ($boundary == "none") or ($line.timestamp > $boundary) then
        .cands += [{
          ts: $line.timestamp,
          tools: [ $line.message.content[] | select(.type=="tool_use")
                   | {name: .name, skill: (.input.skill // "")} ]
        }]
      else
        .
      end
    else
      .
    end
  ) as $r
| {boundary: $boundary, bad: $r.bad, candidates: $r.cands}
'

RESULT="$(jq -Rn "$PARSE_PROG" "$TRANSCRIPT")"
check_rc "$?"

# Pass 2: derive the listing lines and the verdict from pass 1's output.
readonly REPORT_PROG='
. as $in
| ($in.boundary) as $boundary
| ($in.candidates) as $cands
| ( [ $cands[] | .ts as $ts | .tools[]
      | (if .name=="Skill" then "\($ts) Skill \(.skill)" else "\($ts) \(.name)" end) ] ) as $listing_all
| ($listing_all[0:$n]) as $listing
| (
    if ($cands|length)==0 then
      {verdict_line: "VERDICT=NO_TOOL_CALLS", exit: 0}
    else
      ($cands[0]) as $first
      | ($first.tools) as $tools
      | if ($tools|length)==1 and $tools[0].name=="Skill" and $tools[0].skill=="session-bootstrap" then
          {verdict_line: "VERDICT=CLEAN", exit: 0}
        else
          ( [$tools[] | select(.name!="Skill" or .skill!="session-bootstrap")] | .[0] ) as $miss
          | {verdict_line: "VERDICT=MISS \($miss.name // "unknown") at \($first.ts)", exit: 1}
        end
    end
  ) as $v
| {lines: (["BOUNDARY=\($boundary)"] + $listing + [$v.verdict_line]), exit: $v.exit, bad: $in.bad}
'

REPORT="$(jq -c --argjson n "$N" "$REPORT_PROG" <<<"$RESULT")"
check_rc "$?"

BAD="$(jq -r '.bad' <<<"$REPORT")"
check_rc "$?"
EXIT_CODE="$(jq -r '.exit' <<<"$REPORT")"
check_rc "$?"

LINES_OUT="$(jq -r '.lines[]' <<<"$REPORT")"
check_rc "$?"
printf '%s\n' "$LINES_OUT"

if [[ "$BAD" -gt 0 ]]; then
  echo "warning: skipped $BAD malformed line(s)" >&2
fi

exit "$EXIT_CODE"
