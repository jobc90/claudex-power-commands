# Session Protocol Reference

> Managed Agents-inspired session management for all harness pipelines.
> Covers: session state, event log, resume protocol, model routing, execution audit, background diagnostician.

---

## 1. Session State (Wake/Resume)

### Format: `.harness/session-state.md`

Written by the orchestrator at every phase transition. Enables cross-session resume.

```markdown
# Session State
- pipeline: harness | harness-team | harness-review | harness-docs | harness-qa
- scale: S | M | L
- phase: 1 | 2 | 3 | 4 | 5
- round: 1 | 2 | 3
- last_completed_agent: scout | planner | builder | refiner | qa | diagnostician | ...
- last_completed_at: 2026-04-09T14:30:00Z
- status: IN_PROGRESS | COMPLETED
- artifacts_written:
  - .harness/build-context.md
  - .harness/build-spec.md
```

### Resume Protocol

At the START of every harness command (Phase 1), BEFORE creating `.harness/`:

```
1. CHECK: Does `.harness/session-state.md` exist?
   - NO  → Normal start. Create .harness/ and proceed.
   - YES → Read it. Continue to step 2.

2. VALIDATE: Do the referenced artifacts still exist on disk?
   - List all files in artifacts_written
   - Check each file exists

3. PRESENT to user:
   "이전 세션이 감지되었습니다.
    파이프라인: {pipeline} | Scale: {scale}
    중단 시점: Phase {phase}, Round {round}, {last_completed_agent} 완료 후
    시간: {last_completed_at}
    아티팩트: {X}/{Y}개 존재
    
    선택:
    1. 이어서 진행 (Phase {next_phase}부터)
    2. 처음부터 시작 (기존 .harness/ 백업 후 새로 시작)"

4. IF resume:
   - Skip to the phase AFTER last_completed_agent
   - Read existing artifacts as context
   - Continue pipeline normally

5. IF restart:
   - mv .harness/ .harness-backup-{timestamp}/
   - Create fresh .harness/
   - Start from Phase 1
```

### State Update Points

Update `session-state.md` at these moments:

| Pipeline | Update After |
|----------|-------------|
| All | Phase 1 (Setup) complete |
| All | Each agent completes (scout, planner, builder, etc.) |
| All | Each round completes (round N → round N+1 transition) |
| All | Phase 5 (Summary) → status: COMPLETED |

---

## 2. Unified Event Log

### Format: `.harness/session-events.md`

Append-only, one line per event. Created at Phase 1, appended after every agent.

```markdown
# Session Events
[2026-04-09T14:25:00Z] setup | done | session-state.md | Scale M, harness pipeline
[2026-04-09T14:26:00Z] scout | done | build-context.md | 15 files, 3 modules scanned
[2026-04-09T14:30:00Z] planner | done | build-spec.md | 4 features, 2 phases
[2026-04-09T14:31:00Z] approval | user | — | Spec approved, proceeding to build
[2026-04-09T14:35:00Z] builder:r1 | done | build-progress.md | 8 files changed, 0 errors
[2026-04-09T14:38:00Z] refiner:r1 | done | build-refiner-report.md | 3 issues fixed
[2026-04-09T14:42:00Z] qa:r1 | fail | build-round-1-feedback.md | scores: 6,8,7 → FAIL
[2026-04-09T14:45:00Z] diagnostician:r1 | done | diagnosis-round-1.md | 2 root causes found
[2026-04-09T14:50:00Z] builder:r2 | done | build-progress.md | 3 files changed, root causes addressed
[2026-04-09T14:53:00Z] refiner:r2 | done | build-refiner-report.md | 1 issue fixed
[2026-04-09T14:57:00Z] qa:r2 | pass | build-round-2-feedback.md | scores: 8,9,8 → PASS
```

### How to Append

After each agent completes, the orchestrator runs:

```bash
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] {agent}:{round} | {status} | {output_file} | {one-line summary}" >> .harness/session-events.md
```

### Consumers

| Consumer | Purpose |
|----------|---------|
| Diagnostician | Read event log to detect patterns across rounds (e.g., same module failing twice) |
| Session Resume | Read event log to determine exact re-entry point |
| User | Quick overview of what happened in the pipeline |

---

## 3. Selective Context Protocol

### Problem

Round 2+ Builder receives 7-8 artifact paths. The Diagnostician already synthesizes all information into the diagnosis. Builder re-reading raw artifacts is **redundant work** that wastes tokens and dilutes focus.

### Solution: 3-Tier Context Hierarchy

For Round 2+ Builder/Worker agents:

