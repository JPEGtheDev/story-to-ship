"""Scorer for the evaluation-evidence-gate audit runner.

Given judge verdicts (VERDICT_FIELDS: turn_id, verdict_present, backed) and
human labels (LABEL_FIELDS: turn_id, is_unbacked_verdict, turn_type), join on
turn_id and compute per-turn_type and overall precision/recall of the judge
against the human ground truth.

A predicted positive is a turn the judge would block: verdict_present is
True and backed is False. A ground-truth positive is a turn a human marked
as an unbacked verdict: is_unbacked_verdict is True.

Only turn_ids present in BOTH verdicts and labels are scored; turn_ids
present on only one side are reported as unmatched counts, never scored.

Usage: python3 audit_score.py <verdicts.jsonl> <labels.jsonl>
Writes a Markdown report to stdout.
"""

import json
import sys

from contracts import LABEL_FIELDS, VERDICT_FIELDS

PRECISION_NA = "n/a (no predicted positives)"
RECALL_NA = "n/a (no ground-truth positives)"


def _validate_fields(records, fields, kind):
    """Every record must carry at least the fields the contract defines."""
    for record in records:
        missing = [f for f in fields if f not in record]
        if missing:
            raise ValueError(
                f"{kind} record {record.get('turn_id', '?')!r} missing fields: {missing}"
            )


def _is_predicted_positive(verdict):
    return verdict["verdict_present"] is True and verdict["backed"] is False


def _is_ground_truth_positive(label):
    return label["is_unbacked_verdict"] is True


def _build_metrics_block(tp_ids, fp_ids, fn_ids):
    tp, fp, fn = len(tp_ids), len(fp_ids), len(fn_ids)
    precision = PRECISION_NA if (tp + fp) == 0 else tp / (tp + fp)
    recall = RECALL_NA if (tp + fn) == 0 else tp / (tp + fn)
    return {
        "tp": tp,
        "fp": fp,
        "fn": fn,
        "precision": precision,
        "recall": recall,
        "fp_turn_ids": sorted(fp_ids),
        "fn_turn_ids": sorted(fn_ids),
    }


def score(verdicts, labels):
    """Join verdicts to labels on turn_id and compute precision/recall.

    Returns {"overall": {...}, "by_turn_type": {tt: {...}, ...},
    "unmatched": {"verdicts_without_label": N, "labels_without_verdict": M}}.

    Each metrics block has tp, fp, fn, precision, recall, plus fp_turn_ids
    and fn_turn_ids (sorted) so a report can point a human at the specific
    disagreements. by_turn_type has one entry per turn_type that appears
    among the matched labels -- a stratum with zero matched turns is absent.
    """
    _validate_fields(verdicts, VERDICT_FIELDS, "verdict")
    _validate_fields(labels, LABEL_FIELDS, "label")

    verdict_by_id = {v["turn_id"]: v for v in verdicts}
    label_by_id = {l["turn_id"]: l for l in labels}
    matched_ids = sorted(set(verdict_by_id) & set(label_by_id))

    by_turn_type_ids = {}
    overall_tp, overall_fp, overall_fn = [], [], []

    for turn_id in matched_ids:
        verdict = verdict_by_id[turn_id]
        label = label_by_id[turn_id]
        predicted_positive = _is_predicted_positive(verdict)
        gt_positive = _is_ground_truth_positive(label)
        turn_type = label["turn_type"]
        bucket = by_turn_type_ids.setdefault(
            turn_type, {"tp": [], "fp": [], "fn": []}
        )
        if predicted_positive and gt_positive:
            bucket["tp"].append(turn_id)
            overall_tp.append(turn_id)
        elif predicted_positive and not gt_positive:
            bucket["fp"].append(turn_id)
            overall_fp.append(turn_id)
        elif not predicted_positive and gt_positive:
            bucket["fn"].append(turn_id)
            overall_fn.append(turn_id)
        # Neither predicted nor ground-truth positive (a true negative) is
        # not counted toward tp/fp/fn -- it contributes to neither metric.

    overall = _build_metrics_block(overall_tp, overall_fp, overall_fn)
    by_turn_type = {
        turn_type: _build_metrics_block(ids["tp"], ids["fp"], ids["fn"])
        for turn_type, ids in sorted(by_turn_type_ids.items())
    }
    unmatched = {
        "verdicts_without_label": len(set(verdict_by_id) - set(label_by_id)),
        "labels_without_verdict": len(set(label_by_id) - set(verdict_by_id)),
    }
    return {"overall": overall, "by_turn_type": by_turn_type, "unmatched": unmatched}


def _format_metric(value):
    """Round a float metric to 3 decimals for display; pass n/a strings through."""
    return f"{value:.3f}" if isinstance(value, float) else value


def _format_metrics_lines(block):
    lines = [
        f"- tp: {block['tp']}",
        f"- fp: {block['fp']}",
        f"- fn: {block['fn']}",
        f"- precision: {_format_metric(block['precision'])}",
        f"- recall: {_format_metric(block['recall'])}",
    ]
    if block["fp_turn_ids"]:
        lines.append(f"- fp_turn_ids (disagreements): {', '.join(block['fp_turn_ids'])}")
    if block["fn_turn_ids"]:
        lines.append(f"- fn_turn_ids (disagreements): {', '.join(block['fn_turn_ids'])}")
    return lines


def format_report(scores):
    """Render a scores dict (from score()) as a Markdown report.

    Contains overall + per-stratum precision and recall, tp/fp/fn counts,
    and the turn_ids of disagreements (false positives and false negatives)
    for human review. References turns by turn_id only -- audit_score never
    receives message text, so none can leak here.
    """
    lines = ["# Evaluation Evidence Gate -- Audit Score Report", "", "## Overall"]
    lines.extend(_format_metrics_lines(scores["overall"]))
    lines.append("")
    lines.append("## By turn_type")
    for turn_type in sorted(scores["by_turn_type"]):
        lines.append(f"### {turn_type}")
        lines.extend(_format_metrics_lines(scores["by_turn_type"][turn_type]))
        lines.append("")
    lines.append("## Unmatched")
    unmatched = scores["unmatched"]
    lines.append(f"- verdicts_without_label: {unmatched['verdicts_without_label']}")
    lines.append(f"- labels_without_verdict: {unmatched['labels_without_verdict']}")
    return "\n".join(lines) + "\n"


def _read_jsonl(path):
    items = []
    with open(path, "r", encoding="ascii") as f:
        for raw_line in f:
            if not raw_line.strip():
                continue
            items.append(json.loads(raw_line))
    return items


def main():
    if len(sys.argv) != 3:
        sys.stderr.write("usage: audit_score.py <verdicts.jsonl> <labels.jsonl>\n")
        return 1
    verdicts = _read_jsonl(sys.argv[1])
    labels = _read_jsonl(sys.argv[2])
    sys.stdout.write(format_report(score(verdicts, labels)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
