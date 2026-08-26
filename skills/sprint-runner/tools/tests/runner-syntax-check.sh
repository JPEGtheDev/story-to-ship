#!/usr/bin/env bash
# runner-syntax-check.sh -- a PROXY for whether the workflow runtime will
# accept skills/sprint-runner/tools/sprint-runner.js as loadable. It is NOT the
# real gate: the real gate is a live run through the runtime itself (a
# separate, later deliverable). This script exists because a naive `node
# --check` of sprint-runner.js as it sits on disk is a NON-SIGNAL, not a
# gate -- measured fact, recorded in this file's own header and in
# skills/sprint-runner/tools/RUNTIME_FACTS.md's "Runtime script dialect" section:
# on Node v24, with no package "type" set, `node --check` already exits 0
# on sprint-runner.js UNCHANGED, because ambiguous-module auto-detection
# accepts both the `export const meta` header syntax and the bare
# top-level `return` statement the runtime's own dialect allows outside
# any function. A passing `node --check` on the file as-is therefore
# proves nothing about whether the runtime will load it, in either
# direction.
#
# What this script does instead: it strips the runner-only meta-export
# header off the front of sprint-runner.js, and wraps everything that
# remains -- the engine-core region plus the runner glue after it -- in an
# async IIFE, `(async () => { <body> })();`. Inside a function body,
# `return` is unambiguously legal and `await` is legal under `async`, so
# `node --check` on the wrapped copy runs in a deterministic parse mode
# instead of the ambiguous one the unwrapped file triggers -- while a
# genuine syntax error anywhere in the body still fails the parse, since
# wrapping statements in a function does not change whether they parse.
# This is still an APPROXIMATION of runtime loadability, not proof of it:
# a PASS here proves the body is syntactically valid JavaScript once given
# an unambiguous parse context, not that the runtime's own loader accepts
# this exact dialect.
#
# Header-boundary rule: the runner-only header (the leading comment block
# plus the `export const meta = {...}` literal) is stripped up to and
# including the `// ===ENGINE-CORE-BEGIN===` marker line -- the same
# marker skills/sprint-runner/tools/tests/inline-copy-check.sh already treats as
# a checked-exactly-once anchor into this file. Reusing that marker avoids
# re-implementing brace-matching over the meta object literal to find
# where it closes; the marker line already sits immediately after that
# literal's closing brace. The meta-export header line itself is also
# checked for presence separately (see check_exact_once below), so a file
# that lost its header entirely -- not just one whose marker moved -- is
# still caught.
#
# Usage: runner-syntax-check.sh
#   No arguments. Paths are derived from this script's own location (via
#   BASH_SOURCE), so it works identically whether invoked from the repo
#   root or from this tests/ directory.
#
# Exit codes: 0 when the transformed body parses cleanly under `node
# --check`; nonzero on any precondition failure (missing file, missing
# header, missing/duplicated marker, empty extracted body) or on a genuine
# node --check parse failure, in which case node's own exit status is
# reused so the failure class survives.
#
# Fail loud by design: every precondition above is asserted explicitly,
# before node --check ever runs, and each failure names the file and the
# specific condition it hit -- so a failure is diagnosable from the output
# alone, matching the sibling inline-copy-check.sh gate's own convention.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNNER="$SCRIPT_DIR/../sprint-runner.js"

HEADER_LINE='export const meta = {'
BEGIN_MARKER='// ===ENGINE-CORE-BEGIN==='

# count_exact_line LINE FILE -- prints how many lines of FILE match LINE
# exactly (fixed-string, whole-line).
count_exact_line() {
  local line="$1" file="$2"
  grep -c -F -x "$line" "$file"
}

# check_exact_once LABEL LINE FILE -- returns nonzero, with a message on
# stderr naming FILE, LABEL, and the actual count, unless LINE occurs in
# FILE exactly once.
check_exact_once() {
  local label="$1" line="$2" file="$3"
  local count
  count="$(count_exact_line "$line" "$file")"
  if [[ "$count" -eq 0 ]]; then
    echo "runner-syntax-check.sh: missing $label ('$line') in $file" >&2
    return 1
  fi
  if [[ "$count" -ne 1 ]]; then
    echo "runner-syntax-check.sh: multiple $label lines found in $file (expected exactly one, found $count)" >&2
    return 1
  fi
  return 0
}

