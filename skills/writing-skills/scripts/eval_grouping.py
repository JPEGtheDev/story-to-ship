"""Group eval cases by correlated outcomes.

This script reads per-case run history from claude plugin eval JSON and
prints the zero-event bound, the no-signal label and the correlation groups.
"""

import sys


def read_run_file(path: str) -> dict:
    """Read one claude plugin eval JSON run file and return its parsed content."""
    raise NotImplementedError


def pool_columns(paths_by_label: dict) -> dict:
    """Pool the per-case run columns of several run files, keyed by label."""
    raise NotImplementedError


def zero_event_bound(n: int) -> float:
    """Return the zero-event bound for a case that logged n runs with no events."""
    raise NotImplementedError


def correlation(a: list, b: list) -> float:
    """Return the correlation between two equal-length outcome lists."""
    raise NotImplementedError


def group_cases(rates: dict, threshold: float, min_shared: int) -> list:
    """Group cases whose pairwise correlation reaches threshold over min_shared runs."""
    raise NotImplementedError


def report_rows(columns: dict) -> list:
    """Build the printable report rows from pooled columns."""
    raise NotImplementedError


def main(argv: list) -> int:
    """Run the report for the given run files and return a process exit code."""
    raise NotImplementedError


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
