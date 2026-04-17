---
name: harness
description: Adaptive multi-agent builder pipeline (SINGLE: Scout → Planner → Builder → Sentinel → Refiner → QA | TEAM: Scout → Planner/Architect → Workers(N) → Sentinel → Integrator → QA) with Security Triage, Diagnostician, and Auditor. Supports S/M/L scale with auto SINGLE/TEAM mode selection. v4.1.0 — Meta-Loop default: every request becomes a phase-book and runs work→verify→apply cycles until every phase's DoD passes. Small requests degrade to a 1-phase book (backward compatible).
---

# Harness

## Overview

Run the Codex version of `/harness`. Treat `/harness` and `$harness` as the same workflow intent inside Codex.

**v4.1.0** — Meta-Loop is the default and only execution model. Every `/harness` invocation:

1. Detects capability tier (`Standard | Advanced | Elite`) via `CLAUDEX_TIER_OVERRIDE` / `CLAUDEX_ELITE_MODELS` / name-based fallback.
2. Decomposes the request into a **phase-book** (1 phase for small requests, 5–15 for large).
3. Runs each phase through the harness pipeline + Phase Verifier + Cross-Phase Integrity Check.
4. Loops until every phase's DoD passes, retrying up to 3× per phase on failure.

Commit/push/deploy/PR intent detected in the request is appended as terminal phases. Auto-commit is off otherwise.

This skill mirrors the Claude harness structure:

`TRIAGE -> CAPABILITY -> SECURITY TRIAGE -> PHASE-BOOK PLANNER -> USER APPROVAL -> for each phase { SETUP -> SCOUT -> PLAN -> USER APPROVAL -> BUILD/SENTINEL/REFINE/QA LOOP -> AUDITOR -> PHASE VERIFIER -> CROSS-PHASE INTEGRITY } -> FINAL AUDITOR -> SUMMARY`

See `references/meta-loop-protocol.md`, `references/phase-verification-protocol.md`, `references/tier-matrix.md` for authoritative specs.

## Guard Clause

Before starting the protocol, confirm the request is actually asking Codex to build, fix, or implement software.

Do not run the harness loop when the user is:

- asking how harness works
- asking to audit or modify the harness itself
- asking a normal coding question or a small edit
- asking for documentation instead of an app build

In those cases, respond directly instead of executing the harness workflow.

## Arguments

- First argument: task description (required)
- `--workers N`: Force TEAM mode with N parallel workers (default 3, max 5). Only applicable to Scale L.

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

## Architecture Overview

```
$harness <prompt> [--workers N]
  |
  +- Phase 0: Triage            -> Scale S/M/L
  +- Phase 0.5: Security Triage -> LOW/MEDIUM/HIGH
  +- Phase 1: Setup             -> .harness_codex/ + session state
  +- Phase 2: Scout             -> build-context.md
  +- Phase 3: Planning          -> build-spec.md (includes Build Mode: SINGLE/TEAM)
  |                             -> User reviews and approves
  +- Phase 4: Build Loop        -> Mode-dependent:
  |   SINGLE: Builder → Sentinel → Refiner → QA → Diagnostician
  |   TEAM:   Architect → Workers(N) → Sentinel → Integrator → QA
  +- Phase 4-audit: Auditor     -> Cross-verification
  +- Phase 5: Summary
```

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
- `.harness_codex/security-triage.md`
- `.harness_codex/session-state.md`
- `.harness_codex/session-events.md`
- `.harness_codex/build-history.md`
- `.harness_codex/build-mode.md` (Scale L only)
- `.harness_codex/traces/` (execution logs, QA evidence)
- `.harness_codex/sentinel-report-round-{N}.md` (when Sentinel active)
- `.harness_codex/auditor-report.md` (when Auditor active)

All inter-agent communication must happen through these files only.

## Phase 0.5: Security Triage

After Scale classification and before Setup, determine the security sensitivity of the request.

### Classification

Analyze the user's request for security-sensitive keywords:

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

Write to `.harness_codex/security-triage.md`:

```markdown
# Security Triage
- sensitivity: {HIGH/MEDIUM/LOW}
- keywords_matched: [{list}]
- sentinel_active: {true/false}
- qa_security_track: {true/false}
- auditor_active: {true/false}
```

**Activation rules:**
- HIGH → sentinel_active: true, qa_security_track: true, auditor_active: true
- MEDIUM → sentinel_active: {true if Scale L, false otherwise}, qa_security_track: true, auditor_active: {true if Scale M/L, false otherwise}
- LOW → sentinel_active: false, qa_security_track: false, auditor_active: false

### Announce to User

```
보안 민감도: {HIGH/MEDIUM/LOW} — {matched keywords}
Sentinel: {활성화/비활성화}, QA Security Track: {활성화/비활성화}
```

### Post-Scout Re-evaluation

After Phase 2 (Scout) completes, re-read `.harness_codex/build-context.md` and check the "Files to Change" section:
- If files include paths containing `auth/`, `payment/`, `security/`, `.env`, `credential` → upgrade to HIGH
- If files include paths containing `api/`, `routes/`, `middleware/`, `model/` → upgrade to at least MEDIUM
- Update `.harness_codex/security-triage.md` if sensitivity increased. Notify user: **"보안 민감도가 {OLD} → {NEW}로 상향되었습니다."**

## Phase 1. Setup

Load `references/session-protocol.md`.

### 1a. Session Recovery Check

Before creating `.harness_codex/`, check for an existing session:

1. If `.harness_codex/session-state.md` exists:
   - Read it and verify referenced artifacts exist on disk
   - Present to user: **"이전 세션이 감지되었습니다. Phase {phase}, {last_completed_agent} 완료 후 중단. 이어서 진행할까요?"**
   - If **resume**: skip to the phase AFTER `last_completed_agent`, reading existing artifacts as context
   - If **restart**: rename `.harness_codex/` to `.harness_codex-backup-{timestamp}/` and continue to 1b
2. If no session-state.md: continue to 1b

### 1b. Fresh Setup

1. Identify the target project directory first.
2. Create the working directory and initialize git if needed:

```bash
mkdir -p .harness_codex/traces
git init 2>/dev/null || true
```

3. Write the user's original request and classified scale to `.harness_codex/build-prompt.md`.
4. Initialize session state in `.harness_codex/session-state.md`:

```markdown
# Session State
- pipeline: harness
- scale: {S/M/L}
- phase: 1
- round: 1
- last_completed_agent: setup
- last_completed_at: {ISO8601}
- status: IN_PROGRESS
- artifacts_written:
  - .harness_codex/build-prompt.md
```

5. Initialize event log in `.harness_codex/session-events.md`:

```markdown
# Session Events
[{timestamp}] setup | done | build-prompt.md | Scale {S/M/L}, harness pipeline
```

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

Use a fresh explore-style subagent (model: `sonnet`):

- keep `fork_context` false
- pass only the scout prompt plus minimal local context
- require the agent to write `.harness_codex/build-context.md`
- scale guidance:
  - `S`: scan only the 2-5 directly relevant files
  - `M`: scan the relevant modules, roughly 5-15 files
  - `L`: comprehensive scan, roughly 20-40 files
- if FIX/MODIFY: include the Deep Dive instruction above

After Scout completes:
1. Briefly confirm: **"Scout 완료. 코드베이스 컨텍스트를 수집했습니다."** (No approval gate.)
2. Update session state and event log in `.harness_codex/session-state.md` and `.harness_codex/session-events.md`.
3. Run Post-Scout Security Re-evaluation (see Phase 0.5).

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

Spawn a fresh planner subagent (inherit parent model — planning quality is critical):

- keep `fork_context` false
- require it to read `.harness_codex/build-context.md`
- add `MODE: LITE. Scale is M.`
- require it to write `.harness_codex/build-spec.md`

After it finishes, summarize the spec and ask:

`Spec을 검토해주세요. 진행할까요?`

Stop and wait for approval. After approval, update session state and event log.

### Scale `L`

Spawn a fresh planner subagent (inherit parent model):

