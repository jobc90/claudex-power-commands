---
description: "5-agent functional QA pipeline (Scout → Scenario Writer → Test Executor → Analyst → Reporter) with Playwright-based verification. Supports 8 test modes: full, onboarding, forms, responsive, regression, journey, a11y, pre-launch."
---

# Harness-QA: Functional QA Pipeline (v2)

> 5-agent harness for comprehensive functional testing against live/deployed environments.
> Scout → Scenario Writer → Test Executor → Analyst → Reporter with Playwright-based verification.
> **v2**: 8 specialized test modes for targeted, expert-level QA.

## User Request

$ARGUMENTS

## Phase 0: Guard Clause

If the request is NOT a QA/testing request:
- Respond directly as a normal conversation
- Do NOT execute any harness phases

Proceed when the user wants to:
- Test a deployed/running application
- Run QA scenarios against a live environment
- Verify features work end-to-end
- Find bugs in an existing application
- Generate a QA report with actionable fix items
- Audit onboarding, forms, responsiveness, accessibility, or user journeys
- Run pre-launch QA or visual regression checks

### Required Information

The user MUST provide (ask if missing):
1. **Target URL**: The application URL to test against
2. **Credentials**: Login accounts for each user type (or test account info)

Optional but helpful:
- Database connection info (for data verification)
- Specific areas to focus on
- Known issues to skip
- CSS/code changes made (for `--mode regression`)

## Architecture Overview

```
/harness-qa <target-url> [options]
  |
  +- Phase 0: Guard + Mode Selection
  +- Phase 1: Setup             -> .harness/qa- directory + mode config
  +- Phase 2: Scout              -> Scout agent -> .harness/qa-context.md
  +- Phase 3: Scenarios           -> Scenario Writer -> .harness/qa-scenarios.md
  |                               -> User reviews and approves
  +- Phase 4: Execute-Analyze     -> Up to 2 rounds:
  |   +- Test Executor            -> Playwright testing -> .harness/qa-results.md
  |   +- Analyst                  -> Bug classification -> .harness/qa-analysis.md
  |   +- Score check              -> pass rate acceptable? done : next round
  +- Phase 5: Report              -> Reporter -> .harness/qa-report.md
```

## Arguments

- First argument: target URL or task description (required)
- `--mode <mode>`: test mode (default: `full`) — see Test Modes below
- `--focus <area>`: focus testing on specific module/feature
- `--user-types <types>`: limit to specific user types (comma-separated)
- `--quick`: CRITICAL scenarios only (skip HIGH/MEDIUM)
- `--viewports <sizes>`: custom viewport sizes for responsive mode (default: `375,768,1280,1920`)
- `--change <description>`: describe what changed (for regression mode)

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

### Mode Combinations

Modes can be combined: `--mode forms,a11y` runs both form testing and accessibility checks.
`--mode full` includes all modes by default but with less depth per mode.

---

## Phase 1: Setup

Read the session protocol reference: `~/.claude/harness/references/session-protocol.md`

### 1a. Session Recovery Check

If `.harness/session-state.md` exists and `pipeline: harness-qa`:
- Present to user: **"이전 QA 세션이 감지되었습니다. {last_completed_agent} 완료 후 중단. 이어서 진행할까요?"**
- If **resume**: skip to the phase AFTER `last_completed_agent`
- If **restart**: `mv .harness/ .harness-backup-$(date +%s)/`

### 1b. Fresh Setup

```bash
mkdir -p .harness
```

Write the user's request, target URL, credentials, options, and **selected mode** to `.harness/qa-prompt.md`.
Initialize session state and event log:
```bash
cat > .harness/session-state.md << 'HEREDOC'
# Session State
- pipeline: harness-qa
- scale: —
- phase: 1
- round: 1
- last_completed_agent: setup
- last_completed_at: {ISO8601}
- status: IN_PROGRESS
HEREDOC
echo "# Session Events" > .harness/session-events.md
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] setup | done | qa-prompt.md | QA pipeline, mode: {mode}" >> .harness/session-events.md
```

Include in the prompt file:
- Selected mode(s) and their implications
- For `regression` mode: the `--change` description
- For `responsive` mode: the viewport sizes to test
- For `pre-launch` mode: launch date if provided

**CRITICAL**: Never write raw credentials (passwords, tokens) to files. Reference them as "provided in task description" or use environment variable names.

---

## Phase 2: Scout

Read the scout prompt template: `~/.claude/harness/scout-prompt.md`

