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
EXPECTED_CASES=31

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

# Step block for the symlink probe: its run needs skills/honesty/LINK.md to be a link
# whose target is non-empty. The block is passed through ENVIRON, so it is not escaped.
PROBE_LINK_BLOCK='      - name: Probe symlink in the tree
        run: |
          test -L skills/honesty/LINK.md || { echo "LINK is not a link"; exit 1; }
          test -s skills/honesty/LINK.md || { echo "LINK target is empty"; exit 1; }'

# Step block for the frontmatter probe: its run reads the frontmatter of agents/implementer.md
# (up to the second line that is exactly ---) and prints INVALID FRONTMATTER VALUE for a line
# with a colon followed by a space after the key. Read through a heredoc, so it is not escaped.
PROBE_FM_BLOCK=$(cat <<'EOF'
      - name: Probe frontmatter values
        run: |
          awk 'NR == 1 && $0 != "---" { exit 1 } NR > 1 && $0 == "---" { exit 0 } /^[a-z-]+: .*: / { print "INVALID FRONTMATTER VALUE: " $0; exit 1 }' agents/implementer.md
EOF
)

# Step block for the replace probe: its run needs .claude/hooks/session-start.sh to be a link.
# The replace case turns the link into a regular file, so the probe prints "is not a symlink".
PROBE_REPLACE_BLOCK='      - name: Probe replaced symlink
        run: |
          test -L .claude/hooks/session-start.sh || { echo "session-start.sh is not a symlink"; exit 1; }'

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

# make_list WORKFLOW: print one step line for every step in WORKFLOW and nothing else.
make_list() {
  grep -E '^      - name: ' "$1" | sed 's/^      - name: //' | while IFS= read -r name; do
    printf 'step\t%s\n' "$name"
  done
}

# add_rows WORKFLOW WITH_PENDING: print the rows that complete a list made by make_list. The
# size step gets its seven covers lines and one proof line. When WITH_PENDING is 1, every other
# step also gets a pending line with a coverage debt reason; without it, no pending line is printed, so a
# head list written with add_rows holds none. A case that needs a complete list appends this
# output after make_list.
add_rows() {
  grep -E '^      - name: ' "$1" | sed 's/^      - name: //' | while IFS= read -r name; do
    if [ "$name" = "$SIZE_STEP" ]; then
      for path in skills/honesty/SKILL.md skills/communication/SKILL.md \
        skills/subagent-driven-development/SKILL.md skills/two-stage-review/SKILL.md \
        skills/running-a-sprint/SKILL.md skills/session-bootstrap/SKILL.md skills/sprint-close-out/SKILL.md; do
        printf 'covers\t%s\t%s\n' "$name" "$path"
      done
      printf 'proof\t%s\t-\t%s\toversize\texceeding the 20000-character limit\n' \
        "$name" "$SIZE_FILE"
    elif [ "${2:-}" = 1 ]; then
      printf 'pending\t%s\tcoverage debt\n' "$name"
    fi
  done
}

# copy_size_files REPO: copy the seven files the size step covers from the real
# repository into REPO, so the size step's control run can read them.
copy_size_files() {
  for path in skills/honesty/SKILL.md skills/communication/SKILL.md \
    skills/subagent-driven-development/SKILL.md skills/two-stage-review/SKILL.md \
    skills/running-a-sprint/SKILL.md skills/session-bootstrap/SKILL.md skills/sprint-close-out/SKILL.md; do
    mkdir -p "$1/$(dirname "$path")" && cp "$REPO/$path" "$1/$path" || return 1
  done
}

# make_base REPO WITH_LIST: base commit on branch base holding the real workflow,
# the size step's seven covered files and, when WITH_LIST is 1, a complete checks.list.
make_base() {
  mkdir -p "$1/.github/workflows" "$1/tools/validate_workflow"
  git -C "$1" init -q && git -C "$1" symbolic-ref HEAD refs/heads/base || return 1
  cp "$REAL_WF" "$1/.github/workflows/validate.yml"
  copy_size_files "$1" || return 1
  if [ "$2" = 1 ]; then
    make_list "$1/.github/workflows/validate.yml" > "$1/tools/validate_workflow/checks.list"
    add_rows "$1/.github/workflows/validate.yml" 1 >> "$1/tools/validate_workflow/checks.list"
  fi
  commit_all "$1" "base"
}

# use_head REPO: create branch head at the current base commit, then drop the pending lines
# from the working-tree checks.list, so the head list holds none. The Act commit of each case
# carries the dropped lines; the base commit keeps them.
use_head() {
  git -C "$1" checkout -q -b head || return 1
  head_list="$1/tools/validate_workflow/checks.list"
  if [ -f "$head_list" ]; then
    awk -F "$(printf '\t')" '$1 != "pending"' "$head_list" | set_content "$head_list"
  fi
}

