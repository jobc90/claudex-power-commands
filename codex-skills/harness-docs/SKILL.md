---
name: harness-docs
description: Autonomous documentation harness for `/harness-docs` or `$harness-docs` requests. Researcher -> Outliner -> Writer -> Reviewer + Validator workflow with S/M/L scaling. v4.1.0 — tier-aware (Standard/Advanced/Elite) round limits and optional Meta-Loop phase-book decomposition for multi-chapter Scale L documents.
---

# Harness Docs

## Overview

Run the Codex version of `/harness-docs`. Treat `/harness-docs` and `$harness-docs` as the same workflow intent inside Codex.

**v4.1.0 changes:**
- Capability tier detection (`Standard | Advanced | Elite`) at session start; round limits consult `references/tier-matrix.md`.
- Optional Meta-Loop mode for multi-chapter Scale L documents: invoke `references/phase-book-planner-prompt.md` to decompose chapters into phases; otherwise the single-pass pipeline below is equivalent to a 1-phase book.

This skill mirrors the Claude harness-docs structure:

`TRIAGE -> CAPABILITY -> SETUP -> RESEARCH -> OUTLINE -> USER APPROVAL -> WRITE/REVIEW LOOP -> FINALIZE -> SUMMARY`

## Guard Clause

Before starting the protocol, confirm the request is documentation or analysis work.

Run this skill when the user wants things like:

- project documentation
- README or onboarding docs
- architecture overviews
- PRDs or technical specs
- migration guides
- deep codebase analysis that results in written documentation

Do not run this workflow when the user is:

- asking how harness-docs works
- asking to build an application instead of documentation
- asking for an unrelated coding change

In those cases, respond directly.

## Input Modes

Treat these literal tokens in the user's prompt as workflow hints:

- `$harness-docs`
- `/harness-docs`

If no token is present but the request clearly means "run the autonomous documentation harness", this skill still applies.

## Scale Classification

Classify the request before research:

| Scale | Criteria | Examples |
|------|----------|----------|
| `S` | Single-focus output, 1-2 sources, short output | QA checklist, endpoint list, short summary |
| `M` | Multi-section doc, 3-5 sources, medium-length | module API docs, migration guide |
| `L` | Comprehensive doc, full codebase scan, large output | architecture docs, onboarding guide |

When in doubt between two scales, pick the smaller one.

## Required Artifacts

Use `.harness_codex/docs-` in the target project directory.

- `.harness_codex/docs-request.md`
- `.harness_codex/docs-research.md`
- `.harness_codex/docs-outline.md`
- `.harness_codex/docs-draft.md`
- `.harness_codex/docs-round-1-review.md`
- `.harness_codex/docs-round-2-review.md`
- `.harness_codex/docs-round-3-review.md`
- `.harness_codex/docs-round-1-validation.md`
- `.harness_codex/docs-round-2-validation.md`
- `.harness_codex/docs-round-3-validation.md`

All inter-agent communication must happen through these files only.

## Phase 1. Setup

1. Identify the target project directory first.
2. Create the working directory:

```bash
mkdir -p .harness_codex
```

3. Write the user's request and classified scale to `.harness_codex/docs-request.md`.

## Phase 2. Research

Load `references/researcher-prompt.md`.

### Scale `S`

Do not spawn a Researcher agent. The orchestrator directly:

1. reads only the files relevant to the request
2. writes a brief `.harness_codex/docs-research.md`

Then proceed directly to Outline.

### Scale `M`

Spawn a fresh focused research subagent:

- add `MODE: FOCUSED. Scale is M.`
- require output at `.harness_codex/docs-research.md`

### Scale `L`

Spawn a fresh full research subagent:

- add `MODE: FULL. Scale is L.`
- require output at `.harness_codex/docs-research.md`

## Phase 3. Outline

Load `references/outliner-prompt.md`.

### Scale `S`

Do not spawn an Outliner agent. Write `.harness_codex/docs-outline.md` directly with:

- document type
- intended sections
- what each section covers

Then ask exactly:

`문서 범위와 구조를 검토해주세요. 진행할까요?`

Stop and wait for approval.

