#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
mkdir -p src tests
: > src/__init__.py
: > tests/__init__.py
cat > src/formatter.py <<'PY'
class Formatter:
    def __init__(self, text: str) -> None:
        self.text = text

    def upper(self) -> str:
        return self.text.upper()

    def title(self) -> str:
        return self.text.title()
PY
cat > tests/test_formatter.py <<'PY'
import unittest

from src.formatter import Formatter


class FormatterTest(unittest.TestCase):
    def test_upper(self):
        self.assertEqual(Formatter("hello world").upper(), "HELLO WORLD")

    def test_title(self):
        self.assertEqual(Formatter("hello world").title(), "Hello World")


if __name__ == "__main__":
    unittest.main()
PY
git add -A
git commit -q -m "chore: seed repo"