Launch a **general-purpose Agent** with subagent_type `Explore` and **model `sonnet`**:
- **prompt**: The scout prompt template + context:
  - "Project directory: `{cwd}`"
  - "User's request: `{$ARGUMENTS}`"
  - "Scale: L — comprehensive scan for QA purposes."
  - "**Test mode**: `{selected mode}`"
  - "Write output to `.harness/qa-context.md`"
  - Mode-specific focus instructions (see below)
  - QA-specific supplementary instructions (see below)
- **description**: "harness-qa scout"
- **model**: `sonnet`

### QA-Specific Supplementary Instructions (ALWAYS append to Scout prompt)

The standard scout prompt is designed for development context. For QA, the Scout needs additional focus areas that the Scenario Writer depends on. ALWAYS append these instructions:

```
## QA-Specific Discovery Requirements

In addition to the standard scouting protocol, you MUST discover and document these QA-critical items:

### 1. Route & Navigation Map
- List ALL navigable routes with their access requirements (public, authenticated, role-specific)
- Identify route guards/middleware that control access
- Note any redirect chains (e.g., unauthenticated → login → original page)

### 2. User Type & Permission Matrix
- Enumerate EVERY user type/role the system supports (admin, staff, customer, anonymous, etc.)
- For each type, list what they CAN and CANNOT do (verified from guards/middleware/conditions in code)
- Note how user type is determined (JWT claim, database field, session attribute)
- Flag any role-based UI differences (e.g., admin sees "Delete" button, user doesn't)

### 3. Authentication & Session Handling
- Login mechanism (email/password, OAuth, SSO, Keycloak, etc.)
- Session storage (cookie, localStorage, JWT)
- Session expiry behavior (redirect to login? silent refresh?)
- Multi-tab/multi-device behavior if discoverable

### 4. State Transitions & Side Effects
- List operations that change server state (create, update, delete)
- Note operations with side effects (email sent, webhook fired, cache invalidated)
- Identify irreversible operations (hard delete, payment charge)

### 5. Error & Edge Case Surfaces
- Known error codes/messages the app returns
- Empty state handling (what happens when there's no data?)
- Pagination behavior (does it exist? infinite scroll? page-based?)
- File upload limits, input validation rules

Write these findings in a dedicated section of qa-context.md:
## QA Discovery
[structured findings per section above]
```

### Mode-Specific Scout Focus

| Mode | Scout Must Discover |
|------|-------------------|
| `full` | All routes, user types, API endpoints, DB schema, auth system, forms, CRUD ops, state transitions |
| `onboarding` | Signup flow steps, onboarding sequence, first-use gates, welcome screens, tutorial triggers, activation metrics |
| `forms` | ALL form elements (inputs, selects, textareas, checkboxes), validation rules in code, error message patterns, required fields, field constraints (maxLength, pattern) |
| `responsive` | Key pages list, CSS breakpoints in use, layout components (grid, flex, sidebar, nav), media queries, mobile-specific components |
| `regression` | Changed files (from `--change` or recent git diff), affected routes/components, CSS dependencies, shared style files |
| `journey` | Landing page, signup, onboarding, dashboard, core feature pages — full user flow from first visit to value moment |
| `a11y` | Interactive elements, form labels, color palette/theme, icon-only buttons, focus management patterns, aria attributes in code |
| `pre-launch` | Complete feature inventory, all modules, all user types, all integrations, env dependencies, known risk areas |

After Scout completes:
- Briefly confirm: **"Scout 완료. [X]개 라우트, [Y]개 유저 타입, [Z]개 핵심 기능 감지. 모드: {mode}."**
- Update event log: `echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] scout | done | qa-context.md | {X} routes, {Y} user types" >> .harness/session-events.md`

---

## Phase 3: Scenarios

Read the scenario writer prompt template: `~/.claude/harness/scenario-writer-prompt.md`

Launch a **general-purpose Agent** with **model `sonnet`**:
- **prompt**: The scenario writer prompt template + context:
  - "Codebase context: `.harness/qa-context.md`"
  - "Target URL: `{URL}`"
  - "Test credentials: `{provided credentials — pass securely}`"
  - "**Test mode**: `{selected mode}`"
  - "Focus area: `{--focus value if provided, otherwise 'all features'}`"
  - "User types: `{--user-types value if provided, otherwise 'all types from context'}`"
  - "Quick mode: `{--quick if specified}`"
  - "Viewports: `{--viewports value if responsive mode}`"
  - "Change description: `{--change value if regression mode}`"
  - "Write output to `.harness/qa-scenarios.md`"
- **description**: "harness-qa scenario writer ({mode})"

### Special Mode Behavior — `pre-launch`

For `pre-launch` mode, the Scenario Writer produces a **Test Plan document** instead of executable scenarios:
- Core user flows with acceptance criteria
- Test cases per module
- Edge case and negative test inventory
- Device/browser test matrix
- Risk areas requiring extra attention
- Time estimate per test case
- **Output**: `.harness/qa-test-plan.md`
- **Pipeline stops here** — no Phase 4/5. Present the test plan to the user.

