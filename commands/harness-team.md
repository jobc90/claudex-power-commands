---
description: "5-agent parallel team build pipeline (Scout → Architect → Workers(N) → Integrator → QA) for multi-worker implementation."
---

# Harness-Team: Parallel Team Build (v1)

> 5-agent harness for parallel multi-worker implementation.
> Scout → Architect → Workers(N) → Integrator → QA with wave-structured parallelism.

## User Request

$ARGUMENTS

## Phase 0: Guard Clause

If the request is NOT a build/implementation request:
- Respond directly as a normal conversation
- Do NOT execute any harness phases

### When to Use /harness-team vs /harness

| Use | When |
|-----|------|
| `/harness` | 1 Builder로 충분한 작업 (1-10 파일, 단일 기능/모듈) |
| `/harness-team` | N Workers 병렬이 필요한 작업 (10+ 파일, 다중 모듈, 독립적 기능 여러 개) |

**Rule**: 파일이 많아도 순차 의존성이 강하면 /harness가 더 효율적. 파일이 독립적으로 분리 가능할 때만 /harness-team 사용.

## Architecture Overview

```
/harness-team <task> [--agents N]
  |
  +- Phase 1: Setup           -> .harness/team- directory
  +- Phase 2: Scout            -> Scout agent -> .harness/team-context.md
  +- Phase 3: Architect        -> Architect agent -> .harness/team-plan.md
  |                            -> User reviews and approves
  +- Phase 4: Build (Waves)    -> Up to 2 rounds:
  |   +- Wave 1 (sequential)   -> Foundation work
  |   +- Wave 2 (parallel)     -> N Workers simultaneously
  |   +- Wave 3 (sequential)   -> Integrator merges + verifies
  |   +- QA                    -> Tests + scores
  |   +- Score check           -> all >= 7? done : next round
  +- Phase 5: Summary          -> Final report
```

## Arguments

- First argument: task description (required)
- `--agents N`: number of parallel Workers in Wave 2 (default 3, max 5)

---

## Phase 1: Setup

```bash
mkdir -p .harness
```

Write the user's request and agent count to `.harness/team-prompt.md`.

---

## Phase 2: Scout

Read the scout prompt template: `~/.claude/harness/scout-prompt.md`

### Request Type Detection (CRITICAL)

Before launching the Scout, classify the request type:

| Type | Signal | Scout Instruction |
|------|--------|-------------------|
| **FIX** | "수정", "fix", "bug", "안됨", "작동하지 않음", "비활성화", "차단" | Include Deep Dive Protocol |
| **MODIFY** | "변경", "modify", "refactor", "이관", "전환" | Include Deep Dive Protocol |
| **BUILD** | "추가", "구현", "만들어", "생성", "add", "implement", "create" | Standard scan only |

For FIX/MODIFY requests, append this instruction to the Scout prompt:
- "This is a FIX/MODIFICATION request. After the standard codebase scan, you MUST execute the **Deep Dive Protocol** described in the scout prompt. Trace the specific feature's data flow end-to-end, verify each flag/guard/condition with file:line evidence, and map behavior per user type/role. The Architect will reject unverified claims."

Launch a **general-purpose Agent** with subagent_type `Explore`:
- **prompt**: The scout prompt template + context:
  - "Project directory: `{cwd}`"
  - "User's request: `{$ARGUMENTS}`"
  - "Scale: L (team builds are always large-scale)"
  - "Write output to `.harness/team-context.md`"
  - If FIX/MODIFY: Deep Dive instruction (see above)
- **description**: "harness-team scout"

---

## Phase 3: Architect

Read the architect prompt template: `~/.claude/harness/architect-prompt.md`

Launch a **general-purpose Agent**:
- **prompt**: The architect prompt template + context:
  - "Codebase context: `.harness/team-context.md`"
  - "User's request: `{$ARGUMENTS}`"
  - "Worker count: {N}"
  - "Write output to `.harness/team-plan.md`"
- **description**: "harness-team architect"

After completion:
- Read `.harness/team-plan.md`
- Present summary to user:
  - Worker count and assignments
  - Wave structure
  - File ownership map
  - Key risks
- Ask: **"빌드 계획을 검토해주세요. 진행할까요, 조정할 부분이 있나요?"**
- **WAIT for user approval.**

---

## Phase 4: Build (Wave Structure)

Read the worker, integrator, and QA prompt templates from `~/.claude/harness/`.

### Max rounds: 2

**For each round R (1, 2):**

#### 4a. Wave 1 — Foundation (Sequential)

If the Architect's plan includes Wave 1 tasks:

