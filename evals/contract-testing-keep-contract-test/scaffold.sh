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
import logging
import os
import threading
from abc import ABC, abstractmethod

log = logging.getLogger(__name__)


class Store(ABC):
    @abstractmethod
    def get(self, key):
        """Return the value for key, or None when it is missing."""

    @abstractmethod
    def put(self, key, value):
        """Store value under key."""

    @abstractmethod
    def delete(self, key):
        """Remove key; do nothing when it is missing."""

    @abstractmethod
    def size(self):
        """Return the number of stored keys."""


class FileStore(Store):
    def __init__(self, path):
        self._path = path

    def _load(self):
        if not os.path.exists(self._path):
            return {}
        with open(self._path) as handle:
            return json.load(handle)

    def _save(self, data):
        with open(self._path, "w") as handle:
            json.dump(data, handle)

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

    def size(self):
        return len(self._load())


class MemoryStore(Store):
    def __init__(self):
        self._data = {}
        self._lock = threading.Lock()
        self._count = 0
        log.debug("MemoryStore created")

    def get(self, key):
        with self._lock:
            value = self._data.get(key)
            log.debug("get %s -> %r", key, value)
            return value

    def put(self, key, value):
        with self._lock:
            if key not in self._data:
                self._count += 1
            self._data[key] = value
            log.debug("put %s", key)

    def delete(self, key):
        with self._lock:
            if key in self._data:
                del self._data[key]
                self._count -= 1
                log.debug("delete %s", key)
            else:
                log.debug("delete of missing key %s ignored", key)

    def size(self):
        with self._lock:
            return self._count
PY
cat > tests/test_store_contract.py <<'PY'
import os
import tempfile
import unittest

from src.store import FileStore, MemoryStore


class StoreContractTest(unittest.TestCase):
    def setUp(self):
        self._dir = tempfile.TemporaryDirectory()
        self.addCleanup(self._dir.cleanup)

    def _stores(self):
        return {
            "MemoryStore": MemoryStore(),
            "FileStore": FileStore(os.path.join(self._dir.name, "store.json")),
        }

    def test_get_missing_key_returns_none(self):
        for name, store in self._stores().items():
            with self.subTest(store=name):
                self.assertIsNone(store.get("absent"))

    def test_put_then_get_returns_value(self):
        for name, store in self._stores().items():
            with self.subTest(store=name):
                store.put("a", 1)
                self.assertEqual(store.get("a"), 1)

    def test_put_twice_overwrites_and_counts_once(self):
        for name, store in self._stores().items():
            with self.subTest(store=name):
                store.put("a", 1)
                store.put("a", 2)
                self.assertEqual(store.get("a"), 2)
                self.assertEqual(store.size(), 1)

    def test_delete_removes_key(self):
        for name, store in self._stores().items():
            with self.subTest(store=name):
                store.put("a", 1)
                store.delete("a")
                self.assertIsNone(store.get("a"))
                self.assertEqual(store.size(), 0)

    def test_delete_of_missing_key_does_nothing(self):
        for name, store in self._stores().items():
            with self.subTest(store=name):
                store.put("a", 1)
                store.delete("absent")
                self.assertEqual(store.size(), 1)
                self.assertEqual(store.get("a"), 1)


if __name__ == "__main__":
    unittest.main()
PY
git add -A
git commit -q -m "chore: seed repo"
