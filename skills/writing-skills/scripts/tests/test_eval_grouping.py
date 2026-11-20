"""Tests for reading claude plugin eval run files and pooling their columns."""

import contextlib
import io
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


class TestZeroEventBound(unittest.TestCase):
    def test_zeroEventBound_fiveAndThirtyRuns_matchExactBound(self):
        # Arrange: run counts 5 and 30; expected bounds 1 - 0.05 ** (1/n) are 0.451 and 0.095
        run_count_five = 5
        run_count_thirty = 30

        # Act: call the bound for each run count through the error-capturing helper
        result_five, error_five = _attempt(eg.zero_event_bound, run_count_five)
        result_thirty, error_thirty = _attempt(eg.zero_event_bound, run_count_thirty)

        # Assert: neither call raised, and each value matches its expected bound to 3 places
        self.assertIsNone(error_five, f"zero_event_bound raised {type(error_five).__name__}: {error_five}")
        self.assertIsNone(error_thirty, f"zero_event_bound raised {type(error_thirty).__name__}: {error_thirty}")
        self.assertAlmostEqual(result_five, 0.451, places=3)
        self.assertAlmostEqual(result_thirty, 0.095, places=3)

    def test_zeroEventBound_zeroRuns_returnsNone(self):
        # Arrange: a case that logged zero runs, so there is no bound to compute
        run_count_zero = 0

        # Act: call the bound for zero runs through the error-capturing helper
        result, error = _attempt(eg.zero_event_bound, run_count_zero)

        # Assert: no error (no division by zero), and no bound and no verdict is returned
        self.assertIsNone(error, f"zero_event_bound raised {type(error).__name__}: {error}")
        self.assertIsNone(result)


class TestReportRows(unittest.TestCase):
    def test_reportRows_constantWithNoSkill_isExcludedNoSignal(self):
        # Arrange: case c1 has the same pass rate in the no-skill and tsr-before-1 labels, so it is constant
        columns = {"no-skill": {"c1": [True, False, True, False]}, "tsr-before-1": {"c1": [True, False, True, False]}}

        # Act: build the report rows through the error-capturing helper
        result, error = _attempt(eg.report_rows, columns)

        # Assert: no error, and the c1 row is labeled as excluded with no verdict
        self.assertIsNone(error, f"report_rows raised {type(error).__name__}: {error}")
        row = next((r for r in result if r["case"] == "c1"), None)
        self.assertIsNotNone(row, "no row for case c1")
        self.assertEqual(row["label"], "excluded: no signal")
        self.assertIsNone(row["verdict"])

    def test_reportRows_constantWithoutNoSkill_isUnclassified(self):
        # Arrange: case c1 has the same pass rate in both labels, and no label starts with "no-skill"
        columns = {"tsr-before-1": {"c1": [True, False, True, False]}, "tsr-before-2": {"c1": [True, False, True, False]}}

        # Act: build the report rows through the error-capturing helper
        result, error = _attempt(eg.report_rows, columns)

        # Assert: no error, and the c1 row is kept as unclassified with no verdict
        self.assertIsNone(error, f"report_rows raised {type(error).__name__}: {error}")
        row = next((r for r in result if r["case"] == "c1"), None)
        self.assertIsNotNone(row, "no row for case c1")
        self.assertEqual(row["label"], "unclassified: run no-skill first")
        self.assertIsNone(row["verdict"])

    def test_reportRows_constantZero_carriesBoundAndNote(self):
        # Arrange: case c1 passes in no run of either column, so it is constant at 0 with n = 4 per column
        columns = {"no-skill": {"c1": [False, False, False, False]}, "tsr-before-1": {"c1": [False, False, False, False]}}

        # Act: build the report rows through the error-capturing helper
        result, error = _attempt(eg.report_rows, columns)

        # Assert: no error, and the c1 row carries the note and the zero-event bound for n = 4
        self.assertIsNone(error, f"report_rows raised {type(error).__name__}: {error}")
        row = next((r for r in result if r["case"] == "c1"), None)
        self.assertIsNotNone(row, "no row for case c1")
        self.assertIn("not evidence of keeping the behavior", row["note"])
        self.assertAlmostEqual(row["bound"], 1 - 0.05 ** (1 / 4), places=3)


