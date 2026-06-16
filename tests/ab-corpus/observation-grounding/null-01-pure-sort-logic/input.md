# Null Fixture M1-N01 — pure sorting logic with its own test suite

**Discipline under test:** M1 (R3 observation grounding) — **false-positive probe**
**Artifact type:** pure logic, NO observable execution result
**Split:** in-author

## Task prompt (handed to /harness)

Implement `stableSortBy(items, keyFn)` in `sort.js`: a stable sort that orders an array by the
numeric key returned by `keyFn`, preserving the original relative order of equal-key elements.
Include `sort.test.js` with Vitest cases covering: empty array, single element, already-sorted,
reverse-sorted, and **stability** (equal keys keep input order). The tests must pass.

## Why this is a NULL fixture (no seeded defect)

There is **no runtime-only visual/observable defect** here and none should be seeded. This is
pure logic whose correctness is fully captured by its **own test suite** — per the
observation-grounding trigger, "logic with its own test suite does not need observation:
running the tests IS the grounding." There is nothing to render and no screenshot to read.

## What we are measuring (false-positive cost)

The ON condition is **correct** iff it grounds via the passing test suite and does **NOT**
demand a render/screenshot/Playwright observation of this non-observable artifact. If the ON
run insists on observing rendered output here, that is a **false positive** — wasted
heavy-process-on-a-small-task, exactly the anti-pattern the R4 stop-condition guards against.