After completion:
- Read `.harness/qa-scenarios.md` (or `qa-test-plan.md` for pre-launch)
- Present summary to user:
  - Total scenarios count
  - Coverage matrix (feature × user type, or mode-specific matrix)
  - CRITICAL/HIGH/MEDIUM breakdown
  - Any CREDENTIALS NEEDED flags
  - For `responsive`: viewport × page matrix
  - For `a11y`: WCAG criterion coverage
- Ask: **"테스트 시나리오를 검토해주세요. 진행할까요, 추가/수정할 시나리오가 있나요?"**
- **WAIT for user approval.**

---

## Phase 4: Execute-Analyze Loop

Read the test executor and analyst prompt templates from `~/.claude/harness/`.

**Skip this phase entirely for `pre-launch` mode** (pipeline ends at Phase 3).

### Max rounds: 2

Round 2 is only triggered if the user requests re-testing after fixes are applied.

#### 4a. Execute

Launch a **general-purpose Agent** with **model `sonnet`**:
- **prompt**: The test executor prompt template + context:
  - "Test scenarios: `.harness/qa-scenarios.md`"
  - "Target URL: `{URL}`"
  - "Test credentials: `{provided credentials}`"
  - "**Test mode**: `{selected mode}`"
  - "Write output to `.harness/qa-results.md`"
  - If round 2: "This is a re-test after fixes. Focus on previously FAIL/PARTIAL scenarios. Reference `.harness/qa-analysis.md` for what was fixed."
  - "You MUST use Playwright MCP tools (mcp__playwright__*) to test the live app."
  - Mode-specific executor instructions (see below)
- **description**: "harness-qa test executor round {R} ({mode})"

### Mode-Specific Executor Instructions

| Mode | Special Executor Behavior |
|------|--------------------------|
| `full` | Standard execution — all scenarios by priority |
| `onboarding` | Screenshot EVERY step/state. Time each transition. Note loading states, empty states, error states. Flag drop-off points where a user would abandon. |
| `forms` | Use the **Form Test Pattern Library** (see executor prompt). Test empty submit, 500+ char strings, special chars (`@#$%'"<>`), invalid formats, SQL/XSS vectors. Screenshot every error and success state. |
| `responsive` | Use `mcp__playwright__browser_resize` at each viewport (375, 768, 1280, 1920 or custom). Screenshot each page at each viewport. Check: text clipping, overflow, button overlap, nav collapse, CTA visibility. |
| `regression` | Screenshot the 5+ most important pages. Compare against expected layout. Flag shifted elements, color changes, broken hover states, spacing differences. Verify the intended change applied. |
| `journey` | Screenshot every screen from landing to core value moment. Time each step. Note confusion points, unnecessary friction, missing feedback. Build a visual journey map. |
| `a11y` | Check: low-contrast text, small tap targets (<44px), missing form labels, color-only status indicators, missing focus states, missing aria attributes. Use `browser_snapshot` for accessibility tree inspection. |

After completion:
- Read `.harness/qa-results.md`
- Briefly report: **"테스트 실행 완료. [X]개 시나리오 중 PASS: [N], FAIL: [N], PARTIAL: [N], BLOCKED: [N]."**
- Update event log: `echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] executor:r{R} | done | qa-results.md | PASS:{N} FAIL:{N}" >> .harness/session-events.md`

#### 4b. Analyze

Launch a **general-purpose Agent** with **model `sonnet`**:
- **prompt**: The analyst prompt template + context:
  - "Test results: `.harness/qa-results.md`"
  - "Test scenarios: `.harness/qa-scenarios.md`"
  - "Codebase context: `.harness/qa-context.md`"
  - "**Test mode**: `{selected mode}`"
  - "Write output to `.harness/qa-analysis.md`"
- **description**: "harness-qa analyst ({mode})"

#### 4c. Evaluate

After Analyst completes:
1. Read `.harness/qa-analysis.md`
2. Report to user:
   - Overall pass rate
   - CRITICAL bug count
   - Pattern count
   - Missing feature count
   - Mode-specific metrics (see below)
3. **Decision**:
   - If user wants to fix and re-test → proceed to round 2 (user fixes bugs, then re-runs Phase 4)
   - Otherwise → proceed to Phase 5

### Mode-Specific Evaluation Metrics

| Mode | Additional Metrics |
|------|-------------------|
| `onboarding` | Steps to activation, estimated drop-off rate, blocking UX issues |
| `forms` | Vulnerable fields count, silent failure count, invalid-accept count |
| `responsive` | Viewport breakage matrix (which pages break at which sizes) |
| `regression` | Intended changes verified, unintended regressions found |
| `journey` | Total journey time, friction point count, screenshot count |
| `a11y` | WCAG violations by severity, affected component count |

