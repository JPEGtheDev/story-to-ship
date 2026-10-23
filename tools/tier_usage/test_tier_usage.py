import contextlib
import io
import json
import os
import shutil
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import tier_usage  # noqa: E402

FIXTURES = os.path.join(HERE, "fixtures")
BASIC = os.path.join(FIXTURES, "basic")
DUP_USAGE = os.path.join(FIXTURES, "dup_usage")
VERDICTS = os.path.join(FIXTURES, "verdicts")
TIERS_FILE = os.path.join(HERE, "tiers.json")

# Family names are assembled at runtime so this file never spells them out.
FAMILY_A = "hai" + "ku"
FAMILY_B = "son" + "net"
FAMILY_C = "op" + "us"
FAMILY_D = "fa" + "ble"
VENDOR_NAMES = [FAMILY_A, FAMILY_B, FAMILY_C, FAMILY_D]

STAMP = "2026-01-01T00:00:01.000Z"
NO_RATES = "n/a (no rates)"


def usage(input_tokens, cache_write, cache_read, output):
    return {
        "input_tokens": input_tokens,
        "cache_creation_input_tokens": cache_write,
        "cache_read_input_tokens": cache_read,
        "output_tokens": output,
    }


def assistant(model, timestamp=STAMP, message_id=None, token_usage=None):
    message = {"model": model, "content": [{"type": "text", "text": "ok"}]}
    if message_id is not None:
        message["id"] = message_id
    if token_usage is not None:
        message["usage"] = token_usage
    return {"type": "assistant", "timestamp": timestamp, "message": message}


def user_line(timestamp=STAMP):
    return {
        "type": "user",
        "timestamp": timestamp,
        "message": {"role": "user", "content": "x"},
    }


def write_dispatch(folder, agent_id, meta=None, lines=None):
    os.makedirs(folder, exist_ok=True)
    if meta is not None:
        path = os.path.join(folder, "agent-%s.meta.json" % agent_id)
        with open(path, "w", encoding="utf-8") as handle:
            json.dump(meta, handle)
    if lines is not None:
        path = os.path.join(folder, "agent-%s.jsonl" % agent_id)
        with open(path, "w", encoding="utf-8") as handle:
            for line in lines:
                text = line if isinstance(line, str) else json.dumps(line)
                handle.write(text + "\n")


def write_tiers(folder, tiers):
    path = os.path.join(folder, "tiers.json")
    with open(path, "w", encoding="utf-8") as handle:
        json.dump({"tiers": tiers}, handle)
    return path


def default_tiers():
    return tier_usage.load_tiers(TIERS_FILE)


def collect_rows(folder, tiers=None):
    return tier_usage.collect(folder, tiers if tiers is not None else default_tiers())


def row_for(rows, agent_id):
    matches = [row for row in rows if row["agent_id"] == agent_id]
    if len(matches) != 1:
        raise AssertionError("expected one row for %s, got %d" % (agent_id, len(matches)))
    return matches[0]


def token_tuple(row):
    return (
        row["input_tokens"],
        row["cache_write_tokens"],
        row["cache_read_tokens"],
        row["est_output_tokens"],
    )


def run_main(argv):
    out = io.StringIO()
    err = io.StringIO()
    with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
        code = tier_usage.main(argv)
    return code, out.getvalue(), err.getvalue()


def tier_of(lines, meta=None):
    if meta is None:
        meta = {"agentType": "implementer"}
    with tempfile.TemporaryDirectory() as tmp:
        write_dispatch(tmp, "x1", meta=meta, lines=lines)
        rows, _ = collect_rows(tmp)
        return row_for(rows, "x1")["tier"]


def write_chain(folder, count):
    ids = ["c%02d" % index for index in range(count)]
    for index, agent_id in enumerate(ids):
        meta = {"agentType": "implementer"}
        if index + 1 < count:
            meta["parentAgentId"] = ids[index + 1]
        write_dispatch(folder, agent_id, meta=meta)
    return ids