```
PRIMARY (MUST read first — these contain everything you need):
  1. diagnosis-round-{N-1}.md       ← Diagnostician's synthesized root cause analysis
  2. snapshot-round-{N}.md          ← Current project state (git, build, test)

SECONDARY (Read for reference):
  3. build-spec.md                  ← What was requested (stable across rounds)

ON-DEMAND (Read ONLY if diagnosis is insufficient):
  4. build-history.md               ← Cumulative round outcomes
  5. traces/round-{N-1}-qa-evidence.md        ← Raw QA diagnostic data
  6. traces/round-{N-1}-execution-log.md      ← Builder/Refiner execution actions
  7. build-round-{N-1}-feedback.md  ← Previous QA scores
  8. build-progress.md              ← Previous implementation log
```

### Prompt Template for Round 2+ Builder

```
"This is Round {N}. Your PRIMARY inputs are:
  1. `.harness/diagnosis-round-{N-1}.md` — READ THIS FIRST. Contains root cause analysis with file:line citations.
  2. `.harness/snapshot-round-{N}.md` — Current project state.

Reference: `.harness/build-spec.md` — the spec (unchanged).

If the diagnosis is insufficient to fix an issue, you may also read:
  - `.harness/traces/round-{N-1}-execution-log.md` (execution actions)
  - `.harness/traces/round-{N-1}-qa-evidence.md` (QA raw data)
  - `.harness/build-history.md` (cumulative history)
  
Fix ROOT CAUSES from the diagnosis. Do not re-investigate from scratch."
```

---

## 4. Model Selection Protocol

### Per-Agent Model Recommendations

Optimized for the Claude Code subscription environment. Use the `model` parameter in Agent tool calls.

| Agent | Model | Rationale |
|-------|-------|-----------|
| **Scout** | `sonnet` | Systematic exploration, no deep reasoning needed |
| **Planner** | *default (inherit)* | Planning quality is critical — use parent model |
| **Architect** | *default (inherit)* | Architectural decisions require deep judgment |
| **Builder (S/M)** | `sonnet` | Standard implementation, patterns from spec |
| **Builder (L)** | *default (inherit)* | Complex multi-module implementation |
| **Worker (simple)** | `haiku` | 1-2 file mechanical tasks |
| **Worker (standard)** | `sonnet` | Standard implementation with clear brief |
| **Worker (complex)** | *default (inherit)* | Complex judgment, cross-cutting concerns |
| **Sentinel** | `sonnet` | Checklist-driven pattern matching |
| **Refiner** | `sonnet` | Checklist-driven pattern matching |
| **Integrator** | `sonnet` | Systematic merge verification |
| **QA** | `sonnet` | Systematic testing against criteria |
| **Diagnostician** | *default (inherit)* | Root cause analysis requires deep reasoning |
| **Auditor** | `sonnet` | Evidence cross-referencing, systematic comparison |
| **Scanner** | `sonnet` | Git diff analysis, systematic |
| **Analyzer** | `sonnet` | Issue identification from diff |
| **Fixer** | `sonnet` | Targeted, scoped fixes |
| **Verifier** | `sonnet` | Verification against analysis |
| **Reporter** | `sonnet` | Report generation |
| **Researcher** | `sonnet` | Codebase exploration |
| **Outliner** | `sonnet` | Document structure planning |
| **Writer** | *default (inherit)* | Quality writing needs strong model |
| **Reviewer** | `sonnet` | Fact-checking against source |
| **Validator** | `sonnet` | Command execution and verification |
| **Scenario Writer** | `sonnet` | Test scenario generation |
| **Test Executor** | `sonnet` | Playwright-based systematic testing |
| **Analyst** | `sonnet` | Results classification |
| **QA Reporter** | `sonnet` | Report generation |

### How to Apply

In the Agent tool call, add the `model` parameter:

```
Agent({
  description: "harness scout (M)",
  model: "sonnet",
  prompt: "..."
})
```

Agents without explicit model inherit from parent (typically opus).

### Override Rule

If the user's parent model is already `sonnet`, do NOT downgrade agents to `haiku` unless explicitly listed as `haiku` above. The recommendations assume an `opus` parent.

---

## 5. Execution Audit Trail

### Purpose

Builder and Refiner log their key execution actions so the Diagnostician can trace failures to specific commands/operations without re-investigating from scratch.

### Format: `.harness/traces/round-{N}-execution-log.md`

