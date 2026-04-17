# Harness Agent Index

> 27개 에이전트 프롬프트 + 1개 orchestrator helper, 4개 파이프라인, 6개 커맨드의 교차참조 맵.
> **v4.1.0**: Meta-Loop is the default execution model for `/harness`. Phase-Book Planner, Phase Verifier, and Phase Orchestrator reference added.
> **v4.0.0**: `/harness-team` merged into `/harness` as TEAM mode.
> Lint(`/harness-lint`)가 이 파일을 기준으로 일관성을 검증합니다.
> 프롬프트 추가/수정 시 이 Index도 함께 업데이트하세요.

## Agent Catalog (27 prompts + 1 helper)

### /harness Pipeline — SINGLE Mode: Scout → Planner → Builder → Refiner → QA → Diagnostician → Auditor

| # | Agent | Prompt File | Reads | Writes |
|---|-------|------------|-------|--------|
| 1 | Scout | `scout-prompt.md` | CLAUDE.md, package.json, codebase files | `build-context.md` |
| 2 | Planner | `planner-prompt.md` | `build-context.md`, `build-prompt.md` | `build-spec.md` |
| 3 | Builder | `builder-prompt.md` | `build-context.md`, `build-spec.md`, `snapshot-round-{N}.md`, `diagnosis-round-{N-1}.md`¹, `build-history.md`¹, `traces/round-{N-1}-qa-evidence.md`¹, `build-refiner-report.md`¹, `build-round-{N-1}-feedback.md`¹ | `build-progress.md`, code changes |
| 4 | Refiner | `refiner-prompt.md` | `build-context.md`, `build-spec.md`, `build-progress.md`, `build-round-{N-1}-feedback.md`¹ | `build-refiner-report.md`, `traces/round-{N}-refiner-trace.md`² |
| 5 | QA | `qa-prompt.md` | `build-spec.md`, `build-refiner-report.md` | `build-round-{N}-feedback.md`, `traces/round-{N}-qa-evidence.md`² |
| 6 | Diagnostician | `diagnostician-prompt.md` | `build-round-{N}-feedback.md`, `traces/round-{N}-qa-evidence.md`, `snapshot-round-{N}.md`, `build-progress.md`, `build-context.md`, `diagnosis-round-{N-1}.md`¹, `build-history.md`¹ | `diagnosis-round-{N}.md` |
| 25 | Auditor | `auditor-prompt.md` | `build-progress.md`, `build-refiner-report.md`, `build-round-{1..N}-feedback.md`, `traces/round-{1..N}-execution-log.md`, `sentinel-report-round-{1..N}.md`³, `build-spec.md`, `build-history.md` | `auditor-report.md` |

¹ Round 2+ only  ² Scale M/L only  ³ If sentinel was active

### /harness Pipeline — TEAM Mode Agents: Scout → Architect → Workers(N) → [Sentinel] → Integrator → QA → Diagnostician → [Auditor]

| # | Agent | Prompt File | Reads | Writes |
|---|-------|------------|-------|--------|
| 1 | Scout (shared) | `scout-prompt.md` | codebase files | `team-context.md` |
| 17 | Architect | `architect-prompt.md` | `team-context.md` | `team-plan.md` |
| 18 | Worker | `worker-prompt.md` | `team-plan.md`, `team-context.md` | `team-worker-{i}-progress.md` |
| 24 | Sentinel (per-Worker) | `sentinel-prompt.md` | Worker branch diff, `team-plan.md`, `references/agent-containment.md`, `security-triage.md` | `sentinel-worker-{i}-round-{R}.md` |
| 19 | Integrator | `integrator-prompt.md` | `team-plan.md`, `team-worker-{0..N}-progress.md`, `team-context.md` | `team-integration-report.md` *(includes full Refiner-equivalent hygiene + hardening)* |
| 5 | QA (shared) | `qa-prompt.md` | `team-plan.md`, `team-integration-report.md` | `team-round-{R}-feedback.md`, `traces/round-{R}-qa-evidence.md` |
| 6 | Diagnostician (shared) | `diagnostician-prompt.md` | `team-round-{R}-feedback.md`, `traces/`, `team-context.md`, `team-plan.md` | `team-diagnosis-round-{R}.md` |
| 25 | Auditor (shared) | `auditor-prompt.md` | `team-plan.md`, `team-worker-{0..N}-progress.md`, `team-integration-report.md`, `team-round-{1..R}-feedback.md`, `sentinel-worker-{i}-round-{R}.md`³, `team-history.md` | `auditor-report.md` |

