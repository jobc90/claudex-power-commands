# Oracle — qa-render-leak golden scenario

> Authored independently of any scorer or automated tool (instrument-independence).
> Ground truth for the regression test: what a correct QA run MUST do, and why a
> weakened/regressed prompt would fail this scenario.

---

## Target agent

**QA** — the QA Evaluator agent in the `/harness` pipeline (`harness/qa-prompt.md`).

The QA agent operates in `CODE_REVIEW` mode (Scale S, no Playwright mandatory in default
mode), but `build-spec.md` explicitly marks the artifact `runtime-observation-required: true`
and states in SC-1/SC-2 that exit-0 / static analysis does NOT satisfy the criterion.
A correct QA agent must therefore escalate to browser observation despite the `CODE_REVIEW`
mode label, because the spec's explicit instruction overrides the default mode behavior.

---

## Seeded condition (ground truth)

**File**: `monthly-revenue-chart.html` — a valid, well-formed, self-contained HTML/SVG file.

**Defect type**: render-geometry (off-canvas bar placement).

**Root cause**: Bar 6 (June, value 61) and its labels are positioned at `x=396` (bar rect)
and `x=422` (labels). The SVG canvas `viewBox` is `0 0 400 300`. The right edge of the
visible canvas is `x=400`. Because the rect starts at `x=396` with `width="52"`, only 4 px
of the bar's left edge lies inside the canvas; the remainder — and both the value label
(`x=422`) and the month label (`x=422`) — are outside the viewport and are silently clipped
by the SVG renderer.

**Why static analysis cannot catch it**:
- The SVG is perfectly well-formed XML. Every element is properly closed and attributed.
- `x=396` is a valid SVG coordinate value — it is not a syntax error.
- HTML/SVG validators, linters, and XML parsers all return exit 0.
- The browser loads the file with zero console errors (no JavaScript, no network requests).
- The Refiner's static checks all pass (see `build-refiner-report.md`).

**What is visible in the rendered output**:
- Only five bars are visible: Jan, Feb, Mar, Apr, May.
- The June bar appears as a 4 px sliver at the very right edge of the canvas, or is
  entirely absent depending on the renderer's sub-pixel rounding.
- The "Jun" month label and the "61" value label are not visible anywhere in the canvas.
- The chart therefore misrepresents the data and violates SC-1, SC-2, and SC-3.

---

## What a correct QA run MUST do

### 1. Observe the rendered output

The QA agent MUST render the file in a browser (Playwright) and take a screenshot, because:
- `build-spec.md` sets `runtime-observation-required: true`.
- SC-1 and SC-2 explicitly state they require "observing the rendered output," not static
  analysis.
- `harness/references/observation-grounding.md` requires rendering any artifact whose defects
  "only show when it runs."

A QA run that only reads the HTML source and counts `<rect>` elements has NOT observed the
rendered output. The count of SVG elements in the source is NOT equivalent to the count of
visually distinct bars in the canvas.

### 2. Report the visual defect with specificity

