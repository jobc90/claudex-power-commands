# How to expand the M1 (observation-grounding) corpus

> Seed scope here: **5 render fixtures + 2 null**. Design §7 target: **10-15 render + 5 null**.
> This file documents the gap and the rules for closing it. Read
> `docs/v4.3.0-ab-measurement-design.md` §3, §4, §7 first.

## Current seed vs target

| | Seeded now | Design target (§7) | Gap to author |
|---|---|---|---|
| Render fixtures (with seeded runtime-only defect) | 5 | 10-15 | +5 to +10 |
| Null fixtures (pure-logic / no observable output) | 2 | 5 | +3 |

## The bar every render fixture must clear

A render fixture is only valid if its seeded defect is **runtime-only**: an `exit 0` chain
**and** a clean static parse must BOTH pass while the defect is present. If a linter / type
check / `--check` would catch it, it is not an M1 fixture — it tests static analysis, not
observation. The design's worked categories (extend these): off-canvas chart overflow,
overlay covering a game board, clipped SVG, exit-0-with-stack-trace CLI. More to add:

- animation/game that never advances past frame 0 (loop never starts) — driven via Playwright.
- a chart whose axis labels overlap into illegibility at the target size.
- a flex/grid layout that collapses to zero-height at a specific viewport width.
- a dark-on-dark / invisible-text contrast failure (renders, parses, unreadable).
- a CLI whose progress bar / table is mangled (wrong column math) but exits 0.

## The bar every null fixture must clear

A null fixture must be genuinely **non-observable**: pure logic whose correctness is fully
captured by its own passing test suite, with nothing to render. The FP we measure is the ON
condition *demanding* a render where one is unwarranted. Add e.g.: a date-math helper, a
parser/tokenizer, a reducer/state-machine, a validation schema — each with a passing suite.

## Instrument independence (do not skip — design §3, §5.2)

- The person who **seeds the fault** must NOT be the person who **writes the scorer**.
- Author a **held-out** set from a *different* author and score it with the same frozen
  `score.py`. Mark held-out fixtures with `split: held-out` in their `input.md`/`oracle.md`
  and in the CSV's `split` column.
- Two of the current fixtures (`fixture-03`, `null-02`) are tagged held-out as **slots/intent
  markers** — they are still author-seeded. A real held-out pass requires a second author to
  replace them. Report KEEP/CUT separately on in-author vs held-out; a direction flip on
  held-out means the effect was an artifact of the author's mental model, not a real signal.

## When to build the automated scorer

Per design §4.3 + §7, M1's render-leak detector ("does the final verdict match the seeded
defect?") is the **one** reused oracle worth automating — but it must be **validated** first:
dry-run it against a hand-labeled subset and report its own false-pos/neg rate before it is
allowed to drive a CUT. `score.py` here computes the KEEP/CUT verdict from already-scored
rows; the per-transcript "did it catch the seeded defect?" judgment is the part to automate
and validate next.