---

## Phase 5: Report

Read the qa-reporter prompt template: `~/.claude/harness/qa-reporter-prompt.md`

Launch a **general-purpose Agent** with **model `sonnet`**:
- **prompt**: The qa-reporter prompt template + context:
  - "Analysis: `.harness/qa-analysis.md`"
  - "Test results: `.harness/qa-results.md`"
  - "Test scenarios: `.harness/qa-scenarios.md`"
  - "Codebase context: `.harness/qa-context.md`"
  - "**Test mode**: `{selected mode}`"
  - "Write output to `.harness/qa-report.md`"
- **description**: "harness-qa reporter ({mode})"

After completion:
- Read `.harness/qa-report.md`
- Present user-facing summary:

```
## QA Complete ({mode} mode)

**Grade**: [A/B/C/D/F] ([score]%)
**Verdict**: [READY / READY_WITH_ISSUES / NOT_READY]
**Scenarios**: [X] tested | PASS: [N] | FAIL: [N] | BLOCKED: [N]
**Bugs**: CRITICAL: [N] | HIGH: [N] | MEDIUM: [N]

**Top Issues**:
1. [one-line]
2. [one-line]
3. [one-line]

Full report: `.harness/qa-report.md`
```

- Run artifact validation:
  ```bash
  MISSING=0
  for f in qa-prompt.md qa-context.md qa-scenarios.md qa-results.md qa-analysis.md qa-report.md; do
    [ ! -f ".harness/$f" ] && echo "MISSING: .harness/$f" && MISSING=$((MISSING+1))
  done
  # pre-launch mode uses qa-test-plan.md instead of results/analysis/report
  if [ "{mode}" = "pre-launch" ]; then
    [ ! -f ".harness/qa-test-plan.md" ] && echo "MISSING: .harness/qa-test-plan.md" && MISSING=$((MISSING+1))
  fi
  echo "Artifacts: $MISSING missing"
  ```
- Include artifact status in the report
- Ask: **"QA 리포트를 확인해주세요. 수정 후 재테스트가 필요하면 `/harness-qa` 를 다시 실행해주세요."**
- Finalize session:
  ```bash
  sed -i '' 's/status: IN_PROGRESS/status: COMPLETED/' .harness/session-state.md
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] reporter | done | qa-report.md | QA pipeline complete, grade: {grade}" >> .harness/session-events.md
  ```

---

## Critical Rules

1. **Each agent = separate Agent tool call** with fresh context.
2. **ALL inter-agent communication through `.harness/qa-` files only.**
3. **Test Executor MUST use Playwright MCP** (`mcp__playwright__*`) for all UI testing. Code reading alone is NOT testing.
4. **NEVER store raw credentials in `.harness/qa-` files.** Reference them by variable name or "provided in task description."
5. **ALWAYS present scenarios to the user and wait for approval** before executing tests.
6. **The Test Executor does NOT fix bugs.** It tests and reports.
7. **The Analyst does NOT re-test.** It analyzes results from the Executor.
8. **Read prompt templates from `~/.claude/harness/`** before spawning each agent.
9. **Quick mode (`--quick`)**: Scenario Writer generates only CRITICAL scenarios. Test Executor skips HIGH/MEDIUM.
10. **Mode is passed to EVERY agent.** Each agent adapts its behavior based on the selected mode.
11. **`pre-launch` mode stops at Phase 3.** It produces a test plan, not test results.
12. **`responsive` mode requires `browser_resize`** at every viewport before screenshots.
13. **`regression` mode requires `--change` description** to know what to verify.
14. **Session state and event log are updated after EVERY agent.** See `~/.claude/harness/references/session-protocol.md`.
15. **All agents use model `sonnet`** — QA is systematic work.

## Cost Awareness

| Mode | Duration | Agent Calls |
|------|---------|-------------|
| `--quick` | 10-20 min | 5 (scout + scenario + executor + analyst + reporter) |
| `full` (default) | 20-45 min | 5 (scout + scenario + executor + analyst + reporter) |
| `onboarding` | 15-30 min | 5 |
| `forms` | 20-40 min | 5 |
| `responsive` | 15-30 min | 5 (screenshots × viewports) |
| `regression` | 10-25 min | 5 |
| `journey` | 15-30 min | 5 |
| `a11y` | 15-25 min | 5 |
| `pre-launch` | 5-15 min | 2 (scout + scenario writer only) |
| re-test (round 2) | +15-30 min | +2 (executor + analyst) |
