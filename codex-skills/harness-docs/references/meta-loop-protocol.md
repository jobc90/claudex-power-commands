# Meta-Loop Protocol

> **Authoritative design document for the Meta-Loop execution model in claudex harness.**
> Loaded by the orchestrator and the phase-book-planner / phase-verifier / phase-orchestrator agents.

---

## 1. What Meta-Loop Is

Meta-Loop is the default and only execution model of `/harness`. When the orchestrator receives a user request, it:

1. Writes a **phase-book** — a structured decomposition of the request into N executable phases, each with its own Definition of Done (DoD), verify commands, rollback strategy, and evidence requirements.
2. Executes each phase through a **work → verify → apply** cycle, reusing the harness's internal build pipeline (Scout → Planner → Builder → Sentinel → Refiner → QA → Diagnostician → Auditor) as the "work" step.
3. Repeats the cycle for every phase until either all phases satisfy their DoD, or a phase fails three times in a row (hard retry cap).

The loop is **self-terminating**: completion is tied to the phase-book's `completion_promise`, not to session end or user intervention.

### Degradation for small requests

A request that would have fit in a single pass under the pre-Meta-Loop design gets a phase-book with exactly **one** phase. The orchestrator detects this and runs the phase-internal pipeline once, producing behavior indistinguishable from the pre-Meta-Loop single-pass flow.

This is the compatibility guarantee: **small requests are unchanged; large requests unlock phase decomposition.**

---

## 2. When Meta-Loop Activates

Always, for every `/harness` invocation. There is no flag, no opt-in, no opt-out.

The phase-book-planner decides — based on the request scope — how many phases to create. Small requests get a 1-phase book. Large requests get 5–15 phases.

### Resume path

If `.harness/phase-book.md` already exists at session start with `status: in_progress`, the orchestrator prompts the user:

```
Existing phase-book detected (phase {current} of {total}, status: in_progress).
Resume? (Y/N/reset)
```

- `Y` → continue from `current_phase`
- `N` → pause (user may edit the phase-book manually)
- `reset` → archive the existing `.harness/` to `.harness-backup-{timestamp}/` and start fresh

---

## 3. Phase-Book Structure

Canonical path: `.harness/phase-book.md`

### YAML frontmatter (required)

```yaml
---
total_phases: 5
current_phase: 1
status: in_progress   # pending | in_progress | complete | paused | failed
created_at: 2026-04-17T14:22:10Z
completion_promise: "ALL PHASES COMPLETE — {one-line goal}"
commit_push_intent: none   # none | commit | commit+push | commit+push+deploy | pr
---
```

### Body (required sections)

```markdown
# Phase Book — {goal}

## Global Goal
{full restatement of the user's request + the concrete success criteria}

## Phase 1: {imperative name}
- **Goal**: {what this phase delivers}
- **Scope**: {files / modules / endpoints / directories touched}
- **DoD** (Definition of Done):
  - [ ] {functional criterion 1}
  - [ ] {functional criterion 2}
  - [ ] {non-functional criterion, if any}
- **Verify Commands**:
  ```bash
  {cmd 1}
  {cmd 2}
  ```
- **Evidence Required**: {artifact filenames, test output lines, screenshots, etc.}
- **Rollback Strategy**: {exact steps to revert if this phase breaks cross-phase invariants}
- **Depends On**: {comma-separated phase numbers, or "none"}
- **Estimated Rounds**: {1–3, the phase-internal build loop rounds}
- **Estimated Tokens**: {rough estimate from the phase-book-planner}

## Phase 2: ...
## Phase N: ...

## Cross-Phase Invariants
{conditions that must hold after every phase; verified by Phase Verifier at each phase's end}

## Completion Promise
{exact sentence that becomes true when every phase passes verification}
```

### Intent-driven terminal phases

If the phase-book-planner detects commit/push/deploy/PR intent in the user's request, it appends corresponding terminal phases to the book:

- Intent contains `커밋`, `commit` → `Phase ∞-2: Commit`
- Intent contains `푸시`, `push`, `올려` → `Phase ∞-1: Push`
- Intent contains `배포`, `deploy`, `릴리즈`, `release` → `Phase ∞: Deploy`
- Intent contains `PR`, `풀리퀘`, `머지`, `merge` → `Phase ∞: Create PR`

The detected value is recorded in the `commit_push_intent` frontmatter field. **No terminal phase is added when no intent is detected.** Auto-commit is off by default.

---

## 4. Execution Flow