```markdown
# Execution Log — Round {N}

## Builder Actions
[2026-04-09T14:35:00Z] FILE_CREATE: src/components/Login.tsx (85 lines)
[2026-04-09T14:35:30Z] FILE_MODIFY: src/app/layout.tsx (added import, +3 lines)
[2026-04-09T14:36:00Z] CMD: npm install zod → exit 0
[2026-04-09T14:36:30Z] CMD: npm run build → exit 1 → ERROR: Cannot find module '@/lib/auth'
[2026-04-09T14:37:00Z] FILE_CREATE: src/lib/auth.ts (42 lines) — fixing missing module
[2026-04-09T14:37:30Z] CMD: npm run build → exit 0
[2026-04-09T14:38:00Z] CMD: npm run dev → started on :3000
[2026-04-09T14:38:30Z] DEP_INSTALL: zod@3.23.0, @tanstack/react-query@5.60.0

## Refiner Actions
[2026-04-09T14:39:00Z] FIX: src/components/Login.tsx:45 — removed console.log
[2026-04-09T14:39:15Z] FIX: src/lib/auth.ts:12 — added error handling (try/catch)
[2026-04-09T14:39:30Z] CMD: npm run build → exit 0
[2026-04-09T14:39:45Z] CMD: npm test → 12 passed, 0 failed
```

### Instructions for Builder

Add to Builder prompt:

```
## Execution Audit (MANDATORY)

As you work, maintain a running log of your key actions. After completing your implementation,
write (or append) this log to `.harness/traces/round-{N}-execution-log.md`.

Log these events:
- FILE_CREATE: path (line count)
- FILE_MODIFY: path (what changed, +/- lines)
- CMD: command → exit code [→ ERROR: message if failed]
- DEP_INSTALL: package@version list
- ERROR_RESOLVED: what error, how fixed

This log is read by the Diagnostician if your round fails. Accurate logging = faster diagnosis = fewer rounds.
```

### Instructions for Refiner

Add to Refiner prompt:

```
## Execution Audit (MANDATORY)

Append your refinement actions to `.harness/traces/round-{N}-execution-log.md` (the Builder already wrote the first section).

Log these events under a "## Refiner Actions" header:
- FIX: file:line — what was fixed
- CMD: command → exit code
- SKIP: issue — why deferred (if any)
```

---

## 6. Worktree Isolation (Team Workers)

### Applies To

`/harness-team` Wave 2 parallel Workers ONLY.

### Why

