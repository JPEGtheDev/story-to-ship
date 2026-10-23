#!/usr/bin/env python3
"""Print one usage row per subagent dispatch found in a session folder.

The input is SESSION_DIR/subagents when that folder exists, otherwise
SESSION_DIR itself. Each dispatch is an agent-<id>.meta.json file, with an
optional agent-<id>.jsonl transcript beside it. The model-to-tier table is
read from tiers.json (next to this script unless --tiers is given).

Dispatch-to-todo tying. An implementer, spec-compliance-reviewer,
code-quality-reviewer or skill-reviewer row takes its todo key from the first
match of TODO_PATTERN in its dispatch description, lowercased ("1", "3a").
No match gives "unattributed". Keys are scoped per runner. Every other row
shows "-" in the todo, fix_rounds and first_stage1_pass columns.

Worked example from fixtures/full, runner a1: "Implement todo 2" (i2) and
"Fix round 1 for todo 2" (f2) both key to todo 2. f2 is a fix dispatch, and so
is f2b ("Fix round 2 for todo 2"), so both implementer rows show fix_rounds 2.
The Stage 1 reviewer for todo 2 is the earliest spec-compliance-reviewer row
with that key, and its verdict gives first_stage1_pass.
"""

import argparse
import json
import os
import re
import sys

DEFAULT_TIERS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tiers.json")
COLUMNS = [
    "agent_id",
    "agent_type",
    "tier",
    "runner",
    "input_tokens",
    "cache_write_tokens",
    "cache_read_tokens",
    "est_output_tokens",
    "cost_usd",
    "verdict",
    "todo",
    "fix_rounds",
    "first_stage1_pass",
]
NO_RATES = "n/a (no rates)"
NO_VALUE = "-"
MAX_HOPS = 10
SYNTHETIC_MODEL = "<synthetic>"
USAGE_KEYS = (
    "input_tokens",
    "cache_creation_input_tokens",
    "cache_read_input_tokens",
    "output_tokens",
)
RATE_KEY_FOR_USAGE = {
    "input_tokens": "input",
    "cache_creation_input_tokens": "cache_write",
    "cache_read_input_tokens": "cache_read",
    "output_tokens": "output",
}
AGENT_PREFIX = "agent-"
META_SUFFIX = ".meta.json"
TRANSCRIPT_SUFFIX = ".jsonl"
HANDBACK_TOOL = "SubagentHandback"
UNREADABLE = "unreadable"
# Verdict allowlist keyed by agent type. Each entry is (label, values), with
# values listed from least to most severe. An agent type missing from this
# table reads as UNREADABLE by design: its report carries no verdict line that
# this reader is allowed to trust.
VERDICT_TABLE = {
    "implementer": (
        "STATUS",
        ("DONE", "DONE_WITH_CONCERNS", "PARTIAL", "NEEDS_CONTEXT", "BLOCKED"),
    ),
    "spec-compliance-reviewer": ("VERDICT", ("PASS", "GAPS")),
    "code-quality-reviewer": (
        "VERDICT",
        ("APPROVE", "APPROVE WITH NITS", "REQUEST CHANGES", "REJECT"),
    ),
    "skill-reviewer": ("VERDICT", ("PASS", "PASS (size advisory)", "NEEDS WORK")),
    "plan-reviewer": ("VERDICT", ("APPROVE", "REQUEST CHANGES")),
    "skeptic": ("VERDICT", ("APPROVE", "APPROVE WITH CONDITIONS", "REJECT")),
    "researcher": ("VERDICT", ("CONFIRMED", "REFUTED", "INCONCLUSIVE")),
}
# Reports with one verdict per file plus a roll-up: the most severe candidate
# wins. Every other listed type takes its last candidate line.
MOST_SEVERE_TYPES = frozenset({"code-quality-reviewer", "skill-reviewer"})
IMPLEMENTER = "implementer"
STAGE1_TYPE = "spec-compliance-reviewer"
TODO_TYPES = frozenset(
    {IMPLEMENTER, STAGE1_TYPE, "code-quality-reviewer", "skill-reviewer"}
)
UNATTRIBUTED = "unattributed"
NOT_APPLICABLE = "n/a"
TODO_PATTERN = re.compile(r"(?i)\b(?:todo|t)\s*#?(\d+[a-z]?)\b")
FIX_PATTERN = re.compile(r"(?i)\bfix\w*")
ROUND_PATTERN = re.compile(r"(?i)\bround\s*\d+")
RERUN_PATTERN = re.compile(r"(?i)\bre-?(?:check|run)\b")