### /harness-review Pipeline — Scanner → Analyzer → Fixer → Verifier → Reporter

| # | Agent | Prompt File | Reads | Writes |
|---|-------|------------|-------|--------|
| 7 | Scanner | `scanner-prompt.md` | git diff, codebase files | `review-context.md` |
| 8 | Analyzer | `analyzer-prompt.md` | `review-context.md` | `review-analysis.md` |
| 9 | Fixer | `fixer-prompt.md` | `review-analysis.md`, `review-context.md` | `review-fix-report.md`, code fixes |
| 10 | Verifier | `verifier-prompt.md` | `review-fix-report.md`, `review-analysis.md`, `review-context.md` | `review-verify-report.md` |
| 11 | Reporter | `reporter-prompt.md` | `review-context.md`, `review-analysis.md`, `review-fix-report.md`, `review-verify-report.md` | `review-report.md`, git actions |

### /harness-docs Pipeline — Researcher → Outliner → Writer → Reviewer + Validator

| # | Agent | Prompt File | Reads | Writes |
|---|-------|------------|-------|--------|
| 12 | Researcher | `researcher-prompt.md` | codebase files, CLAUDE.md | `docs-research.md` |
| 13 | Outliner | `outliner-prompt.md` | `docs-research.md` | `docs-outline.md` |
| 14 | Writer | `writer-prompt.md` | `docs-research.md`, `docs-outline.md`, source code | `docs-draft.md` |
| 15 | Reviewer | `reviewer-prompt.md` | `docs-draft.md`, `docs-research.md`, `docs-outline.md` | `docs-round-{N}-review.md` |
| 16 | Validator | `validator-prompt.md` | `docs-draft.md`, `docs-research.md` | `docs-round-{N}-validation.md` |

### /harness-qa Pipeline — Scout → Scenario Writer → Test Executor → Analyst → Reporter

| # | Agent | Prompt File | Reads | Writes |
|---|-------|------------|-------|--------|
| 1 | Scout (shared) | `scout-prompt.md` | codebase files | `qa-context.md` |
| 20 | Scenario Writer | `scenario-writer-prompt.md` | `qa-context.md` | `qa-scenarios.md` (or `qa-test-plan.md` for pre-launch) |
| 21 | Test Executor | `test-executor-prompt.md` | `qa-scenarios.md` | `qa-results.md` |
| 22 | Analyst | `analyst-prompt.md` | `qa-results.md`, `qa-scenarios.md`, `qa-context.md` | `qa-analysis.md` |
| 23 | QA Reporter | `qa-reporter-prompt.md` | `qa-analysis.md`, `qa-results.md`, `qa-scenarios.md`, `qa-context.md` | `qa-report.md` |

### Meta-Loop Agents (used by every `/harness` invocation)

| # | Agent | Prompt File | Reads | Writes |
|---|-------|------------|-------|--------|
| 26 | Phase-Book Planner | `phase-book-planner-prompt.md` | `build-prompt.md`, `security-triage.md`, `session-state.md` | `phase-book.md` |
| 27 | Phase Verifier | `phase-verifier-prompt.md` | `phase-book.md`, current phase artifacts, working tree | `phase-evidence-{i}.md` |
| — | Phase Orchestrator (helper) | `phase-orchestrator-prompt.md` | referenced by top-level orchestrator | no direct artifacts |

Phase Orchestrator is a **reference document for the `/harness` orchestrator**, not an independent agent. The top-level command loads it to execute the Meta-Loop correctly.

---

## Shared Agents

