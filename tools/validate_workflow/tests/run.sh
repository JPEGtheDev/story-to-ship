#!/bin/sh
# Test suite for tools/validate_workflow/run.sh.
# Each case builds a throwaway git repository: a commit on branch "base" holding
# the real validate.yml and checks.list (unless the case removes one), then a
# commit on branch "head" with one change. run.sh runs against that repository
# and the case checks the exit code and the FINDING id in its output.
# Run from anywhere: sh tools/validate_workflow/tests/run.sh
# Exit: 0 only when every case ran and passed; 1 on any failed case or a wrong
# case count; 2 when the temporary directory cannot be made.

HERE=$(cd "$(dirname "$0")" && pwd)
REPO=$(cd "$HERE/../../.." && pwd)
RUN="$REPO/tools/validate_workflow/run.sh"
REAL_WF="$REPO/.github/workflows/validate.yml"
SIZE_STEP="Enforce size cap on core skills"
SIZE_FILE="skills/honesty/SKILL.md"
EXPECTED_CASES=16

TMP=$(mktemp -d) || exit 2
trap 'rm -rf "$TMP"' EXIT
CASES=0
FAILS=0

# Adds one probe step before the first named step; used by the new-step cases.
ADD_STEP_AWK='
  !added && /^      - name: / {
    print "      - name: Probe new step"
    print "        run: |"
    print "          echo probe"
    print ""
    added = 1
  }
  { print }'

# commit_all REPO MESSAGE: stage everything and commit, allowing an empty commit.
commit_all() {
  git -C "$1" add -A &&
    git -C "$1" -c user.name=test -c user.email=test@example.invalid \
      -c commit.gpgsign=false commit -q --allow-empty -m "$2"
}

# set_content FILE: replace FILE with standard input, staged through a temp file.
set_content() {
  cat > "$TMP/edit.tmp" && mv "$TMP/edit.tmp" "$1"
}

# make_list WORKFLOW: print a complete checks.list for every step in WORKFLOW.
# The size step gets its five covers lines and one proof line; every other step
# gets a pending line citing #455.
make_list() {
  grep -E '^      - name: ' "$1" | sed 's/^      - name: //' | while IFS= read -r name; do
    printf 'step\t%s\n' "$name"
    if [ "$name" = "$SIZE_STEP" ]; then
      for path in skills/honesty/SKILL.md skills/communication/SKILL.md \
        skills/subagent-driven-development/SKILL.md skills/two-stage-review/SKILL.md \
        skills/running-a-sprint/SKILL.md; do
        printf 'covers\t%s\t%s\n' "$name" "$path"
      done
      printf 'proof\t%s\t-\t%s\toversize\texceeding the 20000-character limit\n' \
        "$name" "$SIZE_FILE"
    else
      printf 'pending\t%s\tcoverage debt #455\n' "$name"
    fi
  done
}

# make_base REPO WITH_LIST: base commit on branch base holding the real workflow
# and, when WITH_LIST is 1, a complete checks.list.
make_base() {
  mkdir -p "$1/.github/workflows" "$1/tools/validate_workflow"
  git -C "$1" init -q && git -C "$1" symbolic-ref HEAD refs/heads/base || return 1
  cp "$REAL_WF" "$1/.github/workflows/validate.yml"
  if [ "$2" = 1 ]; then
    make_list "$1/.github/workflows/validate.yml" > "$1/tools/validate_workflow/checks.list"
  fi
  commit_all "$1" "base"
}

# use_head REPO: create branch head at the current base commit.
use_head() {
  git -C "$1" checkout -q -b head
}

# check_run LABEL REPO EXPECT_RC FINDING: run run.sh against REPO and report
# PASS or FAIL. FINDING is an id such as R1, or - to check the exit code only.
check_run() {
  CASES=$((CASES + 1))
  out="$TMP/run$CASES.out"
  env -u VALIDATE_WORKFLOW_INNER VALIDATE_WORKFLOW_ROOT="$2" VALIDATE_WORKFLOW_BASE=base \
    sh "$RUN" > "$out" 2>&1
  rc=$?
  bad=0
  if [ "$rc" -ne "$3" ]; then
    echo "FAIL: $1: exit $rc, expected $3"
    bad=1
  fi
  if [ "$4" != "-" ] && ! grep -F "FINDING $4" "$out" > /dev/null; then
    echo "FAIL: $1: no FINDING $4 line in output"
    bad=1
  fi
  if [ "$bad" -eq 0 ]; then
    echo "PASS: $1"
  else
    FAILS=$((FAILS + 1))
    sed -n '1,3p' "$out" | sed 's/^/  | /'
  fi
}

