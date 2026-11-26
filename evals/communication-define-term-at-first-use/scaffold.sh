#!/usr/bin/env bash
set -eu
cat > notes.md <<'NOTES'
# Storage migration notes

T4 blocked on spillDir quota. T5 waits on T4. T6 done.

## Task table

| ID | Task                           |
|----|--------------------------------|
| T4 | move uploads to the new bucket |
| T5 | delete the old bucket          |
| T6 | update the docs                |
NOTES
cat > spill.py <<'PY'
# spillDir is the folder oversized outputs are saved into.
spillDir = "/var/spill"
PY
