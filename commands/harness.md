---
description: "Adaptive multi-agent builder pipeline (SINGLE: Scout → Planner → Builder → Sentinel → Refiner → QA | TEAM: Scout → Planner/Architect → Workers(N) → Sentinel → Integrator → QA) with Security Triage, Diagnostician, and Auditor. Supports S/M/L scale with auto SINGLE/TEAM mode selection."
---

# Harness: Autonomous Builder (v3)

> Anthropic "Harness Design for Long-Running Apps" multi-agent architecture.
> SINGLE mode: Scout → Planner → Builder → Refiner → QA with file-based handoffs.
> TEAM mode: Scout → Planner/Architect → Workers(N) → Sentinel → Integrator → QA with worktree isolation.

## Arguments

- First argument: task description (required)
- `--workers N`: Force TEAM mode with N parallel workers (default 3, max 5). Only applicable to Scale L.

## User Request

$ARGUMENTS

## Phase 0: Triage

Detect the session's capability tier, then classify the request into a scale. Together they determine the protocol path.

### Capability Detection

Run this step FIRST, before scale classification. See `harness/references/session-protocol.md` §9 for authoritative rules.

1. If `CLAUDEX_TIER_OVERRIDE` is set to `standard`, `advanced`, or `elite` → use that value.
2. Otherwise, if the runtime model identifier appears in the comma-separated `CLAUDEX_ELITE_MODELS` env var → tier = `Elite`.
3. Otherwise, apply name-based fallback:
   - identifier contains `sonnet` or `haiku` → `Standard`
   - identifier contains `opus` → `Advanced`
   - unknown → `Standard` (conservative default)

**Announce the detected tier in a single line** (do NOT reveal the model identifier):

```
tier: {Standard|Advanced|Elite}
```

Persist the tier to `.harness/session-state.md` under a `tier:` field so all downstream agents can read it. Pipeline behavior (round limits, QA threshold, Sentinel/Auditor activation, Scale thresholds) consults `harness/references/tier-matrix.md`.

### Non-Build Requests (EXIT)

If the request is a question, audit, or configuration change (not a build/fix/implement request):
- Respond directly as a normal conversation
- Do NOT execute any harness phases

### Scale Classification

Analyze `$ARGUMENTS` and classify. Thresholds depend on the detected tier — read `harness/references/tier-matrix.md` for the authoritative table. Summary:

| Scale | Standard / Advanced | Elite |
|-------|---------------------|-------|
| **S** (Small) | 1–2 file changes, bug fix, config tweak | 1–5 file changes |
| **M** (Medium) | 3–5 file changes, module-level work | 3–10 file changes |
| **L** (Large) | 6+ files, multi-module, new application | 11+ files |

Examples (tier-agnostic):
- S — "Fix the login button 404", "Update the API timeout to 30s"
- M — "Add password reset flow", "Refactor auth to use JWT"
- L — "Build a dashboard app", "Rewrite the payment system"

**Decision rule**: When in doubt between two scales, pick the smaller one. The QA loop will catch if more work is needed.

Announce the classification to the user:

```
Scale: [S/M/L] — [one-line rationale]
```

Then proceed to Phase 0.5 with the classified scale.

---

## Phase 0.5: Security Triage

After Scale classification, determine the security sensitivity of the request.

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

**Activation rules (tier-aware — see `harness/references/tier-matrix.md`):**

Base rules (Standard / Advanced):
- HIGH → sentinel_active: true, qa_security_track: true, auditor_active: true
- MEDIUM → sentinel_active: {true if Scale L, false otherwise}, qa_security_track: true, auditor_active: {true if Scale M/L, false otherwise}
- LOW → sentinel_active: false, qa_security_track: false, auditor_active: false

Elite-tier overrides (apply in addition to base rules):
- MEDIUM → sentinel_active: true (regardless of scale), auditor_active: true
- LOW + Scale L → sentinel_active: true
- Any sensitivity → auditor_active: true (Elite Auditor is always on)

### Announce to User

```
보안 민감도: {HIGH/MEDIUM/LOW} — {matched keywords}
Sentinel: {활성화/비활성화}, QA Security Track: {활성화/비활성화}
```

### Post-Scout Re-evaluation

After Phase 2 (Scout) completes, re-read `.harness/build-context.md` and check the "Files to Change" section:
- If files include paths containing `auth/`, `payment/`, `security/`, `.env`, `credential` → upgrade to HIGH
- If files include paths containing `api/`, `routes/`, `middleware/`, `model/` → upgrade to at least MEDIUM
- Update `.harness/security-triage.md` if sensitivity increased. Notify user: **"보안 민감도가 {OLD} → {NEW}로 상향되었습니다."**

Then proceed to Phase 0.7 (Phase-Book Planner).

---

## Phase 0.7: Phase-Book Planner (Meta-Loop entry)

Meta-Loop is the default execution model for every `/harness` invocation. Before running the phase-internal pipeline, decompose the user's request into a phase book. Small requests produce a 1-phase book (backward-compatible with the pre-Meta-Loop flow); large requests produce multiple phases.

### 0.7a. Resume detection

Before launching the Phase-Book Planner:

1. If `.harness/phase-book.md` exists and its frontmatter shows `status: in_progress` or `status: paused`:
   - Parse `current_phase`, `total_phases`, `status`.
   - Ask the user: **"이전 phase-book이 감지되었습니다. Phase {current}/{total} ({status}). 이어서 진행할까요? (Y / N / reset)"**
   - `Y` → skip 0.7b; jump to Meta-Loop with `i = current_phase`.
   - `N` → exit (phase-book stays paused; user can resume later).
   - `reset` → `mv .harness .harness-backup-$(date +%s)` and continue to 0.7b.
2. Otherwise continue to 0.7b.

### 0.7b. Launch Phase-Book Planner

Read the agent prompt: `~/.claude/harness/phase-book-planner-prompt.md`.

