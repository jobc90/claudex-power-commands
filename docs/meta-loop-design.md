# Meta-Loop Design — claudex v4.1.0

> **Purpose**: define the work → verify → apply → next-phase execution model that powers every `/harness` invocation starting with v4.1.0.
> **Status**: shipped in v4.1.0.
> **Authoritative references**: `harness/references/meta-loop-protocol.md`, `harness/references/phase-verification-protocol.md`, `harness/references/tier-matrix.md`, `harness/phase-book-planner-prompt.md`, `harness/phase-verifier-prompt.md`, `harness/phase-orchestrator-prompt.md`.

---

## 1. Motivation

Pre-v4.1.0 harness ran a single-pass pipeline: Scout → Planner → Builder → Refiner → QA (± Sentinel / Diagnostician / Auditor). Large requests either stretched one round beyond reason or silently produced partial output and asked the user to re-invoke.

Meta-Loop fixes this by giving the orchestrator a **book of phases** and a **verify gate** between them. The user asks once; the system runs until every phase's Definition of Done is mechanically verified, or pauses with a specific escalation reason.

This pattern is a from-scratch internal implementation of the "continue until completion" idea — commonly associated with external Ralph-style loops — adapted to harness's artifact model, its capability tiers, and its existing security / audit gates (Sentinel, Auditor).

## 2. Core Flow

```
/harness "<user request>"
  ↓
Phase 0   Capability tier + Scale + Security triage
Phase 0.7 Phase-Book Planner
          → .harness/phase-book.md
          → user approves (sole gate in the whole run)
  ↓
Meta-Loop (repeat until all phases pass or escalate):
  • Phase-internal pipeline (Scout → Planner → Builder →
    Sentinel → Refiner → QA → Diagnostician → Auditor)
  • Phase Verifier (DoD + verify commands + evidence)
  • Cross-Phase Integrity Check
  • PASS → next | FAIL → Diagnostician → retry (cap 3)
  ↓
Phase ∞-* (optional)   commit / push / deploy / PR
Phase ∞                Final Auditor + Summary
```

Small requests produce a 1-phase book and behave exactly like the pre-v4.1.0 single pass. Large requests decompose into 5–15 phases.

## 3. Phase-Book Format

Canonical file: `.harness/phase-book.md`.
Full specification: `harness/references/meta-loop-protocol.md` §3.

Key fields (YAML frontmatter):
- `total_phases`, `current_phase`, `status`
- `completion_promise` — exact sentence that becomes true at the end
- `commit_push_intent` — `none | commit | commit+push | commit+push+deploy | pr`

Each phase has: Goal, Scope, DoD (checkbox list), Verify Commands, Evidence Required, Rollback Strategy, Depends On, Estimated Rounds, Estimated Tokens.

## 4. Intent-Driven Terminal Phases

Auto-commit is **off by default**. The Phase-Book Planner parses the user's original request and, only when it detects explicit intent, appends terminal phases:

| Detected keywords | Appended phase |
|-------------------|----------------|
| `커밋`, `commit` | `Phase ∞-2: Commit` |
| `푸시`, `push`, `올려` | `Phase ∞-1: Push` |
| `배포`, `deploy`, `릴리즈`, `release` | `Phase ∞: Deploy` |
| `PR`, `풀리퀘`, `머지`, `merge` | `Phase ∞: Create PR` |

The detected value is recorded in the `commit_push_intent` frontmatter so the user can see exactly what was inferred.

## 5. Verification Gate

`harness/references/phase-verification-protocol.md` defines the procedure. Summary:

1. Read the phase's DoD, verify commands, invariants.
2. Confirm each DoD item with concrete evidence (file:line, test name, output snippet).
3. Execute every verify command in a fresh shell; capture exit + tail.
4. Re-check every cross-phase invariant.
5. Re-run verify commands of earlier phases whose files this phase touched.
6. Render PASS only when 2–5 are all green.

Evidence file: `.harness/phase-evidence-{i}.md`. One file per phase, required on every iteration.

## 6. Retry + Escalation

- Cap: **3 retries per phase**.
- On FAIL, orchestrator invokes the Diagnostician with the evidence file and retries the phase-internal pipeline.
- On 3rd FAIL, status goes to `paused`, the orchestrator emits an escalation block, and halts.

The user can `/harness` again at any time to resume from the paused phase.

## 7. Tier Interaction

`harness/references/tier-matrix.md` is the authoritative matrix. Meta-Loop-specific rows:

| Parameter | Standard | Advanced | Elite |
|-----------|----------|----------|-------|
| Phase retry cap | 3 | 3 | 3 |
| Phase Verifier rigor | DoD + verify | same | adds Auditor cross-check + quantitative claim verification |
| Max `total_phases` ceiling | 15 | 20 | 20 |

## 8. Resumability

`.harness/phase-book.md`'s `current_phase` and `status` are the single source of truth. Re-invoking `/harness` with no arguments detects the file and prompts the user to resume from `current_phase`, start fresh (`.harness` → `.harness-backup-{ts}`), or leave it paused.

## 9. What Meta-Loop is NOT

- Not a wrapper over external `/ralph-loop`. claudex does not depend on or register that plugin.
- Not parallel: phases run sequentially. The TEAM mode inside a phase is unchanged — it still runs Workers in parallel waves within a single phase.
- Not auto-committing. No git operation runs unless the user's original request contained commit/push/deploy/PR intent.
- Not reversible mid-run: phase-book body (list, DoD, verify commands) is frozen after initial approval. Only `current_phase` and `status` frontmatter fields change.

## 10. Rollout Summary

- **v4.0.0 → v4.1.0**: Meta-Loop is the default. No flag, no opt-in.
- **Backward compatibility**: small requests produce a 1-phase book and behave identically to v4.0.0 single-pass.
- **Agents added**: phase-book-planner, phase-verifier, phase-orchestrator (helper reference).
- **References added**: meta-loop-protocol.md, phase-verification-protocol.md, tier-matrix.md.

## 11. Known Future Work

- Parallel phase execution for independent dependency subgraphs (currently sequential).
- Phase-book mutation policy for mid-run replanning (currently frozen).
- Richer budget forecasting beyond Estimated Tokens summation.
- Integration with scheduled agents (dependency on harness runtime evolution).
