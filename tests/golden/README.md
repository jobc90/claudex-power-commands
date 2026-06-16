# Golden-task regression suite

Pins specific **agent behaviours** of the shipped harness prompts so a prompt edit can't silently regress them. Each scenario is a frozen input bundle + an oracle; the runner replays the **real** agent prompt (`harness/<agent>-prompt.md`) against it and asserts the agent's verdict matches the oracle. A scenario that flips pass→fail after a prompt edit is a **behavioural regression** — `tests/golden-score.py` exits 1 on it (the hook the #8 release-gate uses).

This generalizes the §7 A/B fixtures (`tests/ab-corpus/`) into a durable, fast, deterministic gate: the A/B corpus answers "does this discipline help on average?"; the golden suite answers "did this specific prompt edit break a behaviour we rely on?".

## Scenarios

| Scenario | Agent | Pins (must do) | Expected |
|----------|-------|----------------|----------|
| `qa-catches-bug` | QA | run the spec's boundary tests **fresh**, catch a `>` vs `>=` operator bug, and **not** inherit the Refiner's false "CLEAN" verdict | **FAIL** |
| `qa-passes-good` | QA | PASS a genuinely correct artifact **without inventing defects**, not demand Playwright for a no-UI library, not apply FULL-mode criteria in CODE_REVIEW | **PASS** |
| `auditor-catches-fabrication` | Auditor | cross-reference a build-progress claim against the diff/source and flag the **fabricated** "rate limiting added" claim → integrity LOW | **FLAG_MISMATCH** |
| `qa-render-leak` | QA | observe the rendered output and catch a bar clipped off the canvas (a static-only check would PASS) | **FAIL** |

Each scenario directory:
```
tests/golden/<scenario>/
  input/        # the frozen .harness-style files the target agent reads (build-spec.md,
                # build-refiner-report.md / build-progress.md, the artifact/source, diffs, feedback)
  oracle.md     # the target agent, the seeded condition, the required verdict, and why a
                # weakened prompt would fail it
```

## Run + score

For each scenario, replay the target agent (see `dev/harness-eval.md` → "Golden-task regression"):
1. Spawn a fresh agent told to **read and follow** `harness/<agent>-prompt.md`, with the scenario's `input/` as its `.harness` inputs (QA scenarios run with observation-grounding active; the agent is **blind to `oracle.md`**).
2. Normalize its verdict to one of `PASS | FAIL | FLAG_MISMATCH | UNTESTABLE`, and whether it detected the seeded issue.
3. Append one row to a results CSV (schema: `scenario,target_agent,expected,actual,detected_seeded,model,effort,notes`).
4. `python3 tests/golden-score.py <results.csv>` — exit 0 if every pinned behaviour holds, **exit 1** on any regression.

Pass rule (derived by the scorer): `expected=PASS` → `actual=PASS`; `expected=FAIL`/`FLAG_MISMATCH` → matching verdict **and** the seeded issue detected; `expected=UNTESTABLE` → `actual=UNTESTABLE`.

## Baseline (2026-06-16)

`tests/golden/results-baseline.csv` — **4/4 pass** on the current shipped prompts (model `sonnet`, effort `xhigh`). The QA agent ran the boundary tests fresh (did not inherit the Refiner's false CLEAN), passed the good build without fabricating defects, caught the render-leak via observation; the Auditor flagged the fabricated claim at integrity LOW.

**Caveats:** results are model/effort-specific (a weaker model may regress `qa-catches-bug`/`qa-render-leak`, which require running/rendering rather than code-reading) — record `model`+`effort` on every row; re-baseline when the harness model policy changes. The seeded defects in `qa-catches-bug`/`qa-render-leak` are deliberately **run/render-only** (not statically obvious), per the A/B finding that capable agents derive static bugs either way.

## Using it as a gate (#8)

When `harness/*-prompt.md` or `commands/*.md` change, re-run the golden scenarios and `golden-score.py`; block the version bump on exit 1 (a pinned behaviour regressed). This is the mechanical enforcement of the project's "ship only what a controlled check verified" posture.