# Case a: control. Head equals base and the list holds an entry for every step.
# Arrange
repo="$TMP/a"
make_base "$repo" 1
use_head "$repo"
# Act
commit_all "$repo" "head: no change"
# Assert
check_run "a control" "$repo" 0 -

# Case b: a base step removed from the head workflow.
# Arrange
repo="$TMP/b"
make_base "$repo" 1
use_head "$repo"
wf="$repo/.github/workflows/validate.yml"
# Act
awk -v t="Hook script smoke test" '
  /^      - / || /^  [A-Za-z]/ { skip = ($0 == "      - name: " t) }
  !skip { print }
' "$wf" | set_content "$wf"
commit_all "$repo" "head: drop a step"
# Assert
check_run "b step removed" "$repo" 1 R1

# Case c: a covers path dropped from the size step's for line.
# Arrange
repo="$TMP/c"
make_base "$repo" 1
use_head "$repo"
wf="$repo/.github/workflows/validate.yml"
# Act
awk '/for f in skills\/honesty\/SKILL\.md / { sub(/skills\/honesty\/SKILL\.md /, "") } { print }' \
  "$wf" | set_content "$wf"
commit_all "$repo" "head: drop covers path from for line"
# Assert
check_run "c covers path dropped" "$repo" 1 R1

# Case d: a covers path left only on a comment line inside the size step.
# Arrange
repo="$TMP/d"
make_base "$repo" 1
use_head "$repo"
wf="$repo/.github/workflows/validate.yml"
# Act
awk -v s="$SIZE_STEP" '
  /for f in skills\/honesty\/SKILL\.md / { sub(/skills\/honesty\/SKILL\.md /, "") }
  $0 == "      - name: " s { armed = 1 }
  { print }
  armed && $0 == "          set -e" { print "          # skills/honesty/SKILL.md"; armed = 0 }
' "$wf" | set_content "$wf"
commit_all "$repo" "head: covers path on a comment only"
# Assert
check_run "d covers path on comment only" "$repo" 1 R1

# Case e: a base proof entry downgraded to pending in head.
# Arrange
repo="$TMP/e"
make_base "$repo" 1
use_head "$repo"
list="$repo/tools/validate_workflow/checks.list"
# Act
awk -v s="$SIZE_STEP" 'BEGIN { FS = OFS = "\t" }
  $1 == "proof" && $2 == s { $0 = "pending" OFS $2 OFS "coverage debt #455" }
  { print }
' "$list" | set_content "$list"
commit_all "$repo" "head: proof downgraded to pending"
# Assert
check_run "e proof downgraded" "$repo" 1 R1

# Case f1: a head step with a proof entry and no step entry.
# Arrange
repo="$TMP/f1"
make_base "$repo" 1
use_head "$repo"
wf="$repo/.github/workflows/validate.yml"
list="$repo/tools/validate_workflow/checks.list"
# Act
awk "$ADD_STEP_AWK" "$wf" | set_content "$wf"
printf 'proof\tProbe new step\t-\t%s\toversize\texceeding the 20000-character limit\n' \
  "$SIZE_FILE" >> "$list"
commit_all "$repo" "head: add a step with a proof entry and no step entry"
# Assert
check_run "f1 new step with proof, no step entry" "$repo" 1 R3

# Case f2: a new head step with a step entry and neither a proof nor a pending entry.
# Arrange
repo="$TMP/f2"
make_base "$repo" 1
use_head "$repo"
wf="$repo/.github/workflows/validate.yml"
list="$repo/tools/validate_workflow/checks.list"
# Act
awk "$ADD_STEP_AWK" "$wf" | set_content "$wf"
printf 'step\tProbe new step\n' >> "$list"
commit_all "$repo" "head: add a step with a step entry only"
# Assert
check_run "f2 new step with step entry only" "$repo" 1 R3

# Case f3: a new head step with a step entry, a proof entry and a pending entry.
# Arrange
repo="$TMP/f3"
make_base "$repo" 1
use_head "$repo"
wf="$repo/.github/workflows/validate.yml"
list="$repo/tools/validate_workflow/checks.list"
# Act
awk "$ADD_STEP_AWK" "$wf" | set_content "$wf"
printf 'step\tProbe new step\nproof\tProbe new step\t-\t%s\toversize\texceeding the 20000-character limit\npending\tProbe new step\tcoverage debt #455\n' \
  "$SIZE_FILE" >> "$list"
commit_all "$repo" "head: add a step with a proof and a pending entry"
# Assert
check_run "f3 new step with proof and pending" "$repo" 1 R3

