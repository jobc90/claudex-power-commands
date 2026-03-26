# claudex-power-commands

**English** | [한국어](README.md)

> 5 power commands/skills for [Claude Code](https://claude.ai/code) and Codex

Run code review, team orchestration, large-scale automation, structured documentation, and frontend design through Claude Code slash commands and Codex skills.

---

## At a Glance

```
/check  — Done coding → review → fix → verify → report next step (5 min)
/cowork — Big task → distribute to agent team → parallel implementation → merge → verify (15 min)
/super  — Idea → plan → implement → review → deploy → document (30 min+)
/docs   — Auto-detect doc type → research → structure → write → proofread (10 min)
/design — 3-dial (V/M/D) + presets for frontend design quality control
```

### When to Use What?

#### /check — Code is done, time to review and verify

```bash
/check                          # Review → fix → verify → report next step
/check --dry-run                # Review only (no fix/commit)
/check --commit                 # Commit after verification
/check --push                   # Commit + push after verification
/check --pr                     # Commit + push + create a GitHub PR
```

#### /cowork — Split a big task across a team

```bash
/cowork Add refund feature to payment module
/cowork --agents 4 large-scale refactoring     # Deploy 4 agents simultaneously
```

#### /super — From idea to finish line

```bash
# Default: plan → implement → review → deploy
/super Add 2FA to login
/super --pr Payment module refactoring

# When you already have a spec
/super --skip-discover PRD already exists, start from Plan

# Include design for full service implementation (most powerful)
/super --design soft Read the spec and design.md, implement the entire service
/super --design dashboard --pr Implement admin dashboard and create PR

# Auto-detects design.md in your project (no flag needed)
/super Implement the entire service
```

#### /docs — Write/update/organize documentation

```bash
/docs Write a README for this project
/docs --type prd Payment module feature spec
/docs Organize last meeting's transcript
/docs --dry-run Just outline the architecture doc structure
/docs Full project documentation
```

#### /design — Frontend design

```bash
# Generate design system (one-time)
/design init                             # Analyze project → generate design.md

# Use by purpose
/design --landing SaaS landing page       # Agency-grade premium
/design --dashboard Real-time monitoring   # Dashboard/terminal
/design --workspace Team collaboration     # Minimal editorial
/design --admin Admin panel               # Dense data UI

# Fine-tune with custom dials
/design --v 8 --m 7 --d 2 Luxury brand landing

# Upgrade existing project design
/design init                             # "Make it flashier" → update design.md
/design --redesign Design refactoring

# Integrate with /super (easiest approach)
/design init                             # Generate design.md
/super Implement the service              # Auto-detects design.md → applies design
```

#### Recommended Workflows

```bash
# New service from scratch
/design init                    # Step 1: Define design system
/super Implement based on spec   # Step 2: Plan→build→review→deploy (design auto-applied)

# Design renewal for existing service
/design init                    # Step 1: Analyze current design → set goals
/super Design refactoring        # Step 2: Change design only (preserve functionality)

# Quick feature add and commit
(after coding)
/check --pr                     # Review→fix→verify→PR in one shot
```

### Codex Version

This repository contains both the original slash commands for `Claude Code` and ported skills for `Codex`.

- Claude Code originals: `commands/`
- Codex ports: `codex-skills/`

In Codex, invoke skills instead of slash commands:

```text
Use $check ...
Use $cowork ...
Use $super ...
Use $docs ...
Use $design ...
Use $harness ...
Use $harness-docs ...
```

### Codex-only Added Skills

The Codex port also includes these 2 skills:

- `harness`: autonomous app-building with a `.harness/` file handoff, spec generation, implementation, and Playwright QA rounds
- `harness-docs`: autonomous documentation generation with a `.harness-docs/` file handoff, research, drafting, and source-backed review rounds

```text
Use $harness to autonomously build a substantial application with planner, builder, and QA rounds.
Use $harness-docs to research a codebase, draft documentation, and fact-check it before finalizing.
```

---

## /check — Parallel Code Review + Auto-fix + Verify

Your changed code is reviewed by **5 agents simultaneously**. CRITICAL/HIGH issues are auto-fixed, then build verification runs. Git actions (commit/push/PR) are opt-in via explicit flags.

### 5 Review Agents

| Agent | Type | Review Area |
|-------|------|------------|
| code-reviewer | built-in subagent | Naming, DRY, complexity, error handling |
| code-simplifier | built-in subagent | Unnecessary abstractions, duplicate logic, simpler alternatives |
| silent-failure-hunter | built-in subagent | Empty catches, ignored return values, unhandled Promises |
| type-design-analyzer | built-in subagent | Unsafe `as`/`any`, missing generics, weak types |
| security | general-purpose (security prompt) | CWE Top 25 + STRIDE threat modeling |

### Execution Flow

```
Collect changed files → 5 agents review in parallel → auto-fix → build+lint+test → report verified state
```

### Usage

```bash
/check              # Review → fix → verify → report next step
/check --dry-run    # Review results only (no fix/commit)
/check --commit     # Commit after verification
/check --push       # Commit + push after verification
/check --pr         # Commit + push + create a GitHub PR
```

---

## /cowork — Conductor + Agent Teams Parallel Orchestration

A Conductor analyzes the codebase and distributes work across agent teams.

**Core rule:** The Conductor writes zero lines of code. Recon → plan → distribute → merge → verify only.

### 6-Phase Execution

| Phase | Role | Tools/Commands Used |
|-------|------|---------------------|
| **1. Recon** | Understand codebase structure | Explore agent + code-architect |
| **2. Plan** | Split work into independent units | PM commands (/write-prd, /write-stories, /test-scenarios) |
| **3. Distribute** | Invoke agents per Wave + model selection | Agent tool parallel execution (haiku/sonnet/opus per task) |
| **3.5 Slice Review** | Verify each worker's spec compliance + ownership | Diff check + fix instructions |
| **4. Merge** | Check conflicts + integrate | git diff + Edit |
| **5. Verify** | Build + lint + test | Auto-detected build system |

### Wave Structure

```
Wave 1 (sequential): Shared types, interfaces, utilities
Wave 2 (parallel):   Data layer / UI components / tests
Wave 3 (sequential): Import cleanup, dead code removal
```

### Usage

```bash
/cowork Add refund feature to payment module
/cowork --agents 4 large-scale refactoring
```

---

## /super — Plan → Implement → Review → Deploy Full-Auto Pipeline

From a one-liner idea to deployment. A full pipeline combining `/cowork` (parallel implementation) + `/check` (review+deploy) + `/design` (design quality).

**Principle:** Only halt on CRITICAL security issues. Otherwise, run to completion.

### 6-Phase Pipeline

| Phase | Role | Tools/Commands Used |
|-------|------|---------------------|
| **DISCOVER** | Structure requirements | /write-prd, /write-stories, /pre-mortem, /strategy |
| **PLAN** | Implementation plan + task breakdown + collect design.md | Explore, code-architect, /prioritize-features, /test-scenarios |
| **BUILD** | Parallel implementation (/cowork + /design + TDD) | Agent Teams, Wave distribution, design rule injection, RED→GREEN verification |
| **CHECK** | 5-angle review + design quality check | 5+1 agent review, build/lint/test |
| **SHIP** | Commit + push + PR | git, gh CLI |
| **DOCUMENT** | Release notes + doc updates | /sprint, /revise-claude-md, /sync-docs |

### design.md Auto-Detection

If a design system file (`design.md`, `designsystem.md`, `*DESIGN*.md`, etc.) exists in your project, design rules are automatically applied without the `--design` flag. Explicitly specifying `--design <preset>` takes priority over auto-detection.

For the Codex port, `--design` presets include `landing`, `dashboard`, `workspace`, `portfolio`, `admin`, `soft`, `minimal`, `brutal`, and `redesign`. Using `--design` alone enables design mode, and the actual preset is determined by the detected design system file or current product type.

### Usage

```bash
# Basic (without design)
/super Add 2FA to login
/super --pr Payment module refactoring

# Explicit design preset
/super --design landing Implement service based on spec
/super --design dashboard --pr Admin dashboard

# design.md auto-detection (easiest approach)
/design init                    # One-time — generate design.md
/super Implement entire service  # Auto-detects design.md
/super Design refactoring        # Redesign works the same way
```

---

## /docs — Structured Documentation Pipeline

**Auto-detects** the document type and extracts facts from sources (code/git/existing docs) to write structured documentation.

**Core rule:** No guessing. Unverifiable information is marked `[TODO]`. Final output passes grammar review.

### 10 Auto-Detected Document Types

| Type | Trigger Keywords | Commands Used |
|------|-----------------|---------------|
| PRD | "spec", "requirements" | /write-prd, /write-stories |
| Technical Doc | "architecture", "design" | Explore, code-architect |
| README | "getting started", "install" | Explore + code analysis |
| Release Notes | "deploy", "changelog" | /sprint + git log |
| Meeting Notes | "meeting", "standup" | /meeting-notes |
| Interview Summary | "interview", "user research" | /interview |
| Strategy Doc | "strategy", "GTM" | /strategy |
| Operations Doc | "runbook", "deploy guide" | Explore + code analysis |
| Project Documentation | "full documentation" | All commands combined |
| Proofread/Improve | "proofread", "review" | /proofread |

### 6-Phase Pipeline

```
DETECT → RESEARCH → STRUCTURE → DRAFT → REVIEW → DELIVER
```

### Usage

```bash
/docs Write a README for this project
/docs --type prd Payment module feature spec
/docs Organize last meeting's transcript
/docs --dry-run Just outline the architecture doc structure
/docs Full project documentation
```

---

## /design — Frontend Design Quality Control

Control design tone with 3 dials. Provides a unified entry point for the [taste-skill](https://github.com/Leonxlnx/taste-skill) ecosystem.

### /design init — Create/Update Design System

```bash
/design init
# → Design system file exists: Update mode ("make it flashier", "change preset", etc.)
# → No file + code exists: Redesign mode (scan → audit → set goals)
# → No file + no code: New project mode (ask purpose → generate)
```

Auto-detects custom file names like `design.md`, `designsystem.md`, `BENEEDS_DESIGN_SYSTEM.md`, etc.

### 3-Dial System

| Dial | 1-3 | 4-7 | 8-10 |
|------|-----|-----|------|
| **VARIANCE** (layout) | Clean grid | Offsets, overlaps | Asymmetric, generous whitespace |
| **MOTION** (animation) | Hover only | Fade-in, scroll effects | Magnetic, spring physics |
| **DENSITY** (fill) | Luxurious, spacious | Standard app level | Dashboard, packed |

### Presets — By Style or Purpose

| Style Name | Purpose Name | V | M | D | Use Case |
|-----------|-------------|---|---|---|----------|
| (default) | — | 8 | 6 | 4 | General frontend |
| `--soft` | `--landing` | 7 | 8 | 3 | Landing pages, SaaS |
| `--soft` | `--portfolio` | 8 | 7 | 2 | Portfolio |
| `--minimal` | `--workspace` | 4 | 3 | 5 | Workspace, editorial |
| `--brutal` | `--dashboard` | 6 | 2 | 8 | Dashboard, data-heavy |
| — | `--admin` | 2 | 3 | 9 | Admin panel |
| `--redesign` | `--redesign` | (analyzed) | (analyzed) | (analyzed) | Existing site upgrade |

### Usage

```bash
# Generate design.md (one-time)
/design init

# Use by purpose name (intuitive)
/design --landing SaaS landing page
/design --dashboard Real-time monitoring
/design --workspace Team collaboration tool
/design --admin Admin panel

# Custom dials
/design --v 8 --m 7 --d 2 Luxury brand landing

# Redesign
/design --redesign Design upgrade
```

---

## Installation

### Plugin Manager (Recommended)

```bash
claude plugin install --git https://github.com/jobc90/claudex-power-commands
```

Success if `/check`, `/cowork`, `/super`, `/docs`, `/design` appear as slash commands in a new session.

### Manual Installation

```bash
# 1. Clone
git clone https://github.com/jobc90/claudex-power-commands.git

# 2. Copy commands
cp claudex-power-commands/commands/*.md ~/.claude/commands/

# 3. (Optional) Copy rules
cp claudex-power-commands/rules/*.md ~/.claude/rules/

# 4. Verify — in a new session
#    Success if /check, /cowork, /super, /docs, /design appear as slash commands
```

### Codex Installation

```bash
# 1. Clone
git clone https://github.com/jobc90/claudex-power-commands.git

# 2. Create Codex skill directory
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills"

# 3. Copy Codex skills
cp -R claudex-power-commands/codex-skills/check "${CODEX_HOME:-$HOME/.codex}/skills/"
cp -R claudex-power-commands/codex-skills/cowork "${CODEX_HOME:-$HOME/.codex}/skills/"
cp -R claudex-power-commands/codex-skills/super "${CODEX_HOME:-$HOME/.codex}/skills/"
cp -R claudex-power-commands/codex-skills/docs "${CODEX_HOME:-$HOME/.codex}/skills/"
cp -R claudex-power-commands/codex-skills/design "${CODEX_HOME:-$HOME/.codex}/skills/"
cp -R claudex-power-commands/codex-skills/harness "${CODEX_HOME:-$HOME/.codex}/skills/"
cp -R claudex-power-commands/codex-skills/harness-docs "${CODEX_HOME:-$HOME/.codex}/skills/"

# 4. Verify — in a new Codex session
#    Explicitly invoke $check, $cowork, $super, $docs, $design, $harness, $harness-docs or request related tasks
```

### Codex Usage Examples

```text
Use $check on the current diff.
Use $check --pr after verification passes.
Use $cowork --agents 4 for this refactor.
Use $super --skip-discover because the PRD already exists.
Use $super --design dashboard for the admin UI.
Use $docs to create a README for this project.
Use $docs --type prd for the payment module feature.
Use $docs --dry-run to outline architecture documentation.
Use $design init for this frontend project.
Use $harness to build a browser-based DAW with planner, builder, and QA rounds.
Use $harness-docs to document this repository's architecture with research, writing, and review rounds.
```

### Codex Port Differences

- Uses skill-based invocation instead of slash commands.
- Codex skills embed verification, code quality, security, and git conventions internally so they work without external Forge rule files.
- Commit/push/PR is not auto-executed by default — it only runs when explicitly requested.
- `cowork` and `super` use agent delegation only when parallel agents are effective; otherwise, the same pipeline runs in a single session.
- Calling `$super` alone does not authorize parallel delegation. Parallel execution is only used when the user explicitly requests it or invokes `$cowork`.
- Includes a built-in "no completion claims without verification evidence" rule to prevent unverified done-claims.
- `docs` minimizes shell usage during documentation tasks and routes to actual installed Codex skill names (`create-prd`, `user-stories`, `release-notes`, etc.).
- `design` internalizes taste-skill's core concepts (presets, 3-dial system, design.md detection) into a single Codex skill.
- `harness` ports the Planner → Builder → QA autonomous app-build loop into a Codex skill using `.harness/` artifacts and `spawn_agent`.
- `harness-docs` ports the Researcher → Writer → Reviewer autonomous documentation loop into a Codex skill using `.harness-docs/` artifacts.

### Uninstallation

```bash
# If installed via plugin manager (one-line clean removal)
claude plugin uninstall claudex-power-commands

# If installed manually
rm ~/.claude/commands/{check,cowork,super,docs,design}.md
rm ~/.claude/rules/{code-quality,git-conventions,plugins-catalog,security-checklist,verification}.md

# Codex
rm -rf "${CODEX_HOME:-$HOME/.codex}"/skills/{check,cowork,super,docs,design,harness,harness-docs}
```

### Updating

```bash
# If installed via plugin manager
claude plugin update claudex-power-commands

# If installed manually
cd claudex-power-commands && git pull
cp commands/*.md ~/.claude/commands/
cp rules/*.md ~/.claude/rules/

# Codex
cp -R codex-skills/check "${CODEX_HOME:-$HOME/.codex}/skills/"
cp -R codex-skills/cowork "${CODEX_HOME:-$HOME/.codex}/skills/"
cp -R codex-skills/super "${CODEX_HOME:-$HOME/.codex}/skills/"
cp -R codex-skills/docs "${CODEX_HOME:-$HOME/.codex}/skills/"
cp -R codex-skills/design "${CODEX_HOME:-$HOME/.codex}/skills/"
cp -R codex-skills/harness "${CODEX_HOME:-$HOME/.codex}/skills/"
cp -R codex-skills/harness-docs "${CODEX_HOME:-$HOME/.codex}/skills/"
```

---

## Dependencies (Optional)

This plugin **works standalone**. The following plugins make it more powerful:

The Codex port is also self-contained. Core skills like `super` and `check` embed verification, code quality, security, and git rules in the skill body, so they do not depend on Forge-family plugins.

| Plugin | Required? | Role | Without It? |
|--------|----------|------|-------------|
| [claude-plugins-official](https://github.com/anthropics/claude-plugins-official) | Recommended | pr-review-toolkit (4 review agents), feature-dev, code-simplifier | /check has fewer review agents |
| [pm-skills](https://github.com/phuryn/pm-skills) | Optional | write-prd, write-stories, pre-mortem, test-scenarios, release-notes | PM phases skipped, jumps straight to implementation |
| [taste-skill](https://github.com/Leonxlnx/taste-skill) | Recommended for /design | taste-skill, soft-skill, minimalist-skill, brutalist-skill, redesign-skill, output-skill | Only common anti-patterns applied, preset detail rules reduced |

---

## File Structure

```
claudex-power-commands/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest
├── commands/
│   ├── check.md             # /check (64 lines)
│   ├── cowork.md            # /cowork (77 lines)
│   ├── design.md            # /design (334 lines)
│   ├── docs.md              # /docs (206 lines)
│   └── super.md             # /super (196 lines)
├── codex-skills/
│   ├── check/
│   │   ├── SKILL.md            # Codex skill definition
│   │   └── agents/openai.yaml  # Codex agent configuration
│   ├── cowork/
│   │   ├── SKILL.md
│   │   └── agents/openai.yaml
│   ├── design/
│   │   ├── SKILL.md
│   │   └── agents/openai.yaml
│   ├── docs/
│   │   ├── SKILL.md
│   │   └── agents/openai.yaml
│   ├── harness/
│   │   ├── SKILL.md
│   │   ├── agents/openai.yaml
│   │   └── references/
│   ├── harness-docs/
│   │   ├── SKILL.md
│   │   ├── agents/openai.yaml
│   │   └── references/
│   └── super/
│       ├── SKILL.md
│       └── agents/openai.yaml
├── hooks/
│   └── check-deps.sh        # SessionStart: Detects installation status of 3 recommended plugins
├── rules/
│   ├── code-quality.md      # Code quality principles (immutability, surgical changes, verification)
│   ├── git-conventions.md   # Commit format, PR workflow
│   ├── plugins-catalog.md   # Installed plugin catalog (reference)
│   ├── security-checklist.md # Security checklist (CWE, secrets, injection)
│   └── verification.md      # No completion claims without verification, Red-Green verification
├── README.md
└── LICENSE
```

## License

MIT