Launch a **general-purpose Agent**:
- **prompt**: The worker prompt template + the Wave 1 brief from `plan.md`:
  - "You are Worker 0 (Foundation). Your brief is in `.harness/team-plan.md` under Wave 1."
  - "Codebase context: `.harness/team-context.md`"
  - "Write progress to `.harness/team-worker-0-progress.md`"
  - If R > 1: "Read QA feedback at `.harness/team-round-{R-1}-feedback.md` and fix relevant issues."
- **description**: "harness-team wave1 foundation"

After completion, verify Wave 1 outputs exist before proceeding to Wave 2.

#### 4b. Wave 2 — Implementation (Parallel)

Launch N Worker agents **simultaneously in a single message**:

For each Worker i (1 to N):
- **prompt**: The worker prompt template + Worker i's brief from `plan.md`:
  - "You are Worker {i}. Your brief is in `.harness/team-plan.md` under Worker {i}."
  - "Codebase context: `.harness/team-context.md`"
  - "Wave 1 outputs are available — read-only."
  - "Write progress to `.harness/team-worker-{i}-progress.md`"
  - If R > 1: "Read QA feedback at `.harness/team-round-{R-1}-feedback.md` and fix issues relevant to your files."
- **description**: "harness-team worker {i}"

**All N Workers must complete before proceeding.**

After all Workers complete:
- Read all worker progress files
- Check statuses:
  - All DONE → proceed to Wave 3
  - Any DONE_WITH_CONCERNS → note concerns for Integrator
  - Any NEEDS_CONTEXT → provide context and re-dispatch that Worker
  - Any BLOCKED → assess and escalate to user if needed

#### 4c. Wave 3 — Integration

Launch a **general-purpose Agent**:
- **prompt**: The integrator prompt template + context:
  - "Architect's plan: `.harness/team-plan.md`"
  - "Worker progress reports: `.harness/team-worker-{0..N}-progress.md`"
  - "Codebase context: `.harness/team-context.md`"
  - "Write output to `.harness/team-integration-report.md`"
  - If R > 1: "Previous QA feedback: `.harness/team-round-{R-1}-feedback.md`"
  - "IMPORTANT: After merging, perform CODE HYGIENE on all Worker-changed files: remove console.log/debug, remove TODO/FIXME comments, remove commented-out code, verify naming matches context.md conventions, check for unused imports. Report hygiene issues found/fixed in the integration report."
- **description**: "harness-team integrator"

After completion:
- Read `.harness/team-integration-report.md`
- Verify: "Ready for QA: YES/NO"
- If NO: report issues to user and assess whether to proceed

#### 4d. QA

Read the QA prompt template: `~/.claude/harness/qa-prompt.md`

Launch a **general-purpose Agent**:
- **prompt**: The QA prompt template + context:
  - "Product spec/plan: `.harness/team-plan.md`"
  - "Integration report: `.harness/team-integration-report.md`"
  - "Scale: L"
  - "QA_MODE: FULL or STANDARD based on whether UI exists"
  - "Round number: {R}"
  - "Write QA report to `.harness/team-round-{R}-feedback.md`"
  - "Write evidence traces to `.harness/traces/round-{R}-qa-evidence.md` for FAIL/PARTIAL results."
  - If app has UI: "App URL: `{URL from integration-report.md}`"
- **description**: "harness-team QA round {R}"

#### 4e. Evaluate

After QA completes:
1. Read `.harness/team-round-{R}-feedback.md`
2. Extract scores
3. Report: round, scores, pass/fail, key issues
4. **Decision** (evaluate in this order):
   - R == 2 (max rounds) → go to 4g (History), then Phase 5 regardless of scores
   - ALL criteria >= 7/10 → **PASS** → go to 4g (History), then Phase 5
   - ANY < 7/10 AND R < 2 → **FAIL** → continue to 4f (Diagnose), then 4g (History), then round R+1

#### 4f. Diagnose (Before Round 2 ONLY)

If round R failed and R < max rounds, run the Diagnostician to analyze failures before re-dispatching Workers.

Read the diagnostician prompt template: `~/.claude/harness/diagnostician-prompt.md`

Launch a **general-purpose Agent**:
- **prompt**: The diagnostician prompt template + context:
  - "QA feedback: `.harness/team-round-{R}-feedback.md`"
  - "QA evidence traces: `.harness/traces/round-{R}-qa-evidence.md`"
  - "Architect plan: `.harness/team-plan.md`"
  - "Codebase context: `.harness/team-context.md`"
  - "Round: {R}"
  - "Write diagnosis to `.harness/team-diagnosis-round-{R}.md`"
  - "IMPORTANT: Map each root cause to the Worker who owns the affected files (use file ownership from team-plan.md). This helps the orchestrator re-dispatch only the relevant Workers."
