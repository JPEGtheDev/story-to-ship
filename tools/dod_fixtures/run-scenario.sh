#!/usr/bin/env bash
# run-scenario.sh -- performs or prints the mechanical steps for one
# Definition of Done (DoD) fixture scenario: which DoD document (canon)
# fixture to place at docs/DOD.md, where to find the request or claim
# text to feed the dispatched agent skill, and how to invoke
# check-markers.sh against the transcript afterward.
#
# This script does NOT dispatch the agent skill itself -- that requires an
# actual agent session, and every dispatch is a spend-bearing operation
# (get the user's explicit consent first; see README.md Section 4). It
# only does the file-system setup (or prints it, if no worktree is given)
# and prints the remaining manual steps. Pass --check to also run
# check-markers.sh against a transcript you already captured. Two
# scenarios, dirty-canon and malformed-canon, additionally create one
# baseline commit inside the scratch worktree and then apply a pinned
# mutation on top of it (or, if no worktree is given, print those
# commands instead of running them) -- see their case entries below.
#
# Usage:
#   run-scenario.sh --list
#   run-scenario.sh <scenario> [--worktree <path>] [--check <transcript-file>]
#   run-scenario.sh --help

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
CHECK_MARKERS="$SCRIPT_DIR/check-markers.sh"

SCENARIOS="violating-story compliant-story no-canon-fallback story-stale-canon evidence-missing evidence-complete completion-stale-canon delta-reratification dirty-canon malformed-canon"