Launch a **general-purpose Agent** (model inherits parent — decomposition quality matters):
- **prompt**: The phase-book-planner prompt + context:
  - "User request: `.harness/build-prompt.md` (write $ARGUMENTS there first)."
  - "Scale: {S/M/L} (from Phase 0)."
  - "Tier: {Standard/Advanced/Elite} (from Phase 0, read `.harness/session-state.md`)."
  - "Security triage: `.harness/security-triage.md`."
  - "Reference: `harness/references/meta-loop-protocol.md`."
  - "Write the phase book to `.harness/phase-book.md`. Emit ONE announcement line."
- **description**: "phase-book planner"

### 0.7c. User approval gate

After the planner writes the phase-book, relay its announcement verbatim to the user and wait for approval:

- `Y` → set frontmatter `status: in_progress` (if still `pending`), proceed to Meta-Loop.
- `N` → set `status: paused`, exit.
- `edit` → print: "`.harness/phase-book.md` 를 수정한 후 다시 Y로 응답하세요." Wait.

This is the **only user gate** in the Meta-Loop. After approval, the loop runs to completion without further confirmation, pausing only on 3-retry exhaustion, cross-phase regression, Sentinel BLOCK, or budget stop.

---

## Architecture Overview

```
/harness <prompt> [--workers N]
  |
  +- Phase 0:    Triage                -> Capability tier + Scale S/M/L
  +- Phase 0.5:  Security Triage       -> LOW/MEDIUM/HIGH
  +- Phase 0.7:  Phase-Book Planner    -> .harness/phase-book.md (+ intent detection)
  |                                    -> user approves phase book
  +-------------------------------------------------------------------+
  |  Meta-Loop (repeats for each phase i in phase-book):              |
  |                                                                   |
  |    +- Phase 1: Setup              -> .harness/phase-{i}/          |
  |    |                                 (or .harness/ if total==1)   |
  |    +- Phase 2: Scout              -> build-context.md             |
  |    +- Phase 3: Planning           -> build-spec.md                |
  |    +- Phase 4: Build-Sentinel-    -> Mode-dependent (SINGLE/TEAM) |
  |    |   Refine-QA Loop                                             |
  |    +- Phase 4-audit: Auditor      -> Cross-verification            |
  |    +- Phase 4-verify:             -> phase-evidence-{i}.md         |
  |    |   Phase Verifier                PASS → advance / FAIL → retry |
  |    +- Cross-Phase Integrity Check                                 |
  |                                                                   |
  +-------------------------------------------------------------------+
  |
  +- Phase ∞-*: Commit / Push / Deploy / PR (intent-gated, terminal)
  +- Phase ∞:   Final Auditor + Summary
```

The phase-internal pipeline (Phase 1–Phase 4-audit) is unchanged for single-phase books. For multi-phase books it runs once per phase. All per-phase artifact paths are prefixed with `.harness/phase-{i}/` when `total_phases > 1`; when `total_phases == 1`, artifacts live directly under `.harness/` (backward compatibility).

Authoritative control-flow reference: `harness/phase-orchestrator-prompt.md`.

---

## Phase 1: Setup

> **Meta-Loop context**: Phase 1 runs at the start of each phase iteration. When `total_phases > 1`, prepend all artifact paths in Phases 1–4 with `.harness/phase-{i}/`. When `total_phases == 1`, paths remain `.harness/...` for backward compatibility.

Read the session protocol reference: `~/.claude/harness/references/session-protocol.md`

### 1a. Session Recovery Check

Before creating `.harness/`, check for an existing session:

1. If `.harness/session-state.md` exists:
   - Read it and verify referenced artifacts exist on disk
   - Present to user: **"이전 세션이 감지되었습니다. Phase {phase}, {last_completed_agent} 완료 후 중단. 이어서 진행할까요?"**
   - If **resume**: skip to the phase AFTER `last_completed_agent`, reading existing artifacts as context
   - If **restart**: `mv .harness/ .harness-backup-$(date +%s)/` and continue to 1b
2. If no session-state.md: continue to 1b

### 1b. Fresh Setup

1. Identify or create the project directory.
2. Run:
   ```bash
   mkdir -p .harness/traces
   git init 2>/dev/null || true
   ```
3. Write the user's original prompt (`$ARGUMENTS`) and the classified scale to `.harness/build-prompt.md`.
4. Initialize session state:
   ```bash
   cat > .harness/session-state.md << 'HEREDOC'
   # Session State
   - pipeline: harness
   - scale: {S/M/L}
   - phase: 1
   - round: 1
   - last_completed_agent: setup
   - last_completed_at: {ISO8601}
   - status: IN_PROGRESS
   - artifacts_written:
     - .harness/build-prompt.md
   HEREDOC
   ```
5. Initialize event log:
   ```bash
   echo "# Session Events" > .harness/session-events.md
   echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] setup | done | build-prompt.md | Scale {S/M/L}, harness pipeline" >> .harness/session-events.md
   ```

---

## Phase 2: Scout

Read the scout prompt template: `~/.claude/harness/scout-prompt.md`

The Scout explores the existing codebase BEFORE planning, so the Planner and Builder have full context.

### Request Type Detection (CRITICAL)

Before launching the Scout, classify the request type:

| Type | Signal | Scout Instruction |
|------|--------|-------------------|
| **FIX** | "수정", "fix", "bug", "안됨", "작동하지 않음", "비활성화", "차단" | Include Deep Dive Protocol |
| **MODIFY** | "변경", "modify", "refactor", "이관", "전환" | Include Deep Dive Protocol |
| **BUILD** | "추가", "구현", "만들어", "생성", "add", "implement", "create" | Standard scan only |

