---
description: "5-agent code review pipeline (Scanner → Analyzer → Fixer → Verifier → Reporter) with git handoff support."
---

# Harness-Review: Code Review Pipeline (v1)

> 5-agent harness for post-implementation code review.
> Scanner → Analyzer → Fixer → Verifier → Reporter with file-based handoffs.

## User Request

$ARGUMENTS

## Phase 0: Guard Clause + Capability Detection

### Capability Detection

Run at session start. See `harness/references/session-protocol.md` §9.

1. `CLAUDEX_TIER_OVERRIDE` → use that value.
2. Else `CLAUDEX_ELITE_MODELS` contains current identifier → `Elite`.
3. Else fallback: `sonnet|haiku` → `Standard`; `opus` → `Advanced`; unknown → `Standard`.

Announce `tier: {Standard|Advanced|Elite}`. Persist to `.harness/session-state.md` under `tier:`.

**Tier effect on review** (no internal loop; tier biases severity thresholds):
- Standard / Advanced: baseline severity thresholds
- Elite: Analyzer and Verifier apply a +1 severity bump to detected issues (e.g., a `minor` finding under Standard may be classified `moderate` under Elite). Rationale: Elite-class mistakes are subtler and deserve closer scrutiny. See `harness/references/tier-matrix.md`.

### Guard Clause

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

Read the session protocol reference: `~/.claude/harness/references/session-protocol.md`

### 1a. Session Recovery Check

If `.harness/session-state.md` exists and `pipeline: harness-review`:
- Present to user: **"이전 리뷰 세션이 감지되었습니다. {last_completed_agent} 완료 후 중단. 이어서 진행할까요?"**
- If **resume**: skip to the phase AFTER `last_completed_agent`
- If **restart**: `mv .harness/ .harness-backup-$(date +%s)/`

### 1b. Fresh Setup

```bash
mkdir -p .harness
```

Initialize session state and event log:
```bash
cat > .harness/session-state.md << 'HEREDOC'
# Session State
- pipeline: harness-review
- scale: —
- phase: 1
- round: 1
- last_completed_agent: setup
- last_completed_at: {ISO8601}
- status: IN_PROGRESS
HEREDOC
echo "# Session Events" > .harness/session-events.md
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] setup | done | — | Review pipeline started" >> .harness/session-events.md
```

---

## Phase 2: Scan

Read the scanner prompt template: `~/.claude/harness/scanner-prompt.md`

Launch a **general-purpose Agent** with subagent_type `Explore` and **model `sonnet`**:
- **prompt**: The scanner prompt template + context:
  - "Project directory: `{cwd}`"
  - "Write output to `.harness/review-context.md`"
- **description**: "harness-review scanner"
- **model**: `sonnet`

After completion:
- Read `.harness/review-context.md`
- If "NO CHANGES DETECTED" → report to user and EXIT
- Otherwise, briefly confirm: **"Scanner 완료. [X]개 파일 변경 감지, [Y]개 HIGH risk."**
- Update event log: `echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] scanner | done | review-context.md | {X} files, {Y} HIGH risk" >> .harness/session-events.md`
- Proceed without user approval (review is automated).

---

## Phase 3: Analyze

Read the analyzer prompt template: `~/.claude/harness/analyzer-prompt.md`

Launch a **general-purpose Agent** with **model `sonnet`**:
- **prompt**: The analyzer prompt template + context:
  - "Review context: `.harness/review-context.md`"
  - "Write output to `.harness/review-analysis.md`"
- **description**: "harness-review analyzer"
- **model**: `sonnet`

After completion:
- Read `.harness/review-analysis.md`
- Briefly report: **"분석 완료. [X]개 이슈 발견 (CRITICAL: [N], HIGH: [N], MEDIUM: [N])."**
- Update event log: `echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] analyzer | done | review-analysis.md | {X} issues" >> .harness/session-events.md`

### `--dry-run` mode: STOP here. Present analysis summary to user and EXIT.

---

## Phase 4: Fix

Read the fixer prompt template: `~/.claude/harness/fixer-prompt.md`

Launch a **general-purpose Agent** with **model `sonnet`**:
- **prompt**: The fixer prompt template + context:
  - "Analysis report: `.harness/review-analysis.md`"
  - "Review context: `.harness/review-context.md`"
  - "Write output to `.harness/review-fix-report.md`"
- **description**: "harness-review fixer"
- **model**: `sonnet`

After completion, update event log: `echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] fixer | done | review-fix-report.md | {summary}" >> .harness/session-events.md`

---

## Phase 5: Verify

Read the verifier prompt template: `~/.claude/harness/verifier-prompt.md`

Launch a **general-purpose Agent** with **model `sonnet`**:
- **prompt**: The verifier prompt template + context:
  - "Fix report: `.harness/review-fix-report.md`"
  - "Analysis report: `.harness/review-analysis.md`"
  - "Review context: `.harness/review-context.md`"
  - "Write output to `.harness/review-verify-report.md`"
- **description**: "harness-review verifier"
- **model**: `sonnet`

After completion, update event log: `echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] verifier | done | review-verify-report.md | {summary}" >> .harness/session-events.md`

---

## Phase 6: Report + Git

> **Completion Gate (v4.2.0, MANDATORY)**: The Reporter agent is required by its prompt (`~/.claude/harness/reporter-prompt.md`) to run the Completion Gate scan before writing `.harness/review-report.md`. See `harness/references/completion-gate-protocol.md`. The gate must PASS before any git action flag (`--commit`, `--push`, `--pr`) is honored — even if the review verdict is PASS, unresolved CRITICAL gate findings block the git handoff.

Read the reporter prompt template: `~/.claude/harness/reporter-prompt.md`

Launch a **general-purpose Agent** with **model `sonnet`**:
- **prompt**: The reporter prompt template + context:
  - "Review context: `.harness/review-context.md`"
  - "Analysis report: `.harness/review-analysis.md`"
  - "Fix report: `.harness/review-fix-report.md`"
  - "Verification report: `.harness/review-verify-report.md`"
  - "Git action flags: `{--dry-run | --commit | --push | --pr | default}`"
  - "Write output to `.harness/review-report.md`"
- **description**: "harness-review reporter"
- **model**: `sonnet`

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
- Finalize session:
  ```bash
  sed -i '' 's/status: IN_PROGRESS/status: COMPLETED/' .harness/session-state.md
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] reporter | done | review-report.md | Pipeline complete" >> .harness/session-events.md
  ```

---

## Critical Rules

1. **Each agent = separate Agent tool call** with fresh context.
2. **ALL inter-agent communication through `.harness/review-` files only.**
3. **`--dry-run` stops after Phase 3** (analysis only, no fixes).
4. **Git actions require PASS verdict from Reporter.** FAIL = blocked regardless of flags.
5. **Never push to main/master without user confirmation**, even with `--push` flag.
6. **Read prompt templates from `~/.claude/harness/`** before spawning each agent.
7. **No user approval gates.** Review pipeline runs automatically (unlike /harness which waits for spec approval).
8. **Session state and event log are updated after EVERY agent.** See `~/.claude/harness/references/session-protocol.md`.
9. **All agents use model `sonnet`** — review is systematic work, not creative judgment.

## Cost Awareness

| Mode | Duration | Agent Calls |
|------|---------|-------------|
| `--dry-run` | 2-5 min | 2 (scanner + analyzer) |
| default | 5-10 min | 5 (scanner → analyzer → fixer → verifier → reporter) |
| `--commit/push/pr` | 5-12 min | 5 + git actions |
