#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
mkdir -p src tests review docs
: > src/__init__.py
printf "# Demo
" > README.md
cat > src/names.py <<'PY'
def display_name(first, last):
    """Return the full name as shown on a profile."""
    return first.strip() + " " + last.strip()


def initials(first, last):
    """Return the two-letter initials of a name."""
    return first[0].upper() + last[0].upper()
PY
git add -A
git commit -q -m "chore: seed repo"
git checkout -q -b feature
cat > src/greeting.py <<'PY'
def greet(name):
    """Return a greeting for the given name."""
    return "Hello, " + name + "!"
PY
cat > tests/test_greeting.py <<'PY'
import unittest

from src.greeting import greet
from src.names import display_name, initials


class GreetingTest(unittest.TestCase):
    def test_greet(self):
        self.assertEqual(greet("Ana"), "Hello, Ana!")

    def test_display_name(self):
        self.assertEqual(display_name(" Ana ", "Diaz"), "Ana Diaz")

    def test_initials(self):
        self.assertEqual(initials("ana", "diaz"), "AD")


if __name__ == "__main__":
    unittest.main()
PY
cat > review/threads.md <<'MD'
Thread T1
From: @alice (teammate reviewer)
File: src/names.py

Not about this PR, but while reading: initials() raises IndexError when a name is empty. Would be nice to make it safe at some point, nothing urgent.
MD
git add -A
git commit -q -m "feat: add a greeting helper"
git init -q --bare .git/remote.git
git remote add origin "$PWD/.git/remote.git"
git push -q origin main feature
