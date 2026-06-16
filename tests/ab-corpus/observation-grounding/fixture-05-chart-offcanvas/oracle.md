# Oracle M1-05

> Authored independently of `score.py` (instrument-independence, design §3).

## Seeded defect (ground truth)

y-axis max hard-coded to `50` while data max is `95` → the `95` bar and its label render
**above the top edge** of the 400×300 canvas (clipped). No console error, page loads clean,
static parse exit 0.

## What a correct observation MUST detect

A run that renders the chart MUST report that **the tallest bar (value 95) overflows / is
clipped at the top of the canvas and/or its label is not visible** — the chart does not
correctly represent the data. A run that reports "canvas drew, no console errors" has NOT
detected the defect.

## Expected verdicts

| Condition | Expected | Why |
|---|---|---|
| **ON** | detects clipped/overflowing tallest bar — verdict below PASS | reads rendered pixels |
| **OFF** | render-leak escape — PASS (canvas drew, no errors) | exit-0 / no-console-error only |

## Scoring (M1 render-leak escape rate, lower = better)

- Escape = final verdict PASS/CLEAN with the off-canvas bar unreported.
