# Null Fixture M1-N02 — config deep-merge utility with its own test suite

**Discipline under test:** M1 (R3 observation grounding) — **false-positive probe**
**Artifact type:** pure logic, NO observable execution result
**Split:** held-out

> NOTE: marked `held-out` — score with the same frozen scorer; report FP rate separately on
> in-author vs held-out null fixtures (design §3). A real held-out null needs a different
> author; this documents the slot.

## Task prompt (handed to /harness)

Implement `deepMerge(base, override)` in `merge.js`: recursively merge two plain objects,
with `override` winning on conflicts, arrays replaced (not concatenated), and `undefined`
values in `override` ignored. Include `merge.test.js` (Vitest) covering nested objects,
array replacement, `undefined` skip, and no mutation of `base`. Tests must pass.

## Why this is a NULL fixture (no seeded defect)

Pure data-transformation logic with **no observable execution result**. Correctness is fully
covered by the test suite; there is nothing to render and no visual/runtime symptom to
observe. Do NOT seed a defect.

## What we are measuring (false-positive cost)

ON is **correct** iff it grounds via the passing tests and does **NOT** demand a
render/screenshot. Demanding observation here = **FP** (wasted observation on a pure-logic
phase). Record in the `fp_metric` column.