### Scale `M`

Spawn a fresh outliner subagent:

- input research file: `.harness_codex/docs-research.md`
- scale: `M`
- output: `.harness_codex/docs-outline.md`

After it finishes, summarize the structure and ask:

`문서 구조를 검토해주세요. 진행할까요?`

Stop and wait for approval.

### Scale `L`

Spawn a fresh outliner subagent:

- input research file: `.harness_codex/docs-research.md`
- scale: `L`
- output: `.harness_codex/docs-outline.md`

After it finishes, summarize the structure and ask:

`문서 구조를 검토해주세요. 진행할까요, 조정할 부분이 있나요?`

Stop and wait for approval.

## Phase 4. Write-Review Loop

Load:

- `references/writer-prompt.md`
- `references/reviewer-prompt.md`
- `references/validator-prompt.md`

Run at most:

- `S`: 1 round
- `M`: 2 rounds
- `L`: 3 rounds

### 4a. Write

Spawn a fresh writer subagent for each round.

Writer instructions must include:

- research baseline: `.harness_codex/docs-research.md`
- document blueprint: `.harness_codex/docs-outline.md`
- user's original request
- if round 1: write `.harness_codex/docs-draft.md`
- if round 2+: read `.harness_codex/docs-round-{N-1}-review.md` and `.harness_codex/docs-round-{N-1}-validation.md`, then revise `.harness_codex/docs-draft.md`

### 4b. Review + Validate

Scale `S`: skip reviewer and validator, then proceed to Finalize.

Scale `M` and `L`: spawn both in parallel.

Reviewer instructions must include:

- draft path: `.harness_codex/docs-draft.md`
- research baseline: `.harness_codex/docs-research.md`
- document blueprint: `.harness_codex/docs-outline.md`
- round number
- output path: `.harness_codex/docs-round-{N}-review.md`

Validator instructions must include:

- draft path: `.harness_codex/docs-draft.md`
- research baseline: `.harness_codex/docs-research.md`
- round number
- output path: `.harness_codex/docs-round-{N}-validation.md`

### 4c. Evaluate

After both reviewer and validator finish:

1. Read the review and validation reports.
2. Extract:
   - review scores
   - validation pass/fail summary
3. Report briefly:
   - round number
   - criterion scores
   - validation summary
   - key issues
4. Decide:
   - all review criteria `>= 7` and zero failed validations -> pass
   - otherwise continue if another round remains
   - stop on the final allowed round

## Phase 5. Finalize

After the loop ends:

1. Read the final `.harness_codex/docs-draft.md`.
2. Ask the user where to save it if no path was specified.
3. Default to project root or `docs/` when no destination is given.
4. Copy or move the final document to the chosen path.
5. Keep or remove `.harness_codex/docs-` only if the user explicitly requests cleanup.

## Phase 6. Summary

Use this reporting shape:

```markdown
## Harness-Docs Complete

**Scale**: {S|M|L}
**Rounds**: {N}/{max_rounds}
**Status**: PASS / PARTIAL

### Review Scores
| Criterion | Score |
|-----------|-------|
| ...       | X/10  |

### Validation Summary
- PASS: X
- FAIL: X
- CONDITIONAL: X

### Output
- Final document: {path}

### Artifacts
- Research: `.harness_codex/docs-research.md`
- Outline: `.harness_codex/docs-outline.md`
- Draft: `.harness_codex/docs-draft.md`
- Last review: `.harness_codex/docs-round-{N}-review.md`
- Last validation: `.harness_codex/docs-round-{N}-validation.md`
```

## Execution Rules

1. Each phase agent must be a separate `spawn_agent` call with fresh context.
2. Never pass state between agents in chat. Use `.harness_codex/docs-` files only.
3. Always load the prompt templates from `references/` before composing each agent task.
4. Always wait for explicit user approval after the outline phase.
5. The Reviewer fact-checks by reading source code. The Validator fact-checks by executing commands and examples.
6. Scale `S` skips the review loop and validation for efficiency.
7. Match the document language to the user's request language.
8. If subagents are unavailable, stop and say the harness cannot run as designed. Do not fake the loop in one pass.