# set_proof LIST STEP ENV TARGET MODE SUBSTRING: replace the pending or proof entry
# of STEP in LIST with a proof entry built from the arguments. When LIST holds neither
# for STEP, append one proof entry built from the arguments.
set_proof() {
  awk -v s="$2" -v e="$3" -v t="$4" -v m="$5" -v x="$6" 'BEGIN { FS = OFS = "\t" }
    ($1 == "pending" || $1 == "proof") && $2 == s { print "proof", s, e, t, m, x; done = 1; next }
    { print }
    END { if (!done) print "proof", s, e, t, m, x }
  ' "$1" | set_content "$1"
}

# check_run LABEL REPO EXPECT_RC FINDING [inner] [TEXT]: run run.sh against REPO and
# report PASS or FAIL. FINDING is an id such as R1, or - to check the exit code only.
# The optional fifth argument "inner" exports VALIDATE_WORKFLOW_INNER=1 to the
# suite; any other call (such as -) runs the suite with that variable unset.
# The optional sixth argument TEXT must appear as a fixed string in the combined
# stdout and stderr of the run.
check_run() {
  CASES=$((CASES + 1))
  out="$TMP/run$CASES.out"
  if [ "${5:-}" = inner ]; then
    env VALIDATE_WORKFLOW_INNER=1 VALIDATE_WORKFLOW_ROOT="$2" VALIDATE_WORKFLOW_BASE=base \
      sh "$RUN" > "$out" 2>&1
  else
    env -u VALIDATE_WORKFLOW_INNER VALIDATE_WORKFLOW_ROOT="$2" VALIDATE_WORKFLOW_BASE=base \
      sh "$RUN" > "$out" 2>&1
  fi
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
  if [ -n "${6:-}" ] && ! grep -F "$6" "$out" > /dev/null; then
    echo "FAIL: $1: output lacks '$6'"
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
  $1 == "proof" && $2 == s { $0 = "pending" OFS $2 OFS "coverage debt" }
  { print }
' "$list" | set_content "$list"
commit_all "$repo" "head: proof downgraded to pending"
# Assert
check_run "e proof downgraded" "$repo" 2 - - "malformed head checks.list"

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
add_rows "$wf" >> "$list"
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
copy_size_files "$repo"
make_list "$wf" > "$list"
add_rows "$wf" >> "$list"
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

# Case o: a step-level if key added to a check step.
# Arrange
repo="$TMP/o"
make_base "$repo" 1
use_head "$repo"
wf="$repo/.github/workflows/validate.yml"
# Act
awk '
  $0 == "      - name: Validate hooks.json" { print; print "        if: always()"; next }
  { print }
' "$wf" | set_content "$wf"
commit_all "$repo" "head: step-level if on a check step"
# Assert
check_run "R4 step-level if" "$repo" 1 R4

# Case p: a job-level continue-on-error key added under validate.
# Arrange
repo="$TMP/p"
make_base "$repo" 1
use_head "$repo"
wf="$repo/.github/workflows/validate.yml"
# Act
awk '
  $0 == "    runs-on: ubuntu-latest" { print; print "    continue-on-error: true"; next }
  { print }
' "$wf" | set_content "$wf"
commit_all "$repo" "head: job-level continue-on-error"
# Assert
check_run "R4 job-level continue-on-error" "$repo" 1 R4

# Case q: a paths filter added inside the on: block.
# Arrange
repo="$TMP/q"
make_base "$repo" 1
use_head "$repo"
wf="$repo/.github/workflows/validate.yml"
# Act
awk '
  !done && $0 == "  pull_request:" { print; print "    paths: [skills]"; done = 1; next }
  { print }
' "$wf" | set_content "$wf"
commit_all "$repo" "head: paths filter in the on block"
# Assert
check_run "R4 path filter in on block" "$repo" 1 R4

# Case r: the push trigger and its branches key removed from the on: block.
# Arrange
repo="$TMP/r"
make_base "$repo" 1
use_head "$repo"
wf="$repo/.github/workflows/validate.yml"
# Act
awk '
  $0 == "  push:" { skip = 1; next }
  skip && /^    / { next }
  { skip = 0; print }
' "$wf" | set_content "$wf"
commit_all "$repo" "head: remove the push trigger"
# Assert
check_run "R1 push trigger removed" "$repo" 1 R1

# Case s: a proof whose control run fails on the unmodified copy. The flaky-test
# step is pointed at a file absent from the tree, so its run block exits non-zero.
# Arrange
repo="$TMP/s"
make_base "$repo" 1
use_head "$repo"
list="$repo/tools/validate_workflow/checks.list"
# Act
set_proof "$list" "Check the flaky-test rules are pinned" \
  "FLAKY_TESTS_PATH=skills/testing/references/NO_SUCH.md" \
  skills/testing/references/FLAKY_TESTS.md empty "flaky-test rule pins"
commit_all "$repo" "head: proof whose control run fails"
# Assert
check_run "proof control fails" "$repo" 1 R2

# Case t: a proof whose target, emptied, prints output without the expected substring.
# The flaky-test step prints FAILED lines on an empty target, never the substring below.
# Arrange
repo="$TMP/t"
make_base "$repo" 1
mkdir -p "$repo/skills/testing/references" &&
  cp "$REPO/skills/testing/references/FLAKY_TESTS.md" "$repo/skills/testing/references/" &&
  cp "$REPO/skills/testing/SKILL.md" "$repo/skills/testing/" || exit 2
commit_all "$repo" "base: flaky-test step files"
use_head "$repo"
list="$repo/tools/validate_workflow/checks.list"
# Act
set_proof "$list" "Check the flaky-test rules are pinned" - \
  skills/testing/references/FLAKY_TESTS.md empty "UNPRINTED-SUBSTRING"
commit_all "$repo" "head: proof expected substring never printed"
# Assert
check_run "proof expected substring lost" "$repo" 1 R2 - \
  "did not fail with the expected output"

# Case u: the size step's oversize proof with the correct substring, restated explicitly.
# The step fails on the 20001-byte copy, so both the control and the must-fail run hold.
# Arrange
repo="$TMP/u"
make_base "$repo" 1
use_head "$repo"
list="$repo/tools/validate_workflow/checks.list"
# Act
set_proof "$list" "$SIZE_STEP" - "$SIZE_FILE" oversize "exceeding the 20000-character limit"
commit_all "$repo" "head: size proof restated"
# Assert
check_run "proof oversize mode passes" "$repo" 0 - - "PROOF ok: $SIZE_STEP"

# Case v: a proof whose expected substring is empty.
# Arrange
repo="$TMP/v"
make_base "$repo" 1
use_head "$repo"
list="$repo/tools/validate_workflow/checks.list"
# Act
set_proof "$list" "$SIZE_STEP" - "$SIZE_FILE" oversize ""
commit_all "$repo" "head: proof with an empty expected substring"
# Assert
check_run "empty expected substring" "$repo" 2 - - "empty expected output substring"

# Case w: a proof whose mode is not empty or oversize.
# Arrange
repo="$TMP/w"
make_base "$repo" 1
use_head "$repo"
list="$repo/tools/validate_workflow/checks.list"
# Act
set_proof "$list" "$SIZE_STEP" - "$SIZE_FILE" delete "exceeding the 20000-character limit"
commit_all "$repo" "head: proof with an unknown mode"
# Assert
check_run "proof with unknown mode" "$repo" 2 -

# Case x: the control-failing proof of case s, run with VALIDATE_WORKFLOW_INNER unset.
# The proof must run, so the control failure is reported.
# Arrange
repo="$TMP/x"
make_base "$repo" 1
use_head "$repo"
list="$repo/tools/validate_workflow/checks.list"
# Act
set_proof "$list" "Check the flaky-test rules are pinned" \
  "FLAKY_TESTS_PATH=skills/testing/references/NO_SUCH.md" \
  skills/testing/references/FLAKY_TESTS.md empty "flaky-test rule pins"
commit_all "$repo" "head: control-failing proof, inner guard unset"
# Assert
check_run "guard runs proofs when INNER unset" "$repo" 1 R2

# Case y: the same list as case x, run with VALIDATE_WORKFLOW_INNER=1 exported.
# The proofs are skipped, so the suite passes.
# Arrange
repo="$TMP/y"
make_base "$repo" 1
use_head "$repo"
list="$repo/tools/validate_workflow/checks.list"
# Act
set_proof "$list" "Check the flaky-test rules are pinned" \
  "FLAKY_TESTS_PATH=skills/testing/references/NO_SUCH.md" \
  skills/testing/references/FLAKY_TESTS.md empty "flaky-test rule pins"
commit_all "$repo" "head: control-failing proof, inner guard set"
# Assert
check_run "guard skips proofs when INNER=1" "$repo" 0 - inner "PROOF skipped: VALIDATE_WORKFLOW_INNER=1"

# Case zz: the size step's oversize proof for session-bootstrap, restated explicitly.
# Both the control and the must-fail run hold: the step fails on the 20001-byte copy of session-bootstrap.
# Arrange
repo="$TMP/zz"
make_base "$repo" 1
use_head "$repo"
list="$repo/tools/validate_workflow/checks.list"
# Act
set_proof "$list" "$SIZE_STEP" - skills/session-bootstrap/SKILL.md oversize "exceeding the 20000-character limit"
commit_all "$repo" "head: session-bootstrap size proof restated"
# Assert
check_run "session-bootstrap size proof passes" "$repo" 0 - - "PROOF ok: $SIZE_STEP"

# Case z: a proof row in append mode with a seventh field of two lines and a dollar sign.
# The seventh field is passed through ENVIRON so its backslash-n stays literal. The step
# never reads the target, so the must-fail run passes: the control run passed, then the
# guard reports that the proof did not fail with the expected output.
# Arrange
repo="$TMP/z"
make_base "$repo" 1
use_head "$repo"
list="$repo/tools/validate_workflow/checks.list"
# Act
VW_TEXT='echo $HOME\necho two' awk -v s="Hook script smoke test" -v t="$SIZE_FILE" 'BEGIN { FS = OFS = "\t" }
  ($1 == "pending" || $1 == "proof") && $2 == s { print "proof", s, "-", t, "append", "two", ENVIRON["VW_TEXT"]; done = 1; next }
  { print }
  END { if (!done) print "proof", s, "-", t, "append", "two", ENVIRON["VW_TEXT"] }
' "$list" | set_content "$list"
commit_all "$repo" "head: append proof with a seventh field"
# Assert
check_run "append mode adds two lines with a dollar sign" "$repo" 1 R2 - \
  "did not fail with the expected output"

# Case aa: a proof row in insert-before mode with a seventh field of two lines and a dollar sign.
# The mode puts the text before the last line of its target, so the target has many lines
# (SIZE_FILE). The seventh field is passed through ENVIRON so its backslash-n stays literal.
# The step never reads the target, so the must-fail run passes: the control run passed, then the
# guard reports that the proof did not fail with the expected output.
# Arrange
repo="$TMP/aa"
make_base "$repo" 1
use_head "$repo"
list="$repo/tools/validate_workflow/checks.list"
# Act
VW_TEXT='echo $HOME\necho two' awk -v s="Hook script smoke test" -v t="$SIZE_FILE" 'BEGIN { FS = OFS = "\t" }
  ($1 == "pending" || $1 == "proof") && $2 == s { print "proof", s, "-", t, "insert-before", "two", ENVIRON["VW_TEXT"]; done = 1; next }
  { print }
  END { if (!done) print "proof", s, "-", t, "insert-before", "two", ENVIRON["VW_TEXT"] }
' "$list" | set_content "$list"
commit_all "$repo" "head: insert-before proof with a seventh field"
# Assert
check_run "insert-before mode puts the text before the last line" "$repo" 1 R2 - \
  "did not fail with the expected output"

# Case ab: a symlink in the tracked tree is copied as a link. The probe step's control run
# needs skills/honesty/LINK.md to be a link, so it fails unless prepare_tree copies the
# symlink as a link instead of following it.
# Arrange
repo="$TMP/ab"
make_base "$repo" 1
use_head "$repo"
wf="$repo/.github/workflows/validate.yml"
list="$repo/tools/validate_workflow/checks.list"
# Act
ln -s SKILL.md "$repo/skills/honesty/LINK.md" || exit 2
VW_BLOCK=$PROBE_LINK_BLOCK awk '
  !added && /^      - name: / { print ENVIRON["VW_BLOCK"]; added = 1 }
  { print }
' "$wf" | set_content "$wf"
printf 'step\tProbe symlink in the tree\nproof\tProbe symlink in the tree\t-\t%s\tempty\tLINK target is empty\n' \
  "$SIZE_FILE" >> "$list"
commit_all "$repo" "head: symlink probe step and proof"
# Assert
check_run "symlink in the tree is copied as a link" "$repo" 0 - - "PROOF ok: Probe symlink in the tree"

# Case ac: an insert-before-close proof puts a bad value inside the frontmatter range. The probe
# step reads the frontmatter of agents/implementer.md: the control run passes, and the must-fail
# run prints INVALID FRONTMATTER VALUE only when the text lands before the closing --- line.
# Arrange
repo="$TMP/ac"
make_base "$repo" 1
use_head "$repo"
wf="$repo/.github/workflows/validate.yml"
list="$repo/tools/validate_workflow/checks.list"
mkdir -p "$repo/agents" && cp "$REPO/agents/implementer.md" "$repo/agents/implementer.md" || exit 2
# Act
VW_BLOCK=$PROBE_FM_BLOCK awk '
  !added && /^      - name: / { print ENVIRON["VW_BLOCK"]; print ""; added = 1 }
  { print }
' "$wf" | set_content "$wf"
printf 'step\tProbe frontmatter values\ncovers\tProbe frontmatter values\tagents/implementer.md\nproof\tProbe frontmatter values\t-\tagents/implementer.md\tinsert-before-close\tINVALID FRONTMATTER VALUE\tprobe: a: b\n' >> "$list"
commit_all "$repo" "head: frontmatter probe step and proof"
# Assert
check_run "insert-before-close puts a bad value inside the frontmatter range" "$repo" 0 - - "PROOF ok: Probe frontmatter values"

# Case ad: a replace proof turns a symlink into a regular file. The probe step's control run
# finds .claude/hooks/session-start.sh a link, so it passes. The must-fail run replaces the link
# with a regular file holding "regular file text", so the probe prints "is not a symlink" and exits 1.
# Arrange
repo="$TMP/ad"
make_base "$repo" 1
use_head "$repo"
wf="$repo/.github/workflows/validate.yml"
list="$repo/tools/validate_workflow/checks.list"
# Act
mkdir -p "$repo/.claude/hooks" || exit 2
printf 'real hook\n' > "$repo/.claude/hooks/REAL.sh"
ln -s REAL.sh "$repo/.claude/hooks/session-start.sh" || exit 2
VW_BLOCK=$PROBE_REPLACE_BLOCK awk '
  !added && /^      - name: / { print ENVIRON["VW_BLOCK"]; print ""; added = 1 }
  { print }
' "$wf" | set_content "$wf"
printf 'step\tProbe replaced symlink\ncovers\tProbe replaced symlink\t.claude/hooks/session-start.sh\nproof\tProbe replaced symlink\t-\t.claude/hooks/session-start.sh\treplace\tis not a symlink\tregular file text\n' >> "$list"
commit_all "$repo" "head: replace probe step and proof"
# Assert
check_run "replace turns a symlink into a regular file" "$repo" 0 - - "PROOF ok: Probe replaced symlink"

# Case AC3: a file pinned by a proof of the hand-back step is removed from the head tree. The
# step's control run fails on the unmodified copy, so the guard reports the proof control failure.
# Arrange
repo="$TMP/ac3"
make_base "$repo" 1
mkdir -p "$repo/skills/running-a-sprint/references" "$repo/agents" &&
  cp "$REPO/skills/running-a-sprint/references/HANDBACK_ROUTING.md" "$repo/skills/running-a-sprint/references/" &&
  cp "$REPO/agents/story-coordinator.md" "$repo/agents/" || exit 2
commit_all "$repo" "base: hand-back step files"
use_head "$repo"
list="$repo/tools/validate_workflow/checks.list"
# Act
set_proof "$list" "Check hand-back size contract strings" - \
  skills/running-a-sprint/references/HANDBACK_ROUTING.md empty "is missing required contract string"
rm -f "$repo/skills/running-a-sprint/references/HANDBACK_ROUTING.md"
commit_all "$repo" "head: pinned file removed"
# Assert
check_run "AC3 removing a pinned file from the head tree fails proof control" "$repo" 1 R2 - \
  'proof control for "Check hand-back size contract strings" failed'

# Case AC2: no issue-number citation in tools/validate_workflow. The grep reads the head tree
# (REPO) with the bracket form of the digit class, so this case does not match its own text.
# grep exit 1 means no line matched and the case passes; exit 0 (a citation) or 2 (grep error) fails.
# Arrange
# Act
CASES=$((CASES + 1))
grep -rn '#[[:digit:]]' "$REPO/tools/validate_workflow" > "$TMP/ac2.out" 2>&1
rc=$?
# Assert
if [ "$rc" -eq 1 ]; then
  echo "PASS: AC2 no issue-number citation in tools/validate_workflow"
else
  FAILS=$((FAILS + 1))
  echo "FAIL: AC2 no issue-number citation in tools/validate_workflow: grep exit $rc"
  sed -n '1,3p' "$TMP/ac2.out" | sed 's/^/  | /'
fi

if [ "$CASES" -ne "$EXPECTED_CASES" ]; then
  echo "FAIL: suite: ran $CASES cases, expected $EXPECTED_CASES"
  FAILS=$((FAILS + 1))
fi
echo "CASES RUN: $CASES; FAILED: $FAILS"
if [ "$FAILS" -ne 0 ] || [ "$CASES" -eq 0 ]; then
  exit 1
fi
exit 0
