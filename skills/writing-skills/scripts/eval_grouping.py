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
    holds a record whose passed is not a bool or whose error is not null.
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

    A case is classified only when every label holds a scored run for it. A case
    missing a label, or with no scored run under some label, gets no row here;
    main prints its "no runs under" line instead. A classified case with the same
    pass rate in every label, and a label starting with "no-skill", gets an
    "excluded: no signal" row. A classified case with the same pass rate in every
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
            continue
        edge = next(iter(rates.values())) in (0, 1)
        bound = zero_event_bound(min(len(columns[label][case]) for label in columns)) if edge else None
        note = "not evidence of keeping the behavior" if edge else ""
        if any(label.startswith("no-skill") for label in rates):
            row_label = "excluded: no signal"
        else:
            row_label = "unclassified: run no-skill first"
        rows.append({"case": case, "label": row_label, "verdict": None, "bound": bound, "note": note})
    return rows


def main(argv: list) -> int:
    """Run the report for the given run files and return a process exit code."""
    parts = [item.partition("=") for item in argv]
    if not argv or any(not sep or not label for label, sep, _ in parts):
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
    columns = pool_columns(columns_by_label)
    for row in report_rows(columns):
        line = f"{row['case']}: {row['label']}"
        if row["bound"] is not None:
            line += f" bound {row['bound']:.3f}"
        if row["note"]:
            line += f" ({row['note']})"
        print(line)
    all_cases = sorted({case for label_cases in columns.values() for case in label_cases})
    pooled_rates = {
        case: {
            label: sum(columns[label][case]) / len(columns[label][case])
            for label in columns
            if columns[label].get(case)
        }
        for case in all_cases
    }
    grouped = set()
    for kept, members in group_cases(pooled_rates, 0.9, 3):
        if not members:
            continue
        print(f"group kept {kept}: {', '.join(members)}")
        for member in members:
            print(f"{member}: excluded: grouped with {kept}")
            grouped.add(member)
    for case in all_cases:
        case_rates = pooled_rates[case]
        if case in grouped or len(set(case_rates.values())) <= 1:
            continue
        for other in all_cases:
            if other == case:
                continue
            other_rates = pooled_rates[other]
            shared = sorted(set(case_rates) & set(other_rates))
            value = correlation(
                [case_rates[label] for label in shared],
                [other_rates[label] for label in shared],
            )
            if value is not None:
                print(f"{case}: varies")
                break
    for case in all_cases:
        case_rates = pooled_rates[case]
        if case in grouped or len(set(case_rates.values())) <= 1:
            continue
        uncorrelated = True
        for other in all_cases:
            if other == case:
                continue
            other_rates = pooled_rates[other]
            shared = sorted(set(case_rates) & set(other_rates))
            value = correlation(
                [case_rates[label] for label in shared],
                [other_rates[label] for label in shared],
            )
            if value is not None:
                uncorrelated = False
                break
        if uncorrelated:
            print(f"{case}: not groupable")
    for label in sorted(columns):
        for case in all_cases:
            if not columns[label].get(case):
                print(f"{case}: no runs under {label}")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
