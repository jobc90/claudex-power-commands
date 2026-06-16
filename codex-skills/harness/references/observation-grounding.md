# Observation Grounding (reference)

> Loaded on demand by verify-chain agents (Phase Verifier, review Verifier, and any agent finalizing a verdict on a render/executable artifact). Defines the "run + observe" discipline AND its anti-over-verification bound in **one** place — they are one rule, not two.
> Status: transferred procedure (origin: fablize verification-grounding pack); its effect on claudex's model mix is **not yet A/B-measured**.

## When this applies (the trigger)

Apply ONLY to artifacts with an **observable execution result** — an HTML page, SVG, game, UI, chart, animation, or a script/CLI with observable stdout. Self-test: **"could this look wrong or behave wrong in a way that only shows when it runs?"** If yes → observe. Pure text, prose, config, or logic with its own test suite does **not** need observation — for those, running the tests IS the grounding (which you already do). Do not force observation onto non-observable work — that is the heavy-process-on-small-tasks anti-pattern.

## The flag (optional, backward-compatible)

A producing agent MAY tag a DoD item / finding / artifact `runtime-observation-required` in its `.harness` output. **Absence of the flag = current exit-code behavior** — a consumer that does not recognize it falls back to exit-0 verification exactly as before. The flag never changes semantics for unflagged work.

## The grounding loop

1. **RUN IT** in the real renderer — headless browser (Playwright) for web, render-to-PNG for SVG, execute-and-capture for scripts, `mmdc` for Mermaid. Drive a game/animation far enough that state actually starts.
2. **OBSERVE THE OUTPUT** — read the screenshot, the console, the actual layout. A produced-but-unobserved screenshot is **not** observation. `exit 0` / a clean static parse proves **well-formed, NOT correct** — different claims.
3. **FIX what the observation reveals, then re-run.**

## Observation needs a success criterion

Observation surfaces what the artifact *does* — it does **not** by itself define what *correct* is. A run that renders and accurately describes the output can still emit PASS on a real defect if it was never told the success criterion. (Measured 2026-06-16: an agent rendered a fixed-height card, precisely observed that the bottom rows were clipped off the canvas, and still passed it — its brief omitted "all N items must be visible," so it rationalized the clip as `overflow:hidden` working as intended.) **Pair every observation with the item's explicit success criterion / DoD** — artifact path + observable evidence + the pass condition. Observation *plus* an explicit criterion catches the defect; observation alone may rationalize it away.

## Stop condition (anti-over-verification)

**One clean observation of the rendered output is enough.** Do NOT re-render the same **unchanged** state to accumulate confidence — it wastes tokens without changing the output. Re-render ONLY after you change something: each defect gets one fix and one re-check, and you stop again once that check is clean. The goal is **"I saw it work," not "I checked it N times."** On re-verification rounds, re-observe **only** the features touched by this round's diff.

## Degrade path (honesty)

If the artifact is observable but cannot be observed (no renderer, app won't boot, Playwright cannot connect): record the blocker as evidence and **never emit PASS / CLEAN** on an unobserved observable artifact — cap the verdict below PASS (`PASS_WITH_WARNINGS` / `RENDER_UNCHECKED` / `UNTESTABLE`) and route to the capability-escalation ladder (`meta-loop-protocol.md §5.1`). An unobservable observable artifact is not a pass; it is a blocker.