class TestCorrelation(unittest.TestCase):
    def test_correlation_perfectLinearCopy_isOne(self):
        # Arrange: b is an exact linear copy of a (b = 2 * a + 1)
        a = [0.1, 0.4, 0.5, 0.9]
        b = [2 * x + 1 for x in a]

        # Act: call correlation through the error-capturing helper
        result, error = _attempt(eg.correlation, a, b)

        # Assert: no error, and the correlation is 1.0 to 9 places
        self.assertIsNone(error, f"correlation raised {type(error).__name__}: {error}")
        self.assertAlmostEqual(result, 1.0, places=9)

    def test_correlation_twoSharedColumns_isNone(self):
        # Arrange: two shared columns, which is fewer than the three the correlation needs
        a = [0.1, 0.9]
        b = [0.2, 0.8]

        # Act: call correlation through the error-capturing helper
        result, error = _attempt(eg.correlation, a, b)

        # Assert: no error, and the correlation is None
        self.assertIsNone(error, f"correlation raised {type(error).__name__}: {error}")
        self.assertIsNone(result)

    def test_correlation_zeroVariance_isNone(self):
        # Arrange: a is constant (zero variance), so its correlation with b is undefined
        a = [0.5, 0.5, 0.5]
        b = [0.1, 0.2, 0.3]

        # Act: call correlation through the error-capturing helper
        result, error = _attempt(eg.correlation, a, b)

        # Assert: no error, and the correlation is None
        self.assertIsNone(error, f"correlation raised {type(error).__name__}: {error}")
        self.assertIsNone(result)


class TestGroupCases(unittest.TestCase):
    def test_groupCases_transitivityNotUsed_planOrder(self):
        # Arrange: A~B is 0.9827 and A~C is 0.8367 (below 0.9), so C must not join A through B
        rates = {
            "A": {"l1": 0.1, "l2": 0.2, "l3": 0.3, "l4": 0.4},
            "B": {"l1": 0.1, "l2": 0.2, "l3": 0.3, "l4": 0.5},
            "C": {"l1": 0.1, "l2": 0.3, "l3": 0.2, "l4": 0.6},
        }

        # Act: group the cases at threshold 0.9 over 3 shared labels
        result, error = _attempt(eg.group_cases, rates, 0.9, 3)

        # Assert: no error, A is kept with B as its member, and C is kept with no members
        self.assertIsNone(error, f"group_cases raised {type(error).__name__}: {error}")
        self.assertEqual(result, [("A", ["B"]), ("C", [])])


