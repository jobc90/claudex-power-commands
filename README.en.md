# claudex-power-commands

**English** | [한국어](README.md)

> A 7-command harness suite for Claude Code, mirrored as 7 skills for Codex
>
> **v4.5.0**: `/harness-think` (Surveyor) — a **read-only** codebase-anchored decision/feasibility discussion command (Scope-Gate → cite-or-abstain Ground → Discuss → Handoff seed) that never builds or edits. Its grounding discipline is **A/B-measured KEEP** on both an in-author and an independent-author held-out split (M8, margin +4 each, FP 1/2). 0 new agent prompts; Codex mirror added. Honest ceiling: grounding lowers repo-fact escape, it does not eliminate it. Write-up: `tests/ab-results/RESULTS-grounding.md`.
> **v4.4.0**: Whitepaper-alignment (measured) — observation-grounding is now **A/B-measured KEEP** on both an in-author and an independent-author held-out split (+ M4 untestable KEEP, 0 false-positives). Adds Conductor mode (`/harness --quick`), a Curator agent (approval-gated learned-rules → AGENTS.md), a Trajectory Reporter, deterministic guard hooks (PreToolUse/commit), Builder/Refiner DoD-Check, Summary Residual-Risk, and an eval + golden-regression suite (`tests/`). Write-up: `tests/ab-results/RESULTS-2026-06-16.md`.
> **v4.3.0**: Observation Grounding + Capability Escalation — starts from the finding that claudex's gates are *agent-self-enforced* (a soft entrance). Adds a **Stop hook** (claudex's first runtime-enforced completion entrance), **observe-the-rendered-output** in the verify chain (exit-0 = well-formed, not correct), a **§5.1 capability-escalation ladder** at the 3-retry ceiling (raise effort → higher TIER + evidence package → human), context-first decomposition, and a QA `UNTESTABLE` state. Transferred from fablize/prometheus; **effect on claudex's model mix not yet A/B-measured**.
> **v4.2.0**: Completion Gate protocol — finalizing agents scan for stale iteration artifacts before declaring complete.
> **v4.1.0**: Meta-Loop is the default — `/harness` decomposes every request into a phase-book and runs work→verify→apply cycles until every phase's DoD passes. Small requests degrade to a 1-phase book (backward compatible).
> **v4.0.0**: `/harness-team` merged into `/harness` as TEAM mode

The source of truth is the harness-based command suite first organized on the Claude side, then ported to Codex with the same shape.

- Claude source of truth: 7 files in `commands/`
- Codex ports: 7 matching skills in `codex-skills/`
- Shared harness prompt bundle: 29 agent prompts + 1 orchestrator helper in `harness/`
- Reference checklists: 12 files in `harness/references/`

### v4.1.0 — Meta-Loop + Capability Detection

| Change | Description | Impact |
|--------|-------------|--------|
| **Meta-Loop (default)** | `/harness` auto-writes `phase-book.md` and runs work → verify → apply per phase | One request, run to completion without user babysitting |
| **Phase Verifier** | Executes each phase's DoD + verify commands for real, writes `phase-evidence-{i}.md` | Blocks evidenceless PASS; retry cap of 3 |
| **Intent auto-detection** | Commit / push / deploy / PR keywords in the request append terminal phases | Auto-commit off by default; explicit intent is honored |
| **Capability Tier (Standard / Advanced / Elite)** | `CLAUDEX_ELITE_MODELS` allowlist + `CLAUDEX_TIER_OVERRIDE` | Tier-aware round limits, QA threshold, Sentinel/Auditor activation |
| **Elite-tier reinforcements** | Sentinel (scope creep / evidence backdating), Auditor (quantitative claim verification), QA (anti-sycophancy) | Defense against subtle frontier-model mistake patterns |
| **Cross-Phase Integrity** | Re-verifies earlier phases when later phases touch their files | Keeps multi-phase runs consistent |

Design docs: `docs/meta-loop-design.md`, `docs/capability-detection.md`.