Multiple Workers modifying the same working directory risks:
- Dependency installation conflicts (Worker A installs X, breaks Worker B's build)
- Shared config file race conditions (package.json, tsconfig.json)
- Failed Worker polluting other Workers' environment

### How

1. **Wave 2 Workers** use `isolation: "worktree"` in Agent tool calls:

```
Agent({
  description: "harness-team worker 1",
  isolation: "worktree",
  model: "sonnet",
  prompt: "..."
})
```

2. **Worker completes** → Agent tool returns `{ path, branch }` if changes were made.

3. **Orchestrator collects** all Worker branches after Wave 2 completes.

4. **Before Integrator runs**, orchestrator merges Worker branches:

```bash
# For each Worker branch with changes:
git merge {worker-branch} --no-ff -m "Merge Worker {i}: {brief description}"
```

If merge conflicts (should be rare — Architect ensures file ownership separation):
- Note conflicts in the Integrator's prompt
- Integrator resolves conflicts as part of integration work

5. **Integrator runs** on the merged codebase (not in a worktree).

6. **Worker progress**: Workers return their progress report as the agent result message. The orchestrator writes `.harness/team-worker-{i}-progress.md` from the result.

### Worker Prompt Addition

```
## Worktree Awareness

You are running in an isolated git worktree. Your code changes are on a separate branch.
- Implement your assigned files normally
- Run build/test commands to verify your changes work IN ISOLATION
- Your changes will be merged with other Workers' changes by the Integrator
- Return your progress report as your final message (do NOT write to .harness/ — the orchestrator handles that)
```

---

## 7. Background Diagnostician (Scale L)

### Applies To

`/harness` and `/harness-team`, Scale L only, when QA verdict is FAIL and rounds remain.

### Why

Diagnostician execution (2-5 min) can overlap with History writing + user notification — these are independent operations.

### How

After QA evaluation determines FAIL:

```
1. Launch Diagnostician with `run_in_background: true`:
   Agent({
     description: "harness diagnostician round {N}",
     run_in_background: true,
     prompt: "..."
   })

2. IMMEDIATELY (don't wait for Diagnostician):
   a. Write History entry (4g)
   b. Report QA scores to user
   c. Update session-state.md

3. When Diagnostician completion notification arrives:
   a. Read diagnosis
   b. Briefly report root cause count to user
   c. Proceed to next round Builder
```

### Scale S/M

Run Diagnostician in foreground (default). The time saving is marginal for shorter pipelines.

---

## 10. Integration Summary

## 9. Model Capability Tier (Adaptive Scale)

### Tier Definitions

| Tier | Typical Models | Characteristics |
|------|---------------|----------------|
| Standard | small/fast general-purpose models | Systematic execution, structured tasks |
| Advanced | mid-size reasoning models | Deep reasoning, reliable judgment |
| Elite | high-capability frontier models | Exceptional autonomy; mistakes can be subtle; stricter alignment posture required |

### Tier-Specific Adjustments

| Parameter | Standard | Advanced | Elite |
|-----------|----------|----------|-------|
| Max rounds (Scale L) | 3 | 3 | 2 |
| Max rounds (Scale M) | 2 | 2 | 1 |
| QA pass threshold | 7/10 | 7/10 | 8/10 |
| Sentinel activation | Per triage | Per triage | MEDIUM + HIGH always on |
| Auditor activation | Per triage | Per triage | Always on |
| Scale S file threshold | 1-2 files | 1-2 files | 1-5 files |
| Scale M file threshold | 3-5 files | 3-5 files | 3-10 files |
| Scale L file threshold | 6+ files | 6+ files | 11+ files |

### Tier Detection

The orchestrator classifies the parent model at session start by the following priority:

1. **Explicit override** — `CLAUDEX_TIER_OVERRIDE` environment variable (`standard` | `advanced` | `elite`). For testing and admin-approved scenarios.
2. **Elite allowlist** — if the runtime model identifier appears in the comma-separated `CLAUDEX_ELITE_MODELS` environment variable → Elite.
3. **Name-based fallback** (for unlisted models):
   - Identifier contains `sonnet` or `haiku` → Standard
   - Identifier contains `opus` → Advanced
   - Otherwise → Standard (conservative default)

**User-facing output**: at session start, emit a single line — `tier: {Standard|Advanced|Elite}` — without revealing the underlying model identifier.

### Long-Context Scale Adjustment (Elite Tier)

Elite-tier models with very large effective context (256K–1M+) can process more files per scan:
- Scout (Scale S): 10-15 files instead of 2-5
- Scout (Scale M): 15-30 files instead of 5-15
- Selective Context ON-DEMAND tier → promoted to SECONDARY (all artifacts readable)

---

## 9.5 Elite Model Allowlist

Elite-tier classification is intentionally decoupled from hard-coded model names to preserve the project's naming-neutrality policy. The allowlist lives in an environment variable so downstream consumers and agent prompts see only the `Elite` tier label, never the underlying model identifier.

### Setup

Add to your shell profile or `.env`:

```bash
# Comma-separated list of runtime model identifiers that should use the Elite tier.
export CLAUDEX_ELITE_MODELS="id-1,id-2"
```

### Criteria for inclusion

A model qualifies for Elite classification when it meets **at least two** of the following:
- SWE-bench Verified ≥ 90%
- Terminal-Bench ≥ 80%
- Long-context BFS (256K–1M) ≥ 75%
- Documented exceptional autonomous task completion capability

### Verification

After setting the environment variable, run any `/harness` invocation and confirm the session start emits `tier: Elite`.

### Override flow

For one-off experiments without modifying the allowlist:

```bash
CLAUDEX_TIER_OVERRIDE=elite /harness "..."
```

---

### How Features Work Together

```
Session starts:
  ├─ Check session-state.md (Feature A: Resume)
  ├─ Create session-events.md header (Feature B: Event Log)
  └─ Select agent models (Feature E: Model Selection)

Each agent runs:
  ├─ Orchestrator selects model (Feature E)
  ├─ If team Worker → isolation: "worktree" (Feature D)
  ├─ Agent executes
  ├─ Builder/Refiner write execution log (Feature F: Execution Audit)
  ├─ If Builder/Worker complete → Sentinel gate (when active):
  │     ├─ Sentinel inspects diff vs containment rules
  │     ├─ CLEAR → proceed to Refiner/Integrator
  │     └─ BLOCK → discard changes, report to user
  ├─ Orchestrator appends to session-events.md (Feature B)
  └─ Orchestrator updates session-state.md (Feature A)

Round 2+ Builder:
  ├─ Reads PRIMARY context only (Feature C: Selective Context)
  ├─ Diagnostician read event log + execution log (Features B, F)
  └─ Scale L: Diagnostician ran in background (Feature G)

Session crashes and restarts:
  ├─ session-state.md detected (Feature A)
  ├─ session-events.md shows exact timeline (Feature B)
  └─ User chooses to resume from last checkpoint
```
