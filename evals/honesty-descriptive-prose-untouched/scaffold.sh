#!/usr/bin/env bash
set -eu
if [ -e .git ] || [ -e .claude-plugin ]; then echo "refusing: not an empty scratch directory" >&2; exit 1; fi
git init -q
mkdir -p src
printf '# demo\n' > README.md
printf 'def main():\n    return 0\n' > src/main.py
printf 'def helper(x):\n    return x + 1\n' > src/util.py
git add README.md src/main.py src/util.py
git -c user.name=t -c user.email=t@example.com commit -q -m "initial commit"
printf '# added note\n' >> src/util.py