### v3.2.0 — Managed Agents-Inspired Session Protocol

Inspired by Anthropic's [Managed Agents](https://www.anthropic.com/engineering/managed-agents) architecture, 7 features were added:

| Feature | Description | Impact |
|---------|-------------|--------|
| **Session Protocol** | Track session state in `.harness/session-state.md` + resume | Avoid full restart on Scale L interruptions |
| **Unified Event Log** | Append-only timeline in `.harness/session-events.md` | Better pattern recognition + debugging |
| **Selective Context** | 3-tier context hierarchy for Round 2+ Builder | Token savings + improved agent focus |
| **Worktree Isolation** | `isolation: "worktree"` for Team Workers | True parallel safety (official Claude Code feature) |
| **Model Selection** | All subagents inherit the parent session model (no per-role downgrade) | Single session-model control knob |
| **Execution Audit** | Builder/Refiner action logs for Diagnostician | More accurate root cause analysis, fewer rounds |
| **Background Diagnostician** | `run_in_background` for Scale L | Reduced wait time |

---

## Commands

| Command | Pipeline | Purpose |
|---|---|---|
| `/harness` | SINGLE: Scout -> Planner -> Builder -> Refiner -> QA / TEAM: Scout -> Architect -> Workers(N) -> Integrator -> QA | Adaptive builder (SINGLE/TEAM auto-selection, S/M/L) |
| `/harness-docs` | Researcher -> Outliner -> Writer -> Reviewer + Validator | Documentation generation (S/M/L) |
| `/harness-review` | Scanner -> Analyzer -> Fixer -> Verifier -> Reporter | Code review + git handoff |
| `/harness-qa` | Scout -> Scenario Writer -> Test Executor -> Analyst -> Reporter | Functional QA testing |
| `/harness-think` | Scope-Gate -> Ground (cite-or-abstain) -> Discuss -> Handoff | Read-only codebase-anchored decision/feasibility discussion (Surveyor; 0 sub-agents) |
| `/design` | Setup tool | 3-dial design-system control |
| `/claude-dashboard` | Setup tool | Statusline setup |

## Harness Agents

| Group | Agents |
|---|---|
| `/harness` (SINGLE) | `scout`, `planner`, `builder`, `refiner`, `qa`, `diagnostician`, `sentinel`, `auditor` |
| `/harness` (TEAM) | `scout`, `architect`, `worker`, `integrator`, `sentinel`, `qa`, `diagnostician`, `auditor` |
| `/harness-docs` | `researcher`, `outliner`, `writer`, `reviewer`, `validator` |
| `/harness-review` | `scanner`, `analyzer`, `fixer`, `verifier`, `reporter` |
| `/harness-qa` | `scenario-writer`, `test-executor`, `analyst`, `qa-reporter` plus reused `scout` |

There are 29 prompt templates + 1 orchestrator helper under `harness/`, plus 12 reference checklists in `harness/references/`. Meta-Loop agents: `phase-book-planner`, `phase-verifier`, `phase-orchestrator` (helper). `/harness-think` adds no agent prompts — it is an inline, read-only command whose discipline lives in `references/think-grounding.md`.

---

## Codex Ports

In Codex, use skills with the same names instead of slash commands:

```text
Use $harness ...
Use $harness-docs ...
Use $harness-review ...
Use $harness-qa ...
Use $harness-think ...
Use $design ...
Use $claude-dashboard ...
```

The current Codex port mirrors the Claude structure one-for-one:

- `codex-skills/harness`
- `codex-skills/harness-docs`
- `codex-skills/harness-review`
- `codex-skills/harness-qa`
- `codex-skills/harness-think`
- `codex-skills/design`
- `codex-skills/claude-dashboard`

The previous Codex skills `check`, `cowork`, `docs`, and `super` were removed instead of being kept as legacy shims.

### Codex Usage Examples