```
/harness "<user request>"
  │
  ▼
Phase 0    Triage (Capability tier + Scale + Security triage)
  │
  ▼
Phase 0.7  Phase-Book Planner
  │         → writes .harness/phase-book.md
  │         → announces: "Phase book: {N} phases. Intent: {none|commit|push|deploy|pr}."
  │         → waits for user approval (Y / N / edit)
  │
  ▼
┌─────────────────────────────────────────────────────────────────┐
│  Meta-Loop (for each phase i = 1..N):                           │
│                                                                 │
│    a. Announce "Phase {i}/{N}: {phase name}"                    │
│    b. Run phase-internal pipeline:                              │
│         Scout → Planner → Builder → Sentinel → Refiner →        │
│         QA → Diagnostician → Auditor                            │
│       (scale = this phase's estimated complexity                │
│        rounds = min(phase.estimated_rounds, tier-matrix cap))   │
│    c. Run Phase Verifier:                                       │
│         - Check each DoD item                                   │
│         - Execute verify commands, capture exit codes + output  │
│         - Write .harness/phase-evidence-{i}.md                  │
│    d. Branch:                                                   │
│         PASS → phase-book.md current_phase += 1 → next phase    │
│         FAIL → Diagnostician root-cause → same phase retry      │
│                (retry cap: 3)                                   │
│                after 3 failures → status: paused, escalate      │
│    e. Cross-Phase Integrity Check:                              │
│         If this phase touched files owned by earlier phases,    │
│         re-execute the earlier phase's verify commands.         │
│         Any regression → status: paused, escalate.              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
  │
  ▼
Phase ∞    Final Auditor (cross-phase consistency) + Summary
  │
  ▼
Exit
```

No user gate exists between phases after initial approval. The orchestrator runs the loop to completion, pausing only for (a) 3-retry failure, (b) cross-phase regression, or (c) explicit Sentinel BLOCK that cannot be resolved by Diagnostician.

---

## 5. Safety Limits

| Limit | Value | Enforcement |
|-------|-------|-------------|
| Retry cap per phase | 3 | `phase-verifier-prompt.md` + orchestrator |
| Max total phases | 20 | phase-book-planner refuses >20; escalates |
| Max tokens per phase | Warned at 75% of session budget; hard stop at 95% | orchestrator |
| Max wall time per phase | 30 min before progress check | orchestrator |
| Cross-phase regression | immediate pause | Phase Verifier |
| Sentinel BLOCK | pause current phase, ask user | orchestrator |

### What triggers escalation to the user

- Any phase fails 3 consecutive retries with Diagnostician root cause unchanged.
- Cross-Phase Integrity Check detects that a later phase broke a verified-earlier phase.
- Sentinel BLOCK verdict on the current phase.
- `total_phases` would exceed 20 during initial planning.
- Token budget reaches 95% hard stop.

Escalation format:

```markdown
⏸️ Meta-Loop paused at Phase {i}/{N}: {phase name}

Cause: {one of: 3-retry exhausted | cross-phase regression | Sentinel BLOCK | budget stop}

Evidence:
  - {pointer to evidence / report file}

Recommended next step:
  1. {option A}
  2. {option B}
  3. abort
```

---

## 6. Tier Interaction

Meta-Loop behavior adapts to the detected capability tier (see `tier-matrix.md`):

| Parameter | Standard | Advanced | Elite |
|-----------|----------|----------|-------|
| Phase retry cap | 3 | 3 | 3 |
| Phase Verifier rigor | basic DoD + verify commands | basic | enhanced (Auditor cross-checks each evidence file) |
| Max total_phases ceiling | 15 | 20 | 20 |
| Parallel phase execution | disabled | disabled | disabled (future work) |

---

## 7. Artifact Contract

| Artifact | Writer | Readers |
|----------|--------|---------|
| `.harness/phase-book.md` | phase-book-planner (initial); orchestrator (current_phase, status updates) | all agents (read-only after initial write) |
| `.harness/phase-evidence-{i}.md` | Phase Verifier | Auditor, orchestrator |
| `.harness/phase-{i}/*.md` | phase-internal agents (Scout, Planner, Builder, …) | next-phase agents, Final Auditor |
| `.harness/phase-history.md` | orchestrator (append-only) | Final Auditor |

Phase-internal artifacts live under `.harness/phase-{i}/` when `total_phases > 1`. When `total_phases == 1`, artifacts live directly under `.harness/` for backward compatibility with the pre-Meta-Loop flow.

---

## 8. Non-Goals

- Parallel phase execution (phases run sequentially; dependency graph is linear or respects `Depends On`).
- Distributed multi-agent orchestration beyond the existing SINGLE/TEAM mode inside each phase.
- Automatic phase-book mutation during execution (phase-book is frozen after initial approval; only `current_phase` and `status` change).
- Support for external `/ralph-loop` plugin wrapping (Meta-Loop fully replaces that pattern for `/harness`).

---

## 9. Relationship to External ralph-loop Plugin

claudex does not depend on, register, or wrap the external `/ralph-loop` plugin. Meta-Loop is a from-scratch internal implementation of the same underlying pattern ("continue until completion"), adapted to harness's artifact model and retry semantics.

Users who prefer the turn-based, prompt-replay style of `/ralph-loop` may continue to use that plugin independently. Mixing is discouraged: running `/ralph-loop` with a harness task inside will produce two overlapping loop mechanisms with undefined termination behavior.
