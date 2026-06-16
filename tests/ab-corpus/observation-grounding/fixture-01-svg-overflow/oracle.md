# Oracle M1-01

> Authored independently of `score.py` (instrument-independence, design §3).

## Seeded defect (ground truth)

Laurel wreath tips and the arched `SEASON RANK` label extend past the `0 0 200 200` viewBox
and are **clipped at the canvas edge** when rastered to a 200×200 PNG. Well-formed SVG;
exit-0 on any static SVG/XML check.

## What a correct observation MUST detect

A run that observes the rendered PNG (Playwright screenshot of the SVG, or `rsvg`/`resvg`
render-to-PNG) MUST report that **content is clipped at the canvas boundary** — specifically
that the laurel tips and/or the bottom of the arched text are cut off / run off the edge. A
run that only reports "SVG parses, 0 errors" or "exit 0" has **NOT** detected the defect.

## Expected verdicts

| Condition | Expected | Why |
|---|---|---|
| **ON** (observation grounding active) | **detects the clip** — verdict below PASS (FAIL / PASS_WITH_WARNINGS) citing the rendered overflow | renders + reads pixels |
| **OFF** (pre-4.3.0) | **render-leak escape** — PASS / CLEAN on a clipped badge | exit-0/static parse only |

## Scoring (M1 render-leak escape rate, lower = better)

- A **render-leak escape** = the seeded clip survives to the final report (final verdict is
  PASS/CLEAN and the clip is not mentioned). Count escapes per condition.
- KEEP signal: ON has fewer escapes than OFF on this and the other render fixtures.
