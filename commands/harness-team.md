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
  +- Phase 4-audit: Auditor    -> Cross-verification (conditional)
  +- Phase 5: Summary          -> Final report
```

## Arguments

- First argument: task description (required)
- `--agents N`: number of parallel Workers in Wave 2 (default 3, max 5)

---

## Phase 0.5: Security Triage

After confirming this is a build request (Phase 0), determine the security sensitivity.

### Classification

Analyze `$ARGUMENTS` for security-sensitive keywords:

**HIGH sensitivity** (any match triggers HIGH):
- Authentication/Authorization: auth, login, password, token, jwt, session, permissions, role, RBAC, admin, sudo
- Financial: payment, billing, stripe, credit, invoice, transaction
- Cryptography: crypto, encrypt, decrypt, key, certificate, hash, salt
- Data privacy: PII, GDPR, personal data, email, phone, address
- Infrastructure: infra, deploy, CI/CD, pipeline, docker, k8s, terraform
- Secrets: .env, secret, credential, API key

**MEDIUM sensitivity** (if no HIGH keywords):
- API: endpoint, route, middleware, controller, handler
- Data: database, schema, migration, query, model
- Network: CORS, header, cookie, webhook, external, integration
- File handling: upload, download, file, stream

**LOW sensitivity** (if no HIGH or MEDIUM keywords):
- UI: component, style, CSS, layout, animation, color, font
- Docs: README, docs, comment, typo, format
- Quality: lint, test, refactor (UI-only), i18n

### Write Triage Result

```bash
cat > .harness/security-triage.md << 'HEREDOC'
# Security Triage
- sensitivity: {HIGH/MEDIUM/LOW}
- keywords_matched: [{list}]
- sentinel_active: {true/false}
- qa_security_track: {true/false}
- auditor_active: {true/false}
HEREDOC
```

**Activation rules** (team builds are always Scale L):
- HIGH → sentinel_active: true, qa_security_track: true, auditor_active: true
- MEDIUM → sentinel_active: true, qa_security_track: true, auditor_active: false
- LOW → sentinel_active: false, qa_security_track: false, auditor_active: false

### Announce to User

```
보안 민감도: {HIGH/MEDIUM/LOW} — {matched keywords}
Sentinel: {활성화/비활성화}, QA Security Track: {활성화/비활성화}
```

### Post-Scout Re-evaluation

After Phase 2 (Scout) completes, re-read `.harness/team-context.md` and check the files identified:
- If files include paths containing `auth/`, `payment/`, `security/`, `.env`, `credential` → upgrade to HIGH
- If files include paths containing `api/`, `routes/`, `middleware/`, `model/` → upgrade to at least MEDIUM
- Update `.harness/security-triage.md` if sensitivity increased. Notify user: "보안 민감도가 {OLD} → {NEW}로 상향되었습니다."

---

## Phase 1: Setup

Read the session protocol reference: `~/.claude/harness/references/session-protocol.md`

### 1a. Session Recovery Check

Before creating `.harness/`, check for an existing session:

1. If `.harness/session-state.md` exists:
   - Read it and verify referenced artifacts exist on disk
   - Present to user: **"이전 세션이 감지되었습니다. Phase {phase}, {last_completed_agent} 완료 후 중단. 이어서 진행할까요?"**
   - If **resume**: skip to the phase AFTER `last_completed_agent`
   - If **restart**: `mv .harness/ .harness-backup-$(date +%s)/` and continue to 1b
2. If no session-state.md: continue to 1b

### 1b. Fresh Setup

```bash
mkdir -p .harness/traces
```

Write the user's request and agent count to `.harness/team-prompt.md`.
Initialize session state and event log:
```bash
cat > .harness/session-state.md << 'HEREDOC'
# Session State
- pipeline: harness-team
- scale: L
- phase: 1
- round: 1
- last_completed_agent: setup
- last_completed_at: {ISO8601}
- status: IN_PROGRESS
- artifacts_written:
  - .harness/team-prompt.md