class BasicFixtureTests(unittest.TestCase):
    def test_Collect_BasicFixture_ReturnsExpectedTuples(self):
        rows, _ = collect_rows(BASIC)
        got = [
            (
                row["tier"],
                row["runner"],
                row["input_tokens"],
                row["cache_write_tokens"],
                row["cache_read_tokens"],
                row["est_output_tokens"],
            )
            for row in rows
        ]
        expected = [
            ("standard", "r1:story-coordinator", 1, 10, 100, 5),
            ("economy", "r1:story-coordinator", 5, 50, 500, 16),
            ("standard", "r1:story-coordinator", 4, 40, 400, 11),
            ("premium", "r1:story-coordinator", 6, 60, 600, 13),
            ("unmapped", "r1:story-coordinator", 8, 80, 800, 17),
            ("standard", "r2:implementer", 7, 70, 700, 15),
        ]
        self.assertEqual(got, expected)

    def test_Collect_BasicFixture_RowsOrderedByRunnerThenFirstTs(self):
        rows, _ = collect_rows(BASIC)
        self.assertEqual(
            [row["agent_id"] for row in rows],
            ["r1", "i1", "s1", "g1", "u1", "r2"],
        )

    def test_Collect_BasicFixtureNullRates_CostIsNoRates(self):
        rows, _ = collect_rows(BASIC)
        for row in rows:
            self.assertEqual(row["cost_usd"], NO_RATES)

    def test_Collect_DepthThreeDispatch_RunnerIsTopLevel(self):
        rows, _ = collect_rows(BASIC)
        self.assertEqual(row_for(rows, "g1")["runner"], "r1:story-coordinator")

    def test_Collect_TwoMessageIds_TokensSummed(self):
        rows, _ = collect_rows(BASIC)
        self.assertEqual(token_tuple(row_for(rows, "i1")), (5, 50, 500, 16))

    def test_Main_BasicFixtureHeader_ContainsEstOutputColumn(self):
        code, out, _ = run_main([BASIC])
        self.assertEqual(code, 0)
        header = out.splitlines()[0].split("\t")
        self.assertIn("est_output_tokens", header)

    def test_Main_BasicFixtureRows_HaveThirteenColumns(self):
        code, out, _ = run_main([BASIC])
        self.assertEqual(code, 0)
        table_lines = [
            line for line in out.splitlines() if line and not line.startswith("#")
        ]
        self.assertGreater(len(table_lines), 1)
        for line in table_lines:
            self.assertEqual(len(line.split("\t")), 13, line)


class DupUsageTests(unittest.TestCase):
    def test_Collect_DupUsageFixture_CountsLastLineOfRepeatedMessage(self):
        rows, _ = collect_rows(DUP_USAGE)
        self.assertEqual(len(rows), 1)
        self.assertEqual(token_tuple(rows[0]), (4, 40, 400, 11))

    def test_Collect_DupUsageWithoutDuplicateFirstLine_SameTokens(self):
        with tempfile.TemporaryDirectory() as tmp:
            sub = os.path.join(tmp, "subagents")
            os.makedirs(sub)
            shutil.copy(
                os.path.join(DUP_USAGE, "subagents", "agent-d1.meta.json"), sub
            )
            with open(
                os.path.join(DUP_USAGE, "subagents", "agent-d1.jsonl"),
                encoding="utf-8",
            ) as handle:
                lines = handle.read().splitlines()
            first_dup = next(index for index, line in enumerate(lines) if "m_d1_1" in line)
            del lines[first_dup]
            with open(os.path.join(sub, "agent-d1.jsonl"), "w", encoding="utf-8") as handle:
                handle.write("\n".join(lines) + "\n")
            rows, _ = collect_rows(tmp)
        self.assertEqual(len(rows), 1)
        self.assertEqual(token_tuple(rows[0]), (4, 40, 400, 11))

    def test_Collect_DupUsageWithRates_CostIsExpected(self):
        tiers = default_tiers()
        tiers["standard"]["rates_per_million"] = {
            "input": 1000000,
            "cache_write": 2000000,
            "cache_read": 3000000,
            "output": 4000000,
        }
        with tempfile.TemporaryDirectory() as tmp:
            path = write_tiers(tmp, tiers)
            rows, _ = collect_rows(DUP_USAGE, tier_usage.load_tiers(path))
        self.assertEqual(row_for(rows, "d1")["cost_usd"], 1328.0)


class TierTests(unittest.TestCase):
    def test_TierOf_EconomyFamilyId_ReturnsEconomy(self):
        self.assertEqual(tier_of([assistant("claude-%s-4-5" % FAMILY_A)]), "economy")

    def test_TierOf_StandardFamilyId_ReturnsStandard(self):
        self.assertEqual(tier_of([assistant("claude-%s-4-5" % FAMILY_B)]), "standard")

    def test_TierOf_PremiumFamilyId_ReturnsPremium(self):
        self.assertEqual(tier_of([assistant("claude-%s-5-5" % FAMILY_C)]), "premium")

    def test_TierOf_UnknownId_ReturnsUnmapped(self):
        self.assertEqual(tier_of([assistant("claude-mystery-1")]), "unmapped")

    def test_TierOf_TwoTiersInOneDispatch_ReturnsMixed(self):
        lines = [
            assistant("claude-%s-4-5" % FAMILY_A),
            assistant("claude-%s-5-5" % FAMILY_C),
        ]
        self.assertEqual(tier_of(lines), "mixed")

    def test_TierOf_SyntheticOnlyWithMetaAlias_ReturnsAliasTier(self):
        tier = tier_of(
            [assistant("<synthetic>")],
            meta={"agentType": "implementer", "model": FAMILY_C},
        )
        self.assertEqual(tier, "premium")

    def test_TierOf_NoAssistantLineNoAlias_ReturnsUnmapped(self):
        self.assertEqual(tier_of([user_line()]), "unmapped")

    def test_TierOf_NoMetaModelKey_UsesTranscriptFamily(self):
        tier = tier_of(
            [assistant("claude-%s-4-5" % FAMILY_B)],
            meta={"agentType": "implementer"},
        )
        self.assertEqual(tier, "standard")


