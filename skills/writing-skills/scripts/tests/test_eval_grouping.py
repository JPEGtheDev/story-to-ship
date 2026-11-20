"""Tests for reading claude plugin eval run files and pooling their columns."""

import json
import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import eval_grouping as eg  # noqa: E402


def _attempt(fn, *args):
    """Call fn and return (result, error); error is None when the call succeeded."""
    try:
        return fn(*args), None
    except Exception as exc:  # the stub raises NotImplementedError
        return None, exc


def _record(passed, scored=True, error=None):
    """Build one cases[].arms.with[] record."""
    return {"passed": passed, "score": 1 if passed else 0, "error": error, "scored": scored}


def _run_doc(cases):
    """Build a run document from a mapping of case name to list of records."""
    return {"cases": [{"name": name, "arms": {"with": records}} for name, records in cases.items()]}


class TestReadRunFile(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)

    def _write(self, name, text):
        path = os.path.join(self._tmp.name, name)
        with open(path, "w", encoding="utf-8") as handle:
            handle.write(text)
        return path

    def test_readRunFile_unscoredRecord_isNotCounted(self):
        # Arrange: case c1 has one scored pass, one scored fail, and one unscored record
        doc = _run_doc({"c1": [_record(True), _record(False), _record(True, scored=False)]})
        path = self._write("run.json", json.dumps(doc))

        # Act: read the run file
        result, error = _attempt(eg.read_run_file, path)

        # Assert: the unscored record is neither pass nor fail and is absent from the column
        self.assertIsNone(error, f"read_run_file raised {type(error).__name__}: {error}")
        self.assertEqual(result, {"c1": [True, False]})

    def test_readRunFile_recordWithoutScoredKey_isCounted(self):
        # Arrange: case c1 has one record with no scored key, which counts as scored
        doc = {"cases": [{"name": "c1", "arms": {"with": [{"passed": True, "score": 1, "error": None}]}}]}
        path = self._write("run.json", json.dumps(doc))

        # Act: read the run file
        result, error = _attempt(eg.read_run_file, path)

        # Assert: no error, and the record is counted as a pass in the column
        self.assertIsNone(error, f"read_run_file raised {type(error).__name__}: {error}")
        self.assertEqual(result, {"c1": [True]})

    def test_readRunFile_missingFile_raisesRunFileErrorNamingFile(self):
        # Arrange: a path that does not exist
        path = os.path.join(self._tmp.name, "absent.json")

        # Act: read the missing file
        with self.assertRaises(Exception) as ctx:
            eg.read_run_file(path)

        # Assert: the error type is RunFileError and it names the file
        self.assertEqual(type(ctx.exception).__name__, "RunFileError")
        self.assertIn(path, str(ctx.exception))

    def test_readRunFile_unparsableJson_raisesRunFileErrorNamingFile(self):
        # Arrange: a file whose content is not JSON
        path = self._write("broken.json", "{not json")

        # Act: read the unparsable file
        with self.assertRaises(Exception) as ctx:
            eg.read_run_file(path)

        # Assert: the error type is RunFileError and it names the file
        self.assertEqual(type(ctx.exception).__name__, "RunFileError")
        self.assertIn(path, str(ctx.exception))

    def test_readRunFile_wrongShape_raisesRunFileErrorNamingFile(self):
        # Arrange: valid JSON without the cases[].arms.with[] structure
        path = self._write("shape.json", json.dumps({"results": [1, 2, 3]}))

        # Act: read the wrong-shape file
        with self.assertRaises(Exception) as ctx:
            eg.read_run_file(path)

        # Assert: the error type is RunFileError and it names the file
        self.assertEqual(type(ctx.exception).__name__, "RunFileError")
        self.assertIn(path, str(ctx.exception))

    def test_readRunFile_recordWithError_raisesRunFileErrorNamingFile(self):
        # Arrange: a well-shaped file whose record carries a non-null error
        doc = _run_doc({"c1": [_record(False, error="timeout")]})
        path = self._write("errored.json", json.dumps(doc))

        # Act: read the errored file
        with self.assertRaises(Exception) as ctx:
            eg.read_run_file(path)

        # Assert: the error type is RunFileError and it names the file
        self.assertEqual(type(ctx.exception).__name__, "RunFileError")
        self.assertIn(path, str(ctx.exception))

    def test_readRunFile_nonDictCaseEntry_raisesRunFileError(self):
        # Arrange: a run file whose cases list holds a bare integer instead of a case object
        path = self._write("nondict.json", '{"cases": [5]}')

        # Act: read the file with the non-dict case entry
        result, error = _attempt(eg.read_run_file, path)

        # Assert: the error is a RunFileError, not an AttributeError from case.get
        self.assertIsInstance(
            error,
            eg.RunFileError,
            f"expected RunFileError, got {type(error).__name__}: {error}",
        )


class TestPoolColumns(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)

    def _write(self, name, doc):
        path = os.path.join(self._tmp.name, name)
        with open(path, "w", encoding="utf-8") as handle:
            json.dump(doc, handle)
        return path

    def test_poolColumns_repeatedLabel_mergesCaseColumns(self):
        # Arrange: two files under one label, each holding a different case
        first = self._write("run1.json", _run_doc({"c1": [_record(True)]}))
        second = self._write("run2.json", _run_doc({"c2": [_record(False)]}))
        paths_by_label = {"baseline": [first, second]}

        # Act: pool the columns for the label
        result, error = _attempt(eg.pool_columns, paths_by_label)

        # Assert: one dict for the label holding both cases' columns
        self.assertIsNone(error, f"pool_columns raised {type(error).__name__}: {error}")
        self.assertEqual(result, {"baseline": {"c1": [True], "c2": [False]}})


if __name__ == "__main__":
    unittest.main()
