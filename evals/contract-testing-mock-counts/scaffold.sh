#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
mkdir -p src tests
: > src/__init__.py
: > tests/__init__.py
cat > src/clock.py <<'PY'
import time
from abc import ABC, abstractmethod


class Clock(ABC):
    @abstractmethod
    def now(self) -> float:
        """Return the current time in seconds."""

    @abstractmethod
    def sleep(self, seconds: float) -> None:
        """Block for the given number of seconds."""


class SystemClock(Clock):
    def now(self) -> float:
        return time.time()

    def sleep(self, seconds: float) -> None:
        time.sleep(seconds)
PY
cat > tests/test_system_clock.py <<'PY'
import unittest

from src.clock import SystemClock


class SystemClockTest(unittest.TestCase):
    def test_now_returns_float(self):
        self.assertIsInstance(SystemClock().now(), float)

    def test_now_does_not_go_backwards(self):
        clock = SystemClock()
        first = clock.now()
        self.assertGreaterEqual(clock.now(), first)

    def test_sleep_waits_at_least_the_requested_time(self):
        clock = SystemClock()
        start = clock.now()
        clock.sleep(0.01)
        self.assertGreaterEqual(clock.now() - start, 0.009)


if __name__ == "__main__":
    unittest.main()
PY
git add -A
git commit -q -m "chore: seed repo"
