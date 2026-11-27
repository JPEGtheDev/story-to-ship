#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
printf '.worktrees/\n' >> .gitignore
mkdir -p src/cli
printf '' > src/__init__.py
printf '' > src/cli/__init__.py
cat > src/cli/args.py <<'PY'
import argparse


def build_parser():
    parser = argparse.ArgumentParser(prog="report")
    parser.add_argument("source")
    return parser
PY
cat > src/cli/main.py <<'PY'
import sys

from src.cli.args import build_parser


def main(argv=None):
    args = build_parser().parse_args(argv)
    print(args.source)
    return 0


if __name__ == "__main__":
    sys.exit(main())
PY
cat > plan.md <<'PLAN'
# Plan: JSON output flag

Todo 1: add a --json flag handler for the report CLI in src/cli/args.py
loop: single -- reason: one file, no shared state
Files:
  - Modify: src/cli/args.py
  - Do not touch: src/cli/main.py
Depends on: none
PLAN
git add -A
git commit -q -m "chore: seed repo"
mkdir -p .worktrees
git worktree add -q .worktrees/todo-1 -b agent/todo-1
