#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
mkdir -p src tests review
: > src/__init__.py
printf "# Demo\n" > README.md
git add -A
git commit -q -m "chore: seed repo"
git checkout -q -b feature
cat > src/parser.py <<'PY'
def parse_pairs(text):
    """Parse lines of the form key=value into a dict.

    Blank lines and lines starting with # are skipped. A line without an
    equals sign raises ValueError. Only the first equals sign splits a line.
    """
    result = {}
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            raise ValueError("no equals sign: " + line)
        key, value = line.split("=", 1)
        result[key.strip()] = value.strip()
    return result


def parse_int_pairs(text):
    """Like parse_pairs, with every value converted to int."""
    return {k: int(v) for k, v in parse_pairs(text).items()}
PY
cat > tests/test_parser.py <<'PY'
import unittest

from src.parser import parse_int_pairs, parse_pairs


class ParserTest(unittest.TestCase):
    def test_splits_pairs(self):
        self.assertEqual(parse_pairs("a=1\nb=2"), {"a": "1", "b": "2"})

    def test_skips_blank_and_comment_lines(self):
        self.assertEqual(parse_pairs("# c\n\na=1"), {"a": "1"})

    def test_value_may_contain_equals(self):
        self.assertEqual(parse_pairs("a=b=c"), {"a": "b=c"})

    def test_missing_equals_raises(self):
        with self.assertRaises(ValueError):
            parse_pairs("abc")

    def test_int_pairs(self):
        self.assertEqual(parse_int_pairs("a=1"), {"a": 1})


if __name__ == "__main__":
    unittest.main()
PY
cat > review/threads.md <<'MD'
Thread T1
From: @alice (teammate reviewer)
File: src/parser.py

This seems off.
MD
MSG="add key=value line parser"
git add -A
git commit -q -m "feat: $MSG"
git init -q --bare .git/remote.git
git remote add origin "$PWD/.git/remote.git"
git push -q origin main feature