```text
Use $harness to implement this app.
Use $harness --team --agents 4 for this multi-module feature.
Use $harness-docs to document this repository.
Use $harness-review --dry-run on the current diff.
Use $harness-review --pr after verification passes.
Use $harness-qa --quick on the staging URL.
Use $harness-think on whether to merge a branch before a migration.
Use $design init for this frontend project.
Use $claude-dashboard to configure the statusline.
```

### Codex Port Principles

- Keep the same 7 names as the Claude commands.
- Keep the same harness pipelines and agent roles.
- Bundle the needed prompt templates under `codex-skills/*/references/`.
- Use `design` as the shared design controller for `$harness`.
- Do not depend on an upper-layer router skill such as `super`.

---

## Install

### Claude Code

```bash
# 1. Clone
git clone https://github.com/jobc90/claudex-power-commands.git

# 2. Copy commands
cp claudex-power-commands/commands/*.md ~/.claude/commands/

# 3. Copy harness prompts + reference checklists
mkdir -p ~/.claude/harness/references
cp claudex-power-commands/harness/*.md ~/.claude/harness/
cp claudex-power-commands/harness/references/*.md ~/.claude/harness/references/

# 4. Verify
# In a new session, /harness /harness-docs /harness-review /harness-qa /harness-think /design /claude-dashboard should appear
```

### Codex

```bash
# 1. Clone
git clone https://github.com/jobc90/claudex-power-commands.git

# 2. Create the skill directory
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills"

# 3. Sync the 7 skills
for skill in harness harness-docs harness-review harness-qa harness-think design claude-dashboard; do
  rsync -a --delete "claudex-power-commands/codex-skills/$skill/" "${CODEX_HOME:-$HOME/.codex}/skills/$skill/"
done
rm -rf "${CODEX_HOME:-$HOME/.codex}/skills/harness-team"

# 4. Verify
# In a new Codex session, invoke $harness $harness-docs $harness-review $harness-qa $harness-think $design $claude-dashboard
```

---

## File Structure

```text
claudex-power-commands/
├── commands/
│   ├── harness.md
│   ├── harness-docs.md
│   ├── harness-review.md
│   ├── harness-qa.md
│   ├── harness-think.md
│   ├── design.md
│   └── claude-dashboard.md
├── harness/
│   ├── references/
│   │   ├── session-protocol.md   # Session state, event log, model routing, execution audit
│   │   ├── team-build-protocol.md # TEAM mode wave execution, worker isolation, integration
│   │   ├── security-checklist.md
│   │   ├── error-handling-checklist.md
│   │   └── confidence-calibration.md
│   ├── scout-prompt.md
│   ├── planner-prompt.md
│   ├── builder-prompt.md
│   ├── refiner-prompt.md
│   ├── qa-prompt.md
│   ├── researcher-prompt.md
│   ├── outliner-prompt.md
│   ├── writer-prompt.md
│   ├── reviewer-prompt.md
│   ├── validator-prompt.md
│   ├── scanner-prompt.md
│   ├── analyzer-prompt.md
│   ├── fixer-prompt.md
│   ├── verifier-prompt.md
│   ├── reporter-prompt.md
│   ├── architect-prompt.md
│   ├── worker-prompt.md
│   ├── integrator-prompt.md
│   ├── scenario-writer-prompt.md
│   ├── test-executor-prompt.md
│   ├── analyst-prompt.md
│   └── qa-reporter-prompt.md
├── codex-skills/
│   ├── harness/
│   ├── harness-docs/
│   ├── harness-review/
│   ├── harness-qa/
│   ├── harness-think/
│   ├── design/
│   └── claude-dashboard/
├── dashboard/
├── hooks/
├── rules/
├── README.md
└── README.en.md
```

---

## Notes

- `commands/` and `codex-skills/` now share the same 7-command set.
- Each Codex skill includes its own bundled `references/` prompt templates.
- `claude-dashboard` is still a Claude Code setup skill even when invoked from Codex because it edits `~/.claude/settings.json`.

## License

MIT