| Agent | Prompt | Used By |
|-------|--------|---------|
| Scout | `scout-prompt.md` | `/harness` (SINGLE + TEAM), `/harness-qa` |
| Sentinel | `sentinel-prompt.md` | `/harness` (SINGLE + TEAM) |
| QA | `qa-prompt.md` | `/harness` (SINGLE + TEAM) |
| Diagnostician | `diagnostician-prompt.md` | `/harness` (SINGLE + TEAM) |
| Auditor | `auditor-prompt.md` | `/harness` (SINGLE + TEAM) |

**Note**: Shared agents use the same prompt file but receive different file paths from each orchestrator. The Diagnostician prompt is intentionally generic — it reads file paths from its task description, not from hardcoded values.

---

## Artifact Flow Map

All artifacts are written to `.harness/` (Claude) or `.harness_codex/` (Codex).

### /harness Artifact Flow (SINGLE Mode)

```
build-prompt.md (user request)
     ↓
[Scout] → build-context.md
     ↓
[Planner] → build-spec.md
     ↓
  ┌─── Round N ────────────────────────────────────────────┐
  │ snapshot-round-{N}.md (orchestrator captures)          │
  │     ↓                                                  │
  │ [Builder] → build-progress.md + code changes           │
  │     ↓                                                  │
  │ [Refiner] → build-refiner-report.md                    │
  │           → traces/round-{N}-refiner-trace.md (M/L)    │
  │     ↓                                                  │
  │ [QA] → build-round-{N}-feedback.md                     │
  │      → traces/round-{N}-qa-evidence.md (M/L)           │
  │     ↓                                                  │
  │ [Diagnostician] → diagnosis-round-{N}.md (M/L, if ≠ max)│
  │     ↓                                                  │
  │ build-history.md (orchestrator appends)                 │
  └────────────────────────────────────────────────────────┘
     ↓
[Auditor] → auditor-report.md (conditional: auditor_active)
```

### /harness Artifact Flow (TEAM Mode)

```
team-prompt.md (user request)
     ↓
[Scout] → team-context.md
     ↓
[Architect] → team-plan.md
     ↓
  ┌─── Round R ────────────────────────────────────────────┐
  │ [Worker 0] → team-worker-0-progress.md (Wave 1)       │
  │ [Worker 1..N] → team-worker-{i}-progress.md (Wave 2)  │
  │     ↓                                                  │
  │ [Sentinel ×N] → sentinel-worker-{i}-round-{R}.md      │
  │   (conditional: sentinel_active from security-triage)  │
  │     ↓                                                  │
  │ [Integrator] → team-integration-report.md (Wave 3)     │
  │     ↓                                                  │
  │ [QA] → team-round-{R}-feedback.md                      │
  │      → traces/round-{R}-qa-evidence.md                 │
  │     ↓                                                  │
  │ [Diagnostician] → team-diagnosis-round-{R}.md (if R<2) │
  │     ↓                                                  │
  │ team-history.md (orchestrator appends)                  │
  └────────────────────────────────────────────────────────┘
     ↓
[Auditor] → auditor-report.md (conditional: auditor_active)
```

---

## Codex Mirror Map

Each row maps a Claude-side prompt to its Codex copy.

### /harness mirrors (SINGLE + TEAM mode, Meta-Loop)

| Original (`harness/`) | Mirror (`codex-skills/harness/references/`) |
|----------------------|---------------------------------------------|
| `scout-prompt.md` | `scout-prompt.md` |
| `planner-prompt.md` | `planner-prompt.md` |
| `builder-prompt.md` | `builder-prompt.md` |
| `sentinel-prompt.md` | `sentinel-prompt.md` |
| `refiner-prompt.md` | `refiner-prompt.md` |
| `qa-prompt.md` | `qa-prompt.md` |
| `diagnostician-prompt.md` | `diagnostician-prompt.md` |
| `architect-prompt.md` | `architect-prompt.md` |
| `worker-prompt.md` | `worker-prompt.md` |
| `integrator-prompt.md` | `integrator-prompt.md` |
| `auditor-prompt.md` | `auditor-prompt.md` |
| `phase-book-planner-prompt.md` | `phase-book-planner-prompt.md` |
| `phase-verifier-prompt.md` | `phase-verifier-prompt.md` |
| `phase-orchestrator-prompt.md` | `phase-orchestrator-prompt.md` |
| `references/meta-loop-protocol.md` | `references/meta-loop-protocol.md` |
| `references/phase-verification-protocol.md` | `references/phase-verification-protocol.md` |
| `references/tier-matrix.md` | `references/tier-matrix.md` |
| `references/agent-containment.md` | `references/agent-containment.md` |
| `references/session-protocol.md` | `references/session-protocol.md` |

