# Harness A/B Eval Suite

> Scaffolding for measuring whether a harness *discipline* (a few lines of prompt that
> enforce a behavior) actually changes agent behavior — so each discipline is **kept or cut
> on evidence**, not vibes. Closes the "effect unmeasured" gap noted in `CHANGELOG`/v4.3.0.
>
> Full design: [`docs/v4.3.0-ab-measurement-design.md`](../docs/v4.3.0-ab-measurement-design.md).
> Read it before adding fixtures or running a pass — it is the source of truth for hypotheses,
> the results schema, and the pre-registered KEEP/CUT thresholds.

## Why this exists

The harness ships behavioral disciplines (observation grounding, the `UNTESTABLE` verdict,
the Stop hook, etc.). Each is a procedure a harness can *enforce* while the model is held
fixed. The risk is two-sided:

- A discipline that does nothing is **prompt-token bloat** — it should be cut.
- A discipline that catches real regressions is **load-bearing** — cutting it ships a
  regression to every user.

This suite catches **agent-behavior regressions before shipping a prompt edit**: you run the
same fixture twice — once with the discipline ON, once with it git-reverted (OFF) — and score
which condition catches the seeded defect. The asymmetry matters: a false-CUT ships a
regression to everyone, a false-KEEP only costs tokens. So the decision rule (below) treats
"no measured effect" as INCONCLUSIVE, never as a removal.

## What this scaffolding is — and is NOT

This directory contains **infrastructure only**:

- fixture corpora (seeded-defect inputs + oracles),
- empty results CSVs with the mandatory column schema,
- a scorer that turns populated CSVs into a KEEP/CUT/INCONCLUSIVE verdict.

It does **NOT** contain measured results. The actual **30-40 paired runs** described in the
design's §7 minimal first pass are a **separate manual/execution step** — see
[`dev/harness-eval.md`](../dev/harness-eval.md) for the runner procedure. The CSVs here are
header-only on purpose; `score.py` will tell you "no data yet — run the A/B pass first" until
a human or agent fills them in. **Do not fabricate rows.**

## Seed scope (the §7 minimal first pass)

The design commits to exactly **two** disciplines with crisp oracles, near-blind scoring, and
asymmetric value. Everything else (M2/M3/M5/M6/M7) is explicitly *gated* on these two paying
off — do not build their corpora yet.

| Discipline | Corpus | Scoring | Design target | Seeded here |
|---|---|---|---|---|
| **M1 — render-leak escape rate** | `ab-corpus/observation-grounding/` | automated scorer, **validated** first | 10-15 render + 5 null | 5 render + 2 null |
| **M4 — `UNTESTABLE` fabrication rate** | `ab-corpus/untestable/` | **hand-scored** (1-state prompt change) | 10 unreachable + 5 reachable null | 3 unreachable + 1 null |

The seed sets are intentionally smaller than the design target so a reviewer can sanity-check
the shape before the corpus is expanded. Each corpus has a `_HOW-TO-EXPAND.md` describing the
gap to the full target. N=5/3 reads **nothing** statistically — it exists to validate the
harness, oracle format, and CSV plumbing end-to-end before the real corpus is authored.

## Directory layout

```
tests/
├── README.md                      ← this file
├── score.py                       ← CSV validator + KEEP/CUT/INCONCLUSIVE decision engine
├── ab-corpus/
│   ├── observation-grounding/     ← M1: render tasks with runtime-only defects
│   │   ├── _HOW-TO-EXPAND.md
│   │   ├── fixture-NN-<name>/
│   │   │   ├── input.md           ← artifact to build + the SEEDED runtime-only defect
│   │   │   └── oracle.md          ← what a correct observation MUST detect + expected verdict
│   │   └── null-NN-<name>/        ← pure-logic phases (forcing observation = waste → FP cost)
│   └── untestable/                ← M4: unreachable-app fixtures
│       ├── _HOW-TO-EXPAND.md
│       ├── fixture-NN-<name>/     ← app that cannot boot/be observed → sub-PASS verdict
│       └── null-NN-<name>/        ← reachable app (false-UNTESTABLE = false positive)
└── ab-results/
    ├── observation-grounding.csv  ← header-only skeleton (M1)
    └── untestable.csv             ← header-only skeleton (M4)
```