def load_tiers(path):
    """Return the tiers mapping (name -> spec) in file order."""
    with open(path, encoding="utf-8") as handle:
        data = json.load(handle)
    return data["tiers"]


def tier_for_model(model_id, tiers):
    """Return the first tier (file order) whose match fragment occurs in the id."""
    lowered = model_id.lower()
    for name, spec in tiers.items():
        for fragment in spec.get("match", []):
            if fragment and fragment.lower() in lowered:
                return name
    return None


def tier_label(model_ids, tiers):
    """Combine the tiers of several model ids into one tier label."""
    found = {tier_for_model(model_id, tiers) for model_id in model_ids}
    if not found:
        return "unmapped"
    mapped = {tier for tier in found if tier is not None}
    if None in found:
        return "mixed" if mapped else "unmapped"
    if len(mapped) == 1:
        return mapped.pop()
    return "mixed"


def _as_int(value):
    if isinstance(value, bool) or not isinstance(value, int):
        return 0
    return value


def read_transcript(path):
    """Parse one transcript into its counted usage records and bookkeeping."""
    usage_by_message = {}
    model_ids = set()
    timestamps = []
    malformed = 0
    handback_seen = False
    handback_text = None
    text_report = None
    with open(path, encoding="utf-8", errors="replace") as handle:
        for line_no, raw in enumerate(handle):
            text = raw.strip()
            if not text:
                continue
            try:
                obj = json.loads(text)
            except ValueError:
                malformed += 1
                continue
            if not isinstance(obj, dict):
                malformed += 1
                continue
            if obj.get("type") != "assistant":
                continue
            message = obj.get("message")
            if not isinstance(message, dict):
                continue
            model = message.get("model")
            if not isinstance(model, str):
                model = ""
            if model == SYNTHETIC_MODEL:
                continue
            content = message.get("content")
            if isinstance(content, list):
                for block in content:
                    if not isinstance(block, dict):
                        continue
                    if (
                        block.get("type") == "tool_use"
                        and block.get("name") == HANDBACK_TOOL
                    ):
                        handback_seen = True
                        tool_input = block.get("input")
                        handed_back = (
                            tool_input.get("message")
                            if isinstance(tool_input, dict)
                            else None
                        )
                        handback_text = (
                            handed_back if isinstance(handed_back, str) else None
                        )
                    elif block.get("type") == "text" and isinstance(
                        block.get("text"), str
                    ):
                        text_report = block["text"]
            model_ids.add(model)
            timestamp = obj.get("timestamp")
            if isinstance(timestamp, str):
                timestamps.append(timestamp)
            usage = message.get("usage")
            if not isinstance(usage, dict):
                usage = {}
            message_id = message.get("id")
            key = message_id if isinstance(message_id, str) else ("line", line_no)
            usage_by_message[key] = usage
    return {
        "model_ids": model_ids,
        "usages": list(usage_by_message.values()),
        "first_ts": min(timestamps) if timestamps else None,
        "malformed": malformed,
        "final_text": handback_text if handback_seen else text_report,
    }


def _candidate_values(report, label, values):
    """Return the allowlisted values of every column-0 `label: value` line."""
    prefix = label + ": "
    found = []
    for line in report.splitlines():
        if not line.startswith(prefix):
            continue
        remainder = line[len(prefix) :].rstrip()
        if remainder in values:
            found.append(remainder)
    return found


def read_verdict(agent_type, final_text):
    """Return the verdict the final report states, exactly as spelled, or UNREADABLE."""
    entry = VERDICT_TABLE.get(agent_type)
    if entry is None or final_text is None:
        return UNREADABLE
    label, values = entry
    candidates = _candidate_values(final_text, label, values)
    if not candidates:
        return UNREADABLE
    if agent_type in MOST_SEVERE_TYPES:
        return max(candidates, key=values.index)
    return candidates[-1]


def _read_meta(path):
    try:
        with open(path, encoding="utf-8") as handle:
            meta = json.load(handle)
    except (OSError, ValueError):
        return None
    if not isinstance(meta, dict):
        return None
    return meta