### /harness-review mirrors

| Original (`harness/`) | Mirror (`codex-skills/harness-review/references/`) |
|----------------------|---------------------------------------------------|
| `scanner-prompt.md` | `scanner-prompt.md` |
| `analyzer-prompt.md` | `analyzer-prompt.md` |
| `fixer-prompt.md` | `fixer-prompt.md` |
| `verifier-prompt.md` | `verifier-prompt.md` |
| `reporter-prompt.md` | `reporter-prompt.md` |

### /harness-docs mirrors

| Original (`harness/`) | Mirror (`codex-skills/harness-docs/references/`) |
|----------------------|-------------------------------------------------|
| `researcher-prompt.md` | `researcher-prompt.md` |
| `outliner-prompt.md` | `outliner-prompt.md` |
| `writer-prompt.md` | `writer-prompt.md` |
| `reviewer-prompt.md` | `reviewer-prompt.md` |
| `validator-prompt.md` | `validator-prompt.md` |

### /harness-qa mirrors

| Original (`harness/`) | Mirror (`codex-skills/harness-qa/references/`) |
|----------------------|-----------------------------------------------|
| `scout-prompt.md` | `scout-prompt.md` |
| `scenario-writer-prompt.md` | `scenario-writer-prompt.md` |
| `test-executor-prompt.md` | `test-executor-prompt.md` |
| `analyst-prompt.md` | `analyst-prompt.md` |
| `qa-reporter-prompt.md` | `qa-reporter-prompt.md` |

---

## Pipeline Configuration

| Pipeline | Command | Max Rounds | Diagnostician | Evidence Traces |
|----------|---------|-----------|--------------|----------------|
| `/harness` (SINGLE) | `commands/harness.md` | S=1, M=2, L=3 | M/L (before round 2+, not final) | M/L |
| `/harness` (TEAM) | `commands/harness.md` | 2 | Before round 2 | Yes |
| `/harness-review` | `commands/harness-review.md` | 1 (no loop) | No | No |
| `/harness-docs` | `commands/harness-docs.md` | S=1, M=2, L=3 | No | No |
| `/harness-qa` | `commands/harness-qa.md` | 2 | No | No |

---

## Shared Reference Checklists

Located in `harness/references/`. Agents load these on demand for progressive disclosure (token savings).

| Reference | Used By | Purpose |
|-----------|---------|---------|
| `references/security-checklist.md` | Analyzer, Refiner, Integrator, Builder | Secrets, injection, auth, input validation |
| `references/error-handling-checklist.md` | Refiner, Integrator, Builder | try/catch, loading/empty/error states, data persistence |
| `references/confidence-calibration.md` | Analyzer, Fixer, Refiner, Integrator | 0-100 scoring table with examples and action thresholds |
| `references/agent-containment.md` | Sentinel, Builder, Worker, Fixer, Test Executor | Agent containment boundaries: forbidden commands, filesystem, network, git patterns |
| `references/meta-loop-protocol.md` | Top-level orchestrator, Phase-Book Planner, Phase Verifier | Meta-Loop execution model (phase decomposition, verify/retry cycle, safety limits) |
| `references/phase-verification-protocol.md` | Phase Verifier | Standard procedure for confirming phase DoD + verify commands + cross-phase invariants |
| `references/tier-matrix.md` | Orchestrator and every tier-aware agent | Tier × Scale × Parameter reference (round limits, QA threshold, Sentinel/Auditor activation, Scale file thresholds) |

---

## Maintenance Rules

1. **When adding a new agent**: Add a row to the Agent Catalog, update Artifact Flow, add Codex Mirror entry if applicable.
2. **When modifying file paths**: Update all agents that read/write the changed path in this Index.
3. **When adding a Codex port**: Add mirror entries and ensure `cp` sync is documented.
4. **Run `/harness-lint`** after any structural change to verify consistency.
