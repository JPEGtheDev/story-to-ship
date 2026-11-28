#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
mkdir -p src tests review docs
: > src/__init__.py
printf '__pycache__/\n' > .gitignore
printf '# Demo\n' > README.md
git add -A
git commit -q -m "chore: seed repo"
git checkout -q -b feature
cat > src/textutil.py <<'PY'
def shout(text):
    """Return text in lower case."""
    return text.upper() + "!"


def whisper(text):
    """Return text in lower case."""
    return text.lower()
PY
cat > tests/test_textutil.py <<'PY'
import unittest

from src.textutil import shout, whisper


class TextutilTest(unittest.TestCase):
    def test_shout(self):
        self.assertEqual(shout("hi"), "HI!")

    def test_whisper(self):
        self.assertEqual(whisper("HI"), "hi")


if __name__ == "__main__":
    unittest.main()
PY
cat > review/threads.md <<'MD'
Thread T1
From: @alice (teammate reviewer)
File: src/textutil.py, line 2

The docstring of shout says lower case, but the function upper-cases and adds an exclamation mark. Looks like a copy from whisper.
MD
git add -A
git commit -q -m "feat: add shout and whisper helpers"
git init -q --bare .git/remote.git
git remote add origin "$PWD/.git/remote.git"
git push -q origin main feature