usage() {
  cat <<'EOF'
Usage:
  run-scenario.sh --list
  run-scenario.sh <scenario> [--worktree <path>] [--check <transcript-file>]
  run-scenario.sh --help

<scenario> is one of:
  violating-story         story-generator refusal (story-request-scenarios.md Case A)
  compliant-story         story-generator negative control (story-request-scenarios.md Case B)
  no-canon-fallback       story-generator, no docs/DOD.md present (story-request-scenarios.md Case C)
  story-stale-canon       story-generator, stale document (story-request-scenarios.md Case D)
  evidence-missing        completion-gate failure (completion-claim-scenarios.md Case A)
  evidence-complete       completion-gate negative control (completion-claim-scenarios.md Case B; forbid-only screen -- see below)
  completion-stale-canon  completion-gate, stale document (completion-claim-scenarios.md Case C)
  delta-reratification    defining-done delta re-ratification interview (no marker check -- see below)
  dirty-canon             completion-gate, uncommitted canon edit (completion-claim-scenarios.md Case B; no marker expected -- see below)
  malformed-canon         completion-gate, unparseable canon (completion-claim-scenarios.md Case B; missing Stamp: line -- see below)

--worktree <path>   an existing scratch git working copy of this repo. If
                    given, the scenario's Definition of Done document is
                    copied to <path>/docs/DOD.md (or, for no-canon-fallback,
                    <path>/docs/DOD.md is removed if present). If omitted,
                    the script prints the cp/rm command instead of running it.
                    For dirty-canon and malformed-canon, the script
                    additionally commits the placed document inside <path>
                    and then applies that scenario's own pinned uncommitted
                    edit on top of it (or, if --worktree is omitted, prints
                    those commands instead of running them); dirty-canon
                    edits an unrelated line, malformed-canon deletes the
                    terminal Stamp: line. Both refuse to run at all against
                    <path> when <path> is this repository's own working
                    copy or a linked worktree of it, since either would
                    leave a real uncommitted edit in a repo the scenario
                    does not own.

--check <file>      a transcript file you already captured from dispatching
                    the agent skill. Runs check-markers.sh against it with
                    this scenario's --require/--forbid set. delta-reratification
                    has no marker check -- its correctness is read directly
                    from the transcript (only the new/changed layers should
                    be asked about; every prior ruling must be left
                    byte-identical) -- so --check is rejected for it.
                    evidence-complete's set is a single
                    --forbid 'DOD-GATE: FAIL' -- necessary but not
                    sufficient on its own: if it fails, read the emitted
                    line's stated reason before ruling a real finding vs.
                    a legitimate grounding-driven failure (see README.md
                    Section 3). dirty-canon's set is three --forbid
                    literals and no --require -- a negative control that
                    is necessary but not sufficient; its positive pass
                    condition is a transcript read (see README.md
                    Section 3), and its DOD-GATE: FAIL forbid carries the
                    same grounding-driven caveat as evidence-complete's.
                    malformed-canon's set is one --require and three
                    --forbid literals: --require 'DOD-MALFORMED:' (the
                    consumer's refusal marker for an unparseable canon)
                    plus --forbid on all three verdict markers
                    (DOD-VIOLATION:, DOD-GATE: FAIL, DOD-STALE: canon v),
                    since a consumer that refuses to evaluate the canon
                    must not also emit a verdict from evaluating it. This
                    check is close to a full pass condition on its own --
                    unlike evidence-complete and dirty-canon, malformed-canon
                    has no grounding-driven caveat on its DOD-GATE: FAIL
                    forbid, since a correctly-refusing consumer never
                    reaches evidence evaluation at all.

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

# Step 2b proof functions -- one per mutating scenario, each asserting on
# a command's exit status or exact output (never on emptiness alone), so
# a mutation that silently failed to apply is a hard script failure
# rather than a scenario that quietly runs against unmutated state. Each
# takes the target worktree path as its only argument. Add a new
# scenario's own proof function here without touching the shared Step 2b
# flow below.
proof_dirty_canon() {
  local wt="$1" numstat diff_text
  numstat="$(git -C "$wt" diff --numstat -- docs/DOD.md)"
  [[ "$numstat" == $'1\t1\tdocs/DOD.md' ]] || fail "induced-state proof failed: expected 'git diff --numstat -- docs/DOD.md' to read exactly '1<TAB>1<TAB>docs/DOD.md', got: $numstat"
  diff_text="$(git -C "$wt" diff -- docs/DOD.md)"
  [[ "$diff_text" == *"(edited locally)"* ]] || fail "induced-state proof failed: 'git diff -- docs/DOD.md' does not contain '(edited locally)'"
  echo "Step 2b: induced-state proof -- numstat: $numstat"
}

proof_malformed_canon() {
  local wt="$1"
  if grep -q '^Stamp:' "$wt/docs/DOD.md"; then
    fail "induced-state proof failed: expected no line starting with 'Stamp:' in $wt/docs/DOD.md after mutation, but found one"
  fi
  echo "Step 2b: induced-state proof -- confirmed no line in $wt/docs/DOD.md starts with 'Stamp:'"
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
MUTATE_AFTER_PLACE=0
MUTATION_SED=""
MUTATION_DESC=""
MUTATION_PROOF_FN=""
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
  story-stale-canon)
    DOC_IS_VARIANT=1
    VARIANT_SOURCE="$SCRIPT_DIR/story-request-scenarios.md"
    VARIANT_SENTINEL="STALE-CANON"
    REQUEST_SOURCE="story-request-scenarios.md, Case D (dispatch either Case A or Case B's request text)"
    CHECK_ARGS=(--require 'DOD-STALE: canon v')
    ;;
  evidence-missing)
    DOC_FIXTURE="$SCRIPT_DIR/completion-claim-canon.md"
    REQUEST_SOURCE="completion-claim-scenarios.md, Case A"
    CHECK_ARGS=(--require 'DOD-GATE: FAIL')
    ;;
  evidence-complete)
    DOC_FIXTURE="$SCRIPT_DIR/completion-claim-canon.md"
    REQUEST_SOURCE="completion-claim-scenarios.md, Case B"
    # Forbid-only screen: a FAIL here needs a transcript read to rule out
    # a legitimate grounding-driven failure before it counts as a real
    # finding -- see README.md Section 3.
    CHECK_ARGS=(--forbid 'DOD-GATE: FAIL')
    ;;
  completion-stale-canon)
    DOC_IS_VARIANT=1
    VARIANT_SOURCE="$SCRIPT_DIR/completion-claim-scenarios.md"
    VARIANT_SENTINEL="STALE-CANON"
    REQUEST_SOURCE="completion-claim-scenarios.md, Case C (dispatch either Case A or Case B's claim text)"
    CHECK_ARGS=(--require 'DOD-STALE: canon v')
    ;;
  delta-reratification)
    DOC_FIXTURE="$SCRIPT_DIR/delta-reratification-canon.md"
    REQUEST_SOURCE="dispatch the defining-done skill's re-ratification interview against delta-reratification-taxonomy-v2.md, with delta-reratification-canon.md already ratified against delta-reratification-taxonomy-v1.md"
    if [[ -n "$CHECK_FILE" ]]; then
      fail "delta-reratification has no marker check -- omit --check and read the transcript directly (only the new/changed layers should be asked about; every prior ruling must stay byte-identical)"
    fi
    ;;
  dirty-canon)
    DOC_FIXTURE="$SCRIPT_DIR/completion-claim-canon.md"
    REQUEST_SOURCE="completion-claim-scenarios.md, Case B"
    MUTATE_AFTER_PLACE=1
    MUTATION_SED='s/backend parcel-routing service/backend parcel-routing service (edited locally)/'
    MUTATION_DESC="applied an uncommitted local edit to docs/DOD.md"
    MUTATION_PROOF_FN=proof_dirty_canon
    # Forbid-only screen (necessary, not sufficient -- see README.md
    # Section 3): the DOD-GATE: FAIL forbid carries the same
    # grounding-driven caveat as evidence-complete's; the other two
    # forbids have no such caveat. The scenario's actual pass condition
    # is a transcript read for the uncommitted-edit disclosure.
    CHECK_ARGS=(--forbid 'DOD-VIOLATION:' --forbid 'DOD-GATE: FAIL' --forbid 'DOD-STALE: canon v')
    ;;
  malformed-canon)
    DOC_FIXTURE="$SCRIPT_DIR/completion-claim-canon.md"
    REQUEST_SOURCE="completion-claim-scenarios.md, Case B"
    MUTATE_AFTER_PLACE=1
    MUTATION_SED='/^Stamp: v1$/d'
    MUTATION_DESC="deleted the terminal 'Stamp: v1' line from docs/DOD.md"
    MUTATION_PROOF_FN=proof_malformed_canon
    # Require-plus-forbid (see README.md Section 3): a consumer that
    # refuses to evaluate an unparseable canon must not also emit a
    # verdict marker from evaluating it, so every verdict marker is
    # forbidden alongside the required refusal marker. No
    # grounding-driven caveat applies here (unlike evidence-complete and
    # dirty-canon): a correctly-refusing consumer never reaches evidence
    # evaluation, so a DOD-GATE: FAIL forbid failure here is always a
    # real finding.
    CHECK_ARGS=(--require 'DOD-MALFORMED:' --forbid 'DOD-VIOLATION:' --forbid 'DOD-GATE: FAIL' --forbid 'DOD-STALE: canon v')
    ;;
