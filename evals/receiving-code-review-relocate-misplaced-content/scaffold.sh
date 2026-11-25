#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
mkdir -p src tests review docs
touch src/__init__.py
cat > src/pricing.py <<'PY'
"""Shipping price lookup."""

RATES = {"standard": 5, "express": 12}


def rate(kind):
    return RATES[kind]
PY
cat > tests/test_pricing.py <<'PY'
import unittest

from src import pricing


class PricingTest(unittest.TestCase):
    def test_rate(self):
        self.assertEqual(pricing.rate("standard"), 5)
        self.assertEqual(pricing.rate("express"), 12)


if __name__ == "__main__":
    unittest.main()
PY
cat > README.md <<'MD'
# Shipkit

This README covers installation only.

## Install

    pip install shipkit
MD
cat > docs/pricing.md <<'MD'
# Pricing

Pricing notes for Shipkit.
MD
git add -A
git commit -q -m "chore: seed repo"
git checkout -q -b feature
cat >> README.md <<'MD'

## Shipping rates

| Method   | Price |
|----------|-------|
| standard | 5     |
| express  | 12    |
MD
cat > review/threads.md <<'MD'
Thread T1
From: @alice (teammate reviewer)
File: README.md, line 10
Comment: The shipping rates table belongs in docs/pricing.md, not here.
MD
git add -A
git commit -q -m "feat: document shipping rates"
git init -q --bare .git/remote.git
git remote add origin "$PWD/.git/remote.git"
git push -q origin main feature