if [[ ! -f "$RUNNER" || ! -r "$RUNNER" ]]; then
  echo "runner-syntax-check.sh: cannot read file (not a readable regular file): $RUNNER" >&2
  exit 1
fi

# Fail-safe edge, by design: this checks for the LITERAL line
# 'export const meta = {' anywhere in the file, not specifically in
# header position. A body that happens to contain that exact line for an
# unrelated reason (e.g. inside a template string or a comment) is
# over-rejected as "multiple header lines found" rather than silently
# accepted -- the same false-positive-safe tradeoff the sibling
# inline-copy-check.sh gate makes with its own marker-count checks.
if ! check_exact_once "meta-export header line" "$HEADER_LINE" "$RUNNER"; then
  exit 1
fi

if ! check_exact_once "engine-core begin marker" "$BEGIN_MARKER" "$RUNNER"; then
  exit 1
fi

BEGIN_LINE="$(grep -n -F -x "$BEGIN_MARKER" "$RUNNER" | cut -d: -f1)"
TOTAL_LINES="$(wc -l < "$RUNNER")"

if [[ "$BEGIN_LINE" -ge "$TOTAL_LINES" ]]; then
  echo "runner-syntax-check.sh: '$BEGIN_MARKER' (line $BEGIN_LINE) is the last line of $RUNNER; no body remains after it to check" >&2
  exit 1
fi

# Pre-declared empty and trapped BEFORE either mktemp call, matching the
# sibling gate's convention: `rm -f ""` is a safe no-op, so if the first
# mktemp succeeds and the second fails, the already-registered trap still
# cleans up the first file on exit instead of leaking it.
BODY_TMP=""
WRAPPED_TMP=""
trap 'rm -f "$BODY_TMP" "$WRAPPED_TMP"' EXIT

BODY_TMP="$(mktemp)" || { echo "runner-syntax-check.sh: mktemp failed for the extracted-body temp file" >&2; exit 1; }
# WRAPPED_TMP needs a .js suffix: node --check on this Node version
# determines module format from the file extension and refuses an
# extensionless file with ERR_UNKNOWN_FILE_EXTENSION before it ever
# reaches parsing -- verified by direct measurement (a plain mktemp file
# with no suffix fails with that error even for trivially valid JS; the
# same content with a .js suffix passes).
WRAPPED_TMP="$(mktemp --suffix=.js)" || { echo "runner-syntax-check.sh: mktemp failed for the wrapped-body temp file" >&2; exit 1; }

tail -n "+$((BEGIN_LINE + 1))" "$RUNNER" > "$BODY_TMP"

if [[ ! -s "$BODY_TMP" ]]; then
  echo "runner-syntax-check.sh: body extracted from $RUNNER (everything after '$BEGIN_MARKER') is empty" >&2
  exit 1
fi

{
  echo '(async () => {'
  cat "$BODY_TMP"
  echo '})();'
} > "$WRAPPED_TMP"

if [[ ! -s "$WRAPPED_TMP" ]]; then
  echo "runner-syntax-check.sh: wrapped transform of $RUNNER is empty" >&2
  exit 1
fi

NODE_OUTPUT="$(node --check "$WRAPPED_TMP" 2>&1)"
NODE_STATUS=$?

if [[ "$NODE_STATUS" -eq 0 ]]; then
  echo "runner-syntax-check.sh: PASS -- $(basename "$RUNNER") body parses cleanly under node --check once wrapped in an async IIFE (a loadability PROXY, not proof -- see this script's header; the true gate is a live runtime run, a separate later deliverable)"
  exit 0
fi

echo "runner-syntax-check.sh: FAIL -- node --check rejected the transformed body of $(basename "$RUNNER")" >&2
printf '%s\n' "$NODE_OUTPUT" >&2
# The wrapped copy has one line ("(async () => {") prepended in place of
# everything through '$BEGIN_MARKER' (BEGIN_LINE lines), so any line
# number node reports above is relative to the WRAPPED COPY, not
# $RUNNER: add the offset below to a wrapped-copy line number to get the
# real line in $RUNNER.
echo "runner-syntax-check.sh: note -- line numbers above are relative to the wrapped copy, not $(basename "$RUNNER"); add $((BEGIN_LINE - 1)) to a wrapped-copy line number to get the real line in $(basename "$RUNNER")" >&2
exit "$NODE_STATUS"