esac

echo "Scenario: $SCENARIO"
echo

# Step 1: materialize the variant document, if this scenario uses one.
MATERIALIZED=""
if [[ "$DOC_IS_VARIANT" -eq 1 ]]; then
  MATERIALIZED="$(mktemp --suffix=.md "/tmp/${VARIANT_SENTINEL}-XXXXXX")"
  AWK_PROGRAM="/^<!-- ${VARIANT_SENTINEL}:BEGIN -->\$/{f=1;next}/^<!-- ${VARIANT_SENTINEL}:END -->\$/{f=0}f"
  echo "Step 1: materialize the variant document."
  echo "  awk '$AWK_PROGRAM' '$VARIANT_SOURCE' > '$MATERIALIZED'"
  awk "$AWK_PROGRAM" "$VARIANT_SOURCE" > "$MATERIALIZED"
  [[ -s "$MATERIALIZED" ]] || fail "sentinel ${VARIANT_SENTINEL}:BEGIN/END not found in $VARIANT_SOURCE"
  echo "  (done -- wrote $MATERIALIZED)"
  DOC_FIXTURE="$MATERIALIZED"
fi

# Guard: any scenario with MUTATE_AFTER_PLACE=1 (currently dirty-canon,
# malformed-canon) commits to and then mutates docs/DOD.md in whatever
# worktree it targets, so refuse to run it against this repository's own
# working copy or a linked worktree of it -- either would leave real,
# unintended commit and edit state behind in a repo the scenario does not
# own. This must run before Step 2's cp touches anything. The case
# statement above (which sets each scenario's MUTATE_AFTER_PLACE flag and
# MUTATION_* variables) always runs before this guard, since it appears
# earlier in the script -- checking the flag directly here, rather than a
# separate name list, means a future mutating scenario cannot forget to
# arm the guard: the same case arm that defines the mutation also arms it.
if [[ "$MUTATE_AFTER_PLACE" -eq 1 && -n "$WORKTREE" ]]; then
  [[ -d "$WORKTREE" ]] || fail "--worktree path does not exist: $WORKTREE"
  TARGET_GIT_COMMON_DIR="$(git -C "$WORKTREE" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
  SELF_GIT_COMMON_DIR="$(git -C "$SCRIPT_DIR" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
  if [[ -z "$TARGET_GIT_COMMON_DIR" ]]; then
    fail "refusing to run $SCENARIO against $WORKTREE: it is not a git repository (git -C '$WORKTREE' rev-parse --git-common-dir found none). $SCENARIO needs an unrelated scratch git repository to commit the placed canon into -- run 'git init' there first."
  fi
  if [[ "$TARGET_GIT_COMMON_DIR" == "$SELF_GIT_COMMON_DIR" ]]; then
    fail "refusing to run $SCENARIO against $WORKTREE: it shares this repository's own git-common-dir ($SELF_GIT_COMMON_DIR), so it is this repository's own working copy or a linked worktree of it. $SCENARIO commits to and mutates docs/DOD.md in its target -- point --worktree at an unrelated scratch git repository instead."
  fi
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