Each fixture lives in its own subdirectory with two files:

- **`input.md`** — the task prompt handed to `/harness`, plus a clearly-fenced **SEEDED
  DEFECT** block describing the runtime-only fault the agent must catch by *observing* (not
  by exit-0 / static parse). The defect is the kind that an exit-0 chain or a clean static
  parse would silently pass.
- **`oracle.md`** — the ground truth the *scorer* checks against: what a correct observation
  MUST detect, and the **expected verdict**. This is authored independently of the scorer
  (instrument-independence, design §3): the fault-seeder must not also be the scorer author.

## How to run a paired ON/OFF A/B pass

Full procedure: [`dev/harness-eval.md`](../dev/harness-eval.md). In short, **per fixture**:

1. **OFF arm** — `git revert`/stash the discipline's prompt edit (M1: the R3 observation
   edits in phase-verifier / review verifier; M4: the `UNTESTABLE` block in `qa-prompt.md`).
   Run `/harness` against `input.md`. Record the final verdict.
2. **ON arm** — restore the discipline. Run `/harness` against the same `input.md`. Record
   the final verdict.
3. **Randomize order, block by task, fix the model+effort** (design §2). Record exact
   `model` + `effort` on **every** row — results do not port across model families, and the
   caveat must live in the CSV, not only in prose (design §0).
4. **Score each run against the fixture's `oracle.md`** and append one row per (fixture ×
   condition) to the matching CSV in `ab-results/`. Use the `split` column to mark whether the
   fixture is `in-author` (seeded by the scorer's author) or `held-out` (a different author);
   if direction flips on held-out, the effect was an artifact of the author's mental model.

A null fixture is scored for **false positives**: did the ON arm demand observation on
non-observable work (M1), or emit a false `UNTESTABLE` on a reachable app (M4)? The
false-positive metric is **co-primary** and can override a positive primary result.

## How scoring + KEEP/CUT works

After populating a CSV, run the scorer:

```bash
python3 tests/score.py tests/ab-results/observation-grounding.csv
python3 tests/score.py tests/ab-results/untestable.csv
```

`score.py` (stdlib only):

1. **validates** the CSV against the mandatory header schema and exits non-zero on a schema
   mismatch (so a malformed CSV can't silently produce a verdict),
2. on a **header-only** CSV, prints `no data rows yet — run the A/B pass first` and exits 0,
3. on **populated** rows, applies the design's **pre-registered** decision rule (§6) and
   prints per-condition tallies + a KEEP / CUT / INCONCLUSIVE verdict per `split`.

The decision rule (design §6, thresholds pre-registered in §2 — encoded as constants at the
top of `score.py`):

- **KEEP** — the primary directional margin ON-vs-OFF meets the pre-registered minimum AND
  the null-fixture false-positive rate is below its threshold.
- **CUT** — a *positive harm signal*: a negative primary margin (OFF beat ON), OR the
  null-fixture FP rate at/over its threshold. FP **overrides** a positive primary, because a
  discipline that helps real cases but fires on a meaningful share of null cases is
  net-harmful in a gating pipeline.
- **INCONCLUSIVE** — anything in between (the expected default at this N). **Neutral is never
  CUT.** Downgrade the discipline to opt-in rather than removing it.

`score.py` only computes the verdict — flipping the `CHANGELOG` status from "unmeasured" to a
measured KEEP/CUT (with `model`+`effort` inline) is a human decision, made after reviewing the
scorer output **and** the held-out split.

## Honesty rules (inherited from the design)

- Report **direction + raw tally** (e.g. `7/15 → 2/15`), **never a magnitude**. At N≈15 you
  are entitled to a sign and a count, not an effect size.
- **Single model family ⇒ results do not port.** Every CSV row carries `model` + `effort`.
- The measuring instrument must stay **lighter than** the thing it measures. The seed scope is
  two disciplines; do not expand to a six-classifier corpus without first-pass evidence that
  the approach pays for itself.
