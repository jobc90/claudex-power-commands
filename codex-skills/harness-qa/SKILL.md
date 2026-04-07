---
name: harness-qa
description: Functional QA harness for `/harness-qa` or `$harness-qa` requests. 5-agent pipeline (Scout → Scenario Writer → Test Executor → Analyst → Reporter) with 8 test modes (full, onboarding, forms, responsive, regression, journey, a11y, pre-launch).
---

# Harness QA (v2)

## Overview

Run the Codex version of `/harness-qa`. Treat `/harness-qa` and `$harness-qa` as the same workflow intent inside Codex.

This skill mirrors the Claude harness-qa structure:

`SETUP -> SCOUT -> SCENARIOS -> USER APPROVAL -> EXECUTE -> ANALYZE -> REPORT`

**v2**: 8 specialized test modes for targeted, expert-level QA.

## Guard Clause

Before starting the protocol, confirm the request is a QA or testing request against a real running application.

Proceed when the user wants to:

- test a running or deployed application
- run QA scenarios against a live environment
- verify features end to end
- find bugs in an existing application
- produce a QA report with actionable fix items
- audit onboarding, forms, responsiveness, accessibility, or user journeys
- run pre-launch QA or visual regression checks

## Required Information

The user must provide:

1. target URL
2. credentials for the relevant user types

Never store raw credentials in harness files. Refer to them as provided in the task description or by environment variable name.

## Input Modes

Treat these literal tokens in the user's prompt as workflow hints:

- `$harness-qa`
- `$harness-qa --mode <mode>`
- `$harness-qa --focus <area>`
- `$harness-qa --user-types <types>`
- `$harness-qa --quick`
- `$harness-qa --viewports <sizes>`
- `$harness-qa --change <description>`
- `/harness-qa`

## Test Modes

| Mode | Purpose | Scout Focus | Key Capability |
|------|---------|-------------|----------------|
| `full` | Comprehensive functional QA (default) | All routes, users, features | Full scenario matrix |
| `onboarding` | Onboarding flow audit | Signup/onboarding steps, first-use flows | Drop-off detection, state screenshots |
| `forms` | Form validation & edge cases | All forms, inputs, validation rules | Boundary values, XSS vectors, error UX |
| `responsive` | Cross-viewport layout testing | Key pages, layout components | Multi-viewport screenshots, overflow detection |
| `regression` | Visual regression after deployment | Changed pages/components | Before/after comparison, unintended side effects |
| `journey` | User journey documentation | Complete user flows from landing to value | Screenshot map, timing, confusion points |
| `a11y` | Accessibility spot check (WCAG) | Interactive elements, forms, color usage | Contrast, focus states, labels, tap targets |
| `pre-launch` | Pre-launch test plan generation | Full feature inventory | Test plan document (no execution) |

Modes can be combined: `--mode forms,a11y`.

## Required Artifacts

Use `.harness_codex/qa-` in the target project directory.

- `.harness_codex/qa-prompt.md`
- `.harness_codex/qa-context.md`
- `.harness_codex/qa-scenarios.md` (or `qa-test-plan.md` for pre-launch mode)
- `.harness_codex/qa-results.md`
- `.harness_codex/qa-analysis.md`
- `.harness_codex/qa-report.md`

## Phase 1. Setup

Create the working directory:

```bash
mkdir -p .harness_codex
```

Write the user's request, target URL, non-secret credential references, selected mode, and options to `.harness_codex/qa-prompt.md`.

Include mode-specific context:
- For `regression`: the `--change` description
- For `responsive`: the viewport sizes
- For `pre-launch`: launch date if provided

## Phase 2. Scout

Load `references/scout-prompt.md`.

Spawn a fresh scout subagent:

- focus based on the selected test mode (see scout prompt for mode-specific focus)
- pass the test mode explicitly
- write `.harness_codex/qa-context.md`
- ALWAYS append QA-specific supplementary instructions to the scout prompt:
  1. Route & Navigation Map (all routes with access requirements)
  2. User Type & Permission Matrix (every role, what they can/cannot do, how type is determined)
  3. Authentication & Session Handling (login mechanism, session storage, expiry behavior)
  4. State Transitions & Side Effects (create/update/delete operations, irreversible actions)
  5. Error & Edge Case Surfaces (error codes, empty states, pagination, validation rules)
- These QA-specific findings go in a `## QA Discovery` section of qa-context.md

After it finishes, briefly report the discovered route count, user types, key features, and mode.

## Phase 3. Scenarios

Load `references/scenario-writer-prompt.md`.

Spawn a fresh scenario-writer subagent:

- codebase context: `.harness_codex/qa-context.md`
- target URL
- credential references
- **test mode** (determines scenario templates)
- focus area and user types
- quick mode if specified
- viewports if responsive mode
- change description if regression mode
- output: `.harness_codex/qa-scenarios.md`

### Special: `pre-launch` mode

For pre-launch mode, the scenario writer produces `.harness_codex/qa-test-plan.md` instead. **Pipeline stops here** — present the test plan to the user. No Phase 4/5.

After it finishes, summarize:

- scenario count
- coverage matrix (mode-specific)
- CRITICAL/HIGH/MEDIUM breakdown
- any credential gaps

Then ask exactly:

`테스트 시나리오를 검토해주세요. 진행할까요, 추가/수정할 시나리오가 있나요?`

Stop and wait for approval.

## Phase 4. Execute-Analyze Loop

**Skip entirely for `pre-launch` mode.**

Load:

- `references/test-executor-prompt.md`
- `references/analyst-prompt.md`
- `references/qa-reporter-prompt.md`

Run one round by default. A second round is only for re-test after fixes.

### 4a. Execute

Spawn a fresh test-executor subagent:

- test scenarios: `.harness_codex/qa-scenarios.md`
- target URL
- credential references
- **test mode** (determines execution protocol)
- output: `.harness_codex/qa-results.md`
- round 2: focus on previously failing scenarios
- require Playwright MCP browser tools for UI testing

### 4b. Analyze

Spawn a fresh analyst subagent:

- test results: `.harness_codex/qa-results.md`
- test scenarios: `.harness_codex/qa-scenarios.md`
- codebase context: `.harness_codex/qa-context.md`
- **test mode** (determines analysis patterns)
- output: `.harness_codex/qa-analysis.md`

### 4c. Evaluate

After the Analyst finishes:

1. Read `.harness_codex/qa-analysis.md`.
2. Report:
   - overall pass rate
   - critical bug count
   - bug patterns
   - missing feature count
   - mode-specific metrics
3. Decide:
   - if the user wants to fix and re-test, run round 2
   - otherwise proceed to Report

## Phase 5. Report

Load `references/qa-reporter-prompt.md`.

Spawn a fresh reporter subagent:

- analysis: `.harness_codex/qa-analysis.md`
- test results: `.harness_codex/qa-results.md`
- scenarios: `.harness_codex/qa-scenarios.md`
- codebase context: `.harness_codex/qa-context.md`
- **test mode** (determines report format additions)
- output: `.harness_codex/qa-report.md`

After it finishes, present the user-facing summary and point to the full report.

## Execution Rules

1. Each phase agent must be a separate `spawn_agent` call with fresh context.
2. Never pass state between agents in chat. Use `.harness_codex/qa-` files only.
3. Test Executor must use Playwright MCP tools for UI testing.
4. Never store raw credentials in `.harness_codex/qa-` files.
5. Always wait for explicit user approval after the scenario phase.
6. The Test Executor does not fix bugs.
7. The Analyst does not re-test.
8. Mode is passed to EVERY agent — each adapts its behavior accordingly.
9. `pre-launch` mode stops at Phase 3.
10. `responsive` mode requires `browser_resize` at every viewport.
11. `regression` mode requires `--change` description.