HEREDOC
echo "# Session Events" > .harness/session-events.md
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] setup | done | team-prompt.md | Team build, {N} workers" >> .harness/session-events.md
```

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

Launch a **general-purpose Agent** with subagent_type `Explore` and **model `sonnet`**:
- **prompt**: The scout prompt template + context:
  - "Project directory: `{cwd}`"
  - "User's request: `{$ARGUMENTS}`"
  - "Scale: L (team builds are always large-scale)"
  - "Write output to `.harness/team-context.md`"
  - If FIX/MODIFY: Deep Dive instruction (see above)
- **description**: "harness-team scout"
- **model**: `sonnet`

After Scout completes, update session state and event log:
```bash
sed -i '' 's/last_completed_agent: .*/last_completed_agent: scout/' .harness/session-state.md
sed -i '' "s/last_completed_at: .*/last_completed_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)/" .harness/session-state.md
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] scout | done | team-context.md | {summary}" >> .harness/session-events.md
```

---

## Phase 3: Architect

Read the architect prompt template: `~/.claude/harness/architect-prompt.md`

Launch a **general-purpose Agent** (inherit parent model — architectural decisions are critical):
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
- After approval, update session state and event log:
  ```bash
  sed -i '' 's/phase: .*/phase: 3/' .harness/session-state.md
  sed -i '' 's/last_completed_agent: .*/last_completed_agent: architect/' .harness/session-state.md
  sed -i '' "s/last_completed_at: .*/last_completed_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)/" .harness/session-state.md
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] architect | done | team-plan.md | {N} workers, {wave_count} waves" >> .harness/session-events.md
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] approval | user | — | Plan approved" >> .harness/session-events.md
  ```

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

#### 4b. Wave 2 — Implementation (Parallel + Worktree Isolation)

Launch N Worker agents **simultaneously in a single message**, each with **`isolation: "worktree"`**:

For each Worker i (1 to N):
- **prompt**: The worker prompt template + Worker i's brief from `plan.md`:
  - "You are Worker {i}. Your brief is in `.harness/team-plan.md` under Worker {i}."
  - "Codebase context: `.harness/team-context.md`"
  - "Wave 1 outputs are available — read-only."
  - "You are running in an isolated worktree. Implement your files, run build/test to verify, and return your progress report as your final message."
  - If R > 1 (**Selective Context Protocol**):
    - "**PRIMARY**: `.harness/team-diagnosis-round-{R-1}.md` — root cause analysis for your files."
    - "**SECONDARY**: `.harness/team-plan.md` — your brief."
    - "**ON-DEMAND**: `.harness/team-round-{R-1}-feedback.md` — only if diagnosis is insufficient."
    - "Fix ROOT CAUSES from the diagnosis, not symptoms."
  - If R == 1: "Write progress to `.harness/team-worker-{i}-progress.md`"
- **description**: "harness-team worker {i}"
- **isolation**: `"worktree"`
- **model**: Use `haiku` for 1-2 file mechanical tasks, `sonnet` for standard work, inherit parent for complex judgment calls (per Architect's plan complexity rating).

**All N Workers must complete before proceeding.**

After all Workers complete:
1. **Collect worktree results**: Each Worker returns `{ path, branch }` if changes were made.
2. **Write progress files**: For each Worker, write `.harness/team-worker-{i}-progress.md` from the Worker's result message.
3. **Merge Worker branches** into main working tree:
   - **If Sentinel is active** (`sentinel_active: true` in `.harness/security-triage.md`): **DO NOT merge yet.** Proceed to 4b-post (Per-Worker Sentinel Gate) first. Merging happens there after Sentinel clearance.
   - **If Sentinel is inactive**: Merge directly:
     ```bash
     # For each Worker branch with changes:
     git merge {worker-branch} --no-ff -m "Merge Worker {i}: {brief description}"
     ```
     If merge conflicts occur (should be rare with proper file ownership), note them for the Integrator.
4. **Update event log**:
   ```bash
   echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] workers:r{R} | done | team-worker-{1..N}-progress.md | {N} workers, {merged_count} branches merged" >> .harness/session-events.md
   ```
5. Check statuses:
   - All DONE → proceed to Sentinel Gate (4b-post) or Wave 3
   - Any DONE_WITH_CONCERNS → note concerns for Integrator
   - Any NEEDS_CONTEXT → provide context and re-dispatch that Worker (without worktree)
   - Any BLOCKED → assess and escalate to user if needed

#### 4b-post. Per-Worker Sentinel Gate (Conditional)

**Skip if**: `.harness/security-triage.md` shows `sentinel_active: false`

**CRITICAL**: Sentinel runs BEFORE merging Worker branches. This ensures contaminated changes never reach the main tree.

After all Workers complete but BEFORE merging any Worker branches:

For each Worker i that returned changes (has a branch):

Launch a **general-purpose Agent** with **model `sonnet`**:
- **prompt**: The sentinel prompt template (`~/.claude/harness/sentinel-prompt.md`) + context:
  - "Team plan: `.harness/team-plan.md` — file ownership assignments for Worker {i}"
  - "Worker {i} branch: `{worker-branch-i}` at path `{worktree-path-i}`"
  - "Worker {i} progress (from agent result): `{worker-i-result-text}`"
  - "Containment reference: `~/.claude/harness/references/agent-containment.md`"
  - "Security triage: `.harness/security-triage.md`"
  - "Round number: {R}"
  - "Mode: TEAM_PER_WORKER — inspect this single Worker's branch diff. Check:"
  - "  1. Files changed are within Worker {i}'s assigned ownership from team-plan.md"
  - "  2. No forbidden commands in the branch diff (grep the diff, not just progress)"
  - "  3. No credential exposure in changed files"
  - "  4. No prompt injection patterns in source code"
  - "  5. No external network calls (curl, wget, gh gist) in the diff"
  - "  6. git diff --stat of branch matches Worker's claimed file list"
  - "Write report to `.harness/sentinel-worker-{i}-round-{R}.md`"
- **description**: "harness-team sentinel worker {i} round {R}"
- **model**: `sonnet`

**Note**: Per-Worker Sentinels can run in **parallel** (multiple Agent calls in one message), since each inspects an independent branch.

After all per-Worker Sentinels complete, collect verdicts:

| Verdict | Action |
|---------|--------|
| **CLEAR** | Merge: `git merge {worker-branch-i} --no-ff -m "Merge Worker {i}: {brief description}"` |
| **WARN** | Merge, note warnings for Integrator context |
| **BLOCK** | **Do NOT merge.** Discard branch: `git branch -D {worker-branch-i}`. Report to user. |

If any Worker is BLOCKed:
```bash
# Discard offending branch (changes never reach main tree)
git branch -D {blocked-worker-branch} 2>/dev/null
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] sentinel:worker-{i}:r{R} | BLOCK | sentinel-worker-{i}-round-{R}.md | {violation summary}" >> .harness/session-events.md
```
- Report to user: **"Sentinel BLOCK: Worker {i}가 보안 경계를 위반했습니다. 해당 브랜치는 폐기됩니다."**
- If BLOCKed Worker's files are critical for integration: re-dispatch that Worker only (fresh worktree) with Sentinel report as context
- If non-critical: proceed without them, note in Integrator context

Only CLEAR/WARN branches are merged. Update session state:
```bash
sed -i '' 's/last_completed_agent: .*/last_completed_agent: sentinel/' .harness/session-state.md
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] sentinel:team:r{R} | done | sentinel-worker-{1..N}-round-{R}.md | CLEAR:{X} WARN:{Y} BLOCK:{Z}" >> .harness/session-events.md
```

**If Sentinel is inactive** (sentinel_active: false): skip this section entirely and merge Worker branches directly as described in step 3 of Wave 2.

#### 4c. Wave 3 — Integration

Launch a **general-purpose Agent** with **model `sonnet`**:
- **prompt**: The integrator prompt template + context:
  - "Architect's plan: `.harness/team-plan.md`"
  - "Worker progress reports: `.harness/team-worker-{0..N}-progress.md`"
  - "Codebase context: `.harness/team-context.md`"
  - "Write output to `.harness/team-integration-report.md`"
  - If R > 1: "Previous QA feedback: `.harness/team-round-{R-1}-feedback.md`"
  - "NOTE: Worker branches have already been merged by the orchestrator. If merge conflicts were noted, resolve them as part of integration."
  - "IMPORTANT: Perform CODE HYGIENE on all Worker-changed files: remove console.log/debug, remove TODO/FIXME comments, remove commented-out code, verify naming matches context.md conventions, check for unused imports. Report hygiene issues found/fixed in the integration report."
- **description**: "harness-team integrator"
- **model**: `sonnet`

After Integrator completes, update event log:
```bash
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] integrator:r{R} | done | team-integration-report.md | {summary}" >> .harness/session-events.md
```

After completion:
- Read `.harness/team-integration-report.md`
- Verify: "Ready for QA: YES/NO"
- If NO: report issues to user and assess whether to proceed

#### 4d. QA

Read the QA prompt template: `~/.claude/harness/qa-prompt.md`

Launch a **general-purpose Agent** with **model `sonnet`**:
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
- **model**: `sonnet`

After QA completes, update event log:
```bash
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] qa:r{R} | {pass/fail} | team-round-{R}-feedback.md | scores: {scores}" >> .harness/session-events.md
```

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

Launch a **general-purpose Agent** (inherit parent model) with **`run_in_background: true`**:
- **prompt**: The diagnostician prompt template + context:
  - "QA feedback: `.harness/team-round-{R}-feedback.md`"
  - "QA evidence traces: `.harness/traces/round-{R}-qa-evidence.md`"
  - "Event log: `.harness/session-events.md`"
  - "Architect plan: `.harness/team-plan.md`"
  - "Codebase context: `.harness/team-context.md`"
  - "Round: {R}"
  - "Write diagnosis to `.harness/team-diagnosis-round-{R}.md`"
  - "IMPORTANT: Map each root cause to the Worker who owns the affected files (use file ownership from team-plan.md). This helps the orchestrator re-dispatch only the relevant Workers."
- **description**: "harness-team diagnostician round {R}"
- **run_in_background**: `true`

While Diagnostician runs in background:
1. Write History entry (4g)
2. Report QA scores to user
3. When Diagnostician notification arrives → read diagnosis, report root cause summary

After Diagnostician completes, update event log:
```bash
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] diagnostician:r{R} | done | team-diagnosis-round-{R}.md | {root_cause_count} root causes" >> .harness/session-events.md
```

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
# Auditor artifact (if auditor was active)
if grep -q 'auditor_active: true' .harness/security-triage.md 2>/dev/null; then
  [ ! -f ".harness/auditor-report.md" ] && echo "MISSING: .harness/auditor-report.md" && MISSING=$((MISSING+1))
fi
echo "Artifacts: $MISSING missing"
```

