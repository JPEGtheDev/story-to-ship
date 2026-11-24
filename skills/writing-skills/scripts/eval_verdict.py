"""Stage verdicts for skill eval comparisons (standard library only)."""
import argparse
import hashlib
import json
import os
import sys
from math import comb

# Procedure step d.7: a LOSS is confirmed by a batch of exactly this many fresh runs.
FRESH_BATCH_RUNS = 30


def fisher_one_sided(ref_pass, ref_n, cand_pass, cand_n):
    """P(candidate has at least its observed failures) given the pooled totals."""
    cand_fail = cand_n - cand_pass
    total_fail = (ref_n - ref_pass) + cand_fail
    denom = comb(ref_n + cand_n, total_fail)
    top = min(cand_n, total_fail)
    return sum(comb(cand_n, k) * comb(ref_n, total_fail - k) for k in range(cand_fail, top + 1)) / denom


def stage_verdict(stage, ref_pass, ref_n, cand_pass, cand_n):
    """Return LOSS, EDIT, HOLD or NEXT for a stage of 5, 15 or 30 runs."""
    p = fisher_one_sided(ref_pass, ref_n, cand_pass, cand_n)
    if stage == 5:
        if cand_pass == cand_n:
            return "NEXT"
        return "LOSS" if p <= 0.01 else "EDIT"
    if p <= 0.05:
        return "LOSS"
    if stage == 15 and cand_pass != cand_n and cand_pass * ref_n < ref_pass * cand_n:
        return "NEXT"
    return "HOLD"


def cache_key(case_file_hashes, plugin_commit, model_id, judge_model_id, claude_code_version):
    """Return a SHA-256 hex digest of the run inputs; any changed field changes it.

    case_file_hashes is one string (join per-file hashes before calling); a list raises TypeError.
    """
    fields = (case_file_hashes, plugin_commit, model_id, judge_model_id, claude_code_version)
    return hashlib.sha256("\0".join(fields).encode("utf-8")).hexdigest()


def confirm_verdict(fresh_pass, fresh_n, ref_pass, ref_n):
    """Return LOSS or HOLD for a fresh batch checked against the reference."""
    p = fisher_one_sided(ref_pass, ref_n, fresh_pass, fresh_n)
    return "LOSS" if p <= 0.05 else "HOLD"


def _fail(message):
    """Print an error to stderr and exit 2."""
    print(f"error: {message}", file=sys.stderr)
    sys.exit(2)


def read_run_records(path):
    """Read a run file; return {name: (kept_records, dropped_count)}, dropping error records."""
    if not os.path.isfile(path):
        _fail(f"run file not found: {path}")
    try:
        with open(path) as handle:
            data = json.load(handle)
        result = {}
        for case in data["cases"]:
            records = case["arms"]["with"]
            if not isinstance(records, list):
                raise TypeError("arms.with is not a list")
            kept = [record for record in records if record.get("error") is None]
            if any(not isinstance(record.get("passed"), bool) for record in kept):
                raise TypeError("a kept record has a missing or non-boolean passed field")
            result[case["name"]] = (kept, len(records) - len(kept))
    except json.JSONDecodeError as error:
        _fail(f"run file is not valid JSON: {error}")
    except (KeyError, TypeError, AttributeError) as error:
        _fail(f"run file {path} has a case with no arms.with list or a bad schema: {error!r}")
    return result


def _counts(records):
    """Return (passed, total) for kept records."""
    return sum(1 for record in records if record["passed"]), len(records)


def _parse_path(argument, key):
    """Return the PATH of a key=PATH argument, or exit 2."""
    if not argument.startswith(key + "="):
        _fail(f"expected {key}=PATH, got {argument}")
    return argument[len(key) + 1:]


def _kept(runs, name, label, path):
    """Return the kept records of a case, printing its dropped count; exit 2 if none are kept."""
    kept, dropped = runs[name]
    if dropped:
        print(f"{name}: dropped {dropped} ({label})")
    if not kept:
        _fail(f"case {name} keeps zero runs in the {label} file {path}")
    return kept


def main(argv=None):
    """Print one line per candidate case: name, p, stage verdict; exit 2 on bad input."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--stage", type=int, choices=(5, 15, 30), required=True)
    parser.add_argument("paths", nargs="+", help="ref=PATH cand=PATH [fresh=PATH]")
    args = parser.parse_args(argv)
    if len(args.paths) not in (2, 3):
        _fail("usage: --stage N ref=PATH cand=PATH [fresh=PATH]")
    ref_path = _parse_path(args.paths[0], "ref")
    cand_path = _parse_path(args.paths[1], "cand")
    fresh_path = _parse_path(args.paths[2], "fresh") if len(args.paths) == 3 else None
    ref = read_run_records(ref_path)
    cand = read_run_records(cand_path)
    fresh = read_run_records(fresh_path) if fresh_path else None
    partial = False
    for name, (cand_kept, dropped) in cand.items():
        if name not in ref:
            _fail(f"case {name} is missing from the reference file")
        if dropped:
            print(f"{name}: dropped {dropped}")
        cand_pass, cand_n = _counts(cand_kept)
        if cand_n > args.stage:
            _fail(f"case {name} has {cand_n} runs in the candidate file {cand_path}, more than stage {args.stage}")
        if cand_n < args.stage:
            print(f"{name}: rerun, {cand_n} of {args.stage} runs after dropped errors", file=sys.stderr)
            partial = True
            continue
        ref_pass, ref_n = _counts(_kept(ref, name, "reference", ref_path))
        p = fisher_one_sided(ref_pass, ref_n, cand_pass, cand_n)
        verdict = stage_verdict(args.stage, ref_pass, ref_n, cand_pass, cand_n)
        line = f"{name}: p={p:.6f} {verdict}"
        if verdict == "LOSS" and fresh is not None:
            if name not in fresh:
                _fail(f"case {name} is missing from the fresh file {fresh_path}")
            fresh_pass, fresh_n = _counts(_kept(fresh, name, "fresh", fresh_path))
            if fresh_n != FRESH_BATCH_RUNS:
                _fail(f"case {name} keeps {fresh_n} of {FRESH_BATCH_RUNS} runs in the fresh file {fresh_path}")
            line += f" confirm={confirm_verdict(fresh_pass, fresh_n, ref_pass, ref_n)}"
        print(line)
    if partial:
        sys.exit(2)


if __name__ == "__main__":
    main()
