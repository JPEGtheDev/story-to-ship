#!/usr/bin/env bash
# run-scenario.sh -- performs or prints the mechanical steps for one DoD
# fixture scenario: which Definition of Done document (canon) fixture to
# place at docs/DOD.md, where to find the request or claim text to feed
# the dispatched agent skill, and how to invoke check-markers.sh against
# the transcript afterward.
#
# This script does NOT dispatch the agent skill itself -- that requires an
# actual agent session, and every dispatch is a spend-bearing operation
# (get the user's explicit consent first; see README.md Section 4). It
# only does the file-system setup (or prints it, if no worktree is given)
# and prints the remaining manual steps. Pass --check to also run
# check-markers.sh against a transcript you already captured.
#
# Usage:
#   run-scenario.sh --list
#   run-scenario.sh <scenario> [--worktree <path>] [--check <transcript-file>]
#   run-scenario.sh --help

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
CHECK_MARKERS="$SCRIPT_DIR/check-markers.sh"

SCENARIOS="violating-story compliant-story no-canon-fallback story-stale-tampered evidence-missing evidence-complete completion-stale-tampered delta-reratification"

usage() {
  cat <<'EOF'
Usage:
  run-scenario.sh --list
  run-scenario.sh <scenario> [--worktree <path>] [--check <transcript-file>]
  run-scenario.sh --help

<scenario> is one of:
  violating-story             story-generator refusal (story-request-scenarios.md Case A)
  compliant-story              story-generator negative control (story-request-scenarios.md Case B)
  no-canon-fallback             story-generator, no docs/DOD.md present (story-request-scenarios.md Case C)
  story-stale-tampered          story-generator, stale + tampered document (story-request-scenarios.md Case D)
  evidence-missing               completion-gate failure (completion-claim-scenarios.md Case A)
  evidence-complete               completion-gate negative control (completion-claim-scenarios.md Case B)
  completion-stale-tampered       completion-gate, stale + tampered document (completion-claim-scenarios.md Case C)
  delta-reratification             defining-done delta re-ratification interview (no marker check -- see below)

--worktree <path>   an existing scratch git working copy of this repo. If
                    given, the scenario's Definition of Done document is
                    copied to <path>/docs/DOD.md (or, for no-canon-fallback,
                    <path>/docs/DOD.md is removed if present). If omitted,
                    the script prints the cp/rm command instead of running it.

--check <file>      a transcript file you already captured from dispatching
                    the agent skill. Runs check-markers.sh against it with
                    this scenario's --require/--forbid set. delta-reratification
                    has no marker check -- its correctness is read directly
                    from the transcript (only the new/changed layers should
                    be asked about; every prior ruling must be left
                    byte-identical) -- so --check is rejected for it.

Every invocation is a dry run unless --worktree and/or --check are given:
with neither flag, the script only prints the steps for the named scenario.
EOF
}

list_scenarios() {
  for s in $SCENARIOS; do
    echo "$s"
  done
}

fail() {
  echo "run-scenario.sh: $*" >&2
  exit 2
}

if [[ $# -lt 1 ]]; then
  usage >&2
  exit 2
fi

case "$1" in
  --help|-h)
    usage
    exit 0
    ;;
  --list)
    list_scenarios
    exit 0
    ;;
esac

SCENARIO="$1"
shift

known=0
for s in $SCENARIOS; do
  if [[ "$s" == "$SCENARIO" ]]; then
    known=1
    break
  fi
done
[[ "$known" -eq 1 ]] || fail "unknown scenario: $SCENARIO (run --list to see valid names)"

