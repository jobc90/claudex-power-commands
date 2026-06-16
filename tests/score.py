#!/usr/bin/env python3
"""score.py — A/B results validator + KEEP/CUT/INCONCLUSIVE decision engine.

Stdlib only. Part of the harness A/B eval scaffolding (see tests/README.md).

What it does:
  1. Validates a results CSV against the mandatory header schema (exits non-zero on
     mismatch — a malformed CSV must not silently produce a verdict).
  2. On a header-only CSV, prints the "no data rows yet" message and exits 0.
  3. On populated rows, applies the design's PRE-REGISTERED decision rule
     (docs/v4.3.0-ab-measurement-design.md §6, thresholds from §2) and prints
     per-split tallies + a KEEP / CUT / INCONCLUSIVE verdict.

It computes ONLY the verdict from already-scored rows. The per-transcript
"did the run catch the seeded defect / fabricate?" judgment is done by the
render-leak scorer (M1, must be validated first) or by hand (M4) BEFORE rows
land in the CSV. Flipping the CHANGELOG status is a human decision made after
reviewing this output AND the held-out split.

Usage:
    python3 tests/score.py tests/ab-results/observation-grounding.csv
    python3 tests/score.py tests/ab-results/untestable.csv
"""

import csv
import sys

# --- Mandatory results schema (design §4.5; model+effort first and mandatory, §0) ---
REQUIRED_HEADER = [
    "model",
    "effort",
    "condition",       # ON | OFF
    "fixture",
    "split",           # in-author | held-out
    "primary_metric",  # render/unreachable fixtures: the discipline's primary outcome
    "fp_metric",       # null fixtures: false-positive outcome (blank for non-null rows)
    "verdict",         # final harness/QA verdict string
    "evidence_pointer",
    "notes",
]

# --- PRE-REGISTERED decision thresholds (design §2 + §6) ----------------------------
# The design fixes these BEFORE running. Encoded here as constants so the rule is
# auditable and not re-derived at scoring time. The §2 worked examples are the defaults:
#   - KEEP needs a primary directional margin (ON better than OFF) of at least this many
#     net "good" outcomes across the render/unreachable fixtures.  (§2: "e.g. >=3/15 net")
KEEP_MIN_PRIMARY_MARGIN = 3
#   - A null-fixture false-positive count at/over this threshold FORCES CUT — it overrides
#     a positive primary (a discipline that fires on a meaningful share of null cases is
#     net-harmful in a gating pipeline).  (§2: "e.g. >=2/5 false alarms"; §6 FP-override)
CUT_FP_THRESHOLD = 2
#   - Default for everything in between is INCONCLUSIVE. Neutral is NEVER CUT (§6).
#   - CUT also fires on a *negative* primary margin (OFF beat ON = positive harm signal, §6).

# Outcome tokens recognized in primary_metric for NON-null (render/unreachable) rows.
# "good" = the discipline did its job on this fixture under this condition.
PRIMARY_GOOD = {"caught", "honest", "detected", "pass", "no-escape"}
PRIMARY_BAD = {"escape", "escaped", "fabricated", "fabrication", "leak", "missed"}

# Outcome tokens recognized in fp_metric for NULL rows.
FP_POSITIVE = {"fp", "false-positive", "false-untestable", "demanded-observation", "yes"}
FP_NONE = {"none", "no", "ok", "correct"}


def _strip_comments(raw_lines):
    """Drop blank lines and full-line comments (# ...). Returns kept lines."""
    return [ln for ln in raw_lines if ln.strip() and not ln.lstrip().startswith("#")]


def load_csv(path):
    """Read CSV, skipping comment/blank lines. Returns (header, data_rows)."""
    try:
        with open(path, newline="", encoding="utf-8") as fh:
            kept = _strip_comments(fh.readlines())
    except FileNotFoundError:
        print(f"ERROR: file not found: {path}", file=sys.stderr)
        sys.exit(2)

    if not kept:
        print(f"ERROR: {path} is empty (not even a header).", file=sys.stderr)
        sys.exit(2)

    reader = csv.reader(kept)
    rows = list(reader)
    header = [c.strip() for c in rows[0]]
    data = [r for r in rows[1:]]
    return header, data


def validate_header(header, path):
    if header != REQUIRED_HEADER:
        print(f"ERROR: header schema mismatch in {path}", file=sys.stderr)
        print(f"  expected: {REQUIRED_HEADER}", file=sys.stderr)
        print(f"  found:    {header}", file=sys.stderr)
        sys.exit(2)


def to_records(header, data, path):
    """Turn rows into dicts; validate field count."""
    records = []
    for i, row in enumerate(data, start=1):
        if len(row) != len(header):
            print(
                f"ERROR: row {i} in {path} has {len(row)} fields, "
                f"expected {len(header)}: {row}",
                file=sys.stderr,
            )
            sys.exit(2)
        records.append({k: v.strip() for k, v in zip(header, row)})
    return records


