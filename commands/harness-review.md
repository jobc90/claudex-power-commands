---
description: "5-agent code review pipeline (Scanner → Analyzer → Fixer → Verifier → Reporter) with git handoff support."
---

# Harness-Review: Code Review Pipeline (v1)

> 5-agent harness for post-implementation code review.
> Scanner → Analyzer → Fixer → Verifier → Reporter with file-based handoffs.

## User Request

$ARGUMENTS

## Phase 0: Guard Clause

If the request is NOT a code review request (question about harness, audit, configuration change):
- Respond directly as a normal conversation
- Do NOT execute any harness phases

If there are NO changed files (`git diff --name-only` returns empty):
- Report "No changes to review" and EXIT

## Architecture Overview

```
/harness-review [flags]
  |
  +- Phase 1: Setup           -> .harness/review- directory
  +- Phase 2: Scan            -> Scanner agent -> .harness/review-context.md
  +- Phase 3: Analyze         -> Analyzer agent -> .harness/review-analysis.md
  +- Phase 4: Fix             -> Fixer agent -> .harness/review-fix-report.md
  +- Phase 5: Verify          -> Verifier agent -> .harness/review-verify-report.md
  +- Phase 6: Report + Git    -> Reporter agent -> .harness/review-report.md
```

## Arguments

- `--dry-run`: Review only. No fixes, no git actions.
- `--commit`: Fix + verify + commit if PASS.
- `--push`: Fix + verify + commit + push if PASS.
- `--pr`: Fix + verify + commit + push + create PR if PASS.
- (default): Fix + verify + report recommended git action.

---

## Phase 1: Setup

```bash
mkdir -p .harness
```

---

## Phase 2: Scan

Read the scanner prompt template: `~/.claude/harness/scanner-prompt.md`

Launch a **general-purpose Agent** with subagent_type `Explore`:
- **prompt**: The scanner prompt template + context:
  - "Project directory: `{cwd}`"
  - "Write output to `.harness/review-context.md`"
- **description**: "harness-review scanner"

After completion:
- Read `.harness/review-context.md`
- If "NO CHANGES DETECTED" → report to user and EXIT
- Otherwise, briefly confirm: **"Scanner 완료. [X]개 파일 변경 감지, [Y]개 HIGH risk."**
- Proceed without user approval (review is automated).

---

## Phase 3: Analyze

Read the analyzer prompt template: `~/.claude/harness/analyzer-prompt.md`

Launch a **general-purpose Agent**:
- **prompt**: The analyzer prompt template + context:
  - "Review context: `.harness/review-context.md`"
  - "Write output to `.harness/review-analysis.md`"
- **description**: "harness-review analyzer"

After completion:
- Read `.harness/review-analysis.md`
- Briefly report: **"분석 완료. [X]개 이슈 발견 (CRITICAL: [N], HIGH: [N], MEDIUM: [N])."**

### `--dry-run` mode: STOP here. Present analysis summary to user and EXIT.

---

## Phase 4: Fix

Read the fixer prompt template: `~/.claude/harness/fixer-prompt.md`

Launch a **general-purpose Agent**:
- **prompt**: The fixer prompt template + context:
  - "Analysis report: `.harness/review-analysis.md`"
  - "Review context: `.harness/review-context.md`"
  - "Write output to `.harness/review-fix-report.md`"
- **description**: "harness-review fixer"

---

## Phase 5: Verify

Read the verifier prompt template: `~/.claude/harness/verifier-prompt.md`

Launch a **general-purpose Agent**:
- **prompt**: The verifier prompt template + context:
  - "Fix report: `.harness/review-fix-report.md`"
  - "Analysis report: `.harness/review-analysis.md`"
  - "Review context: `.harness/review-context.md`"
  - "Write output to `.harness/review-verify-report.md`"
- **description**: "harness-review verifier"

---

## Phase 6: Report + Git

Read the reporter prompt template: `~/.claude/harness/reporter-prompt.md`

Launch a **general-purpose Agent**:
- **prompt**: The reporter prompt template + context:
  - "Review context: `.harness/review-context.md`"
  - "Analysis report: `.harness/review-analysis.md`"
  - "Fix report: `.harness/review-fix-report.md`"
  - "Verification report: `.harness/review-verify-report.md`"
  - "Git action flags: `{--dry-run | --commit | --push | --pr | default}`"
  - "Write output to `.harness/review-report.md`"
- **description**: "harness-review reporter"

After completion:
- Read `.harness/review-report.md`
- Run artifact validation:
  ```bash
  MISSING=0
  for f in review-context.md review-analysis.md; do
    [ ! -f ".harness/$f" ] && echo "MISSING: .harness/$f" && MISSING=$((MISSING+1))
  done
  # Skip fix/verify/report checks in --dry-run mode
  if [ "{mode}" != "--dry-run" ]; then
    for f in review-fix-report.md review-verify-report.md review-report.md; do
      [ ! -f ".harness/$f" ] && echo "MISSING: .harness/$f" && MISSING=$((MISSING+1))
    done
  fi
  ```
- Present the user-facing summary from the report
- Include artifact status: "Artifacts: [X] missing" or "Artifacts: OK"

---

## Critical Rules

1. **Each agent = separate Agent tool call** with fresh context.
2. **ALL inter-agent communication through `.harness/review-` files only.**
3. **`--dry-run` stops after Phase 3** (analysis only, no fixes).
4. **Git actions require PASS verdict from Reporter.** FAIL = blocked regardless of flags.
5. **Never push to main/master without user confirmation**, even with `--push` flag.
6. **Read prompt templates from `~/.claude/harness/`** before spawning each agent.
7. **No user approval gates.** Review pipeline runs automatically (unlike /harness which waits for spec approval).

## Cost Awareness

| Mode | Duration | Agent Calls |
|------|---------|-------------|
| `--dry-run` | 2-5 min | 2 (scanner + analyzer) |
| default | 5-10 min | 5 (scanner → analyzer → fixer → verifier → reporter) |
| `--commit/push/pr` | 5-12 min | 5 + git actions |
