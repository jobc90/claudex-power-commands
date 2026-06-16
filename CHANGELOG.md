# Changelog

All notable changes to claudex-power-commands.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versions follow SemVer.

---

## [4.3.0] — 2026-06-15

### Added — Observation Grounding + Capability Escalation

Transferred procedures from two sibling harness plugins (`fivetaku/fablize`, `tmdgusya/prometheus`). **Honest status (at ship):** these shipped as procedures whose effect on claudex's model mix was **not yet A/B-measured** — the direction is sound (each closes a concrete gap below), but no validated-effectiveness claim was made.

> **Update 2026-06-16 — observation-grounding measured** (`tests/ab-results/`): a blind, mechanism-level A/B (the verify-chain isolated under ON vs OFF; model `sonnet`, effort `xhigh`) scores **KEEP** on both the in-author split (primary margin +6) and an **independent-author held-out** split (+4), with **0 false-positives** on pure-logic nulls. Caveats that travel with the claim: this is **not** a full-`/harness` validation; the ON edge concentrates on **render-geometry and execution-output** defects (a capable agent often derives obvious *code* bugs statically either way); and observation must be **paired with an explicit success criterion** or a perfect observer still passes (measured — see RESULTS finding #2, which independently validates the P0-5 DoD work). The M4/untestable degrade-path (the `UNTESTABLE` state) also scores **KEEP** (margin +6) once the OFF baseline is held to static-only (no boot): a static-only OFF false-PASSes an unbootable app ("a missing credential is a deployment issue, not a code defect"), while ON honestly caps it at `UNTESTABLE`. The other transferred procedures (capability-escalation ladder, Stop hook) remain unmeasured. Full write-up: `tests/ab-results/RESULTS-2026-06-16.md`.

**The finding driving this release:** claudex's Meta-Loop / Phase Verifier / Completion Gate are *agent-self-enforced* — the "orchestrator" is the main agent following its own prompt persona, so every gate's entrance sits on agent compliance (the "soft entrance" prometheus diagnosed when it dropped goals.py). v4.3.0 adds claudex's first *runtime-enforced* entrance and sharpens the verify chain.

### New files
- `harness/references/observation-grounding.md` — the "run + observe rendered/executable output" discipline co-located with its anti-over-verification bound (one rule, not two). The `runtime-observation-required` flag is **optional**; absent = current exit-0 behavior (backward compatible).
- `hooks/finish-the-work.sh` — a **Stop hook** (ported from fablize, MIT): claudex's first runtime-enforced completion entrance. Detects a turn ending in a promise of work ("next I'll run QA") without the work and re-engages. Deterministic, loop-guarded, excludes turns ending in a user question.
- `docs/command-agent-update-plan-v4.3.md` — the design analysis (10 readers → synthesis → 3-lens adversarial critique) and the **anti-bloat ledger** (what was deliberately cut to honor fablize's own "ship only what's needed" discipline).

### Changed
- **Meta-Loop** (`meta-loop-protocol.md`): an honest "Enforcement boundary (soft entrance)" note; a **Phase 0.5 Context Sufficiency Check** (4 questions → Scout pass before decomposing); a good-vs-bad **decomposition worked example**; a **§5.1 Capability-escalation ladder** (recommend higher effort → higher TIER label + evidence package → human) at the 3-retry-on-unchanged-root-cause terminal. Escalation is by tier label only, never a model identifier. Retry cap stays flat at 3 across tiers.
- **Verify chain** (`phase-verifier`, review `verifier`, `phase-verification-protocol`): observe `runtime-observation-required` artifacts before PASS/CLEAN — exit-0 proves well-formed, not correct. Producers tag the flag (Builder Render/Execute Observation Gate, Analyzer, Outliner `[RENDERABLE]`); observers honor it; never PASS an unobserved observable artifact.
- **QA** (`qa-prompt`): a new `UNTESTABLE` state, tightly gated against the leniency bias (only with a captured blocker error; never counts toward the grade; routes to the §5.1 ladder — Fabrication Pattern 7). `qa-reporter` embeds the Completion Gate's raw output verbatim for Auditor diffing.
- **Review** (`confidence-calibration`, `analyzer`, `reporter`): review-mode capture-then-filter (surface the 60-79 band in a Deferred tier, never silently drop; FIX thresholds unchanged). **Diagnostician**: restructured to enumerate 2-3 competing hypotheses before testing, reporting the rejected ones.
- **`/claude-dashboard`**: validates `settings.json` is well-formed JSON after editing (a botched merge bricks the user config).
- `hooks/hooks.json` registers the `Stop` hook; `harness/INDEX.md` registers `observation-grounding.md`; Codex mirrors synced.

### Deliberately NOT shipped (anti-bloat ledger)
Per fablize's "ship only what's needed" discipline: no per-prompt re-inlining of R3 (one shared reference, cited), no standalone anti-over-verification sections (it rides inside the R3 reference), no ~10 per-agent third-state variants (only QA `UNTESTABLE`), no tier-variant retry caps. See `docs/command-agent-update-plan-v4.3.md §5`.

## [4.2.0] — 2026-04-23

### Added — Completion Gate Protocol

Prevents the "declare complete → user discovers stale state" failure mode by mandating a stale-iteration-artifact scan before any pipeline-finalizing agent outputs its final report.

**Origin**: Real incident 2026-04-23. A multi-iteration provisioning workflow (4 resource attempts) left an obsolete resource ID in a status document. Multi-layer audits (dedicated plan audit + 5-agent code review) all passed because each checked *cross-document* consistency but none checked *intra-document temporal* consistency after iteration. The user caught the stale reference during final cleanup — exactly the "N-round rework" problem this protocol prevents.

### New files
- `harness/references/completion-gate-protocol.md` — canonical protocol: when to apply, what to scan (6 categories), inline bash scan, reconciliation workflow, integration points. Single source of truth; agent prompts cite this reference.
- `harness/completion-gate-template.sh` — project-agnostic scanner script. Copy to `scripts/completion-gate.sh` in your project, customize for project-specific patterns.

### Agent prompts updated (MANDATORY gate invocation)
- `harness/reporter-prompt.md` — Reporter MUST run the gate before writing `.harness/review-report.md`. Report is INVALID without a `Completion Gate: ✅/🟡/❌ …` attestation line.
- `harness/qa-reporter-prompt.md` — QA Reporter MUST run the gate before writing `.harness/qa-report.md`. A Grade-A QA report with a terminated-resource reference is worse than useless.
- `harness/integrator-prompt.md` — Integrator (TEAM mode) MUST run the gate AND scan Worker progress reports for stale intermediate references before merging.
- `harness/refiner-prompt.md` — Refiner gains secondary responsibility: reconcile Builder's intermediate iteration artifacts before QA sees them.
- `harness/auditor-prompt.md` — Auditor now verifies the Reporter actually executed the gate (checks for attestation line) and independently re-runs the scan to catch fabricated PASS lines.

### Commands updated (Phase integration)
- `commands/harness.md` Phase 5 Summary — inline gate invocation snippet added. Gate must PASS before user-facing summary. Unresolved CRITICAL blocks "complete" declaration.
- `commands/harness-review.md` Phase 6 Report + Git — gate PASS is required before any git action flag is honored. Gate failure blocks `--commit`/`--push`/`--pr` even if review verdict is PASS.
- `commands/harness-qa.md` Phase 5 Report — gate invocation note added, delegated to QA Reporter agent.

### Scan categories (protocol §2)
1. Infrastructure resource IDs — live state cross-check via `aws ec2 describe-instances` (terminated = CRITICAL)
2. Managed Agents / API artifacts — `sesn_*`, `vlt_*`, `agent_*` references
3. WIP markers — Korean (진행 중, TBD, 추정) + English (in progress, TODO: update, <PLACEHOLDER>)
4. Version reference drift — v1/v2/v3 outside history sections
5. Step status contradictions — same step labeled "진행 중" in one file, "완료" in another
6. Date / SHA / PR-number drift (optional)

### Why it matters
Single-pass audits (including dedicated review skills) catch *cross-document* stale references only. Iteration-artifact reconciliation requires *intra-document temporal* awareness — comparing what was written mid-iteration against the final successful state. This protocol adds that layer at every agent that produces a "done" declaration.

### Codex mirror
Codex-side SKILL.md files inherit the behavior through their shared agent prompt references. No Codex-specific changes required for v4.2.0.

---

## [4.1.0] — 2026-04-17

### Added

- **Meta-Loop**, the default execution model for `/harness`. Every invocation:
  - Decomposes the user's request into a **phase-book** (`.harness/phase-book.md`) via the new `phase-book-planner` agent.
  - Runs each phase through the harness pipeline + a new `phase-verifier` gate + cross-phase integrity check.
  - Retries failing phases up to 3× before pausing with a structured escalation.
  - Small requests produce a 1-phase book and behave identically to the pre-v4.1.0 single-pass flow (backward compatible).
  - Commit / push / deploy / PR intent detected in the user's request becomes a terminal phase automatically. Auto-commit is off otherwise.
- **Capability tier detection** with internal labels `Standard / Advanced / Elite`. Explicit environment-driven allowlist (`CLAUDEX_ELITE_MODELS`) and override (`CLAUDEX_TIER_OVERRIDE`). No model identifiers or version numbers are exposed in user-facing output or agent prompts.
- New agent prompts: `phase-book-planner-prompt.md`, `phase-verifier-prompt.md`, `phase-orchestrator-prompt.md` (helper reference).
- New references: `harness/references/meta-loop-protocol.md`, `harness/references/phase-verification-protocol.md`, `harness/references/tier-matrix.md`.
- Elite-tier enhanced checks across agents:
  - Sentinel: silent scope creep, evidence backdating, reinforced hook-bypass / force-push / amend detection.
  - Auditor: quantitative claim verification, cross-agent claim consistency, phase boundary integrity.
  - QA: explicit anti-sycophancy rules under Elite (no "close enough", no vague affirmations, demand quantitative evidence).
  - Builder: optional SHA-256 before/after hashes on FILE_MODIFY, mandatory SUBAGENT_SPAWN logging.
  - Worker: containment-by-default, HIGH-sensitivity file gating, sub-agent spawn forbidden under Elite.
  - Refiner: hook / protection bypass self-check; Elite self-review on prompt-injection and diff size.
  - Diagnostician: cross-phase regression mode for Meta-Loop.
- New docs: `docs/meta-loop-design.md`, `docs/capability-detection.md`.

### Changed

- `/harness`, `/harness-docs`, `/harness-qa`, `/harness-review` now detect tier at Phase 0 and consult `harness/references/tier-matrix.md` for tier-aware round limits, QA threshold, Sentinel/Auditor activation, and Scale file thresholds.
- `/harness` Phase 0.5 Security Triage adds Elite-tier overrides (MEDIUM auto-activates Sentinel; Auditor always on).
- `/harness` Phase 4 `Max rounds` table becomes `tier × scale` (Elite L=2 rounds, Elite M=1 round).
- `/harness` adds Phase 0.7 (Phase-Book Planner) and Phase 4-verify (Phase Verifier) stages.
- QA, Scout, Auditor, Planner, Diagnostician prompts now read `tier:` from `.harness/session-state.md` and adapt behavior.
- `plugin.json` description rewritten for v4.1.0.
- `harness/INDEX.md` reflects 27 prompts + 1 helper, Meta-Loop agents, new references, updated Codex mirror map.
- `harness/INDEX.md` header: "25 prompts" → "27 prompts + 1 helper".
- All references to prior preview codename and specific model version numbers removed from live sources (commands/, agent prompts, references, Codex mirrors). Preview codename preserved only in the renamed history file `docs/harness-hardening-plan-v3.md`.

### Renamed

- `docs/mythos-harness-improvement-plan.md` → `docs/harness-hardening-plan-v3.md` (git mv; original content preserved as historical record of the v3.3 / v3.4 / v3.5 hardening work).

### Migration Notes

- No user-facing command change. `/harness "<task>"` continues to work the same way for small tasks.
- Large tasks now get decomposed automatically. Users will see a "Phase book: N phases. Intent: {...}. Approve? (Y/N/edit)" prompt once. After approval, the run completes without further confirmation.
- To activate Elite-tier behavior for your runtime model, set `CLAUDEX_ELITE_MODELS` in your shell profile. See `docs/capability-detection.md`.
- `.harness/` now contains additional artifacts per phase (`phase-book.md`, `phase-evidence-{i}.md`, `phase-history.md`, `phase-{i}/` subdirectories for multi-phase runs). Consider adding `.harness/` to your project `.gitignore` if you do not already.

---

## [4.0.0] — 2026-03-09

### Changed

- `/harness-team` merged into `/harness` as TEAM mode.
- 25 agent prompts with elite-ready containment, Security Triage, Adaptive Scale Protocol.
- Sentinel + Auditor added.

(Earlier releases predate this changelog.)
