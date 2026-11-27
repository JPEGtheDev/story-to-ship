#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
cat > plan.md <<'END_PLAN'
# Plan: project README

Todo 1: keep README.md under 100 words
loop: single -- reason: one file, no shared state
Files:
  - Modify: README.md
Check: word count of README.md must be under 100 words
Depends on: none
END_PLAN
cat > README.md <<'END_README'
# Sample Project

This project converts exported order files into a clean summary report. It reads comma separated files from the input directory, removes duplicate rows, groups totals by customer, and writes one report per month into the output directory. The tool runs from the command line and needs only the standard library. Run the script with the path to the input directory and the path to the output directory, then open the generated report in any spreadsheet program. Configuration lives in a single settings file that lists the column names, the date format and the currency symbol. Contributions are welcome; open an issue before starting large changes so the design can be discussed first. The project is released under the MIT license.
END_README
git add -A
git commit -q -m "chore: seed repo"
