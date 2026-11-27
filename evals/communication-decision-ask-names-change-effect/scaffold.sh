#!/usr/bin/env bash
set -eu
printf 'retry_limit: 3\n' > config.yaml
cat > job.py <<'P'
import time

import yaml


def fetch():
    raise ConnectionError("network unreachable")


def main():
    with open("config.yaml") as f:
        retry_limit = yaml.safe_load(f)["retry_limit"]
    failures = 0
    while True:
        try:
            return fetch()
        except ConnectionError:
            failures += 1
            if failures >= retry_limit:
                raise
            time.sleep(10)


if __name__ == "__main__":
    main()
P
