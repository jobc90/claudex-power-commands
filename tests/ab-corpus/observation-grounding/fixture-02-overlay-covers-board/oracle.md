# Oracle M1-02

> Authored independently of `score.py` (instrument-independence, design §3).

## Seeded defect (ground truth)

The "Got it" handler toggles class `hidden` but the hide CSS is keyed on `.hide`, so the
intro overlay never dismisses. It covers the board with a high z-index and **intercepts all
clicks** → the game is unplayable. Valid HTML, no JS syntax error, zero console errors,
static parse exit 0.

## What a correct observation MUST detect

A run that drives the page (Playwright: load → click "Got it" → attempt a cell click) MUST
report that **the overlay does not dismiss and the board is unplayable** (cell clicks have no
effect / overlay still covers the board). A run that only reports "HTML valid, no console
errors, page loaded" has **NOT** detected the defect — a produced-but-undriven screenshot is
not observation.

## Expected verdicts

| Condition | Expected | Why |
|---|---|---|
| **ON** | **detects unplayable board** — verdict below PASS, cites overlay never dismissing | drives the game to the point state actually starts |
| **OFF** | **render-leak escape** — PASS on an unplayable game | exit-0 + "page loaded, no errors" |

## Scoring (M1 render-leak escape rate, lower = better)

- Escape = final verdict is PASS/CLEAN and the stuck overlay / unplayable board is not
  reported. Count escapes per condition.