class RunnerTests(unittest.TestCase):
    def test_Collect_ParentAbsent_RunnerIsOrphan(self):
        with tempfile.TemporaryDirectory() as tmp:
            write_dispatch(
                tmp,
                "c1",
                meta={"agentType": "implementer", "parentAgentId": "ghost"},
            )
            rows, _ = collect_rows(tmp)
        self.assertTrue(row_for(rows, "c1")["runner"].startswith("orphan:"))

    def test_Collect_ParentCycle_RunnerIsOrphan(self):
        with tempfile.TemporaryDirectory() as tmp:
            write_dispatch(tmp, "ca", meta={"agentType": "implementer", "parentAgentId": "cb"})
            write_dispatch(tmp, "cb", meta={"agentType": "implementer", "parentAgentId": "ca"})
            rows, _ = collect_rows(tmp)
        self.assertTrue(row_for(rows, "ca")["runner"].startswith("orphan:"))
        self.assertTrue(row_for(rows, "cb")["runner"].startswith("orphan:"))

    def test_Collect_ChainLongerThanTenHops_RunnerIsOrphan(self):
        with tempfile.TemporaryDirectory() as tmp:
            ids = write_chain(tmp, 12)
            rows, _ = collect_rows(tmp)
        self.assertTrue(row_for(rows, ids[0])["runner"].startswith("orphan:"))

    def test_Collect_ChainOfExactlyTenHops_RunnerIsTopLevel(self):
        with tempfile.TemporaryDirectory() as tmp:
            ids = write_chain(tmp, 11)
            rows, _ = collect_rows(tmp)
        self.assertEqual(row_for(rows, ids[0])["runner"], "%s:implementer" % ids[-1])


class MalformedTests(unittest.TestCase):
    def test_Collect_BrokenJsonLine_SkippedAndValidLinesCount(self):
        with tempfile.TemporaryDirectory() as tmp:
            write_dispatch(
                tmp,
                "m1",
                meta={"agentType": "implementer", "model": FAMILY_B},
                lines=[
                    assistant("claude-%s-4-5" % FAMILY_B, message_id="a", token_usage=usage(1, 2, 3, 4)),
                    "{not json",
                    assistant("claude-%s-4-5" % FAMILY_B, message_id="b", token_usage=usage(10, 20, 30, 40)),
                ],
            )
            rows, counts = collect_rows(tmp)
        self.assertEqual(counts["malformed"], 1)
        self.assertEqual(token_tuple(row_for(rows, "m1")), (11, 22, 33, 44))

    def test_Collect_JsonArrayLine_CountsAsMalformed(self):
        with tempfile.TemporaryDirectory() as tmp:
            write_dispatch(
                tmp,
                "m2",
                meta={"agentType": "implementer", "model": FAMILY_B},
                lines=[
                    assistant("claude-%s-4-5" % FAMILY_B, message_id="a", token_usage=usage(1, 2, 3, 4)),
                    "[1, 2]",
                ],
            )
            rows, counts = collect_rows(tmp)
        self.assertEqual(counts["malformed"], 1)
        self.assertEqual(token_tuple(row_for(rows, "m2")), (1, 2, 3, 4))


class EmptyFolderTests(unittest.TestCase):
    def test_Collect_EmptySubagents_ReturnsNoRows(self):
        with tempfile.TemporaryDirectory() as tmp:
            os.makedirs(os.path.join(tmp, "subagents"))
            rows, _ = collect_rows(tmp)
        self.assertEqual(rows, [])

    def test_Main_EmptySubagents_ReturnsZeroWithHeaderAndFooter(self):
        with tempfile.TemporaryDirectory() as tmp:
            os.makedirs(os.path.join(tmp, "subagents"))
            code, out, _ = run_main([tmp])
        self.assertEqual(code, 0)
        lines = out.splitlines()
        self.assertEqual(lines[0], "\t".join(tier_usage.COLUMNS))
        self.assertTrue(lines[-1].startswith("# skipped"), lines[-1])


