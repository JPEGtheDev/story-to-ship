"""Report eval case labels from run history.

This script reads per-case run history from claude plugin eval JSON and
prints the zero-event bound and the label of each case.
"""

import json
import sys


class RunFileError(Exception):
    """Raised when a run file is missing, unparsable, misshapen or holds an errored record."""


def read_run_file(path: str) -> dict:
    """Read one claude plugin eval JSON run file and return case name to list of bool.

    Records with scored false are skipped. Raises RunFileError naming the path
    when the file is missing, unparsable, lacks cases[].arms.with[] records, or
    holds a record whose passed is not a bool, whose scored is present and not a
    bool, or whose error is not null.
    """
    try:
        with open(path, encoding="utf-8") as handle:
            doc = json.load(handle)
    except OSError as exc:
        raise RunFileError(f"cannot read run file {path}: {exc}") from exc
    except ValueError as exc:
        raise RunFileError(f"cannot parse run file {path}: {exc}") from exc

    cases = doc.get("cases") if isinstance(doc, dict) else None
    if not isinstance(cases, list):
        raise RunFileError(f"run file {path} has no cases[] list")

    columns = {}
    for case in cases:
        arms = case.get("arms") if isinstance(case, dict) else None
        records = arms.get("with") if isinstance(arms, dict) else None
        name = case.get("name") if isinstance(case, dict) else None
        if not isinstance(name, str) or not isinstance(records, list):
            raise RunFileError(f"run file {path} has a case without arms.with[] records")
        column = columns.setdefault(name, [])
        for record in records:
            if not isinstance(record, dict) or not isinstance(record.get("passed"), bool):
                raise RunFileError(f"run file {path} has a malformed record in case {name}")
            if record.get("error") is not None:
                raise RunFileError(f"run file {path} has an errored record in case {name}")
            if "scored" in record and not isinstance(record["scored"], bool):
                raise RunFileError(f"run file {path} has a non-bool scored value in case {name}")
            if record.get("scored", True):
                column.append(record["passed"])
    return columns


def pool_columns(columns_by_label: dict) -> dict:
    """Pool the per-case run columns of several run files, keyed by label.

    Takes {label: [file columns, ...]}, where each file columns dict is a
    read_run_file result, so each file is read once and a pipe works. Returns
    {label: {case: [bool, ...]}}; a case found in several files under one label
    has its outcome lists concatenated in file order.
    """
    pooled = {}
    for label, files_columns in columns_by_label.items():
        merged = {}
        for file_columns in files_columns:
            for case, outcomes in file_columns.items():
                merged.setdefault(case, []).extend(outcomes)
        pooled[label] = merged
    return pooled


def zero_event_bound(n: int) -> "float | None":
    """Return the zero-event bound for a case that logged n runs with no events.

    Returns None when n is 0: a case with no runs has no bound and no verdict.
    """
    if n == 0:
        return None
    return 1 - 0.05 ** (1 / n)


def report_rows(columns: dict) -> list:
    """Build the printable report rows from pooled columns.

    A case is classified only when every label holds a scored run for it. A case
    missing a label, or with no scored run under some label, gets no row here;
    main prints its "no runs under" line instead. A classified case with the same
    pass rate in every label, and a label starting with "no-skill", gets an
    "model default" row. A classified case with the same pass rate in every
    label and no label starting with "no-skill" gets an "unclassified: run no-skill
    first" row; it is kept, not excluded. Each row carries no verdict. A row whose
    rate is 0 or 1 carries the bound 1 - 0.05 ** (1/n), with n the smallest run
    count among the labels for that case, and the note "not evidence of keeping
    the behavior". A row whose rate is neither 0 nor 1 carries no bound and an
    empty note. The smallest n gives the widest bound, the conservative choice,
    and the minimum does not depend on argument order.
    """
    rates_by_case = {}
    for label in sorted(columns):
        for case, outcomes in columns[label].items():
            rates_by_case.setdefault(case, {})[label] = sum(outcomes) / len(outcomes) if outcomes else None
    rows = []
    for case, rates in rates_by_case.items():
        if len(rates) != len(columns) or None in rates.values():
            continue
        if len(set(rates.values())) != 1:
            base = [rate for label, rate in rates.items() if label.startswith("no-skill")]
            current = [rate for label, rate in rates.items() if not label.startswith("no-skill")]
            if current and min(current) < 0.9:
                rows.append({"case": case, "label": "weak", "verdict": None, "bound": None, "note": ""})
            elif base and current and min(current) > max(base):
                rows.append({"case": case, "label": "separating", "verdict": None, "bound": None, "note": ""})
            elif base and current:
                rows.append({"case": case, "label": "model default", "verdict": None, "bound": None, "note": ""})
            continue
        edge = next(iter(rates.values())) in (0, 1)
        bound = zero_event_bound(min(len(columns[label][case]) for label in columns)) if edge else None
        note = "not evidence of keeping the behavior" if edge else ""
        if any(label.startswith("no-skill") for label in rates):
            row_label = "model default"
        else:
            row_label = "unclassified: run no-skill first"
        rows.append({"case": case, "label": row_label, "verdict": None, "bound": bound, "note": note})
    return rows


def main(argv: list) -> int:
    """Run the report for the given run files and return a process exit code."""
    parts = [item.partition("=") for item in argv]
    labels = {label for label, _, _ in parts}
    if len(labels) < 2 or any(not sep or not label or not path for label, sep, path in parts):
        print("usage: eval_grouping.py label=path [label=path ...]", file=sys.stderr)
        return 2
    failed = False
    columns_by_label = {}
    for item in argv:
        label, path = item.split("=", 1)
        try:
            file_columns = read_run_file(path)
        except RunFileError:
            print(f"{path}: error, no verdict")
            failed = True
            continue
        columns_by_label.setdefault(label, []).append(file_columns)
    if len(columns_by_label) < 2:
        return 1
    columns = pool_columns(columns_by_label)
    for row in report_rows(columns):
        line = f"{row['case']}: {row['label']}"
        if row["bound"] is not None:
            line += f" bound {row['bound']:.3f}"
        if row["note"]:
            line += f" ({row['note']})"
        print(line)
    all_cases = sorted({case for label_cases in columns.values() for case in label_cases})
    for case in all_cases:
        case_rates = {label: sum(columns[label][case]) / len(columns[label][case]) for label in columns if columns[label].get(case)}
        if len(set(case_rates.values())) > 1:
            print(f"{case}: varies")
    for label in sorted(columns):
        for case in all_cases:
            if not columns[label].get(case):
                print(f"{case}: no runs under {label}")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
