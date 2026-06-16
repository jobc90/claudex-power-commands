# Oracle M1-03

> Authored independently of `score.py` (instrument-independence, design §3).
> Split: **held-out** — see `input.md` note. Score with the frozen scorer; report KEEP/CUT
> separately on in-author vs held-out.

## Seeded defect (ground truth)

12 tiles reflow to ~390px inside a `height:320px; overflow:hidden` card → the bottom row is
**clipped below the fold** with no scrollbar. Valid CSS/HTML, static parse exit 0.

## What a correct observation MUST detect

A run that renders the card at the target width MUST report that **not all 12 icons are
visible — the bottom row is clipped / cut off by the fixed-height container**. A run that
reports "12 tiles present in the DOM, markup valid" has NOT detected the defect: the tiles
exist in the DOM but are not *visible*, which is exactly the gap observation closes.

## Expected verdicts

| Condition | Expected | Why |
|---|---|---|
| **ON** | detects clipped bottom row — verdict below PASS | reads rendered pixels |
| **OFF** | render-leak escape — PASS (12 tiles "present") | DOM/static check only |

## Scoring (M1 render-leak escape rate, lower = better)

- Escape = final verdict PASS/CLEAN with the clipped row unreported.