class PairingTests(unittest.TestCase):
    def test_Collect_MetaWithoutTranscript_RowHasNoneTokensAndAliasTier(self):
        with tempfile.TemporaryDirectory() as tmp:
            write_dispatch(tmp, "p1", meta={"agentType": "implementer", "model": FAMILY_C})
            rows, _ = collect_rows(tmp)
        row = row_for(rows, "p1")
        self.assertEqual(row["tier"], "premium")
        self.assertEqual(token_tuple(row), (None, None, None, None))
        self.assertIsNone(row["cost_usd"])

    def test_Collect_TranscriptWithoutMeta_NoRowAndCountedAsNoMeta(self):
        with tempfile.TemporaryDirectory() as tmp:
            write_dispatch(
                tmp,
                "p2",
                lines=[assistant("claude-%s-4-5" % FAMILY_B, message_id="a", token_usage=usage(1, 1, 1, 1))],
            )
            rows, counts = collect_rows(tmp)
        self.assertEqual(rows, [])
        self.assertEqual(counts["no_meta"], 1)


class UsageTests(unittest.TestCase):
    def test_Collect_UsageObjectMissing_CountsAsZeroTokens(self):
        with tempfile.TemporaryDirectory() as tmp:
            write_dispatch(
                tmp,
                "u2",
                meta={"agentType": "implementer", "model": FAMILY_B},
                lines=[assistant("claude-%s-4-5" % FAMILY_B, message_id="m1")],
            )
            rows, _ = collect_rows(tmp)
        self.assertEqual(token_tuple(row_for(rows, "u2")), (0, 0, 0, 0))


class MainErrorTests(unittest.TestCase):
    def test_Main_NonexistentPath_ReturnsTwoAndWritesStderr(self):
        code, _, err = run_main([os.path.join(BASIC, "does-not-exist")])
        self.assertEqual(code, 2)
        self.assertIn("not a directory", err)

    def test_Main_RegularFilePath_ReturnsTwoAndWritesStderr(self):
        code, _, err = run_main([TIERS_FILE])
        self.assertEqual(code, 2)
        self.assertIn("not a directory", err)


class SessionRootTests(unittest.TestCase):
    def test_Collect_SessionRootWithSubagentsChild_SameRowsAsFixture(self):
        with tempfile.TemporaryDirectory() as tmp:
            shutil.copytree(os.path.join(BASIC, "subagents"), os.path.join(tmp, "subagents"))
            rows_root, _ = collect_rows(tmp)
        rows_fixture, _ = collect_rows(BASIC)
        self.assertEqual(rows_root, rows_fixture)

    def test_Collect_SubagentsFolderPassedDirectly_SameRowsAsFixture(self):
        rows_sub, _ = collect_rows(os.path.join(BASIC, "subagents"))
        rows_fixture, _ = collect_rows(BASIC)
        self.assertEqual(rows_sub, rows_fixture)


class VendorNameTests(unittest.TestCase):
    def test_ScriptAndTestText_ContainsNoFamilyName(self):
        for path in (os.path.join(HERE, "tier_usage.py"), os.path.abspath(__file__)):
            with open(path, encoding="utf-8", errors="replace") as handle:
                lowered = handle.read().lower()
            for name in VENDOR_NAMES:
                self.assertNotIn(name, lowered, os.path.basename(path))

    def test_Folder_OnlyTiersJsonHoldsFamilyNames(self):
        found = set()
        for dirpath, dirnames, filenames in os.walk(HERE):
            dirnames[:] = [d for d in dirnames if d not in ("fixtures", "__pycache__")]
            for name in filenames:
                if name in ("tier_usage.py", "test_tier_usage.py"):
                    continue
                path = os.path.join(dirpath, name)
                with open(path, encoding="utf-8", errors="replace") as handle:
                    lowered = handle.read().lower()
                if any(vendor in lowered for vendor in VENDOR_NAMES):
                    found.add(os.path.relpath(path, HERE))
        self.assertEqual(found, {"tiers.json"})


def text_block(text):
    return {"type": "text", "text": text}


def handback_block(message):
    return {
        "type": "tool_use",
        "name": "SubagentHandback",
        "input": {"message": message},
    }


def reply(*blocks, model=None):
    """Return one assistant transcript line holding the given content blocks."""
    if model is None:
        model = "claude-%s-4-5" % FAMILY_B
    message = {"model": model, "content": list(blocks)}
    return {"type": "assistant", "timestamp": STAMP, "message": message}