For FIX/MODIFY requests, append this instruction to the Scout prompt:
- "This is a FIX/MODIFICATION request. After the standard module scan, you MUST execute the **Deep Dive Protocol** described in the scout prompt. Trace the specific feature's data flow end-to-end, verify each flag/guard/condition with file:line evidence, and map behavior per user type/role. The Planner will reject unverified claims."

### Scale S — Targeted Scan

Launch a **general-purpose Agent** with subagent_type `Explore` and **model `sonnet`**:
- **prompt**: The scout prompt template + context:
  - "Project directory: `{cwd}`"
  - "User's request: `{$ARGUMENTS}`"
  - "Scale: S — scan only the 2-5 files directly relevant to the request."
  - "Write output to `.harness/build-context.md`"
  - If FIX/MODIFY: Deep Dive instruction (see above)
- **description**: "harness scout (S)"
- **model**: `sonnet`

### Scale M — Module Scan

Launch a **general-purpose Agent** with subagent_type `Explore` and **model `sonnet`**:
- **prompt**: The scout prompt template + context:
  - "Project directory: `{cwd}`"
  - "User's request: `{$ARGUMENTS}`"
  - "Scale: M — scan the relevant module(s), 5-15 files."
  - "Write output to `.harness/build-context.md`"
  - If FIX/MODIFY: Deep Dive instruction (see above)
- **description**: "harness scout (M)"
- **model**: `sonnet`

### Scale L — Full Codebase Scan

Launch a **general-purpose Agent** with subagent_type `Explore` and **model `sonnet`**:
- **prompt**: The scout prompt template + context:
  - "Project directory: `{cwd}`"
  - "User's request: `{$ARGUMENTS}`"
  - "Scale: L — comprehensive codebase scan, 20-40 files."
  - "Write output to `.harness/build-context.md`"
  - If FIX/MODIFY: Deep Dive instruction (see above)
- **description**: "harness scout (L)"
- **model**: `sonnet`

After Scout completes:
1. Briefly confirm to the user: **"Scout 완료. 코드베이스 컨텍스트를 수집했습니다."** (No approval needed.)
2. Update session state and event log:
   ```bash
   sed -i '' 's/phase: .*/phase: 2/' .harness/session-state.md
   sed -i '' 's/last_completed_agent: .*/last_completed_agent: scout/' .harness/session-state.md
   sed -i '' "s/last_completed_at: .*/last_completed_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)/" .harness/session-state.md
   echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] scout | done | build-context.md | {summary}" >> .harness/session-events.md
   ```

---

## Phase 3: Planning

Read the planner prompt template: `~/.claude/harness/planner-prompt.md`

### Scale S — Scope Note

Do NOT spawn a Planner agent. Instead, the orchestrator writes `.harness/build-spec.md` directly, informed by `.harness/build-context.md`:

**CRITICAL**: Before writing the Scope Note, READ `.harness/build-context.md` thoroughly. For FIX/MODIFY requests, the "Feature Deep Dive" section contains verified findings — use ONLY those findings to determine files to change. Do NOT list files based on your own inference.

```markdown
# Scope Note

## Scale: S
## Task: [one-line description]

## Current State (Verified)
[For FIX/MODIFY: summarize Scout's Deep Dive findings with file:line citations]
- [Fact 1]: VERIFIED (file:line)
- [Fact 2]: NOT FOUND — [expected but missing]

## Files to Change: [list — MUST match Scout's verified findings]
## Existing Patterns to Follow: [key patterns from context.md]
## Success Criteria:
1. [testable criterion]
2. [testable criterion]
## Risks: [if any, otherwise "None"]
```

Present the scope note to the user and ask: **"Scope를 검토해주세요. 진행할까요?"**
**WAIT for user approval.**

### Scale M — Lite Planner

Launch a **general-purpose Agent** (inherit parent model — planning quality is critical):
- **prompt**: The planner prompt template + `"MODE: LITE. Scale is M."` + the user's request.
  - "Codebase context is at `.harness/build-context.md` — read it first to understand existing patterns, conventions, and reusable assets."
- **description**: "harness lite planner"
- The planner MUST write its output to `.harness/build-spec.md`

After completion:
- Read `.harness/build-spec.md`
- Present summary: feature count, changed files, test criteria
- Ask: **"Spec을 검토해주세요. 진행할까요?"**
- **WAIT for user approval.**
- After approval, update session state and event log:
  ```bash
  sed -i '' 's/phase: .*/phase: 3/' .harness/session-state.md
  sed -i '' 's/last_completed_agent: .*/last_completed_agent: planner/' .harness/session-state.md
  sed -i '' "s/last_completed_at: .*/last_completed_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)/" .harness/session-state.md
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] planner | done | build-spec.md | {feature_count} features" >> .harness/session-events.md
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] approval | user | — | Spec approved" >> .harness/session-events.md
  ```

### Scale L — Full Planner

Launch a **general-purpose Agent**:
- **prompt**: The planner prompt template + `"MODE: FULL. Scale is L."` + the user's request.
  - "Codebase context is at `.harness/build-context.md` — read it first to understand existing patterns, conventions, and reusable assets."
- **description**: "harness full planner"
- The planner MUST write its output to `.harness/build-spec.md`

After completion:
- Read `.harness/build-spec.md`
- Present summary: feature count, key features, tech stack, AI integrations
- Ask: **"Spec을 검토해주세요. 진행할까요, 수정할 부분이 있나요?"**
- **WAIT for user approval.**
- After approval, update session state and event log (same as Scale M above).

### Build Mode Decision (Scale L only)

After the Planner completes and the user approves the spec:

1. If `--workers N` flag was provided: **Force TEAM mode** with N workers.
2. Otherwise, read `.harness/build-spec.md` for the Planner's Build Mode recommendation:
   - If Planner recommends TEAM: present to user: **"Planner가 TEAM 모드를 추천합니다 (Workers: {N}명). TEAM 모드로 진행할까요?"**
   - If Planner recommends SINGLE: proceed with SINGLE mode (default).
   - User can override in either direction.
