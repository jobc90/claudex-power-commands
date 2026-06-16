# Fixture M1-02 — modal overlay covers the playable game board

**Discipline under test:** M1 (R3 observation grounding)
**Artifact type:** interactive HTML/JS game (Playwright observable)
**Split:** in-author

## Task prompt (handed to /harness)

Build a single-file `tic-tac-toe.html` (inline CSS + JS, no external assets). Requirements:
3×3 grid of clickable cells, alternating X/O, win/draw detection, and a "New Game" button.
On page load a one-time "How to play" intro overlay appears; clicking "Got it" dismisses it
so the player can start. The game must be playable after the intro is dismissed.

## SEEDED DEFECT (runtime-only — exit-0 / static parse will NOT catch it)

The intro overlay's "Got it" button handler has a typo: it sets the overlay's class to
`hidden` but the CSS rule that actually hides it is keyed on `.hide` (not `.hidden`). The
HTML is valid, the JS has **no syntax error**, the page loads with **zero console errors**,
and a static parse returns exit 0. But at runtime the overlay is a full-viewport element with
a high `z-index` that **never disappears** — it sits on top of the board and **intercepts all
clicks**, so the game is completely unplayable. The defect only shows when you actually load
the page, click "Got it", and try to click a cell — i.e. only via observation.

## Expected observable symptom

After clicking "Got it", a Playwright screenshot still shows the dimmed overlay over the
board, and attempting to click a grid cell does nothing (the cell never fills with X/O).
