#!/usr/bin/env bash
set -eu
mkdir -p src
cat > src/parse.py <<'PY'
def parse_line(line):
    key, _, value = line.partition("=")
    return key.strip(), value.strip()


def parse_text(text):
    return dict(parse_line(l) for l in text.splitlines() if "=" in l)
PY
cat > src/store.py <<'PY'
import json

from parse import parse_text


def save(path, text):
    with open(path, "w") as f:
        json.dump(parse_text(text), f)


def load(path):
    with open(path) as f:
        return json.load(f)
PY
cat > src/cli.py <<'PY'
import sys

from store import load, save


def main(argv):
    if argv[1] == "save":
        save(argv[2], sys.stdin.read())
    else:
        print(load(argv[2]))


if __name__ == "__main__":
    main(sys.argv)
PY
cat > README.md <<'MD'
# settings-tool

Reads key=value text, stores it as JSON, and prints it back.

Run: `python src/cli.py save out.json < in.txt`, then `python src/cli.py load out.json`.
MD
