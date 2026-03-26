---
name: harness
description: "Autonomous application-building harness for `/harness` or `$harness` requests. Use when Codex needs to turn a product idea into a working app through a file-based multi-agent loop: create `.harness/`, write a product spec, wait for user approval, implement the app, run Playwright-based QA, iterate up to 3 rounds, and deliver a final build summary."
---

# Harness

## Overview

Run the Codex version of `/harness`. Treat `/harness` and `$harness` as the same workflow intent inside Codex.

This skill is for substantial app-building requests, not for ordinary coding tasks. It uses a strict file-based handoff model:

`GUARD -> SETUP -> PLAN -> USER APPROVAL -> BUILD/QA LOOP -> SUMMARY`

## Guard Clause

Before starting the harness protocol, confirm the request is actually asking Codex to build an application or substantial prototype.

Do not run the harness loop when the user is:

- asking how harness works
- asking to audit or modify the harness itself
- asking a normal coding question or a small edit
- asking for documentation rather than an app build

In those cases, respond directly instead of executing the harness workflow.

## Required Artifacts

Use `.harness/` in the target project directory.

- `.harness/prompt.md`
- `.harness/spec.md`
- `.harness/progress.md`
- `.harness/round-1-feedback.md`
- `.harness/round-2-feedback.md`
- `.harness/round-3-feedback.md`

All inter-agent communication must happen through these files only.

## Phase 1. Setup

1. Identify the target project directory before doing any work.
2. Create the working directory and initialize git if needed:

```bash
mkdir -p .harness
git init 2>/dev/null || true
```

3. Write the user's original request to `.harness/prompt.md`.
4. If the request implies a long-running autonomous build, warn the user that the full loop may take hours and consume significant tokens.

## Phase 2. Planning

Load `references/planner-prompt.md`.

Spawn a fresh subagent for planning:

- use `spawn_agent`
- keep `fork_context` false
- pass only the planner prompt template plus the minimal task-local context
- require the planner to read `.harness/prompt.md`
- require the planner to write the final output to `.harness/spec.md`

After the planner finishes:

1. Read `.harness/spec.md`.
2. Summarize the spec for the user:
   - feature count
   - key features
   - tech stack
   - AI integrations
3. Ask exactly: `Spec을 검토해주세요. 진행할까요, 수정할 부분이 있나요?`
4. Stop and wait for approval. Do not start implementation before approval.

## Phase 3. Build-QA Loop

Load:

- `references/builder-prompt.md`
- `references/qa-prompt.md`

Run at most 3 rounds.

### 3a. Build

For each round `N` in `1..3`, spawn a fresh builder subagent.

Builder instructions must include:

- read `.harness/spec.md` first
- if round 1: implement the full application from scratch
- if round 2 or 3: read `.harness/round-{N-1}-feedback.md` and fix every reported issue
- write progress to `.harness/progress.md`
- start the dev server in background
- record the exact dev server URL and start command in `.harness/progress.md`

Use a worker-style subagent when available. Keep the context fresh and bounded to the harness files plus the working tree.

### 3b. Verify Dev Server

After the builder finishes:

1. Read `.harness/progress.md` and extract the app URL.
2. Verify the server responds:

```bash
curl -s -o /dev/null -w '%{http_code}' <URL>
```

3. If the server is down, attempt to start it using the recorded command.
4. If the server still does not run, treat that as a critical QA failure and record it.

### 3c. QA

Spawn a fresh QA subagent.

QA instructions must include:

- product spec path: `.harness/spec.md`
- app URL from `.harness/progress.md`
- round number
- output path: `.harness/round-{N}-feedback.md`
- mandatory use of Playwright MCP browser tools for live testing

The QA pass is required after every build round. Do not accept builder self-certification.

### 3d. Evaluate

After QA finishes:

1. Read `.harness/round-{N}-feedback.md`.
2. Extract scores for:
   - Product Depth
   - Functionality
   - Visual Design
   - Code Quality
3. Report briefly to the user:
   - round number
   - criterion scores
   - pass/fail
   - key issues found
4. Decide:
   - if every score is `>= 7`, pass and exit the loop
   - if any score is `< 7` and `N < 3`, continue to the next round
   - if `N == 3`, stop even if failures remain

## Phase 4. Final Summary

Present the final result in this shape:

```markdown
## Harness Build Complete

**Rounds**: {N}/3
**Status**: PASS / PARTIAL

### Final Scores
| Criterion      | Score | Status |
|----------------|-------|--------|
| Product Depth  | X/10  |        |
| Functionality  | X/10  |        |
| Visual Design  | X/10  |        |
| Code Quality   | X/10  |        |

### Features Delivered
[List features from spec with PASS/PARTIAL/FAIL]

### Remaining Issues
[Actionable items from the last QA report]

### Artifacts
- Spec: `.harness/spec.md`
- Final QA: `.harness/round-{N}-feedback.md`
- Progress: `.harness/progress.md`
- Git log: `git log --oneline`
```

## Execution Rules

1. Each phase agent must be a separate `spawn_agent` call with fresh context.
2. Never pass state between agents in chat. Use `.harness/` files only.
3. Always load the prompt templates from `references/` before composing each agent task.
4. Always wait for explicit user approval after the planning phase.
5. QA must use Playwright MCP browser tools against the live app, not code review alone.
6. If the dev server is not running, QA cannot proceed until that is resolved or explicitly recorded as failure.
7. If subagents are unavailable, stop and say the harness cannot run as designed. Do not fake the multi-agent loop in a single pass.
