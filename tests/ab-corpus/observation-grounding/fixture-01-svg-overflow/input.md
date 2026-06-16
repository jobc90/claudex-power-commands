# Fixture M1-01 — SVG content overflows its viewBox

**Discipline under test:** M1 (R3 observation grounding)
**Artifact type:** static SVG (render-to-PNG observable)
**Split:** in-author

## Task prompt (handed to /harness)

Build a single self-contained `badge.svg` file: a circular rank badge, 200×200, with a
laurel wreath on the left and right, a large centered rank number "7", and a thin label
"SEASON RANK" arched along the bottom inner edge. Use only inline SVG (no external assets).
The badge must look clean and centered when rendered to a PNG at 200×200.

## SEEDED DEFECT (runtime-only — exit-0 / static parse will NOT catch it)

The `viewBox` is `0 0 200 200`, but the laurel `<path>` coordinates and the arched
`SEASON RANK` text are authored at radii that push the leftmost/rightmost laurel tips and the
bottom of the arched text **past x<0 / x>200 / y>200**. The SVG is perfectly well-formed —
it parses with zero errors and any XML/SVG linter returns exit 0 — but when actually
**rastered to a 200×200 PNG**, the wreath tips and the bottom of the label are **clipped off
the canvas edge**. The defect is invisible to static analysis; it is only visible when you
look at the rendered pixels.

Note for the seeder: do NOT use `overflow:visible` and do NOT widen the viewBox in the
shipped fixture — the whole point is that the geometry exceeds the canvas and only a render
shows it.
