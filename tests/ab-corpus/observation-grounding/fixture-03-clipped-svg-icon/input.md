# Fixture M1-03 — icon grid wraps and clips the last row below the fold

**Discipline under test:** M1 (R3 observation grounding)
**Artifact type:** static HTML/CSS layout (Playwright observable)
**Split:** held-out

> NOTE: marked `held-out` — score this fixture with the SAME frozen scorer used on the
> in-author fixtures. If M1's direction flips here vs the in-author set, the effect was an
> artifact of the author's mental model (design §3). A real held-out pass needs a *different*
> author to seed it; this stub documents the slot and the intent.

## Task prompt (handed to /harness)

Build a single-file `icon-gallery.html` (inline CSS, no external assets) that displays a
fixed-height card (height: 320px, `overflow: hidden`, no scroll) containing a grid of 12
labeled icon tiles. All 12 icons must be fully visible inside the card.

## SEEDED DEFECT (runtime-only — exit-0 / static parse will NOT catch it)

The card is `height: 320px; overflow: hidden`, but the 12 tiles at the chosen tile size and
gap reflow into 4 rows whose total height is ~390px. The CSS is valid and the HTML parses
clean (exit 0), but at the target viewport the **bottom row of icons is clipped below the
card's fixed height** and, because `overflow: hidden`, there is no scrollbar to hint at it.
Only a rendered screenshot at the target width reveals that the last row is cut off. A
static check sees a valid grid and passes.

## Expected observable symptom

A Playwright screenshot of the card shows only ~9 of the 12 tiles; the bottom row is missing
(clipped), with no scroll affordance.
