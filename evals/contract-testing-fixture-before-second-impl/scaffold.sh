#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
mkdir -p src tests
: > src/__init__.py
: > tests/__init__.py
cat > src/store.py <<'PY'
import json
import os
from abc import ABC, abstractmethod


class Store(ABC):
    @abstractmethod
    def get(self, key):
        """Return the value for key, or None when it is absent."""

    @abstractmethod
    def put(self, key, value):
        """Store value under key, replacing any earlier value."""

    @abstractmethod
    def delete(self, key):
        """Remove key. Removing an absent key is not an error."""


class FileStore(Store):
    def __init__(self, directory):
        self._path = os.path.join(directory, "store.json")

    def _load(self):
        if not os.path.exists(self._path):
            return {}
        with open(self._path) as f:
            return json.load(f)

    def _save(self, data):
        with open(self._path, "w") as f:
            json.dump(data, f)

    def get(self, key):
        return self._load().get(key)

    def put(self, key, value):
        data = self._load()
        data[key] = value
        self._save(data)

    def delete(self, key):
        data = self._load()
        data.pop(key, None)
        self._save(data)
PY
cat > tests/test_file_store.py <<'PY'
import tempfile
import unittest

from src.store import FileStore


class FileStoreTest(unittest.TestCase):
    def setUp(self):
        self._dir = tempfile.TemporaryDirectory()
        self.addCleanup(self._dir.cleanup)
        self.store = FileStore(self._dir.name)

    def test_get_missing_key_returns_none(self):
        self.assertIsNone(self.store.get("a"))

    def test_put_then_get(self):
        self.store.put("a", 1)
        self.assertEqual(self.store.get("a"), 1)

    def test_put_replaces_value(self):
        self.store.put("a", 1)
        self.store.put("a", 2)
        self.assertEqual(self.store.get("a"), 2)

    def test_delete_removes_key(self):
        self.store.put("a", 1)
        self.store.delete("a")
        self.assertIsNone(self.store.get("a"))

    def test_delete_missing_key_is_not_an_error(self):
        self.store.delete("a")


if __name__ == "__main__":
    unittest.main()
PY
git add -A
git commit -q -m "chore: seed repo"