def verdict_of(agent_type, lines):
    with tempfile.TemporaryDirectory() as tmp:
        write_dispatch(tmp, "x1", meta={"agentType": agent_type}, lines=lines)
        rows, _ = collect_rows(tmp)
        return row_for(rows, "x1")["verdict"]


class VerdictFixtureTests(unittest.TestCase):
    def test_Collect_VerdictsFixture_RowsCarryStatedVerdicts(self):
        rows, _ = collect_rows(VERDICTS)
        got = {row["agent_id"]: row["verdict"] for row in rows}
        self.assertEqual(
            got,
            {"v1": "DONE_WITH_CONCERNS", "v2": "GAPS", "v3": "NEEDS WORK"},
        )

    def test_ReadTranscript_HandbackFixture_FinalTextIsHandbackMessage(self):
        stats = tier_usage.read_transcript(
            os.path.join(VERDICTS, "subagents", "agent-v1.jsonl")
        )
        self.assertEqual(
            stats["final_text"],
            "STATUS: DONE_WITH_CONCERNS\nWorktree: x\nLimitations: none",
        )

    def test_Collect_BasicFixture_VerdictsAreUnreadable(self):
        rows, _ = collect_rows(BASIC)
        self.assertEqual({row["verdict"] for row in rows}, {"unreadable"})


class VerdictReportSourceTests(unittest.TestCase):
    def test_Verdict_HandbackBeforeLaterText_HandbackWins(self):
        verdict = verdict_of(
            "implementer",
            [
                reply(handback_block("STATUS: BLOCKED")),
                reply(text_block("STATUS: DONE")),
            ],
        )
        self.assertEqual(verdict, "BLOCKED")

    def test_Verdict_TwoHandbacks_LastHandbackWins(self):
        verdict = verdict_of(
            "implementer",
            [
                reply(handback_block("STATUS: BLOCKED")),
                reply(handback_block("STATUS: DONE")),
            ],
        )
        self.assertEqual(verdict, "DONE")

    def test_Verdict_NoHandback_LastTextBlockUsed(self):
        verdict = verdict_of(
            "implementer",
            [
                reply(text_block("STATUS: BLOCKED")),
                reply(text_block("STATUS: PARTIAL"), text_block("STATUS: DONE")),
            ],
        )
        self.assertEqual(verdict, "DONE")

    def test_Verdict_SyntheticLineIgnored_EarlierReportUsed(self):
        verdict = verdict_of(
            "spec-compliance-reviewer",
            [
                reply(text_block("VERDICT: GAPS")),
                reply(text_block("VERDICT: PASS"), model="<synthetic>"),
            ],
        )
        self.assertEqual(verdict, "GAPS")

    def test_Verdict_NoAssistantLines_Unreadable(self):
        self.assertEqual(verdict_of("implementer", []), "unreadable")

    def test_Verdict_MetaWithoutTranscript_Unreadable(self):
        with tempfile.TemporaryDirectory() as tmp:
            write_dispatch(tmp, "x1", meta={"agentType": "spec-compliance-reviewer"})
            rows, _ = collect_rows(tmp)
        self.assertEqual(row_for(rows, "x1")["verdict"], "unreadable")


class VerdictSpellingTests(unittest.TestCase):
    def test_Verdict_MisspelledOrPunctuatedValue_Unreadable(self):
        for line in ["VERDICT: Approved", "VERDICT: pass", "VERDICT: PASS."]:
            with self.subTest(line=line):
                verdict = verdict_of(
                    "spec-compliance-reviewer", [reply(text_block(line))]
                )
                self.assertEqual(verdict, "unreadable")

    def test_Verdict_MarkdownWrappedLine_Unreadable(self):
        verdict = verdict_of(
            "spec-compliance-reviewer",
            [reply(text_block("**VERDICT: PASS**"))],
        )
        self.assertEqual(verdict, "unreadable")

    def test_Verdict_IndentedLine_Unreadable(self):
        verdict = verdict_of(
            "spec-compliance-reviewer",
            [reply(text_block("  VERDICT: PASS"))],
        )
        self.assertEqual(verdict, "unreadable")

    def test_Verdict_WrongLabelForType_Unreadable(self):
        verdict = verdict_of(
            "spec-compliance-reviewer",
            [reply(text_block("STATUS: PASS"))],
        )
        self.assertEqual(verdict, "unreadable")

    def test_Verdict_AnotherTypesValue_Unreadable(self):
        verdict = verdict_of(
            "spec-compliance-reviewer",
            [reply(text_block("VERDICT: APPROVE"))],
        )
        self.assertEqual(verdict, "unreadable")

    def test_Verdict_QuotedTemplateAlternatives_Unreadable(self):
        verdict = verdict_of(
            "spec-compliance-reviewer",
            [reply(text_block("VERDICT: PASS | GAPS"))],
        )
        self.assertEqual(verdict, "unreadable")

    def test_Verdict_UnlistedAgentType_Unreadable(self):
        verdict = verdict_of("explorer", [reply(text_block("VERDICT: PASS"))])
        self.assertEqual(verdict, "unreadable")

    def test_Verdict_TrailingWhitespace_Accepted(self):
        verdict = verdict_of(
            "spec-compliance-reviewer",
            [reply(text_block("VERDICT: PASS   "))],
        )
        self.assertEqual(verdict, "PASS")