# Case g: a new head step with a step entry, a proof entry and a pending entry.
# The only R3 cause is the pending entry; this case also pins the pending branch.
# Arrange
repo="$TMP/g"
make_base "$repo" 1
use_head "$repo"
wf="$repo/.github/workflows/validate.yml"
list="$repo/tools/validate_workflow/checks.list"
# Act
awk "$ADD_STEP_AWK" "$wf" | set_content "$wf"
printf 'step\tProbe new step\nproof\tProbe new step\t-\t%s\toversize\texceeding the 20000-character limit\npending\tProbe new step\tcoverage debt #455\n' \
  "$SIZE_FILE" >> "$list"
commit_all "$repo" "head: add a step with a pending entry and a proof entry"
# Assert
check_run "g new step with pending and proof" "$repo" 1 R3

# Case h: a list entry naming a step absent from head.
# Arrange
repo="$TMP/h"
make_base "$repo" 1
use_head "$repo"
list="$repo/tools/validate_workflow/checks.list"
# Act
printf 'step\tGhost step that is gone\n' >> "$list"
commit_all "$repo" "head: list entry for an absent step"
# Assert
check_run "h list entry for absent step" "$repo" 1 R5

# Case i: a pending reason with no #<digits>.
# Arrange
repo="$TMP/i"
make_base "$repo" 1
use_head "$repo"
list="$repo/tools/validate_workflow/checks.list"
# Act
awk 'BEGIN { FS = OFS = "\t" }
  $1 == "pending" && $2 == "Hook script smoke test" { $3 = "coverage debt" }
  { print }
' "$list" | set_content "$list"
commit_all "$repo" "head: pending reason without an issue number"
# Assert
check_run "i pending reason without digits" "$repo" 1 R2

# Case j: a malformed list line (empty step name).
# Arrange
repo="$TMP/j"
make_base "$repo" 1
use_head "$repo"
list="$repo/tools/validate_workflow/checks.list"
# Act
awk 'BEGIN { FS = OFS = "\t" }
  $1 == "step" && $2 == "Hook script smoke test" { $2 = "" }
  { print }
' "$list" | set_content "$list"
commit_all "$repo" "head: malformed list line"
# Assert
check_run "j malformed list line" "$repo" 2 -

# Case k: absent base checks.list is treated as empty; head holds a complete list.
# Arrange
repo="$TMP/k"
make_base "$repo" 0
use_head "$repo"
wf="$repo/.github/workflows/validate.yml"
list="$repo/tools/validate_workflow/checks.list"
# Act
make_list "$wf" > "$list"
commit_all "$repo" "head: add a complete list"
# Assert
check_run "k absent base list" "$repo" 0 -

# Case l: absent base workflow.
# Arrange
repo="$TMP/l"
mkdir -p "$repo"
git -C "$repo" init -q && git -C "$repo" symbolic-ref HEAD refs/heads/base
printf 'readme\n' > "$repo/README.md"
commit_all "$repo" "base: no workflow"
use_head "$repo"
wf="$repo/.github/workflows/validate.yml"
list="$repo/tools/validate_workflow/checks.list"
# Act
mkdir -p "$repo/.github/workflows" "$repo/tools/validate_workflow"
cp "$REAL_WF" "$wf"
make_list "$wf" > "$list"
commit_all "$repo" "head: add workflow and list"
# Assert
check_run "l absent base workflow" "$repo" 2 -

# Case m: a dash line that is neither "name:" nor "uses:" in the steps.
# Arrange
repo="$TMP/m"
make_base "$repo" 1
use_head "$repo"
wf="$repo/.github/workflows/validate.yml"
# Act
awk '!added && /^      - / { print "      - run: echo stray"; added = 1 } { print }' \
  "$wf" | set_content "$wf"
commit_all "$repo" "head: stray step line"
# Assert
check_run "m stray dash line" "$repo" 2 -

# Case n: a base covers entry dropped from the head list while the head workflow keeps the path.
# Arrange
repo="$TMP/n"
make_base "$repo" 1
use_head "$repo"
list="$repo/tools/validate_workflow/checks.list"
# Act
awk -v s="$SIZE_STEP" -v p="$SIZE_FILE" 'BEGIN { FS = OFS = "\t" }
  $1 == "covers" && $2 == s && $3 == p { next }
  { print }
' "$list" | set_content "$list"
commit_all "$repo" "head: covers line dropped from the list"
# Assert
check_run "n covers list entry dropped" "$repo" 1 R1

if [ "$CASES" -ne "$EXPECTED_CASES" ]; then
  echo "FAIL: suite: ran $CASES cases, expected $EXPECTED_CASES"
  FAILS=$((FAILS + 1))
fi
echo "CASES RUN: $CASES; FAILED: $FAILS"
if [ "$FAILS" -ne 0 ] || [ "$CASES" -eq 0 ]; then
  exit 1
fi
exit 0