- **description**: "harness-team diagnostician round {R}"

After completion, use the diagnosis to inform Round 2 re-dispatch logic:

**Round 2 re-dispatch logic (diagnosis-enhanced)**:
1. Read `.harness/team-diagnosis-round-{R}.md` for root cause → file mapping
2. Map each root cause to the Worker who owns the affected file(s) (from Architect's plan file ownership map)
3. Re-dispatch ONLY Workers whose files have root causes. Workers with all-PASS files are NOT re-dispatched.
4. Include the relevant root cause analysis (not just symptoms) in each re-dispatched Worker's prompt:
   - "Read the diagnosis at `.harness/team-diagnosis-round-{R}.md` — fix the ROOT CAUSES identified for your files, not just the symptoms."
5. If a root cause spans files owned by multiple Workers, assign it to the Integrator instead.

#### 4g. Accumulate History (Every Round)

Append to `.harness/team-history.md`:

```markdown
## Round {R}
- **Scores**: [criterion: score pairs]
- **Workers dispatched**: [which workers ran this round]
- **Root causes identified**: [from diagnosis if available]
- **Decision**: PASS → Phase 5 / Continue to Round {R+1}
```

---

## Phase 4-post: Artifact Validation

```bash
MISSING=0
# Core artifacts
for f in team-prompt.md team-context.md team-plan.md team-integration-report.md; do
  [ ! -f ".harness/$f" ] && echo "MISSING: .harness/$f" && MISSING=$((MISSING+1))
done
# Worker progress files
for i in $(seq 0 {N}); do
  [ ! -f ".harness/team-worker-${i}-progress.md" ] && echo "MISSING: .harness/team-worker-${i}-progress.md" && MISSING=$((MISSING+1))
done
# QA per round
for R in $(seq 1 {completed_rounds}); do
  [ ! -f ".harness/team-round-${R}-feedback.md" ] && echo "MISSING: .harness/team-round-${R}-feedback.md" && MISSING=$((MISSING+1))
done
# History
[ ! -f ".harness/team-history.md" ] && echo "MISSING: .harness/team-history.md" && MISSING=$((MISSING+1))
echo "Artifacts: $MISSING missing"
```

Include artifact status in the Summary.

---

## Phase 5: Summary

```
## Harness-Team Build Complete

**Rounds**: {R}/2
**Workers**: {N}
**Status**: PASS / PARTIAL

### Final Scores
| Criterion | Score | Status |
|-----------|-------|--------|
| Completeness | X/10 | |
| Functionality | X/10 | |
| Code Quality | X/10 | |
| Visual Design | X/10 | (if UI) |

### Worker Summary
| Worker | Files | Status | Key Output |
|--------|-------|--------|-----------|
| W0 (Foundation) | X files | DONE | [what was built] |
| W1 | X files | DONE | [what was built] |
| W2 | X files | DONE | [what was built] |

### Integration Summary
- Conflicts resolved: X
- Duplicates consolidated: X
- Wave 3 tasks completed: X/Y

### Remaining Issues
[From last QA report]

### Artifacts
- Context: `.harness/team-context.md`
- Plan: `.harness/team-plan.md`
- Integration: `.harness/team-integration-report.md`
- Final QA: `.harness/team-round-{R}-feedback.md`
- Worker progress: `.harness/team-worker-{0..N}-progress.md`
```

---

## Critical Rules

1. **Each agent = separate Agent tool call** with fresh context.
2. **ALL inter-agent communication through `.harness/team-` files only.**
3. **Wave 2 Workers are launched SIMULTANEOUSLY in one message.** This is the core parallelism.
4. **No two Workers may modify the same file.** The Architect ensures this; the Integrator verifies.
5. **Wave 1 MUST complete before Wave 2 starts.** Foundation dependencies are sequential.
6. **ALWAYS present the Architect's plan to the user and wait for approval.**
7. **Workers CANNOT self-certify.** The Integrator verifies integration; QA verifies quality.
8. **Read prompt templates from `~/.claude/harness/`** before spawning each agent.
9. **Worker model selection**: Use `haiku` for 1-2 file mechanical tasks, `sonnet` for standard work, `opus` for complex judgment calls. Pass model hint in Agent tool call.

## Cost Awareness

| Workers | Typical Duration | Agent Calls |
|---------|-----------------|-------------|
| 2 | 15-30 min | 6-10 (scout + architect + [W0 + W1-2 + integrator + QA] × 1-2) |
| 3 | 20-40 min | 7-12 |
| 5 | 25-50 min | 9-16 |