WORKTREE=""
CHECK_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --worktree)
      [[ $# -ge 2 ]] || fail "--worktree needs an argument"
      WORKTREE="$2"
      shift 2
      ;;
    --check)
      [[ $# -ge 2 ]] || fail "--check needs an argument"
      CHECK_FILE="$2"
      shift 2
      ;;
    *)
      fail "unknown flag: $1"
      ;;
  esac
done

# Per-scenario: which document fixture (empty = no document, i.e. remove
# docs/DOD.md instead of placing one), where the request/claim text lives,
# and the check-markers.sh require/forbid arguments.
DOC_FIXTURE=""
DOC_IS_VARIANT=0
VARIANT_SOURCE=""
VARIANT_SENTINEL=""
REQUEST_SOURCE=""
declare -a CHECK_ARGS=()

case "$SCENARIO" in
  violating-story)
    DOC_FIXTURE="$SCRIPT_DIR/story-request-canon.md"
    REQUEST_SOURCE="story-request-scenarios.md, Case A"
    CHECK_ARGS=(--require 'DOD-VIOLATION:')
    ;;
  compliant-story)
    DOC_FIXTURE="$SCRIPT_DIR/story-request-canon.md"
    REQUEST_SOURCE="story-request-scenarios.md, Case B"
    CHECK_ARGS=(--forbid 'DOD-VIOLATION:')
    ;;
  no-canon-fallback)
    DOC_FIXTURE=""
    REQUEST_SOURCE="story-request-scenarios.md, Case C"
    CHECK_ARGS=(--forbid 'DOD-VIOLATION:')
    ;;
  story-stale-tampered)
    DOC_IS_VARIANT=1
    VARIANT_SOURCE="$SCRIPT_DIR/story-request-scenarios.md"
    VARIANT_SENTINEL="STALE-TAMPERED-CANON"
    REQUEST_SOURCE="story-request-scenarios.md, Case D (dispatch either Case A or Case B's request text)"
    CHECK_ARGS=(--require 'DOD-STALE: canon v' --require 'DOD-HASH: MISMATCH')
    ;;
  evidence-missing)
    DOC_FIXTURE="$SCRIPT_DIR/completion-claim-canon.md"
    REQUEST_SOURCE="completion-claim-scenarios.md, Case A"
    CHECK_ARGS=(--require 'DOD-GATE: FAIL')
    ;;
  evidence-complete)
    DOC_FIXTURE="$SCRIPT_DIR/completion-claim-canon.md"
    REQUEST_SOURCE="completion-claim-scenarios.md, Case B"
    CHECK_ARGS=(--forbid 'DOD-GATE: FAIL')
    ;;
  completion-stale-tampered)
    DOC_IS_VARIANT=1
    VARIANT_SOURCE="$SCRIPT_DIR/completion-claim-scenarios.md"
    VARIANT_SENTINEL="STALE-TAMPERED-CANON"
    REQUEST_SOURCE="completion-claim-scenarios.md, Case C (dispatch either Case A or Case B's claim text)"
    CHECK_ARGS=(--require 'DOD-STALE: canon v' --require 'DOD-HASH: MISMATCH')
    ;;
  delta-reratification)
    DOC_FIXTURE="$SCRIPT_DIR/delta-reratification-canon.md"
    REQUEST_SOURCE="dispatch the defining-done skill's re-ratification interview against delta-reratification-taxonomy-v2.md, with delta-reratification-canon.md already ratified against delta-reratification-taxonomy-v1.md"
    if [[ -n "$CHECK_FILE" ]]; then
      fail "delta-reratification has no marker check -- omit --check and read the transcript directly (only the new/changed layers should be asked about; every prior ruling must stay byte-identical)"
    fi
    ;;
esac

echo "Scenario: $SCENARIO"
echo

# Step 1: materialize the variant document, if this scenario uses one.
MATERIALIZED=""
if [[ "$DOC_IS_VARIANT" -eq 1 ]]; then
  MATERIALIZED="/tmp/$(basename "$VARIANT_SOURCE" .md)-$VARIANT_SENTINEL.md"
  EXTRACT_CMD="awk '/^<!-- ${VARIANT_SENTINEL}:BEGIN -->\$/{f=1;next}/^<!-- ${VARIANT_SENTINEL}:END -->\$/{f=0}f' '$VARIANT_SOURCE' > '$MATERIALIZED'"
  echo "Step 1: materialize the variant document."
  echo "  $EXTRACT_CMD"
  eval "$EXTRACT_CMD"
  echo "  (done -- wrote $MATERIALIZED)"
  DOC_FIXTURE="$MATERIALIZED"
fi

# Step 2: place (or remove) docs/DOD.md in the run worktree.
if [[ -n "$WORKTREE" ]]; then
  [[ -d "$WORKTREE" ]] || fail "--worktree path does not exist: $WORKTREE"
  mkdir -p "$WORKTREE/docs"
  if [[ -n "$DOC_FIXTURE" ]]; then
    cp "$DOC_FIXTURE" "$WORKTREE/docs/DOD.md"
    echo "Step 2: placed $DOC_FIXTURE at $WORKTREE/docs/DOD.md"
  else
    rm -f "$WORKTREE/docs/DOD.md"
    echo "Step 2: removed $WORKTREE/docs/DOD.md (this scenario runs with no document present)"
  fi
else
  if [[ -n "$DOC_FIXTURE" ]]; then
    echo "Step 2: in your scratch worktree, run:"
    echo "  cp '$DOC_FIXTURE' <worktree>/docs/DOD.md"
  else
    echo "Step 2: in your scratch worktree, confirm no file exists at docs/DOD.md (this scenario runs with no document present):"
    echo "  rm -f <worktree>/docs/DOD.md"
  fi
fi
echo

# Step 3: name the request/claim text to feed the dispatched agent.
echo "Step 3: dispatch the agent skill with the request or claim text from:"
echo "  $REQUEST_SOURCE"
echo "  Capture its full output to a transcript file."
echo

# Step 4: check the captured transcript, if given.
if [[ "$SCENARIO" == "delta-reratification" ]]; then
  echo "Step 4: this scenario has no marker check. Read the captured transcript"
  echo "  directly and confirm only the taxonomy's new/changed layers were asked"
  echo "  about, and every prior ruling was left byte-identical."
  exit 0
fi

if [[ -n "$CHECK_FILE" ]]; then
  echo "Step 4: running check-markers.sh against $CHECK_FILE"
  "$CHECK_MARKERS" "$CHECK_FILE" "${CHECK_ARGS[@]}"
  exit $?
else
  echo "Step 4: once you have a transcript, run:"
  printf '  %s <transcript-file>' "$CHECK_MARKERS"
  i=0
  for a in "${CHECK_ARGS[@]}"; do
    if (( i % 2 == 0 )); then
      printf ' %s' "$a"
    else
      printf " '%s'" "$a"
    fi
    i=$((i + 1))
  done
  echo
fi