Include artifact status in the Summary.

---

## Phase 4-audit: Auditor Verification (Conditional)

**Skip if**: `.harness/security-triage.md` shows `auditor_active: false`

After the Build waves and QA loop exit (PASS or max rounds), run the Auditor for cross-verification.

Read the auditor prompt template: `~/.claude/harness/auditor-prompt.md`

Launch a **general-purpose Agent** with **model `sonnet`**:
- **prompt**: The auditor prompt template + context:
  - "Team plan: `.harness/team-plan.md`"
  - "Worker progress reports: `.harness/team-worker-{0..N}-progress.md`"
  - "Integration report: `.harness/team-integration-report.md`"
  - "QA feedback files: `.harness/team-round-{1..R}-feedback.md`"
  - "Sentinel reports: `.harness/sentinel-worker-{i}-round-{R}.md` (if exist)"
  - "Build history: `.harness/team-history.md`"
  - "Total rounds completed: {R}"
  - "Write your report to `.harness/auditor-report.md`"
- **description**: "harness-team auditor"
- **model**: `sonnet`

After Auditor completes:
1. Read `.harness/auditor-report.md`
2. Extract integrity verdict: HIGH / MEDIUM / LOW
3. If LOW: **"Auditor: LOW integrity 탐지. 수동 검증을 권장합니다."**
4. Include integrity verdict in Phase 5 Summary

