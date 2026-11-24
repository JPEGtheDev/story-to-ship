import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import unittest

MODULE_PATH = os.path.join(os.path.dirname(__file__), "..", "eval_verdict.py")


def _load():
    """Load eval_verdict by file path at call time; None while the module is missing."""
    if not os.path.exists(MODULE_PATH):
        return None
    spec = importlib.util.spec_from_file_location("eval_verdict", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _stage_verdict(stage, ref_pass, ref_n, cand_pass, cand_n):
    module = _load()
    return None if module is None else module.stage_verdict(stage, ref_pass, ref_n, cand_pass, cand_n)


def _p(ref_pass, ref_n, cand_pass, cand_n):
    module = _load()
    return None if module is None else module.fisher_one_sided(ref_pass, ref_n, cand_pass, cand_n)


def _confirm_verdict(fresh_pass, fresh_n, ref_pass, ref_n):
    module = _load()
    fn = getattr(module, "confirm_verdict", None)
    return None if fn is None else fn(fresh_pass, fresh_n, ref_pass, ref_n)


def _read_run_records(path):
    module = _load()
    fn = getattr(module, "read_run_records", None)
    return None if fn is None else fn(path)


def _cache_key(case_file_hashes, plugin_commit, model_id, judge_model_id, claude_code_version):
    module = _load()
    fn = getattr(module, "cache_key", None)
    return None if fn is None else fn(case_file_hashes, plugin_commit, model_id, judge_model_id, claude_code_version)


class StageVerdictTest(unittest.TestCase):
    def test_StageVerdict_Stage5TwoOfFiveAgainst30Of30_ReturnsLoss(self):
        # Arrange
        stage, ref, cand = 5, (30, 30), (2, 5)
        # Act
        verdict = _stage_verdict(stage, *ref, *cand)
        # Assert
        self.assertEqual("LOSS", verdict)

    def test_FisherOneSided_TwoOfFiveAgainst30Of30_ReturnsP0001528(self):
        # Arrange / Act
        p = _p(30, 30, 2, 5)
        # Assert
        self.assertIsNotNone(p)
        self.assertAlmostEqual(0.001528, p, places=6)

    def test_StageVerdict_Stage5ThreeOfFiveAgainst30Of30_ReturnsEdit(self):
        # Arrange
        expected_verdict = "EDIT"
        expected_p = 0.016807
        # Act
        verdict = _stage_verdict(5, 30, 30, 3, 5)
        p = _p(30, 30, 3, 5)
        # Assert
        self.assertEqual(expected_verdict, verdict)
        self.assertAlmostEqual(expected_p, p, places=6)

    def test_StageVerdict_Stage5FourOfFiveAgainst30Of30_ReturnsEdit(self):
        # Arrange
        expected_verdict = "EDIT"
        expected_p = 0.142857
        # Act
        verdict = _stage_verdict(5, 30, 30, 4, 5)
        p = _p(30, 30, 4, 5)
        # Assert
        self.assertEqual(expected_verdict, verdict)
        self.assertAlmostEqual(expected_p, p, places=6)

    def test_StageVerdict_Stage5OneOfFiveAgainst30Of30_ReturnsLoss(self):
        # Arrange
        expected_verdict = "LOSS"
        expected_p = 0.000095
        # Act
        verdict = _stage_verdict(5, 30, 30, 1, 5)
        p = _p(30, 30, 1, 5)
        # Assert
        self.assertEqual(expected_verdict, verdict)
        self.assertAlmostEqual(expected_p, p, places=6)

    def test_StageVerdict_Stage15TwelveOfFifteenAgainst30Of30_ReturnsLoss(self):
        # Arrange / Act
        verdict = _stage_verdict(15, 30, 30, 12, 15)
        p = _p(30, 30, 12, 15)
        # Assert
        self.assertEqual("LOSS", verdict)
        self.assertAlmostEqual(0.032065, p, places=6)

    def test_StageVerdict_Stage15FifteenOfFifteenAgainst30Of30_ReturnsHold(self):
        # Arrange / Act
        verdict = _stage_verdict(15, 30, 30, 15, 15)
        # Assert
        self.assertEqual("HOLD", verdict)

    def test_StageVerdict_Stage1513Of15Against30Of30_ReturnsNext(self):
        # Arrange
        stage, ref, cand = 15, (30, 30), (13, 15)
        # Act
        verdict = _stage_verdict(stage, *ref, *cand)
        p = _p(*ref, *cand)
        # Assert
        self.assertEqual("NEXT", verdict)
        self.assertAlmostEqual(0.106061, p, places=6)

    def test_StageVerdict_Stage1514Of15Against30Of30_ReturnsNext(self):
        # Arrange
        stage, ref, cand = 15, (30, 30), (14, 15)
        # Act
        verdict = _stage_verdict(stage, *ref, *cand)
        p = _p(*ref, *cand)
        # Assert
        self.assertEqual("NEXT", verdict)
        self.assertAlmostEqual(0.333333, p, places=6)

    def test_StageVerdict_Stage1513Of15Against27Of30_ReturnsNext(self):
        # Arrange
        stage, ref, cand = 15, (27, 30), (13, 15)
        # Act
        verdict = _stage_verdict(stage, *ref, *cand)
        # Assert
        self.assertEqual("NEXT", verdict)

    def test_StageVerdict_Stage1514Of15Against27Of30_ReturnsHold(self):
        # Arrange
        stage, ref, cand = 15, (27, 30), (14, 15)
        # Act
        verdict = _stage_verdict(stage, *ref, *cand)
        # Assert
        self.assertEqual("HOLD", verdict)

    def test_StageVerdict_Stage1514Of15Against28Of30_ReturnsHold(self):
        # Arrange
        stage, ref, cand = 15, (28, 30), (14, 15)
        # Act
        verdict = _stage_verdict(stage, *ref, *cand)
        # Assert
        self.assertEqual("HOLD", verdict)

    def test_StageVerdict_Stage1513Of15Against28Of30_ReturnsNext(self):
        # Arrange
        stage, ref, cand = 15, (28, 30), (13, 15)
        # Act
        verdict = _stage_verdict(stage, *ref, *cand)
        # Assert
        self.assertEqual("NEXT", verdict)

    def test_StageVerdict_Stage3025Of30Against30Of30_ReturnsLoss(self):
        # Arrange
        stage, ref, cand = 30, (30, 30), (25, 30)
        # Act
        verdict = _stage_verdict(stage, *ref, *cand)
        p = _p(*ref, *cand)
        # Assert
        self.assertEqual("LOSS", verdict)
        self.assertAlmostEqual(0.026093, p, places=6)

    def test_StageVerdict_Stage3026Of30Against30Of30_ReturnsHold(self):
        # Arrange
        stage, ref, cand = 30, (30, 30), (26, 30)
        # Act
        verdict = _stage_verdict(stage, *ref, *cand)
        p = _p(*ref, *cand)
        # Assert
        self.assertEqual("HOLD", verdict)
        self.assertAlmostEqual(0.0562, p, places=4)


class ConfirmVerdictTest(unittest.TestCase):
    def test_ConfirmVerdict_Fresh26Of30Against30Of30PAboveZeroPointZeroFive_ReturnsHold(self):
        # Arrange: fresh 26/30 against reference 30/30 gives exact one-sided p = 0.0562
        fresh, ref = (26, 30), (30, 30)
        # Act
        verdict = _confirm_verdict(*fresh, *ref)
        # Assert
        self.assertEqual("HOLD", verdict)

    def test_ConfirmVerdict_Fresh0Of30Against30Of30PBelowZeroPointZeroFive_ReturnsLoss(self):
        # Arrange: fresh 0/30 against reference 30/30 gives one-sided p far below 0.05
        fresh, ref = (0, 30), (30, 30)
        # Act
        verdict = _confirm_verdict(*fresh, *ref)
        # Assert
        self.assertEqual("LOSS", verdict)


def _write_run(path, cases):
    """Write a run file in the cases[].arms.with[] schema; cases is {name: [(passed, error)]}."""
    data = {
        "cases": [
            {"name": name, "arms": {"with": [{"passed": p, "error": e} for p, e in runs]}}
            for name, runs in cases.items()
        ]
    }
    with open(path, "w") as handle:
        json.dump(data, handle)


def _run_cli(*args):
    return subprocess.run([sys.executable, MODULE_PATH, *args], capture_output=True, text=True)


class ReadRunRecordsTest(unittest.TestCase):
    def test_ReadRunRecords_FiveRecordsOneWithError_ReturnsFourKeptAndOneDropped(self):
        # Arrange
        runs = [(True, None), (False, None), (True, "timeout"), (True, None), (True, None)]
        with tempfile.TemporaryDirectory() as tmp:
            path = os.path.join(tmp, "run.json")
            _write_run(path, {"a": runs})
            # Act
            result = _read_run_records(path)
        # Assert
        self.assertIsNotNone(result)
        kept, dropped = result["a"]
        self.assertEqual(4, len(kept))
        self.assertEqual(1, dropped)


class CliTest(unittest.TestCase):
    def _files(self, tmp, cand_runs):
        ref = os.path.join(tmp, "ref.json")
        cand = os.path.join(tmp, "cand.json")
        _write_run(ref, {"a": [(True, None)] * 30})
        _write_run(cand, {"a": cand_runs})
        return f"ref={ref}", f"cand={cand}", cand

    def test_Cli_FourOfFiveAgainst30Of30_PrintsPAndEdit(self):
        # Arrange
        expected_line = "a: p=0.142857 EDIT"
        with tempfile.TemporaryDirectory() as tmp:
            ref, cand, _ = self._files(tmp, [(True, None)] * 4 + [(False, None)])
            # Act
            result = _run_cli("--stage", "5", ref, cand)
        # Assert
        self.assertEqual(0, result.returncode)
        self.assertIn(expected_line, result.stdout)

    def test_Cli_BadStageArgument_ExitsTwo(self):
        # Arrange
        with tempfile.TemporaryDirectory() as tmp:
            ref, cand, _ = self._files(tmp, [(True, None)] * 5)
            # Act
            result = _run_cli("--stage", "7", ref, cand)
        # Assert
        self.assertEqual(2, result.returncode)

    def test_Cli_PartialStageRunFile_ExitsTwo(self):
        # Arrange
        with tempfile.TemporaryDirectory() as tmp:
            ref, cand, _ = self._files(tmp, [(True, None), (False, None), (True, None)])
            # Act
            result = _run_cli("--stage", "5", ref, cand)
        # Assert
        self.assertEqual(2, result.returncode)
        self.assertIn("rerun", result.stderr)
        self.assertNotIn("LOSS", result.stdout)
        self.assertNotIn("NEXT", result.stdout)

    def test_Cli_MissingRunFile_ExitsTwo(self):
        # Arrange
        with tempfile.TemporaryDirectory() as tmp:
            ref, _, _ = self._files(tmp, [(True, None)] * 5)
            # Act
            result = _run_cli("--stage", "5", ref, "cand=" + os.path.join(tmp, "absent.json"))
        # Assert
        self.assertEqual(2, result.returncode)

    def test_Cli_MalformedJsonRunFile_ExitsTwo(self):
        # Arrange
        with tempfile.TemporaryDirectory() as tmp:
            ref, cand, cand_path = self._files(tmp, [(True, None)] * 5)
            with open(cand_path, "w") as handle:
                handle.write("{not json")
            # Act
            result = _run_cli("--stage", "5", ref, cand)
        # Assert
        self.assertEqual(2, result.returncode)

    def test_Cli_CaseWithoutArmsWithList_ExitsTwo(self):
        # Arrange
        with tempfile.TemporaryDirectory() as tmp:
            ref, cand, cand_path = self._files(tmp, [(True, None)] * 5)
            with open(cand_path, "w") as handle:
                json.dump({"cases": [{"name": "a", "arms": {}}]}, handle)
            # Act
            result = _run_cli("--stage", "5", ref, cand)
        # Assert
        self.assertEqual(2, result.returncode)

    def test_Cli_OneErrorRecordInFive_PrintsDroppedCount(self):
        # Arrange
        with tempfile.TemporaryDirectory() as tmp:
            ref, cand, _ = self._files(tmp, [(None, "timeout")] + [(True, None)] * 4)
            # Act
            result = _run_cli("--stage", "5", ref, cand)
        # Assert
        self.assertIn("a: dropped 1", result.stdout)
        self.assertIn("rerun", result.stderr)

    def test_Cli_TwoOfFiveAgainst30Of30_PrintsPAndLoss(self):
        # Arrange
        with tempfile.TemporaryDirectory() as tmp:
            ref, cand, _ = self._files(tmp, [(True, None)] * 2 + [(False, None)] * 3)
            # Act
            result = _run_cli("--stage", "5", ref, cand)
        # Assert
        self.assertEqual(0, result.returncode)
        self.assertIn("a: p=0.001528 LOSS", result.stdout)


class CacheKeyTest(unittest.TestCase):
    def test_CacheKey_ModelIdChanges_ReturnsDifferentKey(self):
        # Arrange
        others = ("case-hash", "plugin-commit", "judge-model", "1.0.0")
        # Act
        key_a = _cache_key(others[0], others[1], "model-a", others[2], others[3])
        key_b = _cache_key(others[0], others[1], "model-b", others[2], others[3])
        # Assert
        self.assertIsNotNone(key_a)
        self.assertNotEqual(key_a, key_b)

    def _assert_field_changes_key(self, index):
        base = ["case-hash", "plugin-commit", "model-a", "judge-model", "1.0.0"]
        changed = list(base)
        changed[index] = base[index] + "-changed"
        key_a = _cache_key(*base)
        key_b = _cache_key(*changed)
        self.assertIsNotNone(key_a)
        self.assertNotEqual(key_a, key_b)

    def test_CacheKey_CaseFileHashesChange_ReturnsDifferentKey(self):
        self._assert_field_changes_key(0)

    def test_CacheKey_PluginCommitChanges_ReturnsDifferentKey(self):
        self._assert_field_changes_key(1)

    def test_CacheKey_JudgeModelIdChanges_ReturnsDifferentKey(self):
        self._assert_field_changes_key(3)

    def test_CacheKey_ClaudeCodeVersionChanges_ReturnsDifferentKey(self):
        self._assert_field_changes_key(4)

    def test_CacheKey_SameInputsRepeat_ReturnsSameKey(self):
        # Arrange
        inputs = ("case-hash", "plugin-commit", "model-a", "judge-model", "1.0.0")
        # Act
        key_a = _cache_key(*inputs)
        key_b = _cache_key(*inputs)
        # Assert
        self.assertIsNotNone(key_a)
        self.assertEqual(key_a, key_b)


class RefusalTest(unittest.TestCase):
    def _paths(self, tmp, ref_runs, cand_runs, fresh_runs=None):
        ref = os.path.join(tmp, "ref.json")
        cand = os.path.join(tmp, "cand.json")
        _write_run(ref, {"a": ref_runs})
        _write_run(cand, {"a": cand_runs})
        args = [f"ref={ref}", f"cand={cand}"]
        if fresh_runs is not None:
            fresh = os.path.join(tmp, "fresh.json")
            _write_run(fresh, {"a": fresh_runs})
            args.append(f"fresh={fresh}")
        return args

    def test_Cli_FreshBatchConfirmsLoss_PrintsConfirmLoss(self):
        # Arrange
        cand = [(True, None)] * 2 + [(False, None)] * 3
        with tempfile.TemporaryDirectory() as tmp:
            args = self._paths(tmp, [(True, None)] * 30, cand, [(False, None)] * 30)
            # Act
            result = _run_cli("--stage", "5", *args)
        # Assert
        self.assertEqual(0, result.returncode)
        self.assertIn("a: p=0.001528 LOSS confirm=LOSS", result.stdout)

    def test_Cli_FreshBatchDoesNotConfirm_PrintsConfirmHold(self):
        # Arrange
        cand = [(True, None)] * 2 + [(False, None)] * 3
        with tempfile.TemporaryDirectory() as tmp:
            args = self._paths(tmp, [(True, None)] * 30, cand, [(True, None)] * 30)
            # Act
            result = _run_cli("--stage", "5", *args)
        # Assert
        self.assertEqual(0, result.returncode)
        self.assertIn("a: p=0.001528 LOSS confirm=HOLD", result.stdout)

    def test_Cli_RecordWithoutPassedField_ExitsTwo(self):
        # Arrange
        with tempfile.TemporaryDirectory() as tmp:
            args = self._paths(tmp, [(True, None)] * 30, [(True, None)] * 5)
            cand_path = os.path.join(tmp, "cand.json")
            with open(cand_path, "w") as handle:
                json.dump({"cases": [{"name": "a", "arms": {"with": [{"error": None}] * 5}}]}, handle)
            # Act
            result = _run_cli("--stage", "5", *args)
        # Assert
        self.assertEqual(2, result.returncode)
        self.assertNotIn("Traceback", result.stderr)

    def test_Cli_AllErrorReference_ExitsTwo(self):
        # Arrange
        with tempfile.TemporaryDirectory() as tmp:
            args = self._paths(tmp, [(None, "timeout")] * 30, [(True, None)] * 5)
            # Act
            result = _run_cli("--stage", "5", *args)
        # Assert
        self.assertEqual(2, result.returncode)
        self.assertIn("a", result.stderr)
        self.assertIn("ref.json", result.stderr)

    def test_Cli_AllErrorFresh_ExitsTwo(self):
        # Arrange
        cand = [(True, None)] * 2 + [(False, None)] * 3
        with tempfile.TemporaryDirectory() as tmp:
            args = self._paths(tmp, [(True, None)] * 30, cand, [(None, "timeout")] * 30)
            # Act
            result = _run_cli("--stage", "5", *args)
        # Assert
        self.assertEqual(2, result.returncode)
        self.assertIn("fresh.json", result.stderr)

    def test_Cli_FreshBatchShorterThanStage_ExitsTwo(self):
        # Arrange
        cand = [(True, None)] * 2 + [(False, None)] * 3
        with tempfile.TemporaryDirectory() as tmp:
            args = self._paths(tmp, [(True, None)] * 30, cand, [(False, None)] * 3)
            # Act
            result = _run_cli("--stage", "5", *args)
        # Assert
        self.assertEqual(2, result.returncode)
        self.assertNotIn("confirm=", result.stdout)

    def test_Cli_FreshBatchOfFiveRuns_ExitsTwoNamingCaseAndCount(self):
        # Arrange
        cand = [(True, None)] * 2 + [(False, None)] * 3
        with tempfile.TemporaryDirectory() as tmp:
            args = self._paths(tmp, [(True, None)] * 30, cand, [(True, None)] * 4 + [(False, None)])
            # Act
            result = _run_cli("--stage", "5", *args)
        # Assert
        self.assertEqual(2, result.returncode)
        self.assertNotIn("confirm=", result.stdout)
        self.assertIn("case a keeps 5 of 30", result.stderr)

    def test_Cli_FreshBatchOfThirtyOneRuns_ExitsTwoNamingCaseAndCount(self):
        # Arrange
        cand = [(True, None)] * 2 + [(False, None)] * 3
        with tempfile.TemporaryDirectory() as tmp:
            args = self._paths(tmp, [(True, None)] * 30, cand, [(False, None)] * 31)
            # Act
            result = _run_cli("--stage", "5", *args)
        # Assert
        self.assertEqual(2, result.returncode)
        self.assertNotIn("confirm=", result.stdout)
        self.assertIn("case a keeps 31 of 30", result.stderr)

    def test_Cli_LossCaseMissingFromFreshFile_ExitsTwoNamingCase(self):
        # Arrange
        cand = [(True, None)] * 2 + [(False, None)] * 3
        with tempfile.TemporaryDirectory() as tmp:
            args = self._paths(tmp, [(True, None)] * 30, cand)
            fresh = os.path.join(tmp, "fresh.json")
            _write_run(fresh, {"other": [(True, None)] * 30})
            # Act
            result = _run_cli("--stage", "5", *args, f"fresh={fresh}")
        # Assert
        self.assertEqual(2, result.returncode)
        self.assertIn("case a is missing from the fresh file", result.stderr)

    def test_Cli_CandidateCaseMissingFromReference_ExitsTwoWithMessage(self):
        # Arrange
        with tempfile.TemporaryDirectory() as tmp:
            ref = os.path.join(tmp, "ref.json")
            cand = os.path.join(tmp, "cand.json")
            _write_run(ref, {"other": [(True, None)] * 30})
            _write_run(cand, {"a": [(True, None)] * 5})
            # Act
            result = _run_cli("--stage", "5", f"ref={ref}", f"cand={cand}")
        # Assert
        self.assertEqual(2, result.returncode)
        self.assertIn("case a is missing from the reference file", result.stderr)

    def test_Cli_CandidateKeepsZeroRuns_ExitsTwoWithMessageOnStderr(self):
        # Arrange
        with tempfile.TemporaryDirectory() as tmp:
            args = self._paths(tmp, [(True, None)] * 30, [(None, "timeout")] * 5)
            # Act
            result = _run_cli("--stage", "5", *args)
        # Assert
        self.assertEqual(2, result.returncode)
        self.assertIn("a: rerun, 0 of 5 runs", result.stderr)
        self.assertNotIn("rerun", result.stdout)

    def test_Cli_FreshBatchWithDroppedRuns_PrintsDroppedCount(self):
        # Arrange
        cand = [(True, None)] * 2 + [(False, None)] * 3
        fresh = [(None, "timeout")] * 2 + [(False, None)] * 30
        with tempfile.TemporaryDirectory() as tmp:
            args = self._paths(tmp, [(True, None)] * 30, cand, fresh)
            # Act
            result = _run_cli("--stage", "5", *args)
        # Assert
        self.assertEqual(0, result.returncode)
        self.assertIn("a: dropped 2 (fresh)", result.stdout)
        self.assertIn("confirm=LOSS", result.stdout)

    def test_Cli_ReferenceWithDroppedRuns_PrintsDroppedCount(self):
        # Arrange
        ref = [(None, "timeout")] * 2 + [(True, None)] * 28
        with tempfile.TemporaryDirectory() as tmp:
            args = self._paths(tmp, ref, [(True, None)] * 5)
            # Act
            result = _run_cli("--stage", "5", *args)
        # Assert
        self.assertIn("a: dropped 2 (reference)", result.stdout)

    def test_Cli_CandidateWithMoreRunsThanStage_ExitsTwo(self):
        # Arrange
        with tempfile.TemporaryDirectory() as tmp:
            args = self._paths(tmp, [(True, None)] * 30, [(True, None)] * 6)
            # Act
            result = _run_cli("--stage", "5", *args)
        # Assert
        self.assertEqual(2, result.returncode)

    def test_Cli_FiveOfFiveAgainst30Of30_PrintsNextAtStage5(self):
        # Arrange
        with tempfile.TemporaryDirectory() as tmp:
            args = self._paths(tmp, [(True, None)] * 30, [(True, None)] * 5)
            # Act
            result = _run_cli("--stage", "5", *args)
        # Assert
        self.assertEqual(0, result.returncode)
        self.assertIn("a: p=1.000000 NEXT", result.stdout)


class SuiteModeTest(unittest.TestCase):
    def _suite(self, tmp, ref_cases, cand_cases, *extra):
        ref = os.path.join(tmp, "ref.json")
        cand = os.path.join(tmp, "cand.json")
        _write_run(ref, ref_cases)
        _write_run(cand, cand_cases)
        return _run_cli("--suite", f"ref={ref}", f"cand={cand}", *extra)

    def _assert_exit_two_by_suite_logic(self, result):
        self.assertEqual(2, result.returncode)
        self.assertNotIn("unrecognized arguments", result.stderr)
        self.assertNotIn("Traceback", result.stderr)

    def test_Suite_ThirtyOfThirtyAgainst30Of30_PrintsOkAndBelowReferenceZero(self):
        # Arrange
        expected_line = "a: ref=30/30 cand=30/30 OK"
        expected_summary = "below reference: 0"
        with tempfile.TemporaryDirectory() as tmp:
            # Act
            result = self._suite(tmp, {"a": [(True, None)] * 30}, {"a": [(True, None)] * 30})
        # Assert
        self.assertEqual(0, result.returncode)
        self.assertIn(expected_line, result.stdout)
        self.assertIn(expected_summary, result.stdout)

    def test_Suite_TwentySevenOfThirtyAgainst30Of30_PrintsBelowAndBelowReferenceOne(self):
        # Arrange
        expected_line = "a: ref=30/30 cand=27/30 BELOW"
        expected_summary = "below reference: 1"
        cand = [(True, None)] * 27 + [(False, None)] * 3
        with tempfile.TemporaryDirectory() as tmp:
            # Act
            result = self._suite(tmp, {"a": [(True, None)] * 30}, {"a": cand})
        # Assert
        self.assertEqual(0, result.returncode)
        self.assertIn(expected_line, result.stdout)
        self.assertIn(expected_summary, result.stdout)

    def test_Suite_CandidateKeeps29Runs_ExitsTwoNamingCase(self):
        # Arrange
        expected_message = "case a keeps 29 of 30"
        with tempfile.TemporaryDirectory() as tmp:
            # Act
            result = self._suite(tmp, {"a": [(True, None)] * 30}, {"a": [(True, None)] * 29})
        # Assert
        self._assert_exit_two_by_suite_logic(result)
        self.assertIn(expected_message, result.stderr)

    def test_Suite_CandidateKeeps31Runs_ExitsTwo(self):
        # Arrange
        ref, cand = [(True, None)] * 30, [(True, None)] * 31
        with tempfile.TemporaryDirectory() as tmp:
            # Act
            result = self._suite(tmp, {"a": ref}, {"a": cand})
        # Assert
        self._assert_exit_two_by_suite_logic(result)
        self.assertIn("error: case a keeps 31 of 30", result.stderr)

    def test_Suite_CandidateCaseMissingFromReference_ExitsTwo(self):
        # Arrange
        ref = {"a": [(True, None)] * 30}
        cand = {"a": [(True, None)] * 30, "b": [(True, None)] * 30}
        with tempfile.TemporaryDirectory() as tmp:
            # Act
            result = self._suite(tmp, ref, cand)
            ref_path = os.path.join(tmp, "ref.json")
        # Assert
        self._assert_exit_two_by_suite_logic(result)
        self.assertIn(f"case b is missing from the reference file {ref_path}", result.stderr)

    def test_Suite_ReferenceCaseMissingFromCandidate_ExitsTwo(self):
        # Arrange
        ref = {"a": [(True, None)] * 30, "b": [(True, None)] * 30}
        cand = {"a": [(True, None)] * 30}
        with tempfile.TemporaryDirectory() as tmp:
            # Act
            result = self._suite(tmp, ref, cand)
        # Assert
        self._assert_exit_two_by_suite_logic(result)
        self.assertIn("case b", result.stderr)

    def test_Suite_DroppedErroredCandidateRun_PrintsDroppedCountNamingCase(self):
        # Arrange
        expected_line = "a: dropped 1"
        cand = [(None, "timeout")] + [(True, None)] * 30
        with tempfile.TemporaryDirectory() as tmp:
            # Act
            result = self._suite(tmp, {"a": [(True, None)] * 30}, {"a": cand})
        # Assert
        self.assertEqual(0, result.returncode)
        self.assertIn(expected_line, result.stdout)
        self.assertIn("a: ref=30/30 cand=30/30 OK", result.stdout)

    def test_Suite_Reference29Of29Candidate29Of30_PrintsBelowByCrossMultiplication(self):
        # Arrange: 29*29 < 29*30 is BELOW, though 29 < 29 is false
        expected_line = "a: ref=29/29 cand=29/30 BELOW"
        cand = [(True, None)] * 29 + [(False, None)]
        with tempfile.TemporaryDirectory() as tmp:
            # Act
            result = self._suite(tmp, {"a": [(True, None)] * 29}, {"a": cand})
        # Assert
        self.assertEqual(0, result.returncode)
        self.assertIn(expected_line, result.stdout)
        self.assertIn("below reference: 1", result.stdout)

    def test_Suite_PartialCaseAWithCompleteCaseB_ExitsTwoAndStillPrintsCaseB(self):
        # Arrange
        ref = {"a": [(True, None)] * 30, "b": [(True, None)] * 30}
        cand = {"a": [(True, None)] * 29, "b": [(True, None)] * 30}
        with tempfile.TemporaryDirectory() as tmp:
            # Act
            result = self._suite(tmp, ref, cand)
        # Assert
        self._assert_exit_two_by_suite_logic(result)
        self.assertIn("case a keeps 29 of 30, rerun", result.stderr)
        self.assertIn("b: ref=30/30 cand=30/30 OK", result.stdout)

    def test_Suite_CombinedWithStage_ExitsTwo(self):
        # Arrange
        with tempfile.TemporaryDirectory() as tmp:
            # Act
            result = self._suite(tmp, {"a": [(True, None)] * 30}, {"a": [(True, None)] * 30}, "--stage", "5")
        # Assert
        self.assertEqual(2, result.returncode)
        self.assertIn("not allowed with", result.stderr)

    def test_Suite_WithFreshPath_ExitsTwo(self):
        # Arrange
        with tempfile.TemporaryDirectory() as tmp:
            fresh = os.path.join(tmp, "fresh.json")
            _write_run(fresh, {"a": [(True, None)] * 30})
            # Act
            result = self._suite(tmp, {"a": [(True, None)] * 30}, {"a": [(True, None)] * 30}, f"fresh={fresh}")
        # Assert
        self._assert_exit_two_by_suite_logic(result)
        self.assertIn("fresh", result.stderr)


if __name__ == "__main__":
    unittest.main()