- keep `fork_context` false
- require it to read `.harness_codex/build-context.md`
- add `MODE: FULL. Scale is L.`
- require it to write `.harness_codex/build-spec.md`

After it finishes, summarize the spec and ask:

`Spec을 검토해주세요. 진행할까요, 수정할 부분이 있나요?`

Stop and wait for approval. After approval, update session state and event log.

### Build Mode Decision (Scale L only)

After the Planner completes and the user approves the spec:

1. If `--workers N` flag was provided: **Force TEAM mode** with N workers.
2. Otherwise, read `.harness_codex/build-spec.md` for the Planner's Build Mode recommendation:
   - If Planner recommends TEAM: present to user: **"Planner가 TEAM 모드를 추천합니다 (Workers: {N}명). TEAM 모드로 진행할까요?"**
   - If Planner recommends SINGLE: proceed with SINGLE mode (default).
   - User can override in either direction.
3. Write the decision to `.harness_codex/build-mode.md`:
   ```markdown
   mode: {SINGLE/TEAM}
   workers: {N}
   ```

Scale S/M always use SINGLE mode.

## Phase 4. Build-Sentinel-Refine-QA Loop (Meta-Harness Enhanced)

### Build Mode Branch

Read `.harness_codex/build-mode.md` (or default to SINGLE if file doesn't exist — Scale S/M always SINGLE).

**If SINGLE mode**: Follow the Build-Sentinel-Refine-QA loop below.

**If TEAM mode**: Read and follow `references/team-build-protocol.md`. The team protocol handles:
- Architect (wave planning)
- Workers (parallel, worktree isolation)
- Per-Worker Sentinel gate
- Branch merge (CLEAR only)
- Integrator (merge + hygiene)
- QA + Diagnostician (same as SINGLE mode)

After TEAM mode's QA completes, return here for Phase 4-audit (Auditor) and Phase 5 (Summary).

### SINGLE Mode: Build-Sentinel-Refine-QA

Load:

- `references/builder-prompt.md`
- `references/sentinel-prompt.md`
- `references/refiner-prompt.md`
- `references/qa-prompt.md`
- `references/diagnostician-prompt.md`

### Max rounds by scale

| Scale | Max Rounds | Refiner | QA Method | Diagnostician |
|-------|-----------|---------|-----------|--------------|
| S | 1 | Hygiene + pattern check only | Code review + build/test verification | Not used |
| M | 2 | Full checklist | Code review + build/test + Playwright (if UI exists) | Before round 2 |
| L | 3 | Full checklist + security scan | Playwright mandatory | Before rounds 2 and 3 |

### Model Selection

| Agent | Model |
|-------|-------|
| Scout | `sonnet` |
| Planner | inherit parent (planning quality is critical) |
| Builder (S/M) | `sonnet` |
| Builder (L) | inherit parent |
| Sentinel | `sonnet` |
| Refiner | `sonnet` |
| QA | `sonnet` |
| Diagnostician | inherit parent (deep reasoning needed) |
| Auditor | `sonnet` |

### For each round N:

#### 4-pre. Environment Snapshot (Every Round)

Before each Build round, capture the project state to `.harness_codex/snapshot-round-{N}.md`:
- `git diff --stat` and `git diff --name-only`
- Build command exit code + last 20 lines if failure
- Test command exit code + summary
- Dev server status

Pass this path to the Builder.

#### 4a. Build

For each round `N`, spawn a fresh builder subagent (`fork_context` false).

Builder instructions must include:

- codebase context: `.harness_codex/build-context.md`
- product spec: `.harness_codex/build-spec.md`
- environment snapshot: `.harness_codex/snapshot-round-{N}.md`
- scale: `{S|M|L}`
- round handling:
  - round 1: implement the requested changes from the spec
  - round 2+ (**Selective Context Protocol**):
    - **PRIMARY** (read FIRST): `.harness_codex/diagnosis-round-{N-1}.md` — root cause analysis with file:line citations. `.harness_codex/snapshot-round-{N}.md` — current project state.
    - **SECONDARY** (reference): `.harness_codex/build-spec.md` — the spec.
    - **ON-DEMAND** (only if diagnosis is insufficient): `.harness_codex/build-history.md`, `.harness_codex/traces/round-{N-1}-qa-evidence.md`, `.harness_codex/traces/round-{N-1}-execution-log.md`
    - Fix ROOT CAUSES from the diagnosis. Do not re-investigate from scratch.
- write progress to `.harness_codex/build-progress.md`
- **Execution Audit**: write execution log to `.harness_codex/traces/round-{N}-execution-log.md`
- for scale `M` and `L`, start the dev server in background and record the URL in `.harness_codex/build-progress.md`

After Builder completes, update event log in `.harness_codex/session-events.md`.

#### 4a-post. Sentinel Check (Conditional)

**Skip if**: `.harness_codex/security-triage.md` shows `sentinel_active: false`

Load `references/sentinel-prompt.md`.

Spawn a fresh sentinel subagent (model: `sonnet`, `fork_context` false):

- execution audit log: `.harness_codex/traces/round-{N}-execution-log.md`
- build progress: `.harness_codex/build-progress.md`
- product spec: `.harness_codex/build-spec.md`
- containment reference: `references/agent-containment.md`
- security triage: `.harness_codex/security-triage.md`
- round number: {N}
- output: `.harness_codex/sentinel-report-round-{N}.md`

After Sentinel completes, extract the verdict: **BLOCK / WARN / CLEAR**

**If BLOCK**:
- Report to user: **"Sentinel BLOCK — {finding count} CRITICAL 보안 문제 탐지. Builder에게 반환합니다."**
- Pass sentinel report to Builder as additional context
- Re-launch Builder with SENTINEL BLOCK instruction
- If BLOCK again after 2 consecutive attempts: abort pipeline. Report: **"2회 연속 Sentinel BLOCK. 수동 검토가 필요합니다."**

**If WARN**:
- Report to user: **"Sentinel WARN — {finding count} HIGH 수준 발견. Refiner에게 전달합니다."**
- Pass sentinel report path to Refiner prompt
- Proceed to Refiner (4b)

**If CLEAR**:
- Proceed to Refiner (4b) normally

Update event log in `.harness_codex/session-events.md`.

#### 4b. Refine

Spawn a fresh refiner subagent (model: `sonnet`, `fork_context` false).

Refiner instructions must include:

- codebase context: `.harness_codex/build-context.md`
- product spec: `.harness_codex/build-spec.md`
- build progress: `.harness_codex/build-progress.md`
- scale and round number
- round 2+: previous QA feedback path
- apply safe cleanup and hardening directly to the code
- write `.harness_codex/build-refiner-report.md`
- **Execution Audit**: append refinement actions to `.harness_codex/traces/round-{N}-execution-log.md` under a `## Refiner Actions` header

After Refiner completes, update event log.

#### 4c. Verify Dev Server

For scale `M` and `L` only:

1. Read `.harness_codex/build-progress.md` and extract the app URL.
2. Verify the server responds:

```bash
curl -s -o /dev/null -w '%{http_code}' <URL>
```

3. If the server is down, attempt to start it using the recorded command.
4. If it still does not run, treat that as a critical QA failure.

#### 4d. QA

Spawn a fresh QA subagent (model: `sonnet`, `fork_context` false).

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

After QA completes, update event log.

#### 4e. Evaluate

After QA finishes:

1. Read `.harness_codex/build-round-{N}-feedback.md`.
2. Extract the criterion scores.
3. Report briefly: round number, scores, pass/fail, key issues
4. Decide (evaluate in this order):
   - final allowed round reached -> go to 4g (History), then Phase 4-post, then Phase 4-audit, then Phase 5
   - all scores `>= 7` -> pass, go to 4g (History), then Phase 4-post, then Phase 4-audit, then Phase 5
   - any score `< 7` AND rounds remain -> go to 4f (Diagnose), then 4g (History), then continue

#### 4f. Diagnose (Scale M/L, before next round ONLY)

Skip for Scale S or if this was the final round.

Load `references/diagnostician-prompt.md`.

Spawn a fresh diagnostician subagent (inherit parent model, `fork_context` false).

**Scale L**: use `run_in_background` and proceed to 4g (History) immediately. Scale M: foreground (default).

- QA feedback: `.harness_codex/build-round-{N}-feedback.md`
- QA evidence traces: `.harness_codex/traces/round-{N}-qa-evidence.md`
- execution audit log: `.harness_codex/traces/round-{N}-execution-log.md`
- event log: `.harness_codex/session-events.md`
- environment snapshot: `.harness_codex/snapshot-round-{N}.md`
- build progress: `.harness_codex/build-progress.md`
- codebase context: `.harness_codex/build-context.md`
- round number: {N}
- if round 2+: previous diagnosis and build history paths
- output: `.harness_codex/diagnosis-round-{N}.md`

**Scale L flow** (background Diagnostician):
1. Diagnostician runs in background
2. Proceed immediately to 4g (History) — does not depend on diagnosis
3. Report QA scores to user while Diagnostician works
4. When Diagnostician notification arrives → read diagnosis, report root cause summary

**Scale M flow** (foreground):
- After completion, report briefly: root cause count, regression count, top priority fix

After Diagnostician completes, update event log.

#### 4g. Accumulate History (Every Round)

Append to `.harness_codex/build-history.md`:

```markdown
## Round {N}
- **Scores**: [criterion: score pairs from QA]
- **Verdict**: PASS / FAIL
- **Changes made**: [files changed in this round]
- **Issues found by QA**: CRITICAL: X, HIGH: Y, MEDIUM: Z
- **Root causes identified**: [from diagnosis if available, otherwise "N/A (Scale S)"]
- **What worked**: [improvements vs previous round, if applicable]
- **What regressed**: [score drops vs previous round, if applicable]
- **Decision**: PASS → Phase 5 / Continue to Round {N+1}
```

This file is cumulative — NEVER overwrite, only append. Create on round 1 with a header.

After History is written, update session state for the round transition.

## Phase 4-post. Artifact Validation

After exiting the Build-Refine-QA loop (either PASS or max rounds reached), run a quick artifact check before generating the Summary. This is a bash check, not a subagent call.

Verify these artifacts exist:

- Core artifacts (all scales): `build-context.md`, `build-spec.md`, `build-prompt.md`, `build-progress.md`, `security-triage.md`
- Per-round artifacts: `build-round-{N}-feedback.md`, `snapshot-round-{N}.md`
- Scale M/L: `build-refiner-report.md`, `build-history.md`
- Evidence traces (M/L): `traces/round-{N}-qa-evidence.md`
- Sentinel reports (if active): `sentinel-report-round-{N}.md`
- Diagnostician artifacts (M/L, round 2+): `diagnosis-round-{N}.md`
- Auditor artifact (if active): `auditor-report.md`

Report the result:
- 0 missing → **"Artifact validation: PASS"**
- Any missing → **"Artifact validation: [X] missing files"** + list them in the Summary

## Phase 4-audit. Auditor Verification (Conditional)

**Skip if**: `.harness_codex/security-triage.md` shows `auditor_active: false`
**Skip for Scale S**: Auditor is only active for Scale M/L with MEDIUM/HIGH security sensitivity.

After the Build-Sentinel-Refine-QA loop exits, run the Auditor for cross-verification.

Load `references/auditor-prompt.md`.

Spawn a fresh auditor subagent (model: `sonnet`, `fork_context` false):

- build progress: `.harness_codex/build-progress.md`
- refiner report: `.harness_codex/build-refiner-report.md`
- QA feedback files: `.harness_codex/build-round-{1..N}-feedback.md`
- execution logs: `.harness_codex/traces/round-{1..N}-execution-log.md`
- sentinel reports: `.harness_codex/sentinel-report-round-{1..N}.md` (if exist)
- product spec: `.harness_codex/build-spec.md`
- build history: `.harness_codex/build-history.md`
- total rounds completed: {N}
- output: `.harness_codex/auditor-report.md`

After Auditor completes:
1. Read `.harness_codex/auditor-report.md`
2. Extract integrity verdict: HIGH / MEDIUM / LOW
3. If LOW: **"Auditor: LOW integrity 탐지. 수동 검증을 권장합니다."**
4. Include integrity verdict in Phase 5 Summary

Update event log.

## Phase 5. Summary

### Scale S — Compact Report

```markdown
## Harness Complete (Scale S)

**Status**: PASS / PARTIAL
**Changes**: [files changed]
**Refiner**: [issues found/fixed]
**Verification**: [build/test results]
**Remaining**: [issues if any, otherwise "None"]
```

### Scale M — Standard Report

```markdown
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
```

### Scale L — Full Report

```markdown
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
- Context: `.harness_codex/build-context.md`
- Spec: `.harness_codex/build-spec.md`
- Refiner: `.harness_codex/build-refiner-report.md`
- Final QA: `.harness_codex/build-round-{N}-feedback.md`
- Progress: `.harness_codex/build-progress.md`
```

After presenting the Summary, finalize session state (set status to COMPLETED) and write final event log entry.

## Execution Rules

1. Each phase agent must be a separate `spawn_agent` call with fresh context (`fork_context` false).
2. Never pass state between agents in chat. Use `.harness_codex/` files only.
3. Always load the prompt templates from `references/` before composing each agent task.
4. Always wait for explicit user approval after the planning phase.
5. The Builder cannot self-certify. Refiner and QA must run after every build round.
6. The Refiner does not add features. It only cleans, hardens, and aligns with existing patterns.
7. Scale `S` does not require Playwright.
8. Scale `M` uses Playwright only when UI exists.
9. Scale `L` requires live-app QA with Playwright.
10. If subagents are unavailable, stop and say the harness cannot run as designed. Do not fake the multi-agent loop in one pass.
11. **Model selection follows the protocol**: Scout/Refiner/QA/Sentinel/Auditor → `sonnet`; Planner/Diagnostician → inherit parent.
12. **Round 2+ Builder uses Selective Context**: PRIMARY (diagnosis + snapshot), SECONDARY (spec), ON-DEMAND (rest).
13. **Scale L Diagnostician runs in background**. History and user reporting proceed in parallel.
14. **Builder and Refiner write execution audit logs** to `.harness_codex/traces/round-{N}-execution-log.md`.
15. **Sentinel runs AFTER Builder, BEFORE Refiner** (when active). A BLOCK verdict returns to Builder. Two consecutive BLOCKs abort the pipeline.
16. **Security Triage runs AFTER Scale classification** and re-evaluates AFTER Scout.
17. **Auditor runs AFTER the final QA round, BEFORE Summary** (when active). LOW integrity blocks auto-commit.
18. **Scale S/M always use SINGLE mode.** TEAM mode is only available for Scale L.
19. **`--workers N` flag forces TEAM mode** regardless of Planner's recommendation. Max 5 workers.
20. **TEAM mode follows `references/team-build-protocol.md`.** All team-specific logic lives there, not in this file.
21. **Session state and event log are updated after EVERY agent.** See `references/session-protocol.md`.
22. **Build history is cumulative.** NEVER overwrite `.harness_codex/build-history.md` — only append.
23. **Evidence traces go to `.harness_codex/traces/`.** QA and Refiner write raw diagnostic data here for the Diagnostician.

## Cost Awareness

| Scale | Typical Duration | Agent Calls |
|-------|-----------------|-------------|
| S | 5-15 min | 4 (scout + builder + refiner + QA) |
| M | 20-50 min | 6-10 (scout + planner + [builder + refiner + QA + diagnostician] x 1-2) |
| L (SINGLE) | 1-4 hours | 10-17 (scout + planner + [builder + sentinel + refiner + QA + diagnostician] x 1-3) |
| L (TEAM, 3 workers) | 25-50 min | 12-18 (scout + planner + architect + [workers + sentinel + integrator + QA + diagnostician] x 1-2) |
