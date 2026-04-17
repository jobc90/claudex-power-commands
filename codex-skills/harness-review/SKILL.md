---
name: harness-review
description: Post-implementation review harness for `/harness-review` or `$harness-review` requests. Scanner -> Analyzer -> Fixer -> Verifier -> Reporter pipeline with optional git handoff. v4.1.0 — tier-aware severity thresholds (Elite tier applies +1 severity bump to detected issues).
---

# Harness Review

## Overview

Run the Codex version of `/harness-review`. Treat `/harness-review` and `$harness-review` as the same workflow intent inside Codex.

**v4.1.0**: Capability tier detection (`Standard | Advanced | Elite`) at session start. Under Elite tier, Analyzer and Verifier apply a +1 severity bump to compensate for subtler elite-class mistakes. See `references/tier-matrix.md`.

This skill mirrors the Claude harness-review structure:

`CAPABILITY -> SETUP -> SCAN -> ANALYZE -> FIX -> VERIFY -> REPORT`

## Guard Clause

Before starting the protocol, confirm the request is a code review request over a real git diff.

Do not run this workflow when the user is:

- asking how harness-review works
- asking to configure the harness itself
- asking a normal coding question without a review intent

If `git diff --name-only` is empty, report that there are no changes to review and stop.

## Input Modes

Treat these literal tokens in the user's prompt as workflow hints:

- `$harness-review`
- `$harness-review --dry-run`
- `$harness-review --commit`
- `$harness-review --push`
- `$harness-review --pr`

## Required Artifacts

Use `.harness_codex/review-` in the target project directory.

- `.harness_codex/review-context.md`
- `.harness_codex/review-analysis.md`
- `.harness_codex/review-fix-report.md`
- `.harness_codex/review-verify-report.md`
- `.harness_codex/review-report.md`

## Arguments

- `--dry-run`: review only, no fixes, no git actions
- `--commit`: fix, verify, and commit if PASS
- `--push`: fix, verify, commit, and push if PASS
- `--pr`: fix, verify, commit, push, and create PR if PASS
- default: fix, verify, and report the next safe git action

## Phase 1. Setup

Create the working directory:

```bash
mkdir -p .harness_codex
```

## Phase 2. Scan

Load `references/scanner-prompt.md`.

Spawn a fresh scanner subagent:

- require output at `.harness_codex/review-context.md`

After it finishes:

- read `.harness_codex/review-context.md`
- if it reports no changes, stop
- otherwise briefly report the number of changed files and high-risk areas

## Phase 3. Analyze

Load `references/analyzer-prompt.md`.

Spawn a fresh analyzer subagent:

- input context: `.harness_codex/review-context.md`
- output: `.harness_codex/review-analysis.md`

After it finishes:

- read `.harness_codex/review-analysis.md`
- report the issue count by severity

If `--dry-run` is active, stop here and present the analysis summary.

## Phase 4. Fix

Load `references/fixer-prompt.md`.

Spawn a fresh fixer subagent:

- analysis report: `.harness_codex/review-analysis.md`
- review context: `.harness_codex/review-context.md`
- output: `.harness_codex/review-fix-report.md`

## Phase 5. Verify

Load `references/verifier-prompt.md`.

Spawn a fresh verifier subagent:

- fix report: `.harness_codex/review-fix-report.md`
- analysis report: `.harness_codex/review-analysis.md`
- review context: `.harness_codex/review-context.md`
- output: `.harness_codex/review-verify-report.md`

## Phase 6. Report + Git

Load `references/reporter-prompt.md`.

Spawn a fresh reporter subagent:

- review context: `.harness_codex/review-context.md`
- analysis report: `.harness_codex/review-analysis.md`
- fix report: `.harness_codex/review-fix-report.md`
- verification report: `.harness_codex/review-verify-report.md`
- git action flag state
- output: `.harness_codex/review-report.md`

After it finishes:

- read `.harness_codex/review-report.md`
- present the user-facing summary

If the selected mode includes git actions, only execute them when the report verdict is PASS.

## Execution Rules

1. Each phase agent must be a separate `spawn_agent` call with fresh context.
2. Never pass state between agents in chat. Use `.harness_codex/review-` files only.
3. `--dry-run` stops after the Analyze phase.
4. Git actions require a PASS verdict from the Reporter.
5. Never push to `main` or `master` without explicit user instruction.
6. Always load the prompt templates from `references/` before composing each agent task.
