#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email "dev@example.com"
git config user.name "Dev"
printf '# Receipt Tool\n\nThis tool reads receipts and prints a summary of the totals.\n' > README.md
printf 'print("ok")\n' > app.py
git add -A
git commit -q -m "Initial commit"
printf 'print("ok")\nprint("totals")\n' > app.py
