"""Tests for eval_grouping: run-file reading, pooling, bounds, correlation, grouping and the main report."""

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
    except Exception as exc:
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
        with self.assertRaises(eg.RunFileError) as ctx:
            eg.read_run_file(path)

        # Assert: the error is a RunFileError and it names the file
        self.assertIn(path, str(ctx.exception))

    def test_readRunFile_unparsableJson_raisesRunFileErrorNamingFile(self):
        # Arrange: a file whose content is not JSON
        path = self._write("broken.json", "{not json")

        # Act: read the unparsable file
        with self.assertRaises(eg.RunFileError) as ctx:
            eg.read_run_file(path)

        # Assert: the error is a RunFileError and it names the file
        self.assertIn(path, str(ctx.exception))

    def test_readRunFile_wrongShape_raisesRunFileErrorNamingFile(self):
        # Arrange: valid JSON without the cases[].arms.with[] structure
        path = self._write("shape.json", json.dumps({"results": [1, 2, 3]}))

        # Act: read the wrong-shape file
        with self.assertRaises(eg.RunFileError) as ctx:
            eg.read_run_file(path)

        # Assert: the error is a RunFileError and it names the file
        self.assertIn(path, str(ctx.exception))

    def test_readRunFile_recordWithError_raisesRunFileErrorNamingFile(self):
        # Arrange: a well-shaped file whose record carries a non-null error
        doc = _run_doc({"c1": [_record(False, error="timeout")]})
        path = self._write("errored.json", json.dumps(doc))

        # Act: read the errored file
        with self.assertRaises(eg.RunFileError) as ctx:
            eg.read_run_file(path)

        # Assert: the error is a RunFileError and it names the file
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

    def test_readRunFile_nullPassed_raisesRunFileError(self):
        # Arrange: case c1 has one record whose passed value is null
        doc = {"cases": [{"name": "c1", "arms": {"with": [{"passed": None, "score": 0, "error": None}]}}]}
        path = self._write("null_passed.json", json.dumps(doc))

        # Act & Assert: reading the file raises RunFileError, not a later TypeError from summing the column
        with self.assertRaises(eg.RunFileError):
            eg.read_run_file(path)

    def test_readRunFile_stringScored_raisesRunFileErrorNamingFileAndCase(self):
        # Arrange: case c1 has one record whose scored value is the string "false"
        doc = {"cases": [{"name": "c1", "arms": {"with": [{"passed": True, "score": 1, "error": None, "scored": "false"}]}}]}
        path = self._write("string_scored.json", json.dumps(doc))

        # Act: read the file whose scored value is not a bool
        with self.assertRaises(eg.RunFileError) as ctx:
            eg.read_run_file(path)

        # Assert: the error names the file and the case, so the record is not silently counted as scored
        self.assertIn(path, str(ctx.exception))
        self.assertIn("c1", str(ctx.exception))

    def test_readRunFile_stringPassed_raisesRunFileError(self):
        # Arrange: case c1 has one record whose passed value is the string "yes"
        doc = {"cases": [{"name": "c1", "arms": {"with": [{"passed": "yes", "score": 1, "error": None}]}}]}
        path = self._write("string_passed.json", json.dumps(doc))

        # Act & Assert: reading the file raises RunFileError, not a later TypeError from summing the column
        with self.assertRaises(eg.RunFileError):
            eg.read_run_file(path)


