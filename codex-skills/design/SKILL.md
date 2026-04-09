---
name: design
description: 3-dial system (Variance/Motion/Density) + presets (landing/dashboard/workspace) + reference URL analysis for frontend design quality control. init creates/updates design system, --ref analyzes reference sites via Playwright, auto-integrates with $harness.
---

# Design

## Overview

Run the Codex version of `/design`. This skill is based on the taste-skill ecosystem, but customized so Codex can use the same frontend design workflow without requiring Claude-only slash command behavior. It is the shared design controller for `$harness` when a design-system file exists or the user explicitly requests design direction.

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
- `$design --ref <url>`
- `$design --ref <url> --compare`
- `$design --output-guard`

If the user asks for frontend design work without the token, this skill still applies.

## Activation Order

Resolve the design mode in this order:

1. `--ref <url>` → Reference URL Analysis mode (Section 5)
2. Explicit preset or dial values in the current prompt
3. Existing design-system file in the project
4. Default taste baseline: `V8 / M6 / D4`

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

## 5. Reference URL Analysis Mode

When `--ref <url>` is specified, analyze the reference site to extract design tokens and recommend dial values.

**Requires**: `@playwright/mcp` (Playwright MCP tools must be available)

### Execution Flow

```
$design --ref <url> [task description]
  |
  +- Step 1: Navigate & Screenshot
  +- Step 2: Extract Design Tokens (colors, fonts, spacing, layout)
  +- Step 3: Analyze & Classify into 3-Dial System
  +- Step 4: Generate design.md with extracted tokens
  +- Step 5: Present to user for confirmation
```

### Step 1: Navigate & Screenshot

```
1. mcp__playwright__browser_navigate → url
2. mcp__playwright__browser_take_screenshot → full-page screenshot (show to user)
3. mcp__playwright__browser_snapshot → accessibility tree (layout structure)
```

### Step 2: Extract Design Tokens

Use `mcp__playwright__browser_evaluate` to run extraction scripts:

#### 2a. Color Extraction
```javascript
(() => {
  const colors = new Set();
  const elements = document.querySelectorAll('*');
  elements.forEach(el => {
    const style = getComputedStyle(el);
    ['color', 'backgroundColor', 'borderColor', 'boxShadow'].forEach(prop => {
      const val = style[prop];
      if (val && val !== 'rgba(0, 0, 0, 0)' && val !== 'transparent') {
        colors.add(val);
      }
    });
  });
  const colorCounts = {};
  elements.forEach(el => {
    const bg = getComputedStyle(el).backgroundColor;
    if (bg && bg !== 'rgba(0, 0, 0, 0)') colorCounts[bg] = (colorCounts[bg] || 0) + 1;
  });
  return { unique: [...colors].slice(0, 30), frequency: Object.entries(colorCounts).sort((a,b) => b[1]-a[1]).slice(0, 10) };
})()
```

#### 2b. Typography Extraction
```javascript
(() => {
  const fonts = new Set();
  const sizes = new Set();
  const weights = new Set();
  document.querySelectorAll('*').forEach(el => {
    const style = getComputedStyle(el);
    if (el.textContent.trim()) {
      fonts.add(style.fontFamily.split(',')[0].trim().replace(/['"]/g, ''));
      sizes.add(style.fontSize);
      weights.add(style.fontWeight);
    }
  });
  return { fonts: [...fonts], sizes: [...sizes].sort(), weights: [...weights] };
})()
```

#### 2c. Spacing & Layout Extraction
```javascript
(() => {
  const paddings = [];
  const gaps = [];
  const borderRadii = new Set();
  const shadows = new Set();
  const containers = document.querySelectorAll('main, section, article, div[class]');
  containers.forEach(el => {
    const s = getComputedStyle(el);
    paddings.push(s.padding);
    if (s.gap && s.gap !== 'normal') gaps.push(s.gap);
    if (s.borderRadius && s.borderRadius !== '0px') borderRadii.add(s.borderRadius);
    if (s.boxShadow && s.boxShadow !== 'none') shadows.add(s.boxShadow);
  });
  const gridElements = document.querySelectorAll('[style*="grid"], [class*="grid"]').length;
  const flexElements = document.querySelectorAll('[style*="flex"], [class*="flex"]').length;
  return {
    avgPadding: paddings.slice(0, 50),
    gaps: [...new Set(gaps)],
    borderRadii: [...borderRadii],
    shadows: [...shadows].slice(0, 5),
    layoutType: gridElements > flexElements ? 'grid-dominant' : 'flex-dominant',
    gridCount: gridElements, flexCount: flexElements
  };
})()
```

