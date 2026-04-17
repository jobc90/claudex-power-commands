# Changelog

All notable changes to claudex-power-commands.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versions follow SemVer.

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