class TestMain(unittest.TestCase):
    def test_main_noArguments_returnsUsageCode(self):
        # Arrange: no run files, so argv holds no label=path items
        argv = []

        # Act: call main through the error-capturing helper, with stderr captured so the usage line stays out of the output
        with contextlib.redirect_stderr(io.StringIO()):
            result, error = _attempt(eg.main, argv)

        # Assert: no error, and the usage code 2 is returned
        self.assertIsNone(error, f"main raised {type(error).__name__}: {error}")
        self.assertEqual(result, 2)

    def test_main_missingRunFile_printsNoVerdictAndReturnsOne(self):
        # Arrange: a run file path that does not exist
        missing = "/nonexistent-dir-for-s503/missing.json"
        argv = ["tsr-before-1=" + missing]

        # Act: call main through the error-capturing helper, with stdout captured to read the per-file line
        with contextlib.redirect_stdout(io.StringIO()) as out:
            result, error = _attempt(eg.main, argv)

        # Assert: no error, main returns 1, and the output names the missing file with no verdict
        self.assertIsNone(error, f"main raised {type(error).__name__}: {error}")
        self.assertEqual(result, 1)
        self.assertIn(missing + ": error, no verdict", out.getvalue())

    def test_main_cleanRun_printsNoSignalLine(self):
        # Arrange: two clean run files, no-skill and tsr-before-1, both holding case c1 with the same pass pattern
        records = [_record(True), _record(False), _record(True), _record(False)]
        with tempfile.TemporaryDirectory() as tmp:
            path_a = os.path.join(tmp, "no_skill.json")
            path_b = os.path.join(tmp, "tsr_before_1.json")
            with open(path_a, "w", encoding="utf-8") as handle:
                json.dump(_run_doc({"c1": records}), handle)
            with open(path_b, "w", encoding="utf-8") as handle:
                json.dump(_run_doc({"c1": records}), handle)
            argv = ["no-skill=" + path_a, "tsr-before-1=" + path_b]

            # Act: call main through the error-capturing helper, with stdout captured to read the per-case line
            with contextlib.redirect_stdout(io.StringIO()) as out:
                result, error = _attempt(eg.main, argv)

        # Assert: no error, main returns 0, and the output carries the no-signal line for c1
        self.assertIsNone(error, f"main raised {type(error).__name__}: {error}")
        self.assertEqual(result, 0)
        self.assertIn("c1: excluded: no signal", out.getvalue())

    def test_main_cleanRun_printsGroupLine(self):
        # Arrange: three clean run files, one per label; cases c1 and c2 hold identical records in each file,
        # so their pass rates match in every label and they correlate at 1.0
        records_no_skill = [_record(True), _record(False), _record(True), _record(False)]
        records_before_1 = [_record(True), _record(True), _record(True), _record(False)]
        records_before_2 = [_record(True), _record(False), _record(False), _record(False)]
        with tempfile.TemporaryDirectory() as tmp:
            path_a = os.path.join(tmp, "no_skill.json")
            path_b = os.path.join(tmp, "tsr_before_1.json")
            path_c = os.path.join(tmp, "tsr_before_2.json")
            with open(path_a, "w", encoding="utf-8") as handle:
                json.dump(_run_doc({"c1": records_no_skill, "c2": records_no_skill}), handle)
            with open(path_b, "w", encoding="utf-8") as handle:
                json.dump(_run_doc({"c1": records_before_1, "c2": records_before_1}), handle)
            with open(path_c, "w", encoding="utf-8") as handle:
                json.dump(_run_doc({"c1": records_before_2, "c2": records_before_2}), handle)
            argv = ["no-skill=" + path_a, "tsr-before-1=" + path_b, "tsr-before-2=" + path_c]

            # Act: call main through the error-capturing helper, with stdout captured to read the group line
            with contextlib.redirect_stdout(io.StringIO()) as out:
                result, error = _attempt(eg.main, argv)

        # Assert: no error, main returns 0, and the output carries the group line with c2 as c1's member
        self.assertIsNone(error, f"main raised {type(error).__name__}: {error}")
        self.assertEqual(result, 0)
        self.assertIn("group kept c1: c2", out.getvalue().splitlines())

    def test_main_nonConstantCase_printsVaries(self):
        # Arrange: two cases that are non-constant across the three labels; their rate vectors
        # correlate at -1, below the 0.9 threshold, so they are not grouped
        records_no_skill_c1 = [_record(True), _record(False), _record(True), _record(False)]
        records_before_1_c1 = [_record(True), _record(True), _record(True), _record(False)]
        records_before_2_c1 = [_record(True), _record(False), _record(False), _record(False)]
        records_no_skill_c2 = [_record(True), _record(False), _record(True), _record(False)]
        records_before_1_c2 = [_record(True), _record(False), _record(False), _record(False)]
        records_before_2_c2 = [_record(True), _record(True), _record(True), _record(False)]
        with tempfile.TemporaryDirectory() as tmp:
            path_a = os.path.join(tmp, "no_skill.json")
            path_b = os.path.join(tmp, "tsr_before_1.json")
            path_c = os.path.join(tmp, "tsr_before_2.json")
            with open(path_a, "w", encoding="utf-8") as handle:
                json.dump(_run_doc({"c1": records_no_skill_c1, "c2": records_no_skill_c2}), handle)
            with open(path_b, "w", encoding="utf-8") as handle:
                json.dump(_run_doc({"c1": records_before_1_c1, "c2": records_before_1_c2}), handle)
            with open(path_c, "w", encoding="utf-8") as handle:
                json.dump(_run_doc({"c1": records_before_2_c1, "c2": records_before_2_c2}), handle)
            argv = ["no-skill=" + path_a, "tsr-before-1=" + path_b, "tsr-before-2=" + path_c]

            # Act: call main through the error-capturing helper, with stdout captured to read the per-case lines
            with contextlib.redirect_stdout(io.StringIO()) as out:
                result, error = _attempt(eg.main, argv)

        # Assert: no error, main returns 0, and the output carries a varies line for each case
        self.assertIsNone(error, f"main raised {type(error).__name__}: {error}")
        self.assertEqual(result, 0)
        lines = out.getvalue().splitlines()
        self.assertIn("c1: varies", lines)
        self.assertIn("c2: varies", lines)

    def test_main_uncorrelatedCase_printsNotGroupable(self):
        # Arrange: c1 and c2 appear in all three labels; c3 appears only in no-skill and tsr-before-1.
        # c3 is not constant across its two labels (rates 0.25 and 0.5), and it shares only two labels
        # with each other case, below the three the correlation needs, so its correlation is None.
        records_no_skill_c1 = [_record(True), _record(False), _record(True), _record(False)]
        records_before_1_c1 = [_record(True), _record(True), _record(True), _record(False)]
        records_before_2_c1 = [_record(True), _record(False), _record(False), _record(False)]
        records_no_skill_c2 = [_record(True), _record(False), _record(True), _record(False)]
        records_before_1_c2 = [_record(True), _record(False), _record(False), _record(False)]
        records_before_2_c2 = [_record(True), _record(True), _record(True), _record(False)]
        records_no_skill_c3 = [_record(True), _record(False), _record(False), _record(False)]
        records_before_1_c3 = [_record(True), _record(True), _record(False), _record(False)]
        with tempfile.TemporaryDirectory() as tmp:
            path_a = os.path.join(tmp, "no_skill.json")
            path_b = os.path.join(tmp, "tsr_before_1.json")
            path_c = os.path.join(tmp, "tsr_before_2.json")
            with open(path_a, "w", encoding="utf-8") as handle:
                json.dump(
                    _run_doc({"c1": records_no_skill_c1, "c2": records_no_skill_c2, "c3": records_no_skill_c3}),
                    handle,
                )
            with open(path_b, "w", encoding="utf-8") as handle:
                json.dump(
                    _run_doc({"c1": records_before_1_c1, "c2": records_before_1_c2, "c3": records_before_1_c3}),
                    handle,
                )
            with open(path_c, "w", encoding="utf-8") as handle:
                json.dump(_run_doc({"c1": records_before_2_c1, "c2": records_before_2_c2}), handle)
            argv = ["no-skill=" + path_a, "tsr-before-1=" + path_b, "tsr-before-2=" + path_c]

            # Act: call main through the error-capturing helper, with stdout captured to read the per-case lines
            with contextlib.redirect_stdout(io.StringIO()) as out:
                result, error = _attempt(eg.main, argv)

        # Assert: no error, main returns 0, and the output carries the not groupable line for c3
        self.assertIsNone(error, f"main raised {type(error).__name__}: {error}")
        self.assertEqual(result, 0)
        self.assertIn("c3: not groupable", out.getvalue().splitlines())


if __name__ == "__main__":
    unittest.main()
