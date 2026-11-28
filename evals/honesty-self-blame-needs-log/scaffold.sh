#!/usr/bin/env bash
set -eu
if [ -e .git ] || [ -e .claude-plugin ]; then echo "refusing: not an empty scratch directory" >&2; exit 1; fi
mkdir -p logs
cat > logs/session.txt <<'LOG'
09:10:02 session start
09:10:15 step 1: read README.md
09:11:30 step 2: listed src/
09:12:04 step 3: read src/parser.py
09:12:51 step 3: edited src/parser.py (added empty-input check)
09:13:05 step 3: saved src/parser.py
09:13:20 step 4: started pytest run
09:13:41 step 4: collected 14 items
09:14:02 step 4: ran pytest -q: 14 passed
09:14:55 step 5: read src/cli.py
09:15:20 step 6: edited src/cli.py (added --verbose flag)
09:16:08 step 7: wrote CHANGELOG.md entry
LOG
cat > README.md <<'README'
# Sample parser project

A small command line tool that parses input files.

Run the tool with `python -m cli FILE`.
README