# Step 2b: for any scenario with MUTATE_AFTER_PLACE=1 (currently
# dirty-canon, malformed-canon), commit the placed canon as a baseline
# and then apply that scenario's own pinned uncommitted edit on top of
# it, so
# the scenario starts from a real ratified baseline with one deliberate
# uncommitted mutation -- the same shape the completion-gate consumer's
# warn-and-continue and malformed-canon-refusal rules are meant to
# handle. The edit command (MUTATION_SED), its description
# (MUTATION_DESC), and its proof function (MUTATION_PROOF_FN) are all set
# per-scenario in the case statement above; this shared block never
# changes when a new mutating scenario is added.
if [[ "$MUTATE_AFTER_PLACE" -eq 1 ]]; then
  if [[ -n "$WORKTREE" ]]; then
    if [[ -n "$(git -C "$WORKTREE" status --porcelain -- docs/DOD.md)" ]]; then
      git -C "$WORKTREE" add -- docs/DOD.md
      git -C "$WORKTREE" -c user.name=dod-fixture -c user.email=dod-fixture@invalid commit -q -m "test: canon baseline for $SCENARIO scenario" -- docs/DOD.md
      echo "Step 2b: committed the placed canon as a baseline in $WORKTREE"
    else
      echo "Step 2b: $WORKTREE/docs/DOD.md already matches its last commit (baseline already committed, skipping)"
    fi
    sed -i "$MUTATION_SED" "$WORKTREE/docs/DOD.md"
    echo "Step 2b: $MUTATION_DESC"
    "$MUTATION_PROOF_FN" "$WORKTREE"
  else
    echo "Step 2b: in your scratch worktree, commit the placed canon as a baseline (only if it is not already committed), then apply this scenario's pinned edit:"
    echo "  git add -- docs/DOD.md"
    echo "  git -c user.name=dod-fixture -c user.email=dod-fixture@invalid commit -m 'test: canon baseline for $SCENARIO scenario' -- docs/DOD.md"
    echo "  sed -i '$MUTATION_SED' docs/DOD.md"
  fi
  echo
fi

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