class VerdictRollupTests(unittest.TestCase):
    def test_Verdict_CodeQualityPerFileAndRollup_MostSevereWins(self):
        report = "\n".join(
            [
                "FILE: a.py",
                "VERDICT: APPROVE",
                "FILE: b.py",
                "VERDICT: REQUEST CHANGES",
                "VERDICT: REQUEST CHANGES",
            ]
        )
        verdict = verdict_of("code-quality-reviewer", [reply(text_block(report))])
        self.assertEqual(verdict, "REQUEST CHANGES")

    def test_Verdict_CodeQualityNitsThenApprove_MostSevereWins(self):
        report = "VERDICT: APPROVE WITH NITS\nVERDICT: APPROVE"
        verdict = verdict_of("code-quality-reviewer", [reply(text_block(report))])
        self.assertEqual(verdict, "APPROVE WITH NITS")

    def test_Verdict_SkillReviewerNeedsWorkThenPass_MostSevereWins(self):
        report = "FILE: a.md\nVERDICT: NEEDS WORK\nFILE: b.md\nVERDICT: PASS"
        verdict = verdict_of("skill-reviewer", [reply(text_block(report))])
        self.assertEqual(verdict, "NEEDS WORK")

    def test_Verdict_SkillReviewerAdvisoryThenPass_MostSevereWins(self):
        report = "VERDICT: PASS (size advisory)\nVERDICT: PASS"
        verdict = verdict_of("skill-reviewer", [reply(text_block(report))])
        self.assertEqual(verdict, "PASS (size advisory)")


class VerdictOtherTypesTests(unittest.TestCase):
    def test_Verdict_ImplementerBlockedThenDone_LastWins(self):
        report = "STATUS: BLOCKED\nWorktree: x\nSTATUS: DONE"
        verdict = verdict_of("implementer", [reply(text_block(report))])
        self.assertEqual(verdict, "DONE")

    def test_Verdict_PlanReviewerRequestChanges_Read(self):
        verdict = verdict_of(
            "plan-reviewer", [reply(text_block("VERDICT: REQUEST CHANGES"))]
        )
        self.assertEqual(verdict, "REQUEST CHANGES")

    def test_Verdict_SkepticApproveWithConditions_Read(self):
        verdict = verdict_of(
            "skeptic", [reply(text_block("VERDICT: APPROVE WITH CONDITIONS"))]
        )
        self.assertEqual(verdict, "APPROVE WITH CONDITIONS")

    def test_Verdict_ResearcherInconclusive_Read(self):
        verdict = verdict_of(
            "researcher", [reply(text_block("VERDICT: INCONCLUSIVE"))]
        )
        self.assertEqual(verdict, "INCONCLUSIVE")


FULL = os.path.join(FIXTURES, "full")
FULL_TODO_TABLE = [
    ("a1", "-", "-", "-"),
    ("i1", "1", 0, "yes"),
    ("s1", "1", "-", "-"),
    ("q1", "1", "-", "-"),
    ("i2", "2", 2, "no"),
    ("s2", "2", "-", "-"),
    ("f2", "2", 2, "no"),
    ("s2b", "2", "-", "-"),
    ("q2", "2", "-", "-"),
    ("f2b", "2", 2, "no"),
    ("q2b", "2", "-", "-"),
    ("i3", "3a", 0, "no"),
    ("s3", "3a", "-", "-"),
    ("iu", "unattributed", "-", "-"),
    ("a2", "-", "-", "-"),
    ("i4", "1", 0, "n/a"),
    ("q4", "1", "-", "-"),
]


def verdict_line(text, timestamp=STAMP):
    return {
        "type": "assistant",
        "timestamp": timestamp,
        "message": {
            "model": "claude-%s-4-5" % FAMILY_B,
            "content": [text_block(text)],
        },
    }


def dispatch_meta(agent_type, description, parent=None):
    meta = {"agentType": agent_type, "description": description}
    if parent is not None:
        meta["parentAgentId"] = parent
    return meta


def runner_meta():
    return {"agentType": "story-coordinator", "description": "runner"}