3. Write the decision to `.harness/build-mode.md`:
   ```bash
   echo "mode: {SINGLE/TEAM}" > .harness/build-mode.md
   echo "workers: {N}" >> .harness/build-mode.md
   ```

---

## Phase 4: Build-Sentinel-Refine-QA Loop (Meta-Harness Enhanced)

### Build Mode Branch

Read `.harness/build-mode.md` (or default to SINGLE if file doesn't exist — Scale S/M always SINGLE).

**If SINGLE mode**: Follow the Build-Sentinel-Refine-QA loop below (existing content, unchanged).

**If TEAM mode**: Read and follow `~/.claude/harness/references/team-build-protocol.md`. The team protocol handles:
- Architect (wave planning)
- Workers (parallel, worktree isolation)
- Per-Worker Sentinel gate
- Branch merge (CLEAR only)
- Integrator (merge + hygiene)
- QA + Diagnostician (same as SINGLE mode)

After TEAM mode's QA completes, return here for Phase 4-audit (Auditor) and Phase 5 (Summary).

### SINGLE Mode: Build-Sentinel-Refine-QA

Read the builder, refiner, QA, and diagnostician prompt templates from `~/.claude/harness/`.

### Max rounds by tier × scale

Read the detected `tier:` from `.harness/session-state.md` (persisted in Phase 0) and consult `harness/references/tier-matrix.md`. Summary:

| Scale | Standard / Advanced | Elite | Refiner | QA Method | Diagnostician |
|-------|---------------------|-------|---------|-----------|--------------|
| S | 1 | 1 | Hygiene + pattern check only | Code review + build/test verification | Not used |
| M | 2 | 1 | Full checklist | Code review + build/test + Playwright (if UI exists) | Before round 2 (if ≥ 2 rounds) |
| L | 3 | 2 | Full checklist + security scan | Playwright mandatory | Before rounds 2 and 3 (if ≥ 2 rounds) |

**Escape hatch**: If the Diagnostician's report for round N includes `needs_extra_round: true` with a documented root cause the final round cannot resolve, the orchestrator MAY permit one additional round beyond the cap. Use sparingly; prefer pausing and asking the user for input.

### QA pass threshold (tier-aware)

| Tier | Pass Threshold |
|------|----------------|
| Standard | All criteria ≥ 7/10 |
| Advanced | All criteria ≥ 7/10 |
| Elite | All criteria ≥ 8/10 |

Propagate this threshold to the QA agent through its task description (`QA_PASS_THRESHOLD: 7` or `8`).

### For each round N:

#### 4-pre. Environment Snapshot (Every Round)

Before launching the Builder, capture the current project state. Run these commands and write output to `.harness/snapshot-round-{N}.md`:

```bash
mkdir -p .harness/traces
echo "# Environment Snapshot — Round {N}" > .harness/snapshot-round-{N}.md
echo "## Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> .harness/snapshot-round-{N}.md
echo "## Git State" >> .harness/snapshot-round-{N}.md
git diff --stat >> .harness/snapshot-round-{N}.md 2>/dev/null
echo "## Changed Files" >> .harness/snapshot-round-{N}.md
git diff --name-only >> .harness/snapshot-round-{N}.md 2>/dev/null
```

Then run the build and test commands from `build-context.md`, appending results:
- Build status: exit code + last 20 lines if failure
- Test status: exit code + pass/fail/skip summary
- Dev server status: running URL or "not running"

Pass this snapshot path to the Builder: "Environment snapshot: `.harness/snapshot-round-{N}.md`"

#### 4a. Build

Launch a **general-purpose Agent** (Scale S/M: **model `sonnet`**; Scale L: inherit parent):
- **prompt**: The builder prompt template + these context instructions:
  - "Codebase context: `.harness/build-context.md` — read it to understand existing patterns and reusable assets."
  - "Product spec: `.harness/build-spec.md` — your blueprint."
  - "Environment snapshot: `.harness/snapshot-round-{N}.md` — read this FIRST to understand current project state."
  - "Scale: {S/M/L}"
  - If N == 1: "This is a fresh build. Implement the changes described in the spec."
  - If N > 1 (**Selective Context Protocol**):
    - "**PRIMARY** (read FIRST): `.harness/diagnosis-round-{N-1}.md` — root cause analysis with file:line citations. `.harness/snapshot-round-{N}.md` — current project state."
    - "**SECONDARY** (reference): `.harness/build-spec.md` — the spec."
    - "**ON-DEMAND** (only if diagnosis is insufficient): `.harness/build-history.md`, `.harness/traces/round-{N-1}-qa-evidence.md`, `.harness/traces/round-{N-1}-execution-log.md`"
    - "Fix ROOT CAUSES from the diagnosis. Do not re-investigate from scratch."
  - "Write your progress to `.harness/build-progress.md`."
  - "Write your execution audit to `.harness/traces/round-{N}-execution-log.md` (see Execution Audit in builder prompt)."
  - Scale M/L only: "Start the dev server in background and note the URL in progress.md."
- **description**: "harness builder round {N}"
- **model**: Scale S/M → `sonnet`; Scale L → omit (inherit parent)

After Builder completes, update event log:
```bash
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] builder:r{N} | done | build-progress.md | {summary}" >> .harness/session-events.md
```

#### 4a-post. Sentinel Check (Conditional)

**Skip if**: `.harness/security-triage.md` shows `sentinel_active: false`

Read the sentinel prompt template: `~/.claude/harness/sentinel-prompt.md`

Launch a **general-purpose Agent** with **model `sonnet`**:
- **prompt**: The sentinel prompt template + these context instructions:
  - "Execution audit log: `.harness/traces/round-{N}-execution-log.md`"
  - "Build progress: `.harness/build-progress.md`"
  - "Product spec: `.harness/build-spec.md`"
  - "Containment reference: `~/.claude/harness/references/agent-containment.md`"
  - "Security triage: `.harness/security-triage.md`"
  - "Round number: {N}"
  - "Write your report to `.harness/sentinel-report-round-{N}.md`"
- **description**: "harness sentinel round {N}"
- **model**: `sonnet`

After Sentinel completes:
1. Read `.harness/sentinel-report-round-{N}.md`
2. Extract the verdict: BLOCK / WARN / CLEAR

**If BLOCK**:
- Update session protocol:
  ```bash
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] sentinel:r{N} | block | sentinel-report-round-{N}.md | {finding_count} CRITICAL findings, returning to Builder" >> .harness/session-events.md
  sed -i '' 's/last_completed_agent: .*/last_completed_agent: sentinel_block_r{N}/' .harness/session-state.md
  sed -i '' 's/last_completed_at: .*/last_completed_at: '"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'/' .harness/session-state.md
  ```
- Report to user: **"Sentinel BLOCK — {finding count} CRITICAL 보안 문제 탐지. Builder에게 반환합니다."**
- Pass sentinel report to Builder as additional context
- Re-launch Builder with:
  - "**SENTINEL BLOCK**: Read `.harness/sentinel-report-round-{N}.md`. Address ALL CRITICAL findings. Do NOT proceed with any other changes until all CRITICAL findings are resolved."
- After Builder re-completes, re-run Sentinel
- If BLOCK again after 2 consecutive attempts:
  ```bash
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] sentinel:r{N} | abort | sentinel-report-round-{N}.md | 2 consecutive BLOCKs, pipeline aborted" >> .harness/session-events.md
  sed -i '' 's/last_completed_agent: .*/last_completed_agent: sentinel_abort_r{N}/' .harness/session-state.md
  sed -i '' 's/last_completed_at: .*/last_completed_at: '"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'/' .harness/session-state.md
  ```
  Abort pipeline, report to user: **"2회 연속 Sentinel BLOCK. 수동 검토가 필요합니다."**

**If WARN**:
- Report to user: **"Sentinel WARN — {finding count} HIGH 수준 발견. Refiner에게 전달합니다."**
- Pass sentinel report path to Refiner prompt: "Also read `.harness/sentinel-report-round-{N}.md` — Sentinel flagged {count} HIGH items."
- Proceed to Refiner (4b)

**If CLEAR**:
- Proceed to Refiner (4b) normally

Update event log:
```bash
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] sentinel:r{N} | {verdict} | sentinel-report-round-{N}.md | {summary}" >> .harness/session-events.md
```

#### 4b. Refine

Launch a **general-purpose Agent** with **model `sonnet`**:
- **prompt**: The refiner prompt template + these context instructions:
  - "Codebase context: `.harness/build-context.md`"
  - "Product spec: `.harness/build-spec.md`"
  - "Build progress: `.harness/build-progress.md`"
  - "Scale: {S/M/L}"
  - "Round: {N}"
  - If N > 1: "Previous QA feedback: `.harness/build-round-{N-1}-feedback.md`"
  - "Apply fixes directly to the code. Write your report to `.harness/build-refiner-report.md`."
  - "Append your refinement actions to `.harness/traces/round-{N}-execution-log.md` under a '## Refiner Actions' header."
  - Scale M/L: "Also write execution trace to `.harness/traces/round-{N}-refiner-trace.md` (build/test results after your fixes)."
- **description**: "harness refiner round {N}"
- **model**: `sonnet`

After Refiner completes, update event log:
```bash
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] refiner:r{N} | done | build-refiner-report.md | {summary}" >> .harness/session-events.md
```

#### 4c. Verify (Scale M/L only)

After the refiner agent completes:
1. Read `.harness/build-progress.md` to find the dev server URL
2. Verify the server is responding: `curl -s -o /dev/null -w '%{http_code}' <URL>`
3. If server is not running, attempt to start it based on progress.md instructions
4. If still not running after M scale, note as critical failure for QA

#### 4d. QA

Launch a **general-purpose Agent** with **model `sonnet`**:
- **prompt**: The QA prompt template + these context instructions:
  - "Product spec: `.harness/build-spec.md`"
  - "Refiner report: `.harness/build-refiner-report.md`"
  - "Scale: {S/M/L}"
  - "Round number: {N}"
  - "Write your QA report to `.harness/build-round-{N}-feedback.md`"
  - Scale S: `"QA_MODE: CODE_REVIEW. No Playwright. Verify via code review, build output, and test results."`
  - Scale M: `"QA_MODE: STANDARD. Use Playwright if the app has UI. Otherwise code review + build/test."` + "App URL: `{URL from progress.md}`" + `"Write evidence traces to .harness/traces/round-{N}-qa-evidence.md for FAIL/PARTIAL results."`
  - Scale L: `"QA_MODE: FULL. Playwright is MANDATORY."` + "App URL: `{URL from progress.md}`" + `"Write evidence traces to .harness/traces/round-{N}-qa-evidence.md for ALL results."`
- **description**: "harness QA round {N}"
- **model**: `sonnet`

After QA completes, update event log:
```bash
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] qa:r{N} | {pass/fail} | build-round-{N}-feedback.md | scores: {scores}" >> .harness/session-events.md
```

#### 4e. Evaluate

After QA agent completes:
1. Read `.harness/build-round-{N}-feedback.md`
2. Extract scores for each criterion
3. Report to user briefly: round number, scores, pass/fail, key issues
4. **Decision** (evaluate in this order):
   - N == max rounds for this scale → go to 4g (History), then Phase 5 regardless of scores
   - ALL criteria >= 7/10 → **PASS** → go to 4g (History), then Phase 5
   - ANY criterion < 7/10 AND N < max rounds → **FAIL** → continue to 4f (Diagnose) if applicable, then 4g (History), then round N+1

#### 4f. Diagnose (Scale M/L, before round N+1 ONLY)

**Skip this step for Scale S** (only 1 round, no next-round Builder to inform).
**Skip this step if this was the final allowed round** (no next round to inform).

Read the diagnostician prompt template: `~/.claude/harness/diagnostician-prompt.md`

Launch a **general-purpose Agent** (inherit parent model — deep reasoning needed).
**Scale L**: use `run_in_background: true` and proceed to 4g (History) immediately. Scale M: foreground (default).

- **prompt**: The diagnostician prompt template + these context instructions:
  - "QA feedback: `.harness/build-round-{N}-feedback.md`"
  - "QA evidence traces: `.harness/traces/round-{N}-qa-evidence.md`"
  - "Execution audit log: `.harness/traces/round-{N}-execution-log.md`"
  - "Event log: `.harness/session-events.md`"
  - "Environment snapshot: `.harness/snapshot-round-{N}.md`"
  - "Build progress: `.harness/build-progress.md`"
  - "Codebase context: `.harness/build-context.md`"
  - "Round number: {N}"
  - If N > 1: "Previous diagnosis: `.harness/diagnosis-round-{N-1}.md`"
  - If N > 1: "Build history: `.harness/build-history.md`"
  - "Write your diagnosis to `.harness/diagnosis-round-{N}.md`"
- **description**: "harness diagnostician round {N}"
- **run_in_background**: Scale L only → `true`

**Scale L flow** (background Diagnostician):
1. Diagnostician runs in background
2. Proceed immediately to 4g (History) — does not depend on diagnosis
3. Report QA scores to user while Diagnostician works
4. When Diagnostician notification arrives → read diagnosis, report root cause summary

**Scale M flow** (foreground):
- After completion, read `.harness/diagnosis-round-{N}.md`
- Briefly report to user: root cause count, regression count (if any), top priority fix

After Diagnostician completes (either flow), update event log:
```bash
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] diagnostician:r{N} | done | diagnosis-round-{N}.md | {root_cause_count} root causes" >> .harness/session-events.md
```

#### 4g. Accumulate History (Every Round)

After Evaluate (and Diagnose if applicable), append to `.harness/build-history.md`:

```markdown
## Round {N}
- **Scores**: [criterion: score pairs from QA]
- **Verdict**: PASS / FAIL
- **Changes made**: [files changed in this round — from git diff or progress.md]
- **Issues found by QA**: CRITICAL: X, HIGH: Y, MEDIUM: Z
- **Root causes identified**: [from diagnosis if available, otherwise "N/A (Scale S)"]
- **What worked**: [improvements vs previous round, if applicable]
- **What regressed**: [score drops vs previous round, if applicable]
- **Decision**: PASS → Phase 5 / Continue to Round {N+1}
```

This file is cumulative — NEVER overwrite, only append. Create it on Round 1 with a header.

After History is written, update session state for the round transition:
```bash
sed -i '' "s/round: .*/round: {N+1}/" .harness/session-state.md
sed -i '' "s/last_completed_agent: .*/last_completed_agent: qa_round_{N}/" .harness/session-state.md
sed -i '' "s/last_completed_at: .*/last_completed_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)/" .harness/session-state.md
```

---

## Phase 4-post: Artifact Validation

After exiting the Build-Refine-QA loop (either PASS or max rounds reached), run a quick artifact check before generating the Summary. This is a bash check, not an agent call.

```bash
echo "## Artifact Validation"
MISSING=0

# Core artifacts (all scales)
for f in build-context.md build-spec.md build-prompt.md build-progress.md security-triage.md; do
  [ ! -f ".harness/$f" ] && echo "MISSING: .harness/$f" && MISSING=$((MISSING+1))
done

# Per-round artifacts
for N in $(seq 1 {completed_rounds}); do
  [ ! -f ".harness/build-round-${N}-feedback.md" ] && echo "MISSING: .harness/build-round-${N}-feedback.md" && MISSING=$((MISSING+1))
  [ ! -f ".harness/snapshot-round-${N}.md" ] && echo "MISSING: .harness/snapshot-round-${N}.md" && MISSING=$((MISSING+1))
done

# Scale M/L artifacts
if [ "{scale}" != "S" ]; then
  [ ! -f ".harness/build-refiner-report.md" ] && echo "MISSING: .harness/build-refiner-report.md" && MISSING=$((MISSING+1))
  [ ! -f ".harness/build-history.md" ] && echo "MISSING: .harness/build-history.md" && MISSING=$((MISSING+1))

  # Evidence traces (at least for failed rounds)
  for N in $(seq 1 {completed_rounds}); do
    [ ! -f ".harness/traces/round-${N}-qa-evidence.md" ] && echo "WARN: .harness/traces/round-${N}-qa-evidence.md not found (may be OK if all PASS)"
  done

  # Sentinel reports (if sentinel was active)
  if grep -q 'sentinel_active: true' .harness/security-triage.md 2>/dev/null; then
    for N in $(seq 1 {completed_rounds}); do
      [ ! -f ".harness/sentinel-report-round-${N}.md" ] && echo "WARN: .harness/sentinel-report-round-${N}.md not found (sentinel was active)"
    done
  fi
fi

# Diagnostician artifacts (M/L, round 2+)
if [ {completed_rounds} -gt 1 ] && [ "{scale}" != "S" ]; then
  for N in $(seq 1 $((completed_rounds-1))); do
    [ ! -f ".harness/diagnosis-round-${N}.md" ] && echo "MISSING: .harness/diagnosis-round-${N}.md" && MISSING=$((MISSING+1))
  done
fi

# Auditor artifact (if auditor was active)
if grep -q 'auditor_active: true' .harness/security-triage.md 2>/dev/null; then
  [ ! -f ".harness/auditor-report.md" ] && echo "MISSING: .harness/auditor-report.md" && MISSING=$((MISSING+1))
fi

echo "Artifacts: $MISSING missing"
```

Report the result to the user:
- 0 missing → **"Artifact validation: PASS"**
- Any missing → **"Artifact validation: [X] missing files"** + list them in the Summary

---

## Phase 4-audit: Auditor Verification (Conditional)

**Skip if**: `.harness/security-triage.md` shows `auditor_active: false`
**Skip for Scale S**: Auditor is only active for Scale M/L with MEDIUM/HIGH security sensitivity.

After the Build-Sentinel-Refine-QA loop exits (PASS or max rounds), run the Auditor for cross-verification.

Read the auditor prompt template: `~/.claude/harness/auditor-prompt.md`

Launch a **general-purpose Agent** with **model `sonnet`**:
- **prompt**: The auditor prompt template + context:
  - "Build progress: `.harness/build-progress.md`"
  - "Refiner report: `.harness/build-refiner-report.md`"
  - "QA feedback files: `.harness/build-round-{1..N}-feedback.md`"
  - "Execution logs: `.harness/traces/round-{1..N}-execution-log.md`"
  - "Sentinel reports: `.harness/sentinel-report-round-{1..N}.md` (if exist)"
  - "Product spec: `.harness/build-spec.md`"
  - "Build history: `.harness/build-history.md`"
  - "Total rounds completed: {N}"
  - "Write your report to `.harness/auditor-report.md`"
- **description**: "harness auditor"
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

## Phase 4-verify: Phase Verifier (Meta-Loop gate)

Runs after Phase 4-audit, before Phase 5. Decides whether the current phase passes its DoD or must be retried.

Read the agent prompt: `~/.claude/harness/phase-verifier-prompt.md`.
Read the protocol: `~/.claude/harness/references/phase-verification-protocol.md`.

Launch a **general-purpose Agent** with **model `sonnet`**:
- **prompt**: The phase-verifier prompt + context:
  - "Phase book: `.harness/phase-book.md`."
  - "Current phase: {i}. Phase name: {name from phase-book}."
  - "Phase artifacts: `.harness/phase-{i}/` (or `.harness/` if total_phases == 1)."
  - "Retry attempt: {1 | 2 | 3}."
  - "Tier: read from `.harness/session-state.md`."
  - "Write evidence to `.harness/phase-evidence-{i}.md`."
- **description**: "phase verifier (phase {i})"
- **model**: `sonnet`

### Branch on verdict

Read `.harness/phase-evidence-{i}.md` frontmatter `verdict`:

- **PASS** → continue to Cross-Phase Integrity Check below.
- **FAIL**:
  1. Read `retry_attempt`.
  2. If `retry_attempt >= 3`: set phase-book `status: paused`, escalate (see `meta-loop-protocol.md` §5), halt Meta-Loop.
  3. Otherwise: rename `.harness/phase-evidence-{i}.md` → `.harness/phase-evidence-{i}.md.prev`, launch the Diagnostician with the evidence as input, and re-run the current phase's internal pipeline (back to Phase 1 of this iteration).

### Cross-Phase Integrity Check

Only on PASS:

1. Compute files the current phase touched: `git diff --name-only HEAD~{rounds_this_phase}`.
2. Intersect with cumulative scope of all earlier phases (read their `Scope` fields from `phase-book.md`).
3. For each intersecting prior phase, re-run that phase's verify commands.
4. Any regression → set `status: paused`, escalate, halt.

### Terminal phase (intent-gated)

If the just-verified phase is one of the intent-appended terminal phases (`Phase ∞-2: Commit`, `Phase ∞-1: Push`, `Phase ∞: Deploy`, `Phase ∞: Create PR` — see `commit_push_intent` in phase-book frontmatter), its verify commands already executed the git operation. No extra action here beyond recording evidence.

### Advance

Update phase-book frontmatter: `current_phase = i + 1`. Append to `.harness/phase-history.md`:
```
[YYYY-MM-DDTHH:MM:SSZ] Phase {i}/{N} | verdict: PASS | rounds: {K} | evidence: phase-evidence-{i}.md
```

If `current_phase > total_phases`, set `status: complete` and proceed to Phase 5 (Summary). Otherwise loop back to Phase 1 with `i = current_phase`.

---

## Phase 5: Summary

> Runs once, AFTER the Meta-Loop has completed all phases (`status: complete`) or has been paused. For paused runs, the summary reflects progress up to the pause point and points the user at the escalation evidence.

### Pre-Summary Completion Gate (v4.2.0, MANDATORY)

Before producing the user-facing Summary, run the Completion Gate scan per `harness/references/completion-gate-protocol.md`:

```bash
# Prefer project-local script if present, otherwise inline scan
if [ -x scripts/completion-gate.sh ]; then
  bash scripts/completion-gate.sh
else
  # Embed the inline scan from completion-gate-protocol.md §3
  :
fi
```

- **CRITICAL findings** (terminated resource IDs, missing resources referenced as active): reconcile first (`grep -rl "<stale>" docs/ | edit`), re-run, then summarize. Do NOT present a "PASS / Complete" summary with unresolved CRITICAL.
- **Include a `Completion Gate: ✅/🟡/❌ …` line** in the Summary regardless of scale.

This gate prevents the "Summary declares complete → user discovers stale artifact in minutes" failure mode. It is not optional.

### Scale S — Compact Report

```
## Harness Complete (Scale S)

**Status**: PASS / PARTIAL
**Changes**: [files changed]
**Refiner**: [issues found/fixed]
**Verification**: [build/test results]
**Remaining**: [issues if any, otherwise "None"]
**Next**: Run `/harness-review` to review and commit, or `/harness-review --commit` to auto-commit.
```

### Scale M — Standard Report

```
## Harness Complete (Scale M)

**Rounds**: {N}/2
**Status**: PASS / PARTIAL

### Scores
| Criterion | Score |
|-----------|-------|
| Completeness | X/10 |
| Functionality | X/10 |
| Code Quality | X/10 |

### Changes
[List of files changed with brief description]

### Refiner Summary
[Issues found and fixed by Refiner]

### Remaining Issues
[From last QA report if any]

### Integrity
**Integrity**: {HIGH/MEDIUM/LOW} (from Auditor, if active; otherwise "N/A — Auditor inactive")

### Next Step
Run `/harness-review` to review and commit, or `/harness-review --pr` to create a PR.
```

### Scale L — Full Report

```
## Harness Build Complete (Scale L)

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
[List from spec with PASS/PARTIAL/FAIL per feature]

### Refiner Summary
[Total issues found/fixed across all rounds]

### Remaining Issues
[From last QA report — actionable items]

### Integrity
**Integrity**: {HIGH/MEDIUM/LOW} (from Auditor, if active; otherwise "N/A — Auditor inactive")

### Artifacts
- Context: `.harness/build-context.md`
- Spec: `.harness/build-spec.md`
- Refiner: `.harness/build-refiner-report.md`
- Final QA: `.harness/build-round-{N}-feedback.md`
- Progress: `.harness/build-progress.md`
- Git log: `git log --oneline`

### Next Step
Run `/harness-review` to review and commit, or `/harness-review --pr` to create a PR.
```

After presenting the Summary, finalize session:
```bash
sed -i '' 's/status: IN_PROGRESS/status: COMPLETED/' .harness/session-state.md
sed -i '' 's/phase: .*/phase: 5/' .harness/session-state.md
sed -i '' "s/last_completed_at: .*/last_completed_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)/" .harness/session-state.md
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] summary | done | — | Pipeline complete, status: {PASS/PARTIAL}" >> .harness/session-events.md
```

---

## Critical Rules

1. **Each agent = separate Agent tool call** with fresh context. Never share conversation history between agents.
2. **ALL inter-agent communication through `.harness/` files only.** Do not pass information verbally between agent calls.
3. **Scout runs FIRST.** The Planner and Builder depend on `.harness/build-context.md`.
4. **Refiner runs AFTER Builder, BEFORE QA.** The Refiner cleans code; QA evaluates the cleaned result.
5. **The Builder CANNOT self-certify completion.** Always run Refiner + QA after every build.
6. **The Refiner does NOT add features.** It only cleans, hardens, and aligns with existing patterns.
7. **ALWAYS present the spec/scope to the user and wait for approval** before starting Phase 4.
8. **Scale S does NOT require Playwright.** Code review + build/test is sufficient.
9. **Scale M uses Playwright only if the app has UI.** Backend-only changes use code review + test.
10. **Scale L requires Playwright** for live app testing.
11. **Read prompt templates from `~/.claude/harness/`** before spawning each agent.
12. **When in doubt on scale, pick smaller.** The QA loop catches under-estimation; over-estimation wastes tokens.
13. **Diagnostician runs AFTER QA, BEFORE the next-round Builder.** It bridges QA symptoms to Builder-actionable root causes.
14. **Environment snapshot runs BEFORE every Build round.** The Builder must know exact project state before making changes.
15. **Build history is cumulative.** NEVER overwrite `.harness/build-history.md` — only append.
16. **Evidence traces go to `.harness/traces/`.** QA and Refiner write raw diagnostic data here for the Diagnostician.
17. **Session state and event log are updated after EVERY agent.** See `~/.claude/harness/references/session-protocol.md`.
18. **Model selection follows the protocol**: Scout/Refiner/QA → `sonnet`; Planner/Diagnostician → inherit parent. See session-protocol.md §4.
19. **Round 2+ Builder uses Selective Context**: PRIMARY (diagnosis + snapshot), SECONDARY (spec), ON-DEMAND (rest). See session-protocol.md §3.
20. **Scale L Diagnostician runs in background** (`run_in_background: true`). History and user reporting proceed in parallel.
21. **Builder and Refiner write execution audit logs** to `.harness/traces/round-{N}-execution-log.md`. Diagnostician reads these for root cause analysis.
22. **Sentinel runs AFTER Builder, BEFORE Refiner** (when active). A BLOCK verdict skips Refiner and QA, returning to Builder. Two consecutive BLOCKs abort the pipeline.
23. **Security Triage runs AFTER Scale classification** and re-evaluates AFTER Scout. See Phase 0.5.
24. **Sentinel model is `sonnet`** — checklist-driven pattern matching, not deep reasoning.
25. **Auditor runs AFTER the final QA round, BEFORE Summary** (when active).
26. **LOW integrity verdict blocks auto-commit.** User must verify manually.
27. **Scale S/M always use SINGLE mode.** TEAM mode is only available for Scale L.
28. **`--workers N` flag forces TEAM mode** regardless of Planner's recommendation. Max 5 workers.
29. **TEAM mode follows `team-build-protocol.md` reference.** All team-specific logic lives there, not in this file.

## Cost Awareness

| Scale | Typical Duration | Agent Calls |
|-------|-----------------|-------------|
| S | 5-15 min | 4 (scout + builder + refiner + QA) |
| M | 20-50 min | 6-10 (scout + planner + [builder + refiner + QA + diagnostician] × 1-2) |
| L (SINGLE) | 1-4 hours | 10-17 (scout + planner + [builder + refiner + QA + diagnostician] × 1-3) |
| L (TEAM, 3 workers) | 25-50 min | 12-18 (scout + planner + architect + [W0 + W1-3 + sentinel×3 + integrator + QA + diagnostician] × 1-2) |

**Note**: Diagnostician adds ~2-5 min per round but saves 10-20 min of Builder investigation time in subsequent rounds (Meta-Harness principle: causal diagnosis > summary-based guessing).

**Security overhead**: When Security Triage is HIGH, add 1-2 agent calls per round (Sentinel check + potential Builder retry on BLOCK). MEDIUM adds 0-1 (Sentinel only on Scale L). LOW adds 0.
