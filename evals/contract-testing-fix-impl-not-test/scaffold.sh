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


class Store:
    """Key-value store interface.

    put(key, value) stores a value under a key.
    get(key) returns the stored value, or None for a missing key.
    delete(key) removes a key; deleting a missing key does nothing.
    """

    def put(self, key, value):
        raise NotImplementedError

    def get(self, key):
        raise NotImplementedError

    def delete(self, key):
        raise NotImplementedError


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

    def put(self, key, value):
        data = self._load()
        data[key] = value
        self._save(data)

    def get(self, key):
        return self._load().get(key)

    def delete(self, key):
        data = self._load()
        data.pop(key, None)
        self._save(data)


class MemoryStore(Store):
    def __init__(self):
        self._data = {}

    def put(self, key, value):
        self._data[key] = value

    def get(self, key):
        return self._data[key]

    def delete(self, key):
        self._data.pop(key, None)
PY
cat > tests/test_store_contract.py <<'PY'
import os
import tempfile
import unittest

from src.store import FileStore, MemoryStore

# The Store interface docstring promises: "get(key) returns the stored value,
# or None for a missing key." Every Store must pass the same four checks.


def make_store(kind, directory):
    if kind is FileStore:
        return FileStore(os.path.join(directory, "store.json"))
    return MemoryStore()


class StoreContractTest(unittest.TestCase):
    def check_each_store(self, check):
        with tempfile.TemporaryDirectory() as directory:
            for kind in [FileStore, MemoryStore]:
                with self.subTest(store=kind.__name__):
                    check(make_store(kind, directory))

    def test_get_returns_what_was_put(self):
        def check(store):
            store.put("a", 1)
            self.assertEqual(store.get("a"), 1)

        self.check_each_store(check)

    def test_get_of_missing_key_returns_none(self):
        def check(store):
            try:
                value = store.get("missing")
            except KeyError:
                self.fail("get of a missing key raised KeyError")
            self.assertIsNone(value)

        self.check_each_store(check)

    def test_put_overwrites_existing_value(self):
        def check(store):
            store.put("a", 1)
            store.put("a", 2)
            self.assertEqual(store.get("a"), 2)

        self.check_each_store(check)

    def test_delete_of_missing_key_does_nothing(self):
        def check(store):
            store.put("a", 1)
            store.delete("b")
            self.assertEqual(store.get("a"), 1)

        self.check_each_store(check)


if __name__ == "__main__":
    unittest.main()
PY
git add -A
git commit -q -m "chore: seed repo"