def _agent_type(meta):
    value = meta.get("agentType")
    if isinstance(value, str) and value:
        return value
    return "unknown"


def runner_for(agent_id, metas):
    """Follow parent links to the top-level dispatch, or mark the walk orphan."""
    current = agent_id
    seen = {agent_id}
    hops = 0
    while True:
        meta = metas[current]
        parent = meta.get("parentAgentId")
        if not isinstance(parent, str) or not parent:
            return f"{current}:{_agent_type(meta)}"
        if hops == MAX_HOPS or parent in seen or parent not in metas:
            return f"orphan:{current}"
        seen.add(parent)
        current = parent
        hops += 1


def cost_for(totals, spec):
    """Return the dollar cost for the totals under a tier spec, or NO_RATES."""
    rates = spec.get("rates_per_million") if spec else None
    if not isinstance(rates, dict):
        return NO_RATES
    total = 0
    for usage_key in USAGE_KEYS:
        total += totals[usage_key] * rates.get(RATE_KEY_FOR_USAGE[usage_key], 0)
    return round(total / 1000000, 4)


def _description(meta):
    value = meta.get("description")
    return value if isinstance(value, str) else ""


def _todo_key(agent_type, description):
    if agent_type not in TODO_TYPES:
        return NO_VALUE
    match = TODO_PATTERN.search(description)
    if match is None:
        return UNATTRIBUTED
    return match.group(1).lower()


def _is_fix_dispatch(description):
    # Approximation: fix rounds really count across both review stages, but a
    # dispatch that only says "round N" is taken as a fix round here.
    if FIX_PATTERN.search(description):
        return True
    if RERUN_PATTERN.search(description):
        return False
    return ROUND_PATTERN.search(description) is not None


def _first_stage1_pass(reviews):
    if not reviews:
        return NOT_APPLICABLE
    first = min(
        reviews,
        key=lambda row: (
            row["first_ts"] is None,
            row["first_ts"] or "",
            row["agent_id"],
        ),
    )
    return "yes" if first["verdict"] == "PASS" else "no"


def tie_todos(rows):
    """Fill todo, fix_rounds and first_stage1_pass on every row, in place.

    Each row's "description" key is read and then removed.
    """
    fix_counts = {}
    stage1_reviews = {}
    implementers = []
    for row in rows:
        description = row.pop("description", "")
        row["todo"] = _todo_key(row["agent_type"], description)
        row["fix_rounds"] = NO_VALUE
        row["first_stage1_pass"] = NO_VALUE
        if row["todo"] in (NO_VALUE, UNATTRIBUTED):
            continue
        scope = (row["runner"], row["todo"])
        if row["agent_type"] == IMPLEMENTER:
            implementers.append(row)
            if _is_fix_dispatch(description):
                fix_counts[scope] = fix_counts.get(scope, 0) + 1
        elif row["agent_type"] == STAGE1_TYPE:
            stage1_reviews.setdefault(scope, []).append(row)
    for row in implementers:
        scope = (row["runner"], row["todo"])
        row["fix_rounds"] = fix_counts.get(scope, 0)
        row["first_stage1_pass"] = _first_stage1_pass(stage1_reviews.get(scope, []))


