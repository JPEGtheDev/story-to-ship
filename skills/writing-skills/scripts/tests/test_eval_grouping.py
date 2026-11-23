"""Tests for eval_grouping: run-file reading, pooling, bounds and the main report."""

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

    def test_reportRows_currentPassesMoreThanNoSkill_isSeparating(self):
        # Arrange: case c1 passes 4 of 4 under the current skill and 1 of 4 under no-skill
        columns = {"no-skill": {"c1": [True, False, False, False]}, "tsr-before-1": {"c1": [True, True, True, True]}}

        # Act: build the report rows through the error-capturing helper
        result, error = _attempt(eg.report_rows, columns)

        # Assert: no error, and the c1 row is labeled separating
        self.assertIsNone(error, f"report_rows raised {type(error).__name__}: {error}")
        row = next((r for r in result if r["case"] == "c1"), None)
        self.assertIsNotNone(row, "no row for case c1")
        self.assertEqual(row["label"], "separating")

    def test_reportRows_currentPassesTwentySixOfThirty_isWeak(self):
        # Arrange: case c1 passes 26 of 30 (under 90 percent) under the current skill and 10 of 30 under no-skill
        columns = {"no-skill": {"c1": [True] * 10 + [False] * 20}, "tsr-before-1": {"c1": [True] * 26 + [False] * 4}}

        # Act: build the report rows through the error-capturing helper
        result, error = _attempt(eg.report_rows, columns)

        # Assert: no error, and the c1 row is labeled weak because the current skill passes under 90 percent
        self.assertIsNone(error, f"report_rows raised {type(error).__name__}: {error}")
        row = next((r for r in result if r["case"] == "c1"), None)
        self.assertIsNotNone(row, "no row for case c1")
        self.assertEqual(row["label"], "weak")

    def test_reportRows_noSkillPassesAsOftenAsCurrent_isModelDefault(self):
        # Arrange: case c1 passes 4 of 4 under both no-skill and the current skill, so the rates are equal
        columns = {"no-skill": {"c1": [True] * 4}, "tsr-before-1": {"c1": [True] * 4}}

        # Act: build the report rows through the error-capturing helper
        result, error = _attempt(eg.report_rows, columns)

        # Assert: no error, and the c1 row is labeled model default because no-skill passes at least as often
        self.assertIsNone(error, f"report_rows raised {type(error).__name__}: {error}")
        row = next((r for r in result if r["case"] == "c1"), None)
        self.assertIsNotNone(row, "no row for case c1")
        self.assertEqual(row["label"], "model default")

    def test_reportRows_noSkillPassesMoreThanCurrentAndCurrentIsWeak_isWeak(self):
        # Arrange: case c1 passes 4 of 4 under no-skill and 1 of 4 under the current skill, so no-skill is strictly higher and the current skill is under 90 percent
        columns = {"no-skill": {"c1": [True, True, True, True]}, "tsr-before-1": {"c1": [True, False, False, False]}}

        # Act: build the report rows through the error-capturing helper
        result, error = _attempt(eg.report_rows, columns)

        # Assert: no error, and the c1 row is labeled weak, because weak takes precedence over model default
        self.assertIsNone(error, f"report_rows raised {type(error).__name__}: {error}")
        row = next((r for r in result if r["case"] == "c1"), None)
        self.assertIsNotNone(row, "no row for case c1")
        self.assertEqual(row["label"], "weak")

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

    def test_main_oneUsableLabel_printsOnlyErrorLines(self):
        # Arrange: no-skill holds a readable constant case c1; tsr-before-1 points at a missing file, so only one label is usable
        constant = [_record(True), _record(True), _record(True), _record(True)]
        missing = "/nonexistent-dir-for-one-usable-label/tsr_before_1.json"
        with tempfile.TemporaryDirectory() as tmp:
            good = os.path.join(tmp, "no_skill.json")
            with open(good, "w", encoding="utf-8") as handle:
                json.dump(_run_doc({"c1": constant}), handle)
            argv = ["no-skill=" + good, "tsr-before-1=" + missing]

            # Act: call main through the error-capturing helper, with stdout captured to read every output line
            with contextlib.redirect_stdout(io.StringIO()) as out:
                result, error = _attempt(eg.main, argv)

        # Assert: no error, main returns 1, and the only output line is the error line for the unreadable file
        self.assertIsNone(error, f"main raised {type(error).__name__}: {error}")
        self.assertEqual(result, 1)
        self.assertEqual(out.getvalue().splitlines(), [missing + ": error, no verdict"])

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

if __name__ == "__main__":
    unittest.main()
