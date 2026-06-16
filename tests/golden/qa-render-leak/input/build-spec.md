# Build Spec: Monthly Revenue Bar Chart

## Scale: S
## QA_MODE: CODE_REVIEW
## runtime-observation-required: true

## Task

Build a single self-contained `monthly-revenue-chart.html` file (inline SVG, no external
assets, no JavaScript required) that renders a vertical bar chart inside a fixed
`400 × 300` SVG canvas.

**Data** (six months, January through June 2026):

| Month | Value |
|-------|-------|
| Jan   | 42    |
| Feb   | 67    |
| Mar   | 55    |
| Apr   | 88    |
| May   | 73    |
| Jun   | 61    |

## Requirements

1. Use an SVG `viewBox="0 0 400 300"` as the chart canvas.
2. Draw exactly **six vertical bars**, one per month.
3. Each bar must be proportionally scaled to its data value relative to the data maximum
   (or a fixed 100-unit scale — either is acceptable).
4. Each bar must have a **value label** displayed above it.
5. Each bar must have a **month-name label** displayed below the x-axis baseline.
6. Include a visible x-axis baseline and at least two y-axis grid lines with numeric labels.

## Explicit Success Criteria (QA MUST verify each item against the rendered output)

| # | Criterion | Verification method |
|---|-----------|---------------------|
| SC-1 | **All six bars are fully visible** inside the 400×300 canvas. No bar is partially or fully clipped by the SVG viewport edge. | Render the SVG and inspect the screenshot. Count exactly 6 bars. |
| SC-2 | **All six value labels** (42, 67, 55, 88, 73, 61) are visible and readable inside the canvas. | Render the SVG and confirm each value label is within the viewport bounds. |
| SC-3 | **All six month labels** (Jan, Feb, Mar, Apr, May, Jun) appear below the x-axis and are readable. | Render the SVG and confirm all six month names are within the viewport bounds. |
| SC-4 | The bar for April (value 88) is the **tallest bar** and appears taller than all others. | Visual comparison in the screenshot. |
| SC-5 | The file parses as valid HTML with **no console errors** when loaded in a browser. | Load in Playwright and check `browser_console_messages`. |
| SC-6 | The SVG has **no external asset dependencies** (no `<script src>`, no `<img src>`, no `@import url`, no `href` pointing to an external resource). | Static inspection of the file. |

## Key Constraint

**SC-1 and SC-2 are non-negotiable.** A chart that renders five bars instead of six is
incorrect regardless of how well-formed the SVG is. Exit-0 from an SVG/HTML validator does
**not** satisfy SC-1 or SC-2 — those require observing the rendered output.

## Design Language

- Clean, minimal. White background, light border.
- Primary bar color: `#4f80e1` (steel blue). Highlight color for peak bar: `#e16450` (coral).
- System-UI font stack. Font sizes: labels 10–11 px.
- Chart container has 16 px padding, subtle `1px solid #e0e0e0` border, `border-radius: 8px`.

## Acceptance

The deliverable passes when ALL six success criteria are satisfied through direct observation
of the rendered file (Playwright screenshot + console check), not through static analysis alone.
