---
name: design
description: Use when Codex needs to create, update, or apply frontend design direction through presets, three visual dials, design-system files, redesign audits, or when the user asks for design work, landing pages, dashboards, workspaces, admin panels, or `--design` style control.
---

# Design

## Overview

Run the Codex version of `/design`. This skill is based on the taste-skill ecosystem, but customized so Codex can use the same frontend design workflow without requiring Claude-only slash command behavior.

## Input Modes

Treat these literal tokens in the user's prompt as workflow hints:

- `$design`
- `$design init`
- `$design --landing`
- `$design --dashboard`
- `$design --workspace`
- `$design --portfolio`
- `$design --admin`
- `$design --soft`
- `$design --minimal`
- `$design --brutal`
- `$design --redesign`
- `$design --v <n> --m <n> --d <n>`
- `$design --output-guard`

If the user asks for frontend design work without the token, this skill still applies.

## Activation Order

Resolve the design mode in this order:

1. Explicit preset or dial values in the current prompt
2. Existing design-system file in the project
3. Default taste baseline: `V8 / M6 / D4`

## Design-System File Detection

Look for the first matching file in this order:

1. `design.md`, `DESIGN.md`
2. `designsystem.md`, `DESIGNSYSTEM.md`, `design-system.md`, `DESIGN-SYSTEM.md`
3. `docs/design.md`, `docs/DESIGN.md`, `docs/design-system.md`
4. `*DESIGN*.md`, `*design_system*.md`

If one exists, treat it as the source of truth for preset and dial values unless the user explicitly overrides them.

## Modes

### 1. `init`

Create or update the project's design-system document.

- If a design-system file already exists, patch the existing file instead of replacing it wholesale.
- If frontend code exists but no design-system file exists, audit the current UI first and then generate the design-system file.
- If neither exists, infer the project type from the repo or the user's request, and create a starter design-system file.

### 2. Preset or dial-driven design

Apply the selected preset or the resolved dial values directly to frontend work.

- `soft` / `landing` -> premium, polished, soft-depth UI
- `minimal` / `workspace` -> editorial minimalism
- `brutal` / `dashboard` -> Swiss + terminal-informed density
- `portfolio` -> softer, luxury-leaning showcase
- `admin` -> taste baseline tuned for operational panels
- custom `V/M/D` -> override the baseline

### 3. `redesign`

Audit the current UI first, then fix the highest-impact design problems before exploring flourishes.

Prioritize in this order:

1. typography
2. color system
3. layout and spacing
4. interaction states
5. loading, empty, and error states
6. component polish

### 4. `--output-guard`

Prevent lazy output:

- no placeholder comments instead of code
- no "rest of component omitted" patterns
- no half-finished sections

## Three-Dial System

| Dial | 1-3 | 4-7 | 8-10 |
|------|-----|-----|------|
| Variance | strict grid, predictable | offset layouts, measured asymmetry | broken grid, strong asymmetry, wider whitespace |
| Motion | hover and active only | staggered reveals, fluid CSS transitions | stronger choreography, scroll-aware motion, premium micro-interactions |
| Density | spacious, gallery-like | normal app density | cockpit-like density, tighter spacing, dashboard bias |

## Preset Mapping

| Preset | Alias | V | M | D | Direction |
|--------|-------|---|---|---|-----------|
| default | — | 8 | 6 | 4 | taste baseline |
| soft | landing | 7 | 8 | 3 | premium SaaS or marketing |
| soft | portfolio | 8 | 7 | 2 | premium showcase |
| minimal | workspace | 4 | 3 | 5 | editorial productivity |
| brutal | dashboard | 6 | 2 | 8 | data-heavy operational UI |
| taste | admin | 2 | 3 | 9 | admin panel / dense controls |

## Non-Negotiable Design Rules

- Do not use Inter, Roboto, Arial, or Open Sans unless the existing project already depends on them and you are preserving an established system.
- Do not use emoji in UI copy, labels, alt text, or icons.
- Do not use `h-screen` for full-height sections. Use `min-h-[100dvh]`.
- Do not animate layout properties like `top`, `left`, `width`, or `height`. Animate `transform` and `opacity`.
- Do not import third-party UI or motion libraries without checking `package.json` first.
- Do not default to generic 3-equal-card marketing rows.
- Do not use default shadcn/ui or generic component-library styling unchanged.
- Always account for loading, empty, error, and active states.
- Collapse high-variance layouts to a safe single-column mobile layout below `768px`.

## Visual Direction Rules

Apply these unless the existing product system clearly requires something else:

- Prefer a single accent color and a neutral base.
- Avoid the default AI purple glow aesthetic.
- Use expressive typography with deliberate scale contrast.
- Prefer CSS Grid over complicated flexbox math.
- Use staggered reveals and tactile feedback when motion is enabled.
- Keep shadows subtle and purposeful.

## `init` Output Shape

When creating or updating a design-system file, structure it like this:

```markdown
# Design System: {project-name}

## Goal
preset: {preset}
variance: {N}
motion: {N}
density: {N}

## Color Palette
## Typography
## Layout Rules
## Component Rules
## Motion Rules
## Responsive Rules
```

If redesign mode is active, add a `## Current Problems` section before `## Goal`.

## Super Integration

When `$super --design` is used, or when `$super` finds a design-system file, `$design` becomes the design controller for every frontend slice.

Pass these into the frontend work:

- selected preset
- resolved dial values
- detected design-system file path
- banned patterns
- required state coverage

## Output Shape

Use this reporting structure:

1. Mode: init, preset, custom dial, or redesign
2. Source: explicit prompt, detected file, or default baseline
3. Preset/Dials: chosen visual direction
4. Design system: file used, created, or updated
5. Key rules: typography, color, layout, motion constraints
6. Next: frontend implementation step or follow-up

## Quick Prompts

- `Use $design init for this project.`
- `Use $design --landing for the marketing site.`
- `Use $design --dashboard for this analytics UI.`
- `Use $design --v 8 --m 7 --d 2 for a luxury landing page.`
- `Use $super --design admin to build the control panel.`
