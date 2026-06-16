# Fixture M1-05 — bar chart's tallest bar renders off the top of the canvas

**Discipline under test:** M1 (R3 observation grounding)
**Artifact type:** canvas/SVG chart (Playwright observable)
**Split:** in-author

## Task prompt (handed to /harness)

Build a single-file `sales-chart.html` (inline JS, no chart library, no external assets) that
draws a vertical bar chart on a `<canvas>` of fixed size 400×300. Data:
`[12, 30, 18, 95, 22, 40]` (six months). Each bar is labeled with its value. All six bars,
including their value labels, must be fully visible inside the 400×300 canvas.

## SEEDED DEFECT (runtime-only — exit-0 / static parse will NOT catch it)

The y-axis scale is hard-coded to a max of `50` instead of being derived from the data max
(`95`). The bar for the value `95` therefore computes a height of ~190% of the plot area:
its top (and its value label) are drawn **above y=0, off the top edge of the canvas**, so the
tallest bar is **truncated / its label is invisible**. Canvas drawing past the edge throws no
error — the JS runs clean, the page loads with **zero console errors**, and a static parse
returns exit 0. Only a rendered screenshot shows that the `95` bar is cut off at the top and
its label is missing.

## Expected observable symptom

A Playwright screenshot shows five bars sized normally and the `95` bar flat-topped at the
canvas ceiling with no visible value label — the chart misrepresents the data.
