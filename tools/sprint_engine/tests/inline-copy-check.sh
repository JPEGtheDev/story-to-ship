#!/usr/bin/env bash
# inline-copy-check.sh -- verifies that sprint-runner.js carries the
# engine-core.js marker region byte-for-byte, with nothing lost, added, or
# reordered in the copy.
#
# tools/sprint_engine/sprint-runner.js is a workflow-runtime script that
# embeds the dialect-neutral region of tools/sprint_engine/engine-core.js
# (everything between the ===ENGINE-CORE-BEGIN=== and ===ENGINE-CORE-END===
# marker lines, both lines included) so the engine's own logic can run
# inside the runtime's own execution context. This script is the gate that
# keeps that embedded copy honest: it extracts the marker region from both
# files and byte-compares them with cmp, independent of the two files'
# surrounding content (a runner-only header before the region, runner-only
# glue after it).
#
# Usage: inline-copy-check.sh
#   No arguments. Paths are derived from this script's own location (via
#   BASH_SOURCE), so it works identically whether invoked from the repo
#   root or from this tests/ directory.
#
# Exit codes: 0 when the two marker regions are byte-identical; nonzero on
# any difference, or on any extraction failure (a missing/unreadable file,
# a missing marker line in either file, or an empty extracted region).
#
# Fail loud by design: an extraction failure is asserted EXPLICITLY, before
# cmp ever runs -- two independently-empty extractions would otherwise
# report "identical" from cmp's own point of view, which would let this
# gate pass vacuously on a badly broken input instead of catching it. Each
# extraction failure names which file and which marker (or which condition)
# it hit, so a failure is diagnosable from the output alone.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENGINE_CORE="$SCRIPT_DIR/../engine-core.js"
RUNNER="$SCRIPT_DIR/../sprint-runner.js"

BEGIN_MARKER='// ===ENGINE-CORE-BEGIN==='
END_MARKER='// ===ENGINE-CORE-END==='

# extract_marker_region FILE OUT -- writes the marker region (both marker
# lines included) from FILE into OUT. Returns nonzero, with a message on
# stderr naming FILE and the specific problem, on any of: FILE missing or
# unreadable, either marker line absent from FILE, the end marker appearing
# before the begin marker, or an empty extracted region (belt-and-suspenders
# alongside the missing-marker checks above it, since an extraction bug
# unrelated to marker presence could still yield nothing).
extract_marker_region() {
  local file="$1" out="$2"

  if [[ ! -f "$file" || ! -r "$file" ]]; then
    echo "inline-copy-check.sh: cannot read file (not a readable regular file): $file" >&2
    return 1
  fi

  local begin_line end_line
  begin_line="$(grep -n -F -x "$BEGIN_MARKER" "$file" | head -n 1 | cut -d: -f1)"
  end_line="$(grep -n -F -x "$END_MARKER" "$file" | head -n 1 | cut -d: -f1)"

  if [[ -z "$begin_line" ]]; then
    echo "inline-copy-check.sh: missing marker line '$BEGIN_MARKER' in $file" >&2
    return 1
  fi
  if [[ -z "$end_line" ]]; then
    echo "inline-copy-check.sh: missing marker line '$END_MARKER' in $file" >&2
    return 1
  fi
  if [[ "$end_line" -lt "$begin_line" ]]; then
    echo "inline-copy-check.sh: '$END_MARKER' (line $end_line) appears before '$BEGIN_MARKER' (line $begin_line) in $file" >&2
    return 1
  fi

  sed -n "${begin_line},${end_line}p" "$file" > "$out"

  if [[ ! -s "$out" ]]; then
    echo "inline-copy-check.sh: extracted marker region from $file is empty" >&2
    return 1
  fi

  return 0
}

ENGINE_TMP="$(mktemp)"
RUNNER_TMP="$(mktemp)"
trap 'rm -f "$ENGINE_TMP" "$RUNNER_TMP"' EXIT

if ! extract_marker_region "$ENGINE_CORE" "$ENGINE_TMP"; then
  exit 1
fi

if ! extract_marker_region "$RUNNER" "$RUNNER_TMP"; then
  exit 1
fi

if cmp -s "$ENGINE_TMP" "$RUNNER_TMP"; then
  echo "inline-copy-check.sh: PASS -- marker region is byte-identical between $(basename "$ENGINE_CORE") and $(basename "$RUNNER")"
  exit 0
fi

echo "inline-copy-check.sh: FAIL -- marker region differs between $(basename "$ENGINE_CORE") and $(basename "$RUNNER")" >&2
cmp "$ENGINE_TMP" "$RUNNER_TMP" >&2
exit 1