class TestPoolColumns(unittest.TestCase):
    def test_poolColumns_repeatedLabel_mergesCaseColumns(self):
        # Arrange: two already-read files under one label, each holding a different case
        columns_by_label = {"baseline": [{"c1": [True]}, {"c2": [False]}]}

        # Act: pool the columns for the label
        result, error = _attempt(eg.pool_columns, columns_by_label)

        # Assert: one dict for the label holding both cases' columns
        self.assertIsNone(error, f"pool_columns raised {type(error).__name__}: {error}")
        self.assertEqual(result, {"baseline": {"c1": [True], "c2": [False]}})

    def test_poolColumns_twoLabels_concatenatesInPathOrderPerLabel(self):
        # Arrange: label a has two files holding case c1 in path order; label b has one file
        columns_by_label = {"a": [{"c1": [True]}, {"c1": [False]}], "b": [{"c1": [True, True]}]}

        # Act: pool the columns across the two labels
        result, error = _attempt(eg.pool_columns, columns_by_label)

        # Assert: label a concatenates its files in path order, and label b stays separate
        self.assertIsNone(error, f"pool_columns raised {type(error).__name__}: {error}")
        self.assertEqual(result, {"a": {"c1": [True, False]}, "b": {"c1": [True, True]}})


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

    def test_reportRows_unequalRunCounts_boundUsesSmallestLabelCountWhenNoSkillIsFirst(self):
        # Arrange: case c1 is constant at 0 under both labels; tsr-before-1 holds 10 runs and no-skill holds 4
        columns = {
            "tsr-before-1": {"c1": [False] * 10},
            "no-skill": {"c1": [False] * 4},
        }

        # Act: build the report rows through the error-capturing helper
        result, error = _attempt(eg.report_rows, columns)

        # Assert: no error, and the bound uses n = 4, the run count of no-skill, the smallest count among the labels
        self.assertIsNone(error, f"report_rows raised {type(error).__name__}: {error}")
        row = next((r for r in result if r["case"] == "c1"), None)
        self.assertIsNotNone(row, "no row for case c1")
        self.assertAlmostEqual(row["bound"], 1 - 0.05 ** (1 / 4), places=3)

    def test_reportRows_unequalRunCounts_boundUsesSmallestLabelCount(self):
        # Arrange: case c1 fails in every run under both labels; label a holds 10 runs and label b holds 4
        columns = {
            "a": {"c1": [False] * 10},
            "b": {"c1": [False] * 4},
        }
        expected_bound = 1 - 0.05 ** (1 / 4)

        # Act: build the report rows through the error-capturing helper
        result, error = _attempt(eg.report_rows, columns)

        # Assert: no error, and the bound uses n = 4, the smallest run count among the labels
        self.assertIsNone(error, f"report_rows raised {type(error).__name__}: {error}")
        row = next((r for r in result if r["case"] == "c1"), None)
        self.assertIsNotNone(row, "no row for case c1")
        self.assertAlmostEqual(row["bound"], expected_bound, places=3)

    def test_reportRows_allPassRow_carriesBoundForRunCount(self):
        # Arrange: case c1 passes in every run of both labels, so it is constant at 1 with n = 4 per column
        columns = {"no-skill": {"c1": [True] * 4}, "tsr-before-1": {"c1": [True] * 4}}

        # Act: build the report rows through the error-capturing helper
        result, error = _attempt(eg.report_rows, columns)

        # Assert: no error, and the c1 row carries the all-event bound 1 - 0.05 ** (1/n) for n = 4
        self.assertIsNone(error, f"report_rows raised {type(error).__name__}: {error}")
        row = next((r for r in result if r["case"] == "c1"), None)
        self.assertIsNotNone(row, "no row for case c1")
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
    def test_groupCases_transitiveMatchBelowThreshold_keepsCaseSeparate(self):
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

    def test_main_argumentWithoutEquals_returnsUsageCode(self):
        # Arrange: one argument with no label=path separator
        argv = ["run.json"]

        # Act: call main through the error-capturing helper, with stderr captured so the usage line stays out of the output
        with contextlib.redirect_stderr(io.StringIO()):
            result, error = _attempt(eg.main, argv)

        # Assert: no error, and the usage code 2 is returned
        self.assertIsNone(error, f"main raised {type(error).__name__}: {error}")
        self.assertEqual(result, 2)

    def test_main_emptyLabel_returnsUsageCode(self):
        # Arrange: one argument whose label is empty, so the path has no label
        argv = ["=/nonexistent-dir-for-empty-label/run.json"]

        # Act: call main through the error-capturing helper, with stderr captured so the usage line stays out of the output
        with contextlib.redirect_stderr(io.StringIO()):
            result, error = _attempt(eg.main, argv)

        # Assert: no error, and the usage code 2 is returned instead of reading the file
        self.assertIsNone(error, f"main raised {type(error).__name__}: {error}")
        self.assertEqual(result, 2)

    def test_main_emptyPath_returnsUsageCode(self):
        # Arrange: a valid no-skill run file, and a second label whose path is empty
        with tempfile.TemporaryDirectory() as tmp:
            path = os.path.join(tmp, "no_skill.json")
            with open(path, "w", encoding="utf-8") as handle:
                json.dump(_run_doc({"c1": [_record(True)]}), handle)
            argv = ["no-skill=" + path, "tsr-before-1="]

            # Act: call main through the error-capturing helper, with stderr and stdout captured to read the usage line and the output
            with contextlib.redirect_stderr(io.StringIO()) as err:
                with contextlib.redirect_stdout(io.StringIO()) as out:
                    result, error = _attempt(eg.main, argv)

        # Assert: no error, the usage code 2 is returned, the usage line is the only stderr text, and no per-file verdict is printed
        self.assertIsNone(error, f"main raised {type(error).__name__}: {error}")
        self.assertEqual(result, 2)
        self.assertEqual(err.getvalue(), "usage: eval_grouping.py label=path [label=path ...]\n")
        self.assertNotIn(": error, no verdict", out.getvalue())

    def test_main_singleLabel_returnsUsageCode(self):
        # Arrange: one valid run file under one label, so no case can be compared with another label
        with tempfile.TemporaryDirectory() as tmp:
            path = os.path.join(tmp, "no_skill.json")
            with open(path, "w", encoding="utf-8") as handle:
                json.dump(_run_doc({"c1": [_record(True), _record(True)]}), handle)
            argv = ["no-skill=" + path]

            # Act: call main through the error-capturing helper, with stderr and stdout captured to read the usage line and the output
            with contextlib.redirect_stderr(io.StringIO()) as err:
                with contextlib.redirect_stdout(io.StringIO()) as out:
                    result, error = _attempt(eg.main, argv)

        # Assert: no error, the usage code 2 is returned, the usage line is the only stderr text, and no case line is printed
        self.assertIsNone(error, f"main raised {type(error).__name__}: {error}")
        self.assertEqual(result, 2)
        self.assertEqual(err.getvalue(), "usage: eval_grouping.py label=path [label=path ...]\n")
        self.assertEqual(out.getvalue(), "")

    def test_main_oneLabelTwoFiles_returnsUsageCode(self):
        # Arrange: two valid run files, both under the same label, so the run still has only one label
        with tempfile.TemporaryDirectory() as tmp:
            path_a = os.path.join(tmp, "no_skill_a.json")
            path_b = os.path.join(tmp, "no_skill_b.json")
            with open(path_a, "w", encoding="utf-8") as handle:
                json.dump(_run_doc({"c1": [_record(True), _record(True)]}), handle)
            with open(path_b, "w", encoding="utf-8") as handle:
                json.dump(_run_doc({"c1": [_record(False), _record(False)]}), handle)
            argv = ["no-skill=" + path_a, "no-skill=" + path_b]

            # Act: call main through the error-capturing helper, with stderr and stdout captured to read the usage line and the output
            with contextlib.redirect_stderr(io.StringIO()) as err:
                with contextlib.redirect_stdout(io.StringIO()) as out:
                    result, error = _attempt(eg.main, argv)

        # Assert: no error, the usage code 2 is returned, the usage line is the only stderr text, and no case line is printed
        self.assertIsNone(error, f"main raised {type(error).__name__}: {error}")
        self.assertEqual(result, 2)
        self.assertEqual(err.getvalue(), "usage: eval_grouping.py label=path [label=path ...]\n")
        self.assertEqual(out.getvalue(), "")

    def test_main_missingRunFile_printsNoVerdictAndReturnsOne(self):
        # Arrange: a run file path that does not exist
        missing = "/nonexistent-dir-for-missing-run/missing.json"
        other_missing = "/nonexistent-dir-for-missing-run/other.json"
        argv = ["tsr-before-1=" + missing, "no-skill=" + other_missing]

        # Act: call main through the error-capturing helper, with stdout captured to read the per-file line
        with contextlib.redirect_stdout(io.StringIO()) as out:
            result, error = _attempt(eg.main, argv)

        # Assert: no error, main returns 1, and the output names the missing file with no verdict
        self.assertIsNone(error, f"main raised {type(error).__name__}: {error}")
        self.assertEqual(result, 1)
        self.assertIn(missing + ": error, no verdict", out.getvalue())

    def test_main_badFileKeepsOtherCases(self):
        # Arrange: readable no-skill and tsr-before-2 files both holding a constant case c1, and a
        # tsr-before-1 file that is not JSON
        constant = [_record(True), _record(True), _record(True), _record(True)]
        with tempfile.TemporaryDirectory() as tmp:
            good = os.path.join(tmp, "no_skill.json")
            bad = os.path.join(tmp, "tsr_before_1.json")
            good_two = os.path.join(tmp, "tsr_before_2.json")
            with open(good, "w", encoding="utf-8") as handle:
                json.dump(_run_doc({"c1": constant}), handle)
            with open(bad, "w", encoding="utf-8") as handle:
                handle.write("not json")
            with open(good_two, "w", encoding="utf-8") as handle:
                json.dump(_run_doc({"c1": constant}), handle)
            argv = ["no-skill=" + good, "tsr-before-1=" + bad, "tsr-before-2=" + good_two]

            # Act: call main through the error-capturing helper, with stdout captured to read the output lines
            with contextlib.redirect_stdout(io.StringIO()) as out:
                result, error = _attempt(eg.main, argv)

        # Assert: no error, main returns 1, the bad file is named with no verdict, and c1 still gets its no-signal row
        self.assertIsNone(error, f"main raised {type(error).__name__}: {error}")
        self.assertEqual(result, 1)
        lines = out.getvalue().splitlines()
        self.assertIn(bad + ": error, no verdict", lines)
        self.assertTrue(any(line.startswith("c1: excluded: no signal") for line in lines), lines)

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

    def test_main_groupedAwayCasePrintsExcludedLine(self):
        # Arrange: the same three clean run files as test_main_cleanRun_printsGroupLine, so c2 is grouped
        # away under c1 and must also print its own excluded line
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

            # Act: call main through the error-capturing helper, with stdout captured to read the output lines
            with contextlib.redirect_stdout(io.StringIO()) as out:
                result, error = _attempt(eg.main, argv)

        # Assert: no error, main returns 0, the group line keeps c1 with c2, and c2 prints its excluded line
        self.assertIsNone(error, f"main raised {type(error).__name__}: {error}")
        self.assertEqual(result, 0)
        lines = out.getvalue().splitlines()
        self.assertIn("group kept c1: c2", lines)
        self.assertIn("c2: excluded: grouped with c1", lines)

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

    def test_main_caseMissingFromOneLabelPrintsLine(self):
        # Arrange: c1 appears in all four labels with rates 0.5, 0.75, 0.25, 0.5. c3 appears in the
        # first three labels only (rates 0.5, 0.25, 0.75). Over the three labels c1 and c3 share, their
        # rate vectors correlate at -1, which is not None, so c3 is non-constant and must print varies.
        records_no_skill_c1 = [_record(True), _record(False), _record(True), _record(False)]
        records_before_1_c1 = [_record(True), _record(True), _record(True), _record(False)]
        records_before_2_c1 = [_record(True), _record(False), _record(False), _record(False)]
        records_before_3_c1 = [_record(True), _record(False), _record(True), _record(False)]
        records_no_skill_c3 = [_record(True), _record(False), _record(True), _record(False)]
        records_before_1_c3 = [_record(True), _record(False), _record(False), _record(False)]
        records_before_2_c3 = [_record(True), _record(True), _record(True), _record(False)]
        with tempfile.TemporaryDirectory() as tmp:
            path_a = os.path.join(tmp, "no_skill.json")
            path_b = os.path.join(tmp, "tsr_before_1.json")
            path_c = os.path.join(tmp, "tsr_before_2.json")
            path_d = os.path.join(tmp, "tsr_before_3.json")
            with open(path_a, "w", encoding="utf-8") as handle:
                json.dump(_run_doc({"c1": records_no_skill_c1, "c3": records_no_skill_c3}), handle)
            with open(path_b, "w", encoding="utf-8") as handle:
                json.dump(_run_doc({"c1": records_before_1_c1, "c3": records_before_1_c3}), handle)
            with open(path_c, "w", encoding="utf-8") as handle:
                json.dump(_run_doc({"c1": records_before_2_c1, "c3": records_before_2_c3}), handle)
            with open(path_d, "w", encoding="utf-8") as handle:
                json.dump(_run_doc({"c1": records_before_3_c1}), handle)
            argv = [
                "no-skill=" + path_a,
                "tsr-before-1=" + path_b,
                "tsr-before-2=" + path_c,
                "tsr-before-3=" + path_d,
            ]

            # Act: call main through the error-capturing helper, with stdout captured to read the per-case lines
            with contextlib.redirect_stdout(io.StringIO()) as out:
                result, error = _attempt(eg.main, argv)

        # Assert: no error, main returns 0, and the output carries a varies line for c3
        self.assertIsNone(error, f"main raised {type(error).__name__}: {error}")
        self.assertEqual(result, 0)
        self.assertIn("c3: varies", out.getvalue().splitlines())

    def test_main_caseWithNoRuns_printsNoRunsLine(self):
        # Arrange: two label files. In no-skill, c2 has two records that are both unscored, so its
        # pooled list for no-skill is empty. In tsr-before-1, c2 has one scored pass and one scored fail.
        with tempfile.TemporaryDirectory() as tmp:
            path_a = os.path.join(tmp, "no_skill.json")
            path_b = os.path.join(tmp, "tsr_before_1.json")
            with open(path_a, "w", encoding="utf-8") as handle:
                json.dump(
                    _run_doc(
                        {
                            "c1": [_record(True), _record(False)],
                            "c2": [_record(True, scored=False), _record(True, scored=False)],
                        }
                    ),
                    handle,
                )
            with open(path_b, "w", encoding="utf-8") as handle:
                json.dump(
                    _run_doc({"c1": [_record(True), _record(True)], "c2": [_record(True), _record(False)]}),
                    handle,
                )
            argv = ["no-skill=" + path_a, "tsr-before-1=" + path_b]

            # Act: call main through the error-capturing helper, with stdout captured to read the per-case lines
            with contextlib.redirect_stdout(io.StringIO()) as out:
                result, error = _attempt(eg.main, argv)

        # Assert: no error, main returns 0, and the output carries the no-runs line for c2 under no-skill
        self.assertIsNone(error, f"main raised {type(error).__name__}: {error}")
        self.assertEqual(result, 0)
        self.assertIn("c2: no runs under no-skill", out.getvalue().splitlines())


    @unittest.skipUnless(os.path.isdir("/dev/fd"), "needs /dev/fd to pass a pipe as a path")
    def test_main_pipeArgument_printsNormalOutput(self):
        # Arrange: a run file written into a pipe, which can be read only once, and a second label's
        # regular file with the same records, so case c1 is classified under two labels
        doc = json.dumps(_run_doc({"c1": [_record(True), _record(False), _record(True), _record(False)]}))
        read_fd, write_fd = os.pipe()
        os.write(write_fd, doc.encode("utf-8"))
        os.close(write_fd)
        try:
            with tempfile.TemporaryDirectory() as tmp:
                path_b = os.path.join(tmp, "tsr_before_1.json")
                with open(path_b, "w", encoding="utf-8") as handle:
                    handle.write(doc)
                argv = ["no-skill=/dev/fd/" + str(read_fd), "tsr-before-1=" + path_b]
                # Act: call main with the pipe as the no-skill run file, with stdout captured to read the per-case line
                with contextlib.redirect_stdout(io.StringIO()) as out:
                    result, error = _attempt(eg.main, argv)
        finally:
            os.close(read_fd)

        # Assert: no traceback, main returns 0, and the output carries the no-signal line for c1
        self.assertIsNone(error, f"main raised {type(error).__name__}: {error}")
        self.assertEqual(result, 0)
        self.assertIn("c1: excluded: no signal", out.getvalue())

    def test_main_nonBoolScored_printsNoVerdictAndReturnsOne(self):
        # Arrange: a no-skill run file whose only record has scored set to the string "false", and a clean tsr-before-1 file
        with tempfile.TemporaryDirectory() as tmp:
            path_a = os.path.join(tmp, "no_skill.json")
            path_b = os.path.join(tmp, "tsr_before_1.json")
            doc = {"cases": [{"name": "c1", "arms": {"with": [{"passed": True, "score": 1, "error": None, "scored": "false"}]}}]}
            with open(path_a, "w", encoding="utf-8") as handle:
                json.dump(doc, handle)
            with open(path_b, "w", encoding="utf-8") as handle:
                json.dump(_run_doc({"c1": [_record(True)]}), handle)
            argv = ["no-skill=" + path_a, "tsr-before-1=" + path_b]

            # Act: call main through the error-capturing helper, with stdout captured to read the per-file line
            with contextlib.redirect_stdout(io.StringIO()) as out:
                result, error = _attempt(eg.main, argv)

        # Assert: no traceback, main returns 1, and the output names the non-bool file with no verdict
        self.assertIsNone(error, f"main raised {type(error).__name__}: {error}")
        self.assertEqual(result, 1)
        self.assertIn(path_a + ": error, no verdict", out.getvalue().splitlines())

    def test_main_nullPassed_printsNoVerdictAndReturnsOne(self):
        # Arrange: a run file whose only record has passed set to null
        with tempfile.TemporaryDirectory() as tmp:
            path = os.path.join(tmp, "null_passed.json")
            doc = {"cases": [{"name": "c1", "arms": {"with": [{"passed": None, "score": 0, "error": None}]}}]}
            with open(path, "w", encoding="utf-8") as handle:
                json.dump(doc, handle)
            argv = ["no-skill=" + path, "tsr-before-1=" + path]

            # Act: call main through the error-capturing helper, with stdout captured to read the per-file line
            with contextlib.redirect_stdout(io.StringIO()) as out:
                result, error = _attempt(eg.main, argv)

        # Assert: no traceback, main returns 1, and the output names the file with no verdict
        self.assertIsNone(error, f"main raised {type(error).__name__}: {error}")
        self.assertEqual(result, 1)
        self.assertIn(path + ": error, no verdict", out.getvalue().splitlines())

    def test_main_caseWithNoScoredRuns_isNotExcludedAsNoSignal(self):
        # Arrange: case z has only unscored records under both labels, so it has no scored run anywhere
        unscored = [_record(True, scored=False), _record(False, scored=False)]
        with tempfile.TemporaryDirectory() as tmp:
            path_a = os.path.join(tmp, "no_skill.json")
            path_b = os.path.join(tmp, "tsr_before_1.json")
            with open(path_a, "w", encoding="utf-8") as handle:
                json.dump(_run_doc({"z": unscored}), handle)
            with open(path_b, "w", encoding="utf-8") as handle:
                json.dump(_run_doc({"z": unscored}), handle)
            argv = ["no-skill=" + path_a, "tsr-before-1=" + path_b]

            # Act: call main through the error-capturing helper, with stdout captured to read the per-case lines
            with contextlib.redirect_stdout(io.StringIO()) as out:
                result, error = _attempt(eg.main, argv)

        # Assert: no error, main returns 0, z prints no-runs lines under both labels, and no no-signal line
        self.assertIsNone(error, f"main raised {type(error).__name__}: {error}")
        self.assertEqual(result, 0)
        lines = out.getvalue().splitlines()
        self.assertNotIn("z: excluded: no signal", lines)
        self.assertIn("z: no runs under no-skill", lines)
        self.assertIn("z: no runs under tsr-before-1", lines)

    def test_main_caseUnderOneLabelOnly_isNotExcludedAsNoSignal(self):
        # Arrange: case only holds scored runs under no-skill; case c1 holds scored runs under tsr-before-1 only
        with tempfile.TemporaryDirectory() as tmp:
            path_a = os.path.join(tmp, "no_skill.json")
            path_b = os.path.join(tmp, "tsr_before_1.json")
            with open(path_a, "w", encoding="utf-8") as handle:
                json.dump(_run_doc({"only": [_record(True), _record(True)]}), handle)
            with open(path_b, "w", encoding="utf-8") as handle:
                json.dump(_run_doc({"c1": [_record(True), _record(False)]}), handle)
            argv = ["no-skill=" + path_a, "tsr-before-1=" + path_b]

            # Act: call main through the error-capturing helper, with stdout captured to read the per-case lines
            with contextlib.redirect_stdout(io.StringIO()) as out:
                result, error = _attempt(eg.main, argv)

        # Assert: no error, main returns 0, only is not excluded as no signal, and it names the label it lacks
        self.assertIsNone(error, f"main raised {type(error).__name__}: {error}")
        self.assertEqual(result, 0)
        lines = out.getvalue().splitlines()
        self.assertNotIn("only: excluded: no signal", lines)
        self.assertIn("only: no runs under tsr-before-1", lines)

    def test_main_unequalRunCountsBothOrders_printsSameBoundLine(self):
        # Arrange: case c1 fails every run; no-skill holds 4 runs and tsr-before-1 holds 10
        with tempfile.TemporaryDirectory() as tmp:
            path_a = os.path.join(tmp, "no_skill.json")
            path_b = os.path.join(tmp, "tsr_before_1.json")
            with open(path_a, "w", encoding="utf-8") as handle:
                json.dump(_run_doc({"c1": [_record(False)] * 4}), handle)
            with open(path_b, "w", encoding="utf-8") as handle:
                json.dump(_run_doc({"c1": [_record(False)] * 10}), handle)
            argv_forward = ["no-skill=" + path_a, "tsr-before-1=" + path_b]
            argv_reverse = ["tsr-before-1=" + path_b, "no-skill=" + path_a]

            # Act: call main in both argument orders, with stdout captured to read the per-case lines
            with contextlib.redirect_stdout(io.StringIO()) as out_forward:
                result_forward, error_forward = _attempt(eg.main, argv_forward)
            with contextlib.redirect_stdout(io.StringIO()) as out_reverse:
                result_reverse, error_reverse = _attempt(eg.main, argv_reverse)

        # Assert: no error in either order, and both orders print the bound for n = 4, the no-skill run count
        self.assertIsNone(error_forward, f"main raised {type(error_forward).__name__}: {error_forward}")
        self.assertIsNone(error_reverse, f"main raised {type(error_reverse).__name__}: {error_reverse}")
        self.assertEqual(result_forward, 0)
        self.assertEqual(result_reverse, 0)
        expected = "c1: excluded: no signal bound 0.527 (not evidence of keeping the behavior)"
        self.assertIn(expected, out_forward.getvalue().splitlines())
        self.assertIn(expected, out_reverse.getvalue().splitlines())

    def test_main_singletonCase_printsNoGroupLine(self):
        # Arrange: case c1 is non-constant and is the only case, so it is grouped with nothing
        with tempfile.TemporaryDirectory() as tmp:
            path_a = os.path.join(tmp, "no_skill.json")
            path_b = os.path.join(tmp, "tsr_before_1.json")
            with open(path_a, "w", encoding="utf-8") as handle:
                json.dump(_run_doc({"c1": [_record(True), _record(False), _record(True), _record(False)]}), handle)
            with open(path_b, "w", encoding="utf-8") as handle:
                json.dump(_run_doc({"c1": [_record(True), _record(True), _record(True), _record(False)]}), handle)
            argv = ["no-skill=" + path_a, "tsr-before-1=" + path_b]

            # Act: call main through the error-capturing helper, with stdout captured to read the output lines
            with contextlib.redirect_stdout(io.StringIO()) as out:
                result, error = _attempt(eg.main, argv)

        # Assert: no error, main returns 0, and no line announces a group kept
        self.assertIsNone(error, f"main raised {type(error).__name__}: {error}")
        self.assertEqual(result, 0)
        self.assertEqual([line for line in out.getvalue().splitlines() if line.startswith("group kept")], [])

    def test_main_noSignalCase_printsNoGroupLine(self):
        # Arrange: case c1 has the same pass rate in both labels, so it is a no-signal case
        records = [_record(True), _record(False), _record(True), _record(False)]
        with tempfile.TemporaryDirectory() as tmp:
            path_a = os.path.join(tmp, "no_skill.json")
            path_b = os.path.join(tmp, "tsr_before_1.json")
            with open(path_a, "w", encoding="utf-8") as handle:
                json.dump(_run_doc({"c1": records}), handle)
            with open(path_b, "w", encoding="utf-8") as handle:
                json.dump(_run_doc({"c1": records}), handle)
            argv = ["no-skill=" + path_a, "tsr-before-1=" + path_b]

            # Act: call main through the error-capturing helper, with stdout captured to read the output lines
            with contextlib.redirect_stdout(io.StringIO()) as out:
                result, error = _attempt(eg.main, argv)

        # Assert: no error, main returns 0, c1 is excluded as no signal, and no line announces a group kept
        self.assertIsNone(error, f"main raised {type(error).__name__}: {error}")
        self.assertEqual(result, 0)
        lines = out.getvalue().splitlines()
        self.assertIn("c1: excluded: no signal", lines)
        self.assertEqual([line for line in lines if line.startswith("group kept")], [])

    def test_main_threeSharedLabelsWithFourthMissing_groupsCases(self):
        # Arrange: cases c1 and c2 hold identical records under the first three labels, so they correlate at 1.0
        # over those three shared labels; c2 has no run under the fourth label, tsr-before-3
        records_no_skill = [_record(True), _record(False), _record(True), _record(False)]
        records_before_1 = [_record(True), _record(True), _record(True), _record(False)]
        records_before_2 = [_record(True), _record(False), _record(False), _record(False)]
        records_before_3 = [_record(True), _record(False), _record(True), _record(False)]
        with tempfile.TemporaryDirectory() as tmp:
            path_a = os.path.join(tmp, "no_skill.json")
            path_b = os.path.join(tmp, "tsr_before_1.json")
            path_c = os.path.join(tmp, "tsr_before_2.json")
            path_d = os.path.join(tmp, "tsr_before_3.json")
            with open(path_a, "w", encoding="utf-8") as handle:
                json.dump(_run_doc({"c1": records_no_skill, "c2": records_no_skill}), handle)
            with open(path_b, "w", encoding="utf-8") as handle:
                json.dump(_run_doc({"c1": records_before_1, "c2": records_before_1}), handle)
            with open(path_c, "w", encoding="utf-8") as handle:
                json.dump(_run_doc({"c1": records_before_2, "c2": records_before_2}), handle)
            with open(path_d, "w", encoding="utf-8") as handle:
                json.dump(_run_doc({"c1": records_before_3}), handle)
            argv = [
                "no-skill=" + path_a,
                "tsr-before-1=" + path_b,
                "tsr-before-2=" + path_c,
                "tsr-before-3=" + path_d,
            ]

            # Act: call main through the error-capturing helper, with stdout captured to read the group lines
            with contextlib.redirect_stdout(io.StringIO()) as out:
                result, error = _attempt(eg.main, argv)

        # Assert: no error, main returns 0, and c2 is grouped with c1 on the three labels they share
        self.assertIsNone(error, f"main raised {type(error).__name__}: {error}")
        self.assertEqual(result, 0)
        lines = out.getvalue().splitlines()
        self.assertIn("group kept c1: c2", lines)
        self.assertIn("c2: excluded: grouped with c1", lines)


if __name__ == "__main__":
    unittest.main()
