#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
mkdir -p src tests review docs
printf '__pycache__/\n' > .gitignore
printf '# Users\n\nUser lookup helpers.\n' > README.md
git add -A
git commit -q -m "chore: seed repo"
git checkout -q -b feature
cat > src/users.py <<'PY'
USERS = {1: "ada", 2: "grace"}


def find(user_id):
    return USERS.get(user_id)


def display_name(user_id):
    user = find(user_id)
    return user.capitalize()
PY
cat > tests/test_users.py <<'PY'
import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))

import users


class TestUsers(unittest.TestCase):
    def test_display_name_known_user(self):
        self.assertEqual(users.display_name(1), "Ada")

    def test_display_name_unknown_user_gives_empty_string(self):
        self.assertEqual(users.display_name(99), "")


if __name__ == "__main__":
    unittest.main()
PY
cat > review/threads.md <<'MD'
# Review threads

Thread T1
From: @alice (teammate reviewer)
File: src/users.py line 9
Why is the user lookup not null-checked?
MD
git add -A
git commit -q -m "feat: add user display name"
git init -q --bare .git/remote.git
git remote add origin "$PWD/.git/remote.git"
git push -q origin main feature
