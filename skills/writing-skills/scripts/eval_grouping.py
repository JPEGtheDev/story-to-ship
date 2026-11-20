"""Group eval cases by correlated outcomes.

This script reads per-case run history from claude plugin eval JSON and
prints the zero-event bound, the no-signal label and the correlation groups.
"""

import json
import sys


class RunFileError(Exception):
    """Raised when a run file is missing, unparsable, misshapen or holds an errored record."""


def read_run_file(path: str) -> dict:
    """Read one claude plugin eval JSON run file and return case name to list of bool.

    Records with scored false are skipped. Raises RunFileError naming the path
    when the file is missing, unparsable, lacks cases[].arms.with[] records, or
    holds a record whose error is not null.
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
            if not isinstance(record, dict) or "passed" not in record:
                raise RunFileError(f"run file {path} has a malformed record in case {name}")
            if record.get("error") is not None:
                raise RunFileError(f"run file {path} has an errored record in case {name}")
            if record.get("scored", True):
                column.append(record["passed"])
    return columns


def pool_columns(paths_by_label: dict) -> dict:
    """Pool the per-case run columns of several run files, keyed by label.

    Returns {label: {case: [bool, ...]}}; a case found in several files under
    one label has its outcome lists concatenated in path order.
    """
    pooled = {}
    for label, paths in paths_by_label.items():
        merged = {}
        for path in paths:
            for case, outcomes in read_run_file(path).items():
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


def correlation(a: list, b: list) -> "float | None":
    """Return the correlation between two equal-length outcome lists.

    Returns None when the lists have fewer than three entries, or when either
    list has zero variance (all entries equal).
    """
    if len(a) < 3:
        return None
    if len(set(a)) == 1 or len(set(b)) == 1:
        return None
    n = len(a)
    mean_a = sum(a) / n
    mean_b = sum(b) / n
    cov = sum((x - mean_a) * (y - mean_b) for x, y in zip(a, b))
    var_a = sum((x - mean_a) ** 2 for x in a)
    var_b = sum((y - mean_b) ** 2 for y in b)
    return cov / (var_a * var_b) ** 0.5


def group_cases(rates: dict, threshold: float, min_shared: int) -> list:
    """Group cases whose pairwise correlation reaches threshold over min_shared runs.

    Cases are visited in the key order of rates. Each case is compared only with
    the kept cases, in kept order; it joins the first kept case whose correlation
    with it is at least threshold, and otherwise becomes a new kept case. Labels
    shared by two cases are compared in sorted order; fewer than min_shared shared
    labels, or a None correlation, never joins. Returns [(kept case, members)].
    """
    kept = []
    for case, case_rates in rates.items():
        for kept_case, members in kept:
            kept_rates = rates[kept_case]
            shared = sorted(set(case_rates) & set(kept_rates))
            if len(shared) < min_shared:
                continue
            value = correlation(
                [case_rates[label] for label in shared],
                [kept_rates[label] for label in shared],
            )
            if value is not None and value >= threshold:
                members.append(case)
                break
        else:
            kept.append((case, []))
    return kept


def report_rows(columns: dict) -> list:
    """Build the printable report rows from pooled columns.

    A case with the same pass rate in every label, and a label starting with
    "no-skill", gets an "excluded: no signal" row with no verdict and no bound.
    A case with the same pass rate in every label and no label starting with
    "no-skill" gets an "unclassified: run no-skill first" row with no verdict,
    no bound and an empty note; it is kept, not excluded.
    """
    rates_by_case = {}
    runs_by_case = {}
    for label, cases in columns.items():
        for case, outcomes in cases.items():
            rates_by_case.setdefault(case, {})[label] = sum(outcomes) / len(outcomes) if outcomes else None
            runs_by_case.setdefault(case, len(outcomes))
    rows = []
    for case, rates in rates_by_case.items():
        if len(set(rates.values())) != 1:
            continue
        edge = next(iter(rates.values())) in (0, 1)
        bound = zero_event_bound(runs_by_case[case]) if edge else None
        note = "not evidence of keeping the behavior" if edge else ""
        if any(label.startswith("no-skill") for label in rates):
            row_label = "excluded: no signal"
        else:
            row_label = "unclassified: run no-skill first"
        rows.append({"case": case, "label": row_label, "verdict": None, "bound": bound, "note": note})
    return rows


def main(argv: list) -> int:
    """Run the report for the given run files and return a process exit code."""
    if not argv or any("=" not in item for item in argv):
        print("usage: eval_grouping.py label=path [label=path ...]", file=sys.stderr)
        return 2
    failed = False
    paths_by_label = {}
    for item in argv:
        label, path = item.split("=", 1)
        paths_by_label.setdefault(label, []).append(path)
        try:
            read_run_file(path)
        except RunFileError:
            print(f"{path}: error, no verdict")
            failed = True
    if failed:
        return 1
    columns = pool_columns(paths_by_label)
    for row in report_rows(columns):
        line = f"{row['case']}: {row['label']}"
        if row["bound"] is not None:
            line += f" bound {row['bound']:.3f}"
        if row["note"]:
            line += f" ({row['note']})"
        print(line)
    rates = {}
    all_cases = sorted({case for label_cases in columns.values() for case in label_cases})
    for case in all_cases:
        outcomes = {label: columns[label].get(case) for label in columns}
        if all(outcomes.values()):
            rates[case] = {label: sum(values) / len(values) for label, values in outcomes.items()}
    for kept, members in group_cases(rates, 0.9, 3):
        print(f"group kept {kept}: {', '.join(members) if members else 'none'}")
    for case in sorted(rates):
        case_rates = rates[case]
        if len(set(case_rates.values())) == 1:
            continue
        for other in sorted(rates):
            if other == case:
                continue
            other_rates = rates[other]
            shared = sorted(set(case_rates) & set(other_rates))
            value = correlation(
                [case_rates[label] for label in shared],
                [other_rates[label] for label in shared],
            )
            if value is not None:
                print(f"{case}: varies")
                break
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