def tied_rows(dispatches):
    """Collect rows for (agent_id, meta, lines-or-None) entries in one folder."""
    with tempfile.TemporaryDirectory() as tmp:
        for agent_id, meta, lines in dispatches:
            write_dispatch(tmp, agent_id, meta=meta, lines=lines)
        rows, _ = collect_rows(tmp)
    return rows


def todo_of(description, agent_type="implementer"):
    meta = {"agentType": agent_type}
    if description is not None:
        meta["description"] = description
    rows = tied_rows([("x1", meta, None)])
    return row_for(rows, "x1")["todo"]


def fix_rounds_of(description):
    rows = tied_rows(
        [
            ("p1", runner_meta(), None),
            ("x1", dispatch_meta("implementer", description, "p1"), None),
        ]
    )
    return row_for(rows, "x1")["fix_rounds"]


class TodoFixtureTests(unittest.TestCase):
    def test_Collect_FullFixture_TodoFixRoundsAndStage1MatchExpectedTable(self):
        rows, _ = collect_rows(FULL)
        got = [
            (row["agent_id"], row["todo"], row["fix_rounds"], row["first_stage1_pass"])
            for row in rows
        ]
        self.assertEqual(got, FULL_TODO_TABLE)

    def test_Main_FullFixtureHeader_EndsWithTodoColumns(self):
        code, out, _ = run_main([FULL])
        self.assertEqual(code, 0)
        header = out.splitlines()[0].split("\t")
        self.assertEqual(header[-3:], ["todo", "fix_rounds", "first_stage1_pass"])


class TodoKeyTests(unittest.TestCase):
    def test_TodoKey_ImplementTodoOne_KeyIsOne(self):
        self.assertEqual(todo_of("Implement todo 1"), "1")

    def test_TodoKey_TodoOneA_KeyIsOneA(self):
        self.assertEqual(todo_of("Todo 1a"), "1a")

    def test_TodoKey_TodoOneB_KeyIsOneB(self):
        self.assertEqual(todo_of("Todo 1b"), "1b")

    def test_TodoKey_StageTwoT18Checklist_KeyIsEighteen(self):
        self.assertEqual(
            todo_of("Stage 2 review T18 checklist", "code-quality-reviewer"), "18"
        )

    def test_TodoKey_HashAfterT_KeyIsFour(self):
        self.assertEqual(todo_of("T#4 x"), "4")

    def test_TodoKey_FirstOfTwoTodos_KeyIsThirteen(self):
        self.assertEqual(todo_of("Fix round: todo 13 nits + todo 14 concern"), "13")

    def test_TodoKey_ReviewOfLetterSuffixId_Unattributed(self):
        self.assertEqual(todo_of("Stage 1 review of A3a", "spec-compliance-reviewer"), "unattributed")

    def test_TodoKey_RerunAfterFixRound_Unattributed(self):
        self.assertEqual(todo_of("Stage 1 re-run after fix round"), "unattributed")

    def test_TodoKey_NoNumber_Unattributed(self):
        self.assertEqual(todo_of("Implement the thing"), "unattributed")

    def test_TodoKey_DescriptionMissing_Unattributed(self):
        self.assertEqual(todo_of(None), "unattributed")

    def test_TodoKey_SpecReviewTodoFifteen_KeyIsFifteen(self):
        self.assertEqual(
            todo_of("Stage 1 spec review, todo 15", "spec-compliance-reviewer"), "15"
        )


class FixRoundDetectionTests(unittest.TestCase):
    def test_FixRound_FixRoundOneForTodoTwo_Counts(self):
        self.assertEqual(fix_rounds_of("Fix round 1 for todo 2"), 1)

    def test_FixRound_RoundOneWithoutFixWord_Counts(self):
        self.assertEqual(fix_rounds_of("T5 round 1 add rationale pins"), 1)

    def test_FixRound_ImplementRerun_DoesNotCount(self):
        self.assertEqual(fix_rounds_of("Implement todo 4 re-run"), 0)

    def test_FixRound_FixWithRerun_Counts(self):
        self.assertEqual(fix_rounds_of("Fix: re-run todo 4"), 1)

    def test_FixRound_ReviewerDescriptionSaysFix_DoesNotCount(self):
        rows = tied_rows(
            [
                ("p1", runner_meta(), None),
                ("i1", dispatch_meta("implementer", "Implement todo 3", "p1"), None),
                (
                    "s1",
                    dispatch_meta("spec-compliance-reviewer", "Fix stage 1 todo 3", "p1"),
                    None,
                ),
            ]
        )
        self.assertEqual(row_for(rows, "i1")["fix_rounds"], 0)

    def test_FixRound_TwoFixDispatches_OriginalShowsTwo(self):
        rows = tied_rows(
            [
                ("p1", runner_meta(), None),
                ("i1", dispatch_meta("implementer", "Implement todo 2", "p1"), None),
                ("f1", dispatch_meta("implementer", "Fix round 1 for todo 2", "p1"), None),
                ("f2", dispatch_meta("implementer", "Fix round 2 for todo 2", "p1"), None),
            ]
        )
        self.assertEqual(row_for(rows, "i1")["fix_rounds"], 2)


