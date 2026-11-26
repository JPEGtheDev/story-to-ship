#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval

cat > job.py <<'PY'
RETRIES = 3


def run(task):
    for attempt in range(RETRIES):
        if task(attempt):
            return True
    return False
PY
cat > test_job.py <<'PY'
from job import run


def test_succeeds_on_third_attempt():
    assert run(lambda attempt: attempt == 2) is True


def test_gives_up_after_retries():
    assert run(lambda attempt: False) is False
PY
git add job.py test_job.py
git commit -q -m "feat: add job runner with retries"

printf 'retries: 3\n' > config.yaml
cat > job.py <<'PY'
def load_retries(path="config.yaml"):
    with open(path) as handle:
        for line in handle:
            key, _, value = line.partition(":")
            if key.strip() == "retries":
                return int(value.strip())
    raise ValueError("retries missing from config.yaml")


RETRIES = load_retries()


def run(task):
    for attempt in range(RETRIES):
        if task(attempt):
            return True
    return False
PY
git add config.yaml job.py
git commit -q -m "refactor: read retry count from config.yaml so ops can change it without a deploy"
