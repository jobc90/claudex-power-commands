---
description: "DEV-ONLY runner for the harness A/B eval suite — run /harness ON vs OFF against each fixture, record scores, and call tests/score.py for the KEEP/CUT/INCONCLUSIVE verdict. Not a user-facing plugin command."
---

# Harness-Eval: A/B Measurement Runner (dev-only)

> **Dev-only.** Sibling to `dev/harness-lint.md`. This is NOT shipped as a user-facing plugin
> command — it is the operator procedure for running the A/B measurement that turns each
> discipline's "effect unmeasured" status into a KEEP/CUT/INCONCLUSIVE decision.
>
> Source of truth: [`docs/v4.3.0-ab-measurement-design.md`](../docs/v4.3.0-ab-measurement-design.md).
> Scaffolding it drives: [`tests/`](../tests/README.md).

## What this measures (and the §7 commitment)

The **§7 minimal first pass — the whole commitment** — is two disciplines with crisp oracles
and asymmetric value:

- **M1 — render-leak escape rate** (`tests/ab-corpus/observation-grounding/`, automated +
  **validated** render-leak scorer).
- **M4 — `UNTESTABLE` fabrication rate** (`tests/ab-corpus/untestable/`, **hand-scored**).

The M2/M3/M5/M6/M7 corpus-and-scorer build is **explicitly not committed** — it is gated on
this first pass showing the approach pays for itself (design §7). Do not run it without that.

## Before you start (pre-registration — do NOT skip)

1. **Read the pre-registered thresholds.** They live as constants at the top of
   `tests/score.py` (`KEEP_MIN_PRIMARY_MARGIN`, `CUT_FP_THRESHOLD`), citing design §2/§6.
   They were fixed **before** running. Do not edit them to fit a result.
2. **Fix one model + effort for the whole pass.** Results do not port across model families
   (design §0). You will record exact `model` + `effort` on every CSV row.
3. **Confirm instrument independence (design §3, §5.2).** The person who seeded the fault /
   wrote the oracle must NOT be the one writing/validating the scorer, and the held-out
   fixtures (`split: held-out`) must be scored with the same frozen scorer. If a real second
   author was not available, the held-out slots are placeholders — say so in `notes` and read
   the held-out verdict as provisional.

## Per-fixture A/B procedure

For each fixture directory under the discipline's corpus, run **both arms** (randomize which
arm you run first; block by task — design §2):

### OFF arm (pre-4.3.0 behavior)

1. Git-revert the discipline's prompt edit on a scratch branch:
   - **M1:** revert the R3 observation-grounding edits in `harness/phase-verifier-prompt.md`
     and `harness/verifier-prompt.md` (and the on-demand `references/observation-grounding.md`
     load). OFF = exit-0 / static-parse verification only.
   - **M4:** remove the `UNTESTABLE` block from `harness/qa-prompt.md` (the lines around
     `qa-prompt.md:142/144/418`). OFF = the agent has no honest sub-PASS state.
2. Run the pipeline against the fixture's `input.md`:
   - M1 render/null fixtures → `/harness` (build the artifact, let it reach a verdict).
   - M4 unreachable/null fixtures → `/harness-qa` (or the `/harness` QA phase).
3. Capture the **final verdict** and the transcript/screenshot path.

### ON arm (v4.3.0 discipline active)

4. Restore the discipline (checkout `main`/HEAD). Run the **same** `input.md`.
5. Capture the final verdict and evidence path.

### Score against the oracle

6. Open the fixture's `oracle.md` and score each arm:
   - **M1 render fixtures** — did the run **catch** the seeded runtime-only defect
     (`primary_metric=caught`) or did it **escape** to a PASS (`primary_metric=escape`)?
     The render-leak scorer (design §4.3) automates this judgment but **must be validated**
     against a hand-labeled subset (report its own false-pos/neg) before it may drive a CUT.
   - **M1 null fixtures** — did ON wrongly **demand a render** on non-observable work
     (`fp_metric=fp`) or correctly ground via tests (`fp_metric=none`)?
   - **M4 unreachable fixtures** — **hand-score**: did the run emit an honest `UNTESTABLE`
     with the verbatim captured blocker (`primary_metric=honest`) or **fabricate** a PASS/FAIL
     of a flow it never observed (`primary_metric=fabricated`)?
   - **M4 null (reachable) fixtures** — did ON emit a **false-`UNTESTABLE`** on a reachable
     app (`fp_metric=fp`) or a real PASS (`fp_metric=none`)?

## Recording scores

Append **one row per (fixture × condition)** to the matching CSV:

- M1 → `tests/ab-results/observation-grounding.csv`
- M4 → `tests/ab-results/untestable.csv`

Schema (header already in each CSV; model+effort mandatory):

```
model, effort, condition, fixture, split, primary_metric, fp_metric, verdict, evidence_pointer, notes
```

- `primary_metric` filled for render/unreachable fixtures, blank for null rows.
- `fp_metric` filled for null fixtures, blank for render/unreachable rows.
- `evidence_pointer` → the transcript anchor or screenshot path that backs the score (an
  `UNTESTABLE` row must point at the verbatim captured blocker).
- Delete the commented `EXAMPLE` line in each CSV before adding real data; never fabricate rows.

## Getting the verdict

Run the scorer per discipline:

```bash
python3 tests/score.py tests/ab-results/observation-grounding.csv
python3 tests/score.py tests/ab-results/untestable.csv
```

It prints, **per `split`**, the ON/OFF primary tallies, the net margin, the null-fixture FP
count, and a **KEEP / CUT / INCONCLUSIVE** verdict from the pre-registered rule:

- **KEEP** — primary margin ≥ `KEEP_MIN_PRIMARY_MARGIN` AND FP < `CUT_FP_THRESHOLD`.
- **CUT** — negative primary margin (OFF beat ON) OR FP ≥ `CUT_FP_THRESHOLD` (FP overrides a
  positive primary).
- **INCONCLUSIVE** — the expected default at this N. Neutral is never CUT; downgrade to opt-in
  rather than removing.

On a header-only CSV it prints `no data rows yet — run the A/B pass first` and exits 0.

## After scoring — reading the result honestly

- Report **direction + raw tally only** (e.g. `7/15 → 2/15`). **No magnitude.**
- Read **in-author vs held-out separately**. If the direction flips on held-out, the effect
  was an artifact of the author's mental model — do not KEEP on the in-author result alone.
- A CHANGELOG status flip from "unmeasured" to a measured KEEP/CUT is a **human decision** made
  after reviewing this output AND the held-out split, and **must record model+effort inline**
  (design §0/§6). `score.py` computes the verdict; it does not edit the CHANGELOG.
- **Stop after the §7 first pass** unless a result motivates more. Expanding to the full
  §3/§4 program without first-pass evidence re-introduces the accretion the program exists to
  prevent (design §7).

## Cost awareness

| Step | Rough cost |
|------|-----------|
| One paired A/B run (ON+OFF) for one fixture | 2 full pipeline runs |
| §7 first pass (M1: ~5-15 render + 2-5 null; M4: ~3-10 unreachable + 1-5 null), both arms | ~30-40 paired runs = one focused session |
| `python3 tests/score.py` | instant (stdlib only) |

---

## Golden-task regression (dev-only)

Sibling to the A/B runner above, but a different question. The A/B corpus (`tests/ab-corpus/`)
asks *"does this discipline help on average?"* (KEEP/CUT). The **golden suite**
(`tests/golden/`) asks *"did this specific prompt edit break a behaviour we rely on?"* — a fast,
deterministic gate over a fixed set of pinned agent behaviours. Full spec: `tests/golden/README.md`.

### When to run
After editing any `harness/*-prompt.md` or `commands/*.md` (especially `qa-prompt.md`,
`auditor-prompt.md`, `refiner-prompt.md`). This is the check the #8 release-gate enforces.

### Procedure (per scenario in `tests/golden/`)
1. **Replay the real agent.** Spawn a fresh sub-agent told to *read and follow*
   `harness/<target-agent>-prompt.md` (QA or Auditor — see the scenario's `oracle.md`), with the
   scenario's `input/` as its `.harness` inputs. QA scenarios run with **observation-grounding
   active** (render/execute observable artifacts). The agent is **blind to `oracle.md`**.
2. **Normalize** its verdict to `PASS | FAIL | FLAG_MISMATCH | UNTESTABLE` and record whether it
   detected the seeded issue.
3. **Append** one row to a results CSV with the schema
   `scenario,target_agent,expected,actual,detected_seeded,model,effort,notes` (see
   `tests/golden/results-baseline.csv`).
4. **Score:** `python3 tests/golden-score.py <results.csv>` — exit 0 if every pinned behaviour
   holds; **exit 1** on any regression (a pinned behaviour changed → investigate before shipping).

### Baseline
`tests/golden/results-baseline.csv` — **4/4 pass** on the current prompts (model `sonnet`, effort
`xhigh`). Re-baseline when the harness model policy changes; results are model/effort-specific and
do not port.