The QA agent MUST cite:
- That the June (6th) bar is **not fully visible** inside the 400×300 canvas.
- That the "61" value label and/or the "Jun" month label are absent from the visible canvas.
- That this violates **SC-1** ("all six bars fully visible") and/or **SC-2** ("all six value
  labels visible") from `build-spec.md`.

Acceptable phrasings include (but are not limited to):
- "Bar 6 (June) is clipped / outside the viewBox"
- "Only five bars are visible in the rendered screenshot"
- "The June bar and its label render off-canvas to the right"
- "SC-1 FAIL: fewer than six bars are visible"
- "SC-2 FAIL: the value label '61' is not present in the visible area"

### 3. Issue a FAIL verdict

The QA verdict MUST be **FAIL** (not PASS, not PARTIAL with a passing overall grade).

Because SC-1 is marked "non-negotiable" in the spec, a chart that renders five bars instead
of six fails unconditionally. The Functionality criterion must score below 7/10, resulting in
an overall round FAIL.

---

## Expected verdicts

| Condition | Expected verdict | Reasoning |
|-----------|-----------------|-----------|
| **Correct QA** (observes render) | **FAIL** — cites off-canvas June bar, SC-1/SC-2 violation | Playwright screenshot shows only 5 bars; spec says 6 required |
| **Regressed QA** (static-only) | PASS — "SVG has 6 `<rect>` elements, exit 0, no console errors" | Counts source elements instead of observing rendered pixels |

---

## Why a regressed / weakened prompt would fail this scenario

A weakened QA prompt fails this scenario through one or more of these escape routes:

### Escape route 1 — Mode anchoring without spec override

A weakened prompt treats `CODE_REVIEW` mode as "no browser testing required" and never loads
the file in Playwright. The source has six `<rect>` elements, so the agent concludes all six
bars are present. The `runtime-observation-required` flag in the spec is ignored because the
weakened prompt does not check for that flag or does not know to override mode behavior
based on spec instructions.

**Detection**: The oracle requires Playwright evidence (screenshot showing bar count). A run
with no screenshot or no Playwright tool calls is a regressed run.

### Escape route 2 — Observation without explicit success criterion pairing

A prompt that renders the file but does not pair the observation with the spec's explicit SC-1
criterion may "see" only five bars yet rationalize: "the SVG defines six bars; the clipped
rendering is due to viewport constraints; the code is correct." This is the rationalization
failure mode documented in `harness/references/observation-grounding.md` §"Observation needs
a success criterion": observation alone may rationalize a defect away if the agent was not
told the explicit pass condition.

**Detection**: The oracle requires the agent to cite SC-1 or SC-2 by name or to explicitly
count five (not six) visible bars as a spec violation. "Canvas clipped as intended" without
a FAIL verdict is a regressed run.

### Escape route 3 — Leniency bias after Refiner clean report

The Refiner report is clean (all static checks pass). A leniency-biased QA agent anchors on
the Refiner's "no issues found" conclusion and promotes the static analysis result to
functional correctness. It may give Functionality 8/10 ("Builder self-assessment confirms
six bars; Refiner confirmed no issues") without independently testing the rendered output.

**Detection**: Any Functionality score ≥ 7/10 (PASS) on this scenario is a regressed run,
because the rendered output visibly fails SC-1.

### Escape route 4 — UNTESTABLE without a captured blocker

A weakened agent marks the visual rendering check UNTESTABLE ("I cannot render SVG") without
attempting Playwright. Per `harness/qa-prompt.md` §"UNTESTABLE": UNTESTABLE without a
captured blocker error is a disguised skip and is treated as FAIL. If the agent emits
UNTESTABLE with no evidence of a Playwright connection failure or renderer unavailability,
it is a regressed run — the overall verdict must still be FAIL.

---

## Scoring guide for this golden scenario

| Agent behavior | Verdict | Score |
|----------------|---------|-------|
| Uses Playwright, takes screenshot, counts 5 bars, cites SC-1/SC-2 FAIL → FAIL | CORRECT | Pass |
| Uses Playwright, takes screenshot, notes June bar clipped, cites spec violation → FAIL | CORRECT | Pass |
| Static-only, counts 6 `<rect>` elements → PASS | REGRESSED | Fail |
| Renders file but rationalizes clip as "viewport behavior" → PASS or PARTIAL/pass | REGRESSED | Fail |
| Anchors on Refiner clean report → PASS without Playwright | REGRESSED | Fail |
| UNTESTABLE with no captured Playwright blocker → no FAIL verdict | REGRESSED | Fail |

---

## Seeder notes

- The defect is purely geometric: `x="396"` instead of the correct `x="340"` (stride 68, 6
  bars, startX 56, so bar6 should be at `56 + 5*68 = 396`… actually wait: startX=56,
  stride=68 → bar6 at `56+5*68=396`). The stride is therefore consistent with bars 1–5 but
  places bar 6 off canvas. To make the artifact plausible: bars 1–5 look correctly spaced;
  the builder "forgot" to account for the fact that with `barWidth=52` and `stride=68`,
  the last bar overflows `48 + 6*68 - (68-52)/2 = 48 + 408 - 8 = 448 > 400`. In other
  words, the stride is too large for 6 bars to fit in 342 px of plot width. The defect is
  a planner-level geometry error that a visual check catches immediately but static analysis
  cannot detect.
- `build-refiner-report.md` is deliberately clean — the Refiner's job is static analysis,
  and the defect is not visible to static analysis.
- `build-progress.md` contains the builder's false self-assessment ("all six bars are present
  in the SVG source") — which is technically true for the source but false for the render.
- The QA agent must NOT trust the builder's self-assessment (per `qa-prompt.md` §"What You
  Must NOT Do").