class PerRunnerScopingTests(unittest.TestCase):
    def test_FixRound_SameTodoInTwoRunners_FixInOneDoesNotRaiseOther(self):
        rows = tied_rows(
            [
                ("p1", runner_meta(), None),
                ("p2", runner_meta(), None),
                ("i1", dispatch_meta("implementer", "Implement todo 1", "p1"), None),
                ("i2", dispatch_meta("implementer", "Implement todo 1", "p2"), None),
                ("f2", dispatch_meta("implementer", "Fix round 1 for todo 1", "p2"), None),
            ]
        )
        self.assertEqual(row_for(rows, "i1")["fix_rounds"], 0)
        self.assertEqual(row_for(rows, "i2")["fix_rounds"], 1)


class FirstStage1Tests(unittest.TestCase):
    def test_FirstStage1_EarlierReviewerWinsOverLaterAgentId(self):
        rows = tied_rows(
            [
                ("p1", runner_meta(), None),
                ("i5", dispatch_meta("implementer", "Implement todo 5", "p1"), None),
                (
                    "zz",
                    dispatch_meta("spec-compliance-reviewer", "Stage 1 review of todo 5", "p1"),
                    [verdict_line("VERDICT: PASS", "2026-01-01T00:00:05.000Z")],
                ),
                (
                    "aa",
                    dispatch_meta("spec-compliance-reviewer", "Stage 1 re-check, todo 5", "p1"),
                    [verdict_line("VERDICT: GAPS", "2026-01-01T00:00:09.000Z")],
                ),
            ]
        )
        self.assertEqual(row_for(rows, "i5")["first_stage1_pass"], "yes")

    def test_FirstStage1_ReviewerWithoutFirstTsIsLast(self):
        rows = tied_rows(
            [
                ("p1", runner_meta(), None),
                ("i5", dispatch_meta("implementer", "Implement todo 5", "p1"), None),
                (
                    "aa",
                    dispatch_meta("spec-compliance-reviewer", "Stage 1 review of todo 5", "p1"),
                    None,
                ),
                (
                    "zz",
                    dispatch_meta("spec-compliance-reviewer", "Stage 1 re-check, todo 5", "p1"),
                    [verdict_line("VERDICT: PASS", "2026-01-01T00:00:05.000Z")],
                ),
            ]
        )
        self.assertEqual(row_for(rows, "i5")["first_stage1_pass"], "yes")

    def test_FirstStage1_OnlyReviewerUnattributed_NotApplicable(self):
        rows = tied_rows(
            [
                ("p1", runner_meta(), None),
                ("i6", dispatch_meta("implementer", "Implement todo 6", "p1"), None),
                (
                    "s6",
                    dispatch_meta("spec-compliance-reviewer", "Stage 1 review of A3a", "p1"),
                    [verdict_line("VERDICT: PASS", "2026-01-01T00:00:05.000Z")],
                ),
            ]
        )
        self.assertEqual(row_for(rows, "i6")["first_stage1_pass"], "n/a")


class OtherTypesTests(unittest.TestCase):
    def test_OtherTypes_ExplorerAndCoordinator_AllDashes(self):
        rows = tied_rows(
            [
                ("e1", dispatch_meta("explorer", "Fix todo 9 survey"), None),
                ("a1", dispatch_meta("story-coordinator", "Stage 1 review of todo 9"), None),
            ]
        )
        for agent_id in ("e1", "a1"):
            row = row_for(rows, agent_id)
            self.assertEqual(
                (row["todo"], row["fix_rounds"], row["first_stage1_pass"]),
                ("-", "-", "-"),
            )

    def test_Unattributed_ImplementerRow_FixRoundsAndFirstStage1Dashes(self):
        rows = tied_rows(
            [
                ("p1", runner_meta(), None),
                ("iu", dispatch_meta("implementer", "Fix README nit", "p1"), None),
            ]
        )
        row = row_for(rows, "iu")
        self.assertEqual(
            (row["todo"], row["fix_rounds"], row["first_stage1_pass"]),
            ("unattributed", "-", "-"),
        )


if __name__ == "__main__":
    unittest.main()