def classify_primary(value):
    """Return 'good', 'bad', or None for a primary_metric cell."""
    v = value.strip().lower()
    if not v:
        return None
    if v in PRIMARY_GOOD:
        return "good"
    if v in PRIMARY_BAD:
        return "bad"
    return None  # unrecognized → treated as 'not a primary outcome' (likely a null row)


def classify_fp(value):
    """Return True (false positive present), False (clean), or None (not an FP cell)."""
    v = value.strip().lower()
    if not v:
        return None
    if v in FP_POSITIVE:
        return True
    if v in FP_NONE:
        return False
    return None


def score_split(records, split):
    """Compute primary margin + FP count for one split. Returns a dict of tallies."""
    rows = [r for r in records if r["split"].strip().lower() == split]
    on_good = on_bad = off_good = off_bad = 0
    fp_count = fp_total = 0

    for r in rows:
        cond = r["condition"].strip().upper()
        prim = classify_primary(r["primary_metric"])
        if prim is not None:
            if cond == "ON" and prim == "good":
                on_good += 1
            elif cond == "ON" and prim == "bad":
                on_bad += 1
            elif cond == "OFF" and prim == "good":
                off_good += 1
            elif cond == "OFF" and prim == "bad":
                off_bad += 1

        fp = classify_fp(r["fp_metric"])
        if fp is not None:
            # FP cost is measured on the ON condition (the discipline firing wrongly).
            if cond == "ON":
                fp_total += 1
                if fp:
                    fp_count += 1

    # Primary margin = how many MORE "good" outcomes ON produced vs OFF.
    # (Net directional signal; design entitles us to a sign + count, not an effect size.)
    margin = (on_good - on_bad) - (off_good - off_bad)
    return {
        "split": split,
        "n_rows": len(rows),
        "on_good": on_good,
        "on_bad": on_bad,
        "off_good": off_good,
        "off_bad": off_bad,
        "margin": margin,
        "fp_count": fp_count,
        "fp_total": fp_total,
    }


def decide(tally):
    """Apply the pre-registered §6 decision rule. Returns (verdict, reason)."""
    margin = tally["margin"]
    fp = tally["fp_count"]

    # FP override (design §6): null-fixture FP at/over threshold forces CUT,
    # overriding a positive primary.
    if fp >= CUT_FP_THRESHOLD:
        return ("CUT", f"null-fixture FP {fp} >= threshold {CUT_FP_THRESHOLD} (FP overrides primary)")

    # Positive harm signal on the primary (OFF beat ON).
    if margin < 0:
        return ("CUT", f"negative primary margin {margin} (OFF beat ON = harm signal)")

    # KEEP requires the pre-registered minimum margin AND FP below threshold.
    if margin >= KEEP_MIN_PRIMARY_MARGIN and fp < CUT_FP_THRESHOLD:
        return ("KEEP", f"primary margin {margin} >= {KEEP_MIN_PRIMARY_MARGIN} and FP {fp} < {CUT_FP_THRESHOLD}")

    # Everything else is the expected default. Neutral is never CUT (§6).
    return ("INCONCLUSIVE", f"primary margin {margin} below KEEP threshold {KEEP_MIN_PRIMARY_MARGIN}; not a harm signal")


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        print("ERROR: exactly one argument required (path to a results CSV).", file=sys.stderr)
        sys.exit(2)

    path = sys.argv[1]
    header, data = load_csv(path)
    validate_header(header, path)

    print(f"== A/B score: {path} ==")
    print(f"schema: OK ({len(header)} columns)")

    if not data:
        print()
        print("no data rows yet — run the A/B pass first.")
        print("  See dev/harness-eval.md for the runner procedure, then append one row")
        print("  per (fixture x condition) to this CSV and re-run score.py.")
        sys.exit(0)

    records = to_records(header, data, path)
    print(f"data rows: {len(records)}")
    print()
    print(f"pre-registered thresholds (design §2/§6): "
          f"KEEP margin >= {KEEP_MIN_PRIMARY_MARGIN}, CUT FP >= {CUT_FP_THRESHOLD}")
    print()

    splits = sorted({r["split"].strip().lower() for r in records})
    any_decided = False
    for split in splits:
        tally = score_split(records, split)
        verdict, reason = decide(tally)
        any_decided = True
        print(f"-- split: {split} (n={tally['n_rows']}) --")
        print(f"   primary  ON  good/bad = {tally['on_good']}/{tally['on_bad']}   "
              f"OFF good/bad = {tally['off_good']}/{tally['off_bad']}")
        print(f"   primary margin (net good, ON - OFF) = {tally['margin']}")
        print(f"   null-fixture FP (ON) = {tally['fp_count']}/{tally['fp_total']}")
        print(f"   VERDICT: {verdict}  — {reason}")
        print()

    if any_decided:
        print("NOTE: report direction + raw tally only — never a magnitude (design §0).")
        print("NOTE: a CHANGELOG status flip also requires reviewing the held-out split")
        print("      and must record model+effort inline (results do not port).")


if __name__ == "__main__":
    main()
