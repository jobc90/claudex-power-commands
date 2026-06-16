#!/usr/bin/env python3
"""golden-score.py — golden-task regression scorer for the harness agent prompts.

Stdlib only. Part of the harness eval scaffolding (see tests/golden/README.md).

Unlike `score.py` (an A/B KEEP/CUT engine over a corpus), this scores a fixed set
of GOLDEN SCENARIOS that each pin one agent behaviour: replay the real shipped
agent prompt against a frozen input, then assert the agent's verdict matches the
scenario's oracle. A scenario that flips from pass -> fail after a prompt edit is a
BEHAVIOURAL REGRESSION. Intended to gate prompt edits (the #8 release-gate hook).

The pass rule per scenario (derived here, not trusted from the CSV):
  - expected PASS           -> pass iff actual == PASS
  - expected FAIL           -> pass iff actual == FAIL          AND detected_seeded
  - expected FLAG_MISMATCH  -> pass iff actual == FLAG_MISMATCH AND detected_seeded
  - expected UNTESTABLE     -> pass iff actual == UNTESTABLE

Exit code: 0 if every scenario passes; 1 if any scenario regressed (so a hook can
block on it); 2 on a malformed CSV.

Usage:
    python3 tests/golden-score.py tests/golden/results-baseline.csv
"""

import csv
import sys

REQUIRED_HEADER = [
    "scenario",
    "target_agent",
    "expected",       # PASS | FAIL | FLAG_MISMATCH | UNTESTABLE
    "actual",         # the agent's normalized verdict
    "detected_seeded",  # yes|no — did the agent detect the seeded bug/fabrication
    "model",
    "effort",
    "notes",
]

EXPECTED_TOKENS = {"PASS", "FAIL", "FLAG_MISMATCH", "UNTESTABLE"}


def _truthy(v):
    return v.strip().lower() in {"yes", "y", "true", "1"}


def load_csv(path):
    try:
        with open(path, newline="", encoding="utf-8") as fh:
            kept = [ln for ln in fh.readlines() if ln.strip() and not ln.lstrip().startswith("#")]
    except FileNotFoundError:
        print(f"ERROR: file not found: {path}", file=sys.stderr)
        sys.exit(2)
    if not kept:
        print(f"ERROR: {path} is empty (not even a header).", file=sys.stderr)
        sys.exit(2)
    rows = list(csv.reader(kept))
    return [c.strip() for c in rows[0]], rows[1:]


def passed(expected, actual, detected):
    e, a = expected.strip().upper(), actual.strip().upper()
    if e not in EXPECTED_TOKENS:
        return None  # unknown expectation — flagged separately
    if e == "PASS":
        return a == "PASS"
    if e == "UNTESTABLE":
        return a == "UNTESTABLE"
    # FAIL / FLAG_MISMATCH require both the right verdict AND that the seeded issue was caught
    return a == e and detected


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        print("ERROR: exactly one argument required (path to a golden results CSV).", file=sys.stderr)
        sys.exit(2)

    path = sys.argv[1]
    header, data = load_csv(path)
    if header != REQUIRED_HEADER:
        print(f"ERROR: header schema mismatch in {path}", file=sys.stderr)
        print(f"  expected: {REQUIRED_HEADER}", file=sys.stderr)
        print(f"  found:    {header}", file=sys.stderr)
        sys.exit(2)

    print(f"== golden-task regression: {path} ==")
    print(f"schema: OK ({len(header)} columns)")

    if not data:
        print()
        print("no golden results yet — run the golden scenarios first.")
        print("  See tests/golden/README.md / dev/harness-eval.md for the runner, then append")
        print("  one row per scenario (scenario,target_agent,expected,actual,detected_seeded,model,effort,notes).")
        sys.exit(0)

    records = []
    for i, row in enumerate(data, start=1):
        if len(row) != len(header):
            print(f"ERROR: row {i} has {len(row)} fields, expected {len(header)}: {row}", file=sys.stderr)
            sys.exit(2)
        records.append({k: v.strip() for k, v in zip(header, row)})

    print(f"scenarios: {len(records)}")
    print()
    regressions = 0
    unknown = 0
    for r in records:
        p = passed(r["expected"], r["actual"], _truthy(r["detected_seeded"]))
        if p is None:
            mark, unknown = "?? UNKNOWN-EXPECT", unknown + 1
        elif p:
            mark = "PASS"
        else:
            mark, regressions = "FAIL <- REGRESSION", regressions + 1
        print(f"  [{mark:18}] {r['scenario']:32} {r['target_agent']:8} expected={r['expected']:14} actual={r['actual']}")

    print()
    total = len(records)
    ok = total - regressions - unknown
    print(f"RESULT: {ok}/{total} scenarios pass"
          + (f", {regressions} REGRESSION(S)" if regressions else "")
          + (f", {unknown} unknown-expectation" if unknown else ""))
    if regressions or unknown:
        print("=> a regressed scenario means a prompt edit changed a pinned agent behaviour. Investigate before shipping.")
        sys.exit(1)
    print("=> all pinned agent behaviours intact.")
    sys.exit(0)


if __name__ == "__main__":
    main()
