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


def correlation(a: list, b: list) -> float:
    """Return the correlation between two equal-length outcome lists."""
    raise NotImplementedError


def group_cases(rates: dict, threshold: float, min_shared: int) -> list:
    """Group cases whose pairwise correlation reaches threshold over min_shared runs."""
    raise NotImplementedError


def report_rows(columns: dict) -> list:
    """Build the printable report rows from pooled columns.

    A case with the same pass rate in every label, and a label starting with
    "no-skill", gets an "excluded: no signal" row with no verdict and no bound.
    A case with the same pass rate in every label and no label starting with
    "no-skill" gets an "unclassified: run no-skill first" row with no verdict,
    no bound and an empty note; it is kept, not excluded.
    """
    rates_by_case = {}
    for label, cases in columns.items():
        for case, outcomes in cases.items():
            rates_by_case.setdefault(case, {})[label] = sum(outcomes) / len(outcomes) if outcomes else None
    rows = []
    for case, rates in rates_by_case.items():
        if len(set(rates.values())) == 1 and any(label.startswith("no-skill") for label in rates):
            rows.append({"case": case, "label": "excluded: no signal", "verdict": None, "bound": None, "note": ""})
        elif len(set(rates.values())) == 1:
            rows.append({"case": case, "label": "unclassified: run no-skill first", "verdict": None, "bound": None, "note": ""})
    return rows


def main(argv: list) -> int:
    """Run the report for the given run files and return a process exit code."""
    raise NotImplementedError


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
