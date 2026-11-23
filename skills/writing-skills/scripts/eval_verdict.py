"""Stage verdicts for skill eval comparisons (standard library only)."""
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


def confirm_verdict(fresh_pass, fresh_n, ref_pass, ref_n):
    """Return LOSS or HOLD for a fresh batch checked against the reference."""
    p = fisher_one_sided(ref_pass, ref_n, fresh_pass, fresh_n)
    return "LOSS" if p <= 0.05 else "HOLD"