def collect(session_dir, tiers):
    """Return (rows, counts) for every dispatch in the session folder."""
    subagents = os.path.join(session_dir, "subagents")
    root = subagents if os.path.isdir(subagents) else session_dir
    counts = {"malformed": 0, "no_meta": 0}

    metas = {}
    transcripts = {}
    for name in sorted(os.listdir(root)):
        path = os.path.join(root, name)
        if not os.path.isfile(path) or not name.startswith(AGENT_PREFIX):
            continue
        if name.endswith(META_SUFFIX):
            agent_id = name[len(AGENT_PREFIX) : -len(META_SUFFIX)]
            meta = _read_meta(path)
            if meta is None:
                counts["malformed"] += 1
            else:
                metas[agent_id] = meta
        elif name.endswith(TRANSCRIPT_SUFFIX):
            agent_id = name[len(AGENT_PREFIX) : -len(TRANSCRIPT_SUFFIX)]
            transcripts[agent_id] = path

    stats_by_id = {}
    for agent_id, path in transcripts.items():
        stats = read_transcript(path)
        counts["malformed"] += stats["malformed"]
        if agent_id in metas:
            stats_by_id[agent_id] = stats
        else:
            counts["no_meta"] += 1

    rows = []
    for agent_id in sorted(metas):
        meta = metas[agent_id]
        stats = stats_by_id.get(agent_id)
        if stats and stats["model_ids"]:
            tier = tier_label(sorted(stats["model_ids"]), tiers)
        else:
            alias = meta.get("model")
            alias_ids = [alias] if isinstance(alias, str) and alias else []
            tier = tier_label(alias_ids, tiers)

        row = {
            "agent_id": agent_id,
            "agent_type": _agent_type(meta),
            "tier": tier,
            "runner": runner_for(agent_id, metas),
            "verdict": read_verdict(
                _agent_type(meta), stats["final_text"] if stats else None
            ),
            "first_ts": stats["first_ts"] if stats else None,
            "description": _description(meta),
        }
        if stats and stats["usages"]:
            totals = {key: 0 for key in USAGE_KEYS}
            for usage in stats["usages"]:
                for key in USAGE_KEYS:
                    totals[key] += _as_int(usage.get(key))
            row["input_tokens"] = totals["input_tokens"]
            row["cache_write_tokens"] = totals["cache_creation_input_tokens"]
            row["cache_read_tokens"] = totals["cache_read_input_tokens"]
            row["est_output_tokens"] = totals["output_tokens"]
            row["cost_usd"] = cost_for(totals, tiers.get(tier))
        else:
            row["input_tokens"] = None
            row["cache_write_tokens"] = None
            row["cache_read_tokens"] = None
            row["est_output_tokens"] = None
            row["cost_usd"] = None
        rows.append(row)

    tie_todos(rows)
    rows.sort(
        key=lambda row: (
            row["runner"],
            row["first_ts"] is None,
            row["first_ts"] or "",
            row["agent_id"],
        )
    )
    return rows, counts


def _cell(value):
    if value is None:
        return NO_VALUE
    return str(value)


def render(rows, counts):
    """Return the tab-separated table followed by the skipped-lines summary."""
    lines = ["\t".join(COLUMNS)]
    for row in rows:
        lines.append("\t".join(_cell(row[column]) for column in COLUMNS))
    lines.append(
        f"# skipped malformed lines: {counts['malformed']}; "
        f"jsonl without meta: {counts['no_meta']}"
    )
    return "\n".join(lines) + "\n"


SUMMARY_COMMENT = (
    "# summary per runner per tier; est_output_tokens is estimated because "
    "transcripts record placeholder output counts"
)
SUMMARY_COLUMNS = [
    "runner",
    "tier",
    "dispatches",
    "input_side_tokens",
    "cost_usd",
    "est_output_tokens",
    "cost_per_todo_tokens",
    "cost_per_todo_usd",
    "first_pass_stage1",
    "avg_fix_rounds",
    "stage2_not_passed",
    "stage2_unreadable",
    "unattributed",
]
TIER_ORDER = ("economy", "standard", "premium")
STAGE2_TYPES = frozenset({"code-quality-reviewer", "skill-reviewer"})
STAGE2_NOT_PASSED = frozenset({"REQUEST CHANGES", "REJECT", "NEEDS WORK"})


def _start_key(row):
    return (row["first_ts"] is None, row["first_ts"] or "", row["agent_id"])


def _tier_rank(tier):
    if tier in TIER_ORDER:
        return (0, TIER_ORDER.index(tier), "")
    return (1, 0, tier)


