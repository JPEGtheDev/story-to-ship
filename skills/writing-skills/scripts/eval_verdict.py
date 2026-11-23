"""Stage verdicts for skill eval comparisons (standard library only)."""
import argparse
import hashlib
import json
import os
import sys
from math import comb


def fisher_one_sided(ref_pass, ref_n, cand_pass, cand_n):
    """P(candidate has at least its observed failures) given the pooled totals."""
    cand_fail = cand_n - cand_pass
    total_fail = (ref_n - ref_pass) + cand_fail
    denom = comb(ref_n + cand_n, total_fail)
    top = min(cand_n, total_fail)
    return sum(comb(cand_n, k) * comb(ref_n, total_fail - k) for k in range(cand_fail, top + 1)) / denom


def stage_verdict(stage, ref_pass, ref_n, cand_pass, cand_n):
    """Return LOSS, HOLD or NEXT for a stage of 5, 15 or 30 runs."""
    p = fisher_one_sided(ref_pass, ref_n, cand_pass, cand_n)
    if stage == 5:
        return "LOSS" if p <= 0.01 else "NEXT"
    if p <= 0.05:
        return "LOSS"
    if stage == 15 and cand_pass != cand_n and cand_pass * ref_n < ref_pass * cand_n:
        return "NEXT"
    return "HOLD"


def cache_key(case_hash, plugin_commit, model_id, judge_model_id, claude_code_version):
    """Return a SHA-256 hex digest of the run inputs; any changed field changes it."""
    fields = (case_hash, plugin_commit, model_id, judge_model_id, claude_code_version)
    return hashlib.sha256("\0".join(fields).encode("utf-8")).hexdigest()


def confirm_verdict(fresh_pass, fresh_n, ref_pass, ref_n):
    """Return LOSS or HOLD for a fresh batch checked against the reference."""
    p = fisher_one_sided(ref_pass, ref_n, fresh_pass, fresh_n)
    return "LOSS" if p <= 0.05 else "HOLD"


def read_run_records(path):
    """Read a JSON run file; return (kept_records, dropped_count) with error records dropped."""
    with open(path) as handle:
        records = json.load(handle)
    kept = [record for record in records if record.get("error") is None]
    return kept, len(records) - len(kept)


def main(argv=None):
    """Parse the command line; an invalid stage makes argparse exit 2."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--stage", type=int, choices=(5, 15, 30), required=True)
    parser.add_argument("run_file")
    args = parser.parse_args(argv)
    if not os.path.isfile(args.run_file):
        print(f"error: run file not found: {args.run_file}", file=sys.stderr)
        sys.exit(2)
    return args


if __name__ == "__main__":
    main()
