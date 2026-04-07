---
name: harness
description: Autonomous application-building harness for `/harness` or `$harness` requests. Use when Codex needs to run the same Scout -> Planner -> Builder -> Refiner -> QA workflow as the Claude command, including S/M/L scale handling and file-based handoffs.
---

# Harness

## Overview

Run the Codex version of `/harness`. Treat `/harness` and `$harness` as the same workflow intent inside Codex.

This skill mirrors the Claude harness structure:

`TRIAGE -> SETUP -> SCOUT -> PLAN -> USER APPROVAL -> BUILD/REFINE/QA LOOP -> SUMMARY`

## Guard Clause

Before starting the protocol, confirm the request is actually asking Codex to build, fix, or implement software.

Do not run the harness loop when the user is:

- asking how harness works
- asking to audit or modify the harness itself
- asking a normal coding question or a small edit
- asking for documentation instead of an app build

In those cases, respond directly instead of executing the harness workflow.

## Input Modes

Treat these literal tokens in the user's prompt as workflow hints:

- `$harness`
- `/harness`

If no token is present but the request clearly means "run the autonomous build harness", this skill still applies.

## Scale Classification

Classify the request before planning:

| Scale | Criteria | Examples |
|------|----------|----------|
| `S` | Bug fix, typo, 1-2 file changes, config tweak | fix a broken route, tweak a timeout |
| `M` | Feature addition, 3-5 file changes, module-level work | add password reset, refactor auth module |
| `L` | New application, major refactor, 6+ files, multi-module work | build a dashboard app, rewrite payments |

When in doubt between two scales, pick the smaller one.

## Required Artifacts

Use `.harness_codex/` in the target project directory.

- `.harness_codex/build-prompt.md`
- `.harness_codex/build-context.md`
- `.harness_codex/build-spec.md`
- `.harness_codex/build-progress.md`
- `.harness_codex/build-refiner-report.md`
- `.harness_codex/build-round-1-feedback.md`
- `.harness_codex/build-round-2-feedback.md`
- `.harness_codex/build-round-3-feedback.md`

All inter-agent communication must happen through these files only.

## Phase 1. Setup

1. Identify the target project directory first.
2. Create the working directory and initialize git if needed:

```bash
mkdir -p .harness_codex
git init 2>/dev/null || true
```

3. Write the user's original request and classified scale to `.harness_codex/build-prompt.md`.

## Phase 2. Scout

Load `references/scout-prompt.md`.

### Request Type Detection (CRITICAL)

Before launching the Scout, classify the request type:

| Type | Signal | Scout Instruction |
|------|--------|-------------------|
| **FIX** | "수정", "fix", "bug", "안됨", "작동하지 않음", "비활성화", "차단" | Include Deep Dive Protocol |
| **MODIFY** | "변경", "modify", "refactor", "이관", "전환" | Include Deep Dive Protocol |
| **BUILD** | "추가", "구현", "만들어", "생성", "add", "implement", "create" | Standard scan only |

For FIX/MODIFY requests, append this instruction to the Scout prompt:
- "This is a FIX/MODIFICATION request. After the standard module scan, you MUST execute the **Deep Dive Protocol** described in the scout prompt. Trace the specific feature's data flow end-to-end, verify each flag/guard/condition with file:line evidence, and map behavior per user type/role. The Planner will reject unverified claims."

Use a fresh explore-style subagent:

- keep `fork_context` false
- pass only the scout prompt plus minimal local context
- require the agent to write `.harness_codex/build-context.md`
- scale guidance:
  - `S`: scan only the 2-5 directly relevant files
  - `M`: scan the relevant modules, roughly 5-15 files
  - `L`: comprehensive scan, roughly 20-40 files
- if FIX/MODIFY: include the Deep Dive instruction above

After Scout completes, briefly report that codebase context was collected. No approval gate here.

## Phase 3. Planning

Load `references/planner-prompt.md`.

### Scale `S`

Do not spawn a Planner agent. Write `.harness_codex/build-spec.md` directly using `.harness_codex/build-context.md`.

**CRITICAL**: Before writing the spec, READ `.harness_codex/build-context.md` thoroughly. For FIX/MODIFY requests, the "Feature Deep Dive" section contains verified findings — use ONLY those findings to determine files to change. Do NOT list files based on your own inference.

Include:

- task summary
- current state (verified) — for FIX/MODIFY: summarize Scout's Deep Dive findings with file:line citations
- files to change — MUST match Scout's verified findings
- existing patterns to follow
- success criteria
- risks

Then ask exactly:

`Scope를 검토해주세요. 진행할까요?`

Stop and wait for approval.

### Scale `M`

Spawn a fresh planner subagent:

- require it to read `.harness_codex/build-context.md`
- add `MODE: LITE. Scale is M.`
- require it to write `.harness_codex/build-spec.md`

After it finishes, summarize the spec and ask:

`Spec을 검토해주세요. 진행할까요?`

Stop and wait for approval.

### Scale `L`

Spawn a fresh planner subagent:

- require it to read `.harness_codex/build-context.md`
- add `MODE: FULL. Scale is L.`
- require it to write `.harness_codex/build-spec.md`

After it finishes, summarize the spec and ask:

`Spec을 검토해주세요. 진행할까요, 수정할 부분이 있나요?`

Stop and wait for approval.

## Phase 4. Build-Refine-QA Loop (Meta-Harness Enhanced)

Load:

- `references/builder-prompt.md`
- `references/refiner-prompt.md`
- `references/qa-prompt.md`
- `references/diagnostician-prompt.md`

