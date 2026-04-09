# claudex-power-commands

**English** | [한국어](README.md)

> A 6-command harness suite for Claude Code, mirrored as 6 skills for Codex
>
> **v4.0.0**: `/harness-team` merged into `/harness` as TEAM mode

The source of truth is the harness-based command suite first organized on the Claude side, then ported to Codex with the same shape.

- Claude source of truth: 6 files in `commands/`
- Codex ports: 6 matching skills in `codex-skills/`
- Shared harness prompt bundle: 25 agent prompts in `harness/`
- Reference checklists: 5 files in `harness/references/`

### v3.2.0 — Managed Agents-Inspired Session Protocol

Inspired by Anthropic's [Managed Agents](https://www.anthropic.com/engineering/managed-agents) architecture, 7 features were added:

| Feature | Description | Impact |
|---------|-------------|--------|
| **Session Protocol** | Track session state in `.harness/session-state.md` + resume | Avoid full restart on Scale L interruptions |
| **Unified Event Log** | Append-only timeline in `.harness/session-events.md` | Better pattern recognition + debugging |
| **Selective Context** | 3-tier context hierarchy for Round 2+ Builder | Token savings + improved agent focus |
| **Worktree Isolation** | `isolation: "worktree"` for Team Workers | True parallel safety (official Claude Code feature) |
| **Model Selection** | Per-agent optimal model routing (sonnet/opus) | Faster execution + cost reduction |
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

There are 25 prompt templates under `harness/`, plus 5 reference checklists in `harness/references/`.

---

## Codex Ports

In Codex, use skills with the same names instead of slash commands:

```text
Use $harness ...
Use $harness-docs ...
Use $harness-review ...
Use $harness-qa ...
Use $design ...
Use $claude-dashboard ...
```

The current Codex port mirrors the Claude structure one-for-one:

- `codex-skills/harness`
- `codex-skills/harness-docs`
- `codex-skills/harness-review`
- `codex-skills/harness-qa`
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
Use $design init for this frontend project.
Use $claude-dashboard to configure the statusline.
```

### Codex Port Principles

- Keep the same 6 names as the Claude commands.
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
# In a new session, /harness /harness-docs /harness-review /harness-qa /design /claude-dashboard should appear
```

### Codex

```bash
# 1. Clone
git clone https://github.com/jobc90/claudex-power-commands.git

# 2. Create the skill directory
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills"

# 3. Copy the 6 skills
cp -R claudex-power-commands/codex-skills/harness "${CODEX_HOME:-$HOME/.codex}/skills/"
cp -R claudex-power-commands/codex-skills/harness-docs "${CODEX_HOME:-$HOME/.codex}/skills/"
cp -R claudex-power-commands/codex-skills/harness-review "${CODEX_HOME:-$HOME/.codex}/skills/"
cp -R claudex-power-commands/codex-skills/harness-qa "${CODEX_HOME:-$HOME/.codex}/skills/"
cp -R claudex-power-commands/codex-skills/design "${CODEX_HOME:-$HOME/.codex}/skills/"
cp -R claudex-power-commands/codex-skills/claude-dashboard "${CODEX_HOME:-$HOME/.codex}/skills/"

# 4. Verify
# In a new Codex session, invoke $harness $harness-docs $harness-review $harness-qa $design $claude-dashboard
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

- `commands/` and `codex-skills/` now share the same 6-command set.
- Each Codex skill includes its own bundled `references/` prompt templates.
- `claude-dashboard` is still a Claude Code setup skill even when invoked from Codex because it edits `~/.claude/settings.json`.

## License

MIT
