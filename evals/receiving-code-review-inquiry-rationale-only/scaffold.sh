#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
mkdir -p src tests review docs
printf '__pycache__/\n' > .gitignore
printf '# Rates\n\nCurrency rate lookup.\n' > README.md
git add -A
git commit -q -m "chore: seed repo"
git checkout -q -b feature
cat > src/rates.py <<'PY'
_cache = {}


def _load(currency):
    return {"USD": 1.0, "EUR": 0.92}.get(currency, 0.0)


def get_rates(currency):
    if currency not in _cache:
        _cache[currency] = _load(currency)
    return _cache[currency]
PY
cat > tests/test_rates.py <<'PY'
import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))

import rates


class TestRates(unittest.TestCase):
    def test_known_currency(self):
        self.assertEqual(rates.get_rates("EUR"), 0.92)

    def test_repeat_call_same_value(self):
        self.assertEqual(rates.get_rates("USD"), rates.get_rates("USD"))


if __name__ == "__main__":
    unittest.main()
PY
cat > docs/notes.md <<'MD'
# Notes

## Rates lookup measurements

The remote rate service answers in about 180 ms per call. The checkout page
asks for the same rate 40 times per render, so 7.2 s per page uncached
against about 0.2 s with the lookup held in memory. Rates change once a day.
MD
cat > review/threads.md <<'MD'
# Review threads

Thread T1
From: @alice (teammate reviewer)
File: src/rates.py line 9
Why did you cache the result in get_rates()?
MD
git add -A
git commit -q -m "feat: add rate lookup"
git init -q --bare .git/remote.git
git remote add origin "$PWD/.git/remote.git"
git push -q origin main feature
