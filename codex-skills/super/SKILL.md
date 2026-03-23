---
name: super
description: Use when the user wants an idea, feature request, or large change carried from discovery through planning, implementation, review, verification, git handoff, and light documentation in one Codex-guided workflow.
---

# Super

## Overview

Run the Codex version of `/super`. This is the end-to-end orchestrator that routes a request through discovery, planning, build, review, shipping, and documentation while preserving Codex's stricter git and verification rules.

## Input Modes

Treat these literal tokens in the user's prompt as workflow hints:

- `$super`
- `$super --skip-discover`
- `$super --design`
- `$super --design <landing|dashboard|workspace|portfolio|admin|soft|minimal|brutal|redesign>`
- `$super --commit`
- `$super --push`
- `$super --pr`

If the user gives a raw feature request that clearly means "take this from idea to done", this skill still applies even without the literal token.

## Pipeline

`DISCOVER -> PLAN -> BUILD -> CHECK -> SHIP -> DOCUMENT`

## Design Mode

Design mode activates when either of these is true:

- the user explicitly passes `--design` or a design preset
- a design-system file is detected in the project

Valid preset names are:

- `landing`
- `dashboard`
- `workspace`
- `portfolio`
- `admin`
- `soft`
- `minimal`
- `brutal`
- `redesign`

If the user passes bare `--design` without a preset, turn design mode on and resolve the preset from the detected design-system file or the current product type before BUILD.

Use this precedence:

1. explicit `--design <preset>` or custom design request
2. detected design-system file
3. no design mode

## Stage Rules

### 1. DISCOVER

Clarify the goal, scope, constraints, and success criteria.

Use this routing table to decide the initial documentation or PM artifact:

| Condition | Skill route | Output |
|----------|-------------|--------|
| New feature, likely 3+ files | `create-prd` | PRD-style scope document |
| Existing feature improvement, likely 1-2 files | `user-stories` | concise story and acceptance criteria |
| High-risk change | `pre-mortem` | risk framing before planning |
| Strategic or product-direction decision | `product-strategy` | strategy framing |
| Competitor or market framing needed | `competitor-analysis` | comparison and differentiation notes |
| Monetization or packaging question | `pricing-strategy` | pricing tradeoffs and implications |

Gate:

- If requirements are still too ambiguous to verify later, do not leave DISCOVER yet.
- If `--skip-discover` is present and requirements already exist, start from PLAN.
- If design mode is active, resolve the preset, dial values, or detected design-system file before leaving DISCOVER.

### 2. PLAN

Produce a concrete execution plan before touching code:

- files likely to change
- verification strategy
- risk areas
- whether the work is sequential or parallelizable

For larger implementation work, break the plan into waves:

- Wave 1: shared contracts, types, utilities
- Wave 2: independent implementation slices
- Wave 3: integration and cleanup

Gate:

- If the work cannot be decomposed safely, plan for local sequential execution instead of forced delegation.
- If design mode is active, attach the resolved design direction to every frontend slice in the plan.

### 3. BUILD

Choose the implementation mode that fits the task:

- small or tightly coupled work -> implement locally
- larger work with clean ownership boundaries and explicit delegation permission -> use the `$cowork` workflow
- frontend or UI-heavy work with design mode -> route through `$design` first, then build under those rules

Gate:

- Do not dispatch subagents unless the user explicitly asked for delegation or parallel execution, or explicitly invoked `$cowork`.
- Do not move to CHECK until the requested behavior is implemented and locally integrated.
- Do not let frontend slices ignore the selected design preset or detected design-system file.

### 4. CHECK

Run the `$check` workflow on the resulting diff:

- review
- safe fixes
- verification
- remaining recommendations

Gate:

- Do not move to SHIP until verification evidence exists.
- If verification fails 3 times, stop and report instead of pushing forward.

### 5. SHIP

Git actions are opt-in, not automatic:

- `--commit`: commit after verification
- `--push`: commit if needed, then push
- `--pr`: commit, push, and create a PR if possible

Without an explicit shipping flag or explicit user instruction, stop at a verified ready-to-ship state and report the next safe git step.

### 6. DOCUMENT

Update only the docs directly affected by the change:

- release-note style summary if requested
- plan or design notes created during the task
- small developer-facing docs that would otherwise become stale

If the user wants a fuller doc pass, route into `$docs`.

## Codex-Native Routing

Inside this workflow, prefer real installed skills and workflows:

- Discovery and PM framing -> `create-prd`, `user-stories`, `pre-mortem`, `product-strategy`, `competitor-analysis`, `pricing-strategy`
- Design direction and design-system control -> `$design`
- Parallel build -> `$cowork`
- Review and verification -> `$check`
- Full documentation pass -> `$docs`

## Output Shape

Use this structure when reporting:

1. Discover: selected route and requirements state
2. Design: preset, dial values, or detected design-system file
3. Plan: execution shape and risks
4. Build: local or delegated implementation path
5. Check: review and verification outcome
6. Ship: git action taken, or next safe step
7. Document: docs updated or deferred

## Red Flags

- Starting implementation before the request is clear enough to verify
- Carrying out irreversible git actions without explicit instruction
- Letting "end-to-end" become an excuse for broad unrelated refactors
- Claiming the full pipeline is done without fresh evidence from real verification commands

## Quick Prompts

- `Use $super to add 2FA to login.`
- `Use $super --skip-discover because the PRD already exists.`
- `Use $super --pr for this feature from plan through ready-to-review branch.`
- `Use $super --design landing for the new marketing site.`
