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
    def get(self, key: str):
        """Return the value for key, or None when the key is absent."""

    @abstractmethod
    def put(self, key: str, value) -> None:
        """Store value under key, replacing any earlier value."""

    @abstractmethod
    def delete(self, key: str) -> None:
        """Remove key. Removing an absent key is not an error."""

    @abstractmethod
    def keys(self) -> list:
        """Return all keys in sorted order."""


class FileStore(Store):
    def __init__(self, path: str):
        self._path = path

    def _load(self) -> dict:
        if not os.path.exists(self._path):
            return {}
        with open(self._path) as handle:
            return json.load(handle)

    def _save(self, data: dict) -> None:
        with open(self._path, "w") as handle:
            json.dump(data, handle)

    def get(self, key: str):
        return self._load().get(key)

    def put(self, key: str, value) -> None:
        data = self._load()
        data[key] = value
        self._save(data)

    def delete(self, key: str) -> None:
        data = self._load()
        data.pop(key, None)
        self._save(data)

    def keys(self) -> list:
        return sorted(self._load())
PY
cat > tests/test_store_contract.py <<'PY'
import os
import tempfile
import unittest

from src.store import FileStore


def make_file_store(directory):
    return FileStore(os.path.join(directory, "store.json"))


IMPLEMENTATIONS = [make_file_store]


class StoreContractTest(unittest.TestCase):
    def each_store(self):
        for factory in IMPLEMENTATIONS:
            with self.subTest(implementation=factory.__name__):
                with tempfile.TemporaryDirectory() as directory:
                    yield factory(directory)

    def test_get_missing_key_returns_none(self):
        for store in self.each_store():
            self.assertIsNone(store.get("absent"))

    def test_put_then_get_returns_value(self):
        for store in self.each_store():
            store.put("a", "one")
            self.assertEqual(store.get("a"), "one")

    def test_delete_removes_key_and_missing_delete_is_safe(self):
        for store in self.each_store():
            store.put("a", "one")
            store.delete("a")
            store.delete("a")
            self.assertIsNone(store.get("a"))

    def test_keys_are_sorted(self):
        for store in self.each_store():
            store.put("b", 2)
            store.put("a", 1)
            self.assertEqual(store.keys(), ["a", "b"])


if __name__ == "__main__":
    unittest.main()
PY
git add -A
git commit -q -m "chore: seed repo"