Run at most:

- `S`: 1 round
- `M`: 2 rounds
- `L`: 3 rounds

### 4-pre. Environment Snapshot (Every Round)

Before each Build round, capture the project state to `.harness_codex/snapshot-round-{N}.md`:
- `git diff --stat` and `git diff --name-only`
- Build command exit code + last 20 lines if failure
- Test command exit code + summary
- Dev server status

Pass this path to the Builder.

### 4a. Build

For each round `N`, spawn a fresh builder subagent.

Builder instructions must include:

- codebase context: `.harness_codex/build-context.md`
- product spec: `.harness_codex/build-spec.md`
- environment snapshot: `.harness_codex/snapshot-round-{N}.md`
- scale: `{S|M|L}`
- round handling:
  - round 1: implement the requested changes from the spec
  - round 2+: read diagnosis at `.harness_codex/diagnosis-round-{N-1}.md` (PRIMARY input), cumulative history at `.harness_codex/build-history.md`, and evidence traces at `.harness_codex/traces/round-{N-1}-qa-evidence.md`. Fix ROOT CAUSES, not symptoms.
- write progress to `.harness_codex/build-progress.md`
- for scale `M` and `L`, start the dev server in background and record the URL in `.harness_codex/build-progress.md`

### 4b. Refine

Spawn a fresh refiner subagent.

Refiner instructions must include:

- codebase context: `.harness_codex/build-context.md`
- product spec: `.harness_codex/build-spec.md`
- build progress: `.harness_codex/build-progress.md`
- scale and round number
- round 2+: previous QA feedback path
- apply safe cleanup and hardening directly to the code
- write `.harness_codex/build-refiner-report.md`

### 4c. Verify Dev Server

For scale `M` and `L` only:

1. Read `.harness_codex/build-progress.md` and extract the app URL.
2. Verify the server responds:

```bash
curl -s -o /dev/null -w '%{http_code}' <URL>
```

3. If the server is down, attempt to start it using the recorded command.
4. If it still does not run, treat that as a critical QA failure.

### 4d. QA

Spawn a fresh QA subagent.

QA instructions must include:

- product spec path: `.harness_codex/build-spec.md`
- refiner report path: `.harness_codex/build-refiner-report.md`
- scale and round number
- output path: `.harness_codex/build-round-{N}-feedback.md`
- for scale M/L: write evidence traces to `.harness_codex/traces/round-{N}-qa-evidence.md`
- mode:
  - `S`: code review plus build/test verification only
  - `M`: Playwright if UI exists, otherwise code review plus build/test
  - `L`: Playwright is mandatory
- if UI exists, pass the app URL

### 4e. Evaluate

After QA finishes:

1. Read `.harness_codex/build-round-{N}-feedback.md`.
2. Extract the criterion scores.
3. Report briefly: round number, scores, pass/fail, key issues
4. Decide (evaluate in this order):
   - final allowed round reached -> go to 4g (History), then stop regardless of scores
   - all scores `>= 7` -> pass, go to 4g (History), then Phase 5
   - any score `< 7` AND rounds remain -> go to 4f (Diagnose), then 4g (History), then continue

### 4f. Diagnose (Scale M/L, before next round ONLY)

Skip for Scale S or if this was the final round.

Load `references/diagnostician-prompt.md`.

Spawn a fresh diagnostician subagent:

- QA feedback: `.harness_codex/build-round-{N}-feedback.md`
- QA evidence traces: `.harness_codex/traces/round-{N}-qa-evidence.md`
- environment snapshot: `.harness_codex/snapshot-round-{N}.md`
- codebase context: `.harness_codex/build-context.md`
- round number: {N}
- if round 2+: previous diagnosis and build history paths
- output: `.harness_codex/diagnosis-round-{N}.md`

Report briefly: root cause count, regression count, top priority fix.

### 4g. Accumulate History (Every Round)

Append to `.harness_codex/build-history.md`:

- Scores, verdict, changes made, QA issues, root causes, what worked/regressed
- NEVER overwrite — only append. Create on round 1 with a header.

## Phase 5. Summary

Use this reporting shape:

```markdown
## Harness Complete

**Scale**: {S|M|L}
**Rounds**: {N}/{max_rounds}
**Status**: PASS / PARTIAL

### Scores
| Criterion | Score |
|-----------|-------|
| ...       | X/10  |

### Changes
[files changed and what was delivered]

### Refiner Summary
[issues found and fixed]

### Remaining Issues
[actionable items from the last QA report]

### Artifacts
- Context: `.harness_codex/build-context.md`
- Spec: `.harness_codex/build-spec.md`
- Progress: `.harness_codex/build-progress.md`
- Refiner: `.harness_codex/build-refiner-report.md`
- Final QA: `.harness_codex/build-round-{N}-feedback.md`
```

## Execution Rules

1. Each phase agent must be a separate `spawn_agent` call with fresh context.
2. Never pass state between agents in chat. Use `.harness_codex/` files only.
3. Always load the prompt templates from `references/` before composing each agent task.
4. Always wait for explicit user approval after the planning phase.
5. The Builder cannot self-certify. Refiner and QA must run after every build round.
6. The Refiner does not add features. It only cleans, hardens, and aligns with existing patterns.
7. Scale `S` does not require Playwright.
8. Scale `M` uses Playwright only when UI exists.
9. Scale `L` requires live-app QA with Playwright.
10. If subagents are unavailable, stop and say the harness cannot run as designed. Do not fake the multi-agent loop in one pass.