def _is_number(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def _todo_owners(rows):
    """Map (runner, todo) to the implementer row that owns the todo.

    A todo counts once, under the tier that did its first implementation: the
    tier of its implementer row with the earliest first_ts (rows without one
    last, ties by agent_id). A fix dispatch on another tier does not move it.
    """
    owners = {}
    for row in rows:
        if row["agent_type"] != IMPLEMENTER:
            continue
        if row["todo"] in (NO_VALUE, UNATTRIBUTED):
            continue
        scope = (row["runner"], row["todo"])
        current = owners.get(scope)
        if current is None or _start_key(row) < _start_key(current):
            owners[scope] = row
    return owners


def _summary_entry(runner, tier, members, owners, todo_count):
    counted = [row for row in members if row["input_tokens"] is not None]
    input_side = sum(
        row["input_tokens"] + row["cache_write_tokens"] + row["cache_read_tokens"]
        for row in counted
    )
    est_output = sum(row["est_output_tokens"] for row in counted)
    priced = [row["cost_usd"] for row in counted if _is_number(row["cost_usd"])]
    cost = round(sum(priced), 4) if priced else NO_RATES

    assigned = [
        owner
        for (owner_runner, _todo), owner in owners.items()
        if owner_runner == runner and owner["tier"] == tier
    ]
    if todo_count:
        per_todo_tokens = "%.1f" % (input_side / todo_count)
        if _is_number(cost):
            per_todo_usd = round(cost / todo_count, 4)
        else:
            per_todo_usd = NO_RATES
    else:
        per_todo_tokens = NOT_APPLICABLE
        per_todo_usd = NOT_APPLICABLE

    yes = sum(1 for owner in assigned if owner["first_stage1_pass"] == "yes")
    no = sum(1 for owner in assigned if owner["first_stage1_pass"] == "no")
    first_pass = "%d/%d" % (yes, yes + no) if yes + no else NOT_APPLICABLE
    if assigned:
        fix_total = sum(owner["fix_rounds"] for owner in assigned)
        avg_fix = "%.1f" % (fix_total / len(assigned))
    else:
        avg_fix = NOT_APPLICABLE

    stage2 = [row for row in members if row["agent_type"] in STAGE2_TYPES]
    not_passed = sum(1 for row in stage2 if row["verdict"] in STAGE2_NOT_PASSED)
    unreadable = sum(1 for row in stage2 if row["verdict"] == UNREADABLE)

    typed = [row for row in members if row["agent_type"] in TODO_TYPES]
    unattributed_count = sum(1 for row in typed if row["todo"] == UNATTRIBUTED)

    return {
        "runner": runner,
        "tier": tier,
        "dispatches": len(members),
        "input_side_tokens": input_side,
        "cost_usd": cost,
        "est_output_tokens": est_output,
        "cost_per_todo_tokens": per_todo_tokens,
        "cost_per_todo_usd": per_todo_usd,
        "first_pass_stage1": first_pass,
        "avg_fix_rounds": avg_fix,
        "stage2_not_passed": not_passed,
        "stage2_unreadable": unreadable,
        "unattributed": "%d/%d" % (unattributed_count, len(typed)),
    }


def summarize(rows):
    """Return one summary dict per (runner, tier) group that has rows.

    Groups are ordered by runner, then tier in TIER_ORDER, then any other
    tier names alphabetically. Values are already formatted for output.
    """
    owners = _todo_owners(rows)
    todo_counts = {}
    for runner, _todo in owners:
        todo_counts[runner] = todo_counts.get(runner, 0) + 1
    groups = {}
    for row in rows:
        groups.setdefault((row["runner"], row["tier"]), []).append(row)
    ordered = sorted(groups, key=lambda key: (key[0], _tier_rank(key[1])))
    return [
        _summary_entry(
            runner,
            tier,
            groups[(runner, tier)],
            owners,
            todo_counts.get(runner, 0),
        )
        for runner, tier in ordered
    ]


def render_summary(summary):
    """Return the per-runner, per-tier summary as tab-separated text."""
    lines = [SUMMARY_COMMENT, "\t".join(SUMMARY_COLUMNS)]
    for entry in summary:
        lines.append("\t".join(_cell(entry[column]) for column in SUMMARY_COLUMNS))
    return "\n".join(lines) + "\n"


def main(argv):
    parser = argparse.ArgumentParser(
        description="Print one tier usage row per subagent dispatch in a session folder."
    )
    parser.add_argument("session_dir")
    parser.add_argument("--tiers", default=DEFAULT_TIERS)
    args = parser.parse_args(argv)

    if not os.path.isdir(args.session_dir):
        print(f"not a directory: {args.session_dir}", file=sys.stderr)
        return 2
    try:
        tiers = load_tiers(args.tiers)
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(f"cannot load tiers from {args.tiers}: {error}", file=sys.stderr)
        return 2

    rows, counts = collect(args.session_dir, tiers)
    sys.stdout.write(render(rows, counts))
    sys.stdout.write("\n")
    sys.stdout.write(render_summary(summarize(rows)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