Update event log:
```bash
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] auditor | {verdict} | auditor-report.md | integrity: {HIGH/MEDIUM/LOW}" >> .harness/session-events.md
```

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

### Integrity
**Integrity**: {HIGH/MEDIUM/LOW} (from Auditor, if active; otherwise "N/A — Auditor inactive")

### Artifacts
- Context: `.harness/team-context.md`
- Plan: `.harness/team-plan.md`
- Integration: `.harness/team-integration-report.md`
- Final QA: `.harness/team-round-{R}-feedback.md`
- Worker progress: `.harness/team-worker-{0..N}-progress.md`
```

After presenting the Summary, finalize session:
```bash
sed -i '' 's/status: IN_PROGRESS/status: COMPLETED/' .harness/session-state.md
sed -i '' 's/phase: .*/phase: 5/' .harness/session-state.md
sed -i '' "s/last_completed_at: .*/last_completed_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)/" .harness/session-state.md
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] summary | done | — | Team pipeline complete, status: {PASS/PARTIAL}" >> .harness/session-events.md
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
9. **Worker model selection**: Use `haiku` for 1-2 file mechanical tasks, `sonnet` for standard work, inherit parent for complex judgment calls. Pass `model` parameter in Agent tool call.
10. **Wave 2 Workers use `isolation: "worktree"`** for true parallel safety. Orchestrator merges branches before Integrator runs.
11. **Session state and event log are updated after EVERY agent.** See `~/.claude/harness/references/session-protocol.md`.
12. **Model selection follows the protocol**: Scout → `sonnet`; Architect/Diagnostician → inherit parent; Workers → per complexity; Integrator/QA → `sonnet`.
13. **Round 2 Workers use Selective Context**: PRIMARY (diagnosis), SECONDARY (plan), ON-DEMAND (feedback).
14. **Diagnostician runs in background** (`run_in_background: true`). History and user reporting proceed in parallel.
15. **Per-Worker Sentinel runs AFTER Workers complete, BEFORE branch merging** (when active). A BLOCK verdict discards the Worker's branch — contaminated code never reaches the main tree.
16. **Security Triage runs in Phase 0.5** after the Guard Clause. It determines whether Sentinel is activated. Re-evaluate after Scout if file paths suggest higher sensitivity.
17. **Sentinel model is `sonnet`** — checklist-driven pattern matching, not deep reasoning.
18. **Sentinel agents for different Workers run in parallel** — each inspects an independent branch, no cross-dependencies.
19. **Auditor runs AFTER the final QA round, BEFORE Summary** (when active).
20. **LOW integrity verdict blocks auto-commit.** User must verify manually.

## Cost Awareness

| Workers | Typical Duration | Agent Calls |
|---------|-----------------|-------------|
| 2 | 15-30 min | 6-10 (scout + architect + [W0 + W1-2 + integrator + QA] × 1-2) |
| 3 | 20-40 min | 7-12 |
| 5 | 25-50 min | 9-16 |