#### 2d. Motion Detection
```javascript
(() => {
  const transitions = new Set();
  const animations = new Set();
  document.querySelectorAll('*').forEach(el => {
    const s = getComputedStyle(el);
    if (s.transition && s.transition !== 'all 0s ease 0s') transitions.add(s.transition);
    if (s.animation && s.animation !== 'none 0s ease 0s 1 normal none running') animations.add(s.animationName);
  });
  const hasFramerMotion = !!document.querySelector('[data-framer-appear-id], [style*="willChange"]');
  const hasScrollAnimations = !!document.querySelector('[data-scroll], .aos-animate, [class*="animate-"]');
  return {
    transitions: [...transitions].slice(0, 10),
    animations: [...animations],
    hasFramerMotion, hasScrollAnimations,
    motionLevel: animations.length > 3 ? 'heavy' : transitions.size > 5 ? 'moderate' : 'minimal'
  };
})()
```

### Step 3: Analyze & Classify

Based on extracted tokens, calculate recommended dial values:

#### Variance (Layout Experimentalism)
| Signal | Score |
|--------|-------|
| Symmetric grid-only layout | 1-3 |
| Mix of grid + offset layouts, varied column widths | 4-6 |
| Asymmetric, masonry, broken-grid, wide margins | 7-10 |

#### Motion (Animation Intensity)
| Signal | Score |
|--------|-------|
| No transitions or animations detected | 1-2 |
| CSS transitions on hover/focus only | 3-5 |
| Scroll-triggered animations, cascade delays | 6-8 |
| Framer Motion / GSAP, parallax, persistent animation | 9-10 |

#### Density (Screen Fill)
| Signal | Score |
|--------|-------|
| Large padding (>48px sections), wide margins, few elements per screen | 1-3 |
| Standard web spacing, moderate content per screen | 4-6 |
| Tight padding (<16px), dividers, many data points per screen | 7-10 |

### Step 4: Generate design.md

Write the design.md file using extracted tokens:

```markdown
# Design System: {Project Name}

## Reference
- Source: {url}
- Screenshot: (attached above)
- Analyzed: {date}

## Goals (Auto-detected from {url})
preset: {closest matching preset}
variance: {detected V}
motion: {detected M}
density: {detected D}

## Color Palette (Extracted)
- Canvas: {most frequent background color → hex}
- Surface: {secondary background → hex}
- Text: {primary text color → hex}
- Accent: {most prominent non-neutral color → hex}
- Base: {Zinc or Slate based on color temperature}

## Typography (Extracted)
- Display: {primary heading font}, {largest size}
- Body: {body text font}, {body size}
- Mono: {monospace font if detected, else recommend Geist Mono}
- Scale: {detected sizes list}

## Component Patterns (Observed)
- Cards: {border-radius, shadow, padding patterns}
- Buttons: {style, hover effect}
- Navigation: {type — sticky/fixed, layout}
- Spacing: {primary gap/padding values}

## Motion (Detected)
- Transition: {primary transition pattern}
- Animations: {detected animation types}
- Scroll behavior: {scroll-triggered? parallax?}

## Responsive
- Breakpoints: {detected if available}
- Mobile pattern: {observed mobile behavior if tested}
```

### Step 5: Present to User

Show:
1. The screenshot (already displayed in Step 1)
2. Extracted dial values with justification
3. The generated design.md content
4. Ask: **"추출된 디자인 시스템을 검토해주세요. 저장할까요?"**

### --compare Mode

When `--ref <url> --compare` is used with an existing design.md:

1. Extract tokens from reference URL (Steps 1-3)
2. Read existing design.md
3. Generate comparison table:

```markdown
## Design Comparison: Current vs Reference

| Aspect | Current | Reference ({url}) | Gap |
|--------|---------|-------------------|-----|
| Variance | V{current} | V{ref} | {diff} |
| Motion | M{current} | M{ref} | {diff} |
| Density | D{current} | D{ref} | {diff} |
| Primary Font | {current} | {ref} | {match/mismatch} |
| Accent Color | {current} | {ref} | {similarity %} |
| Spacing Scale | {current} | {ref} | {match/mismatch} |
```

4. Ask: **"참고 사이트 방향으로 디자인을 조정할까요? (현재 design.md를 업데이트합니다)"**

## Harness Integration

When `$harness` is used and the request is UI-heavy or a design-system file is present, `$design` becomes the design controller for every frontend slice.

Pass these into the frontend work:

- selected preset
- resolved dial values
- detected design-system file path
- banned patterns
- required state coverage

## Output Shape

Use this reporting structure:

1. Mode: init, preset, custom dial, redesign, or ref analysis
2. Source: explicit prompt, detected file, reference URL, or default baseline
3. Preset/Dials: chosen visual direction
4. Design system: file used, created, or updated
5. Key rules: typography, color, layout, motion constraints
6. Next: frontend implementation step or follow-up

## Quick Prompts

- `Use $design init for this project.`
- `Use $design --landing for the marketing site.`
- `Use $design --dashboard for this analytics UI.`
- `Use $design --v 8 --m 7 --d 2 for a luxury landing page.`
- `Use $design --ref https://linear.app SaaS dashboard inspired by Linear.`
- `Use $design --ref https://stripe.com --compare Compare my design vs Stripe.`
- `Use $harness to build the app and apply the detected design system.`
