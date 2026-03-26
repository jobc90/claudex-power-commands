---
name: harness-docs
description: Autonomous documentation-building harness for `/harness-docs` or `$harness-docs` requests. Use when Codex needs to research a codebase, propose document scope, wait for user approval, draft documentation, fact-check it against source files, iterate up to 3 review rounds, and finalize the document through a file-based multi-agent loop in `.harness-docs/`.
---

# Harness Docs

## Overview

Run the Codex version of `/harness-docs`. Treat `/harness-docs` and `$harness-docs` as the same workflow intent inside Codex.

This skill is for substantial documentation or codebase-analysis requests that need deliberate research, drafting, and fact-checking:

`GUARD -> SETUP -> RESEARCH -> USER APPROVAL -> WRITE/REVIEW LOOP -> FINALIZE -> SUMMARY`

## Guard Clause

Before starting the protocol, confirm the request is documentation or analysis work.

Run this skill when the user wants things like:

- project documentation
- README or onboarding docs
- architecture overviews
- PRD or spec-like documents
- migration guides
- deep codebase analysis that results in written documentation

Do not run this workflow when the user is:

- asking how harness-docs works
- asking to build an application instead of documentation
- asking for an unrelated coding change

In those cases, respond directly.

## Required Artifacts

Use `.harness-docs/` in the target project directory.

- `.harness-docs/request.md`
- `.harness-docs/research.md`
- `.harness-docs/draft.md`
- `.harness-docs/round-1-review.md`
- `.harness-docs/round-2-review.md`
- `.harness-docs/round-3-review.md`

All inter-agent communication must happen through these files only.

## Phase 1. Setup

1. Identify the target project directory first.
2. Create the working directory:

```bash
mkdir -p .harness-docs
```

3. Write the user's request to `.harness-docs/request.md`, capturing:
   - requested document type
   - expected scope and depth
   - target audience when specified

## Phase 2. Research

Load `references/researcher-prompt.md`.

Spawn a fresh research subagent:

- use `spawn_agent`
- keep `fork_context` false
- pass only the researcher prompt template plus minimal local context
- require the agent to explore the actual codebase
- require the agent to write `.harness-docs/research.md`

After the researcher finishes:

1. Read `.harness-docs/research.md`.
2. Present a scope summary to the user:
   - project name and type
   - key areas discovered
   - proposed document structure
   - estimated size
3. Ask exactly: `리서치 범위와 문서 구조를 검토해주세요. 진행할까요, 조정할 부분이 있나요?`
4. Stop and wait for approval.

## Phase 3. Write-Review Loop

Load:

- `references/writer-prompt.md`
- `references/reviewer-prompt.md`

Run at most 3 rounds.

### 3a. Write

For each round `N` in `1..3`, spawn a fresh writer subagent.

Writer instructions must include:

- research baseline: `.harness-docs/research.md`
- user's original request
- if round 1: write the full draft to `.harness-docs/draft.md`
- if round 2 or 3: read `.harness-docs/round-{N-1}-review.md` and address every issue in `.harness-docs/draft.md`
- source code may be read directly to fill verified gaps

### 3b. Review

Spawn a fresh reviewer subagent.

Reviewer instructions must include:

- draft path: `.harness-docs/draft.md`
- research baseline: `.harness-docs/research.md`
- original user request
- round number
- output path: `.harness-docs/round-{N}-review.md`
- mandatory fact-checking against real source files and config files

The reviewer cannot rely on the draft alone.

### 3c. Evaluate

After the reviewer finishes:

1. Read `.harness-docs/round-{N}-review.md`.
2. Extract scores for:
   - Completeness
   - Accuracy
   - Coherence
   - Clarity
3. Report briefly to the user:
   - round number
   - criterion scores
   - pass/fail
   - key issues found
4. Decide:
   - if every score is `>= 7`, pass and exit the loop
   - if any score is `< 7` and `N < 3`, continue
   - if `N == 3`, stop even if issues remain

## Phase 4. Finalize

After the loop ends:

1. Read the final `.harness-docs/draft.md`.
2. Ask the user where to save it if no path was specified.
3. Default to project root or `docs/` when the user has not chosen a destination.
4. Copy or move the final document to the chosen path.
5. Keep or remove `.harness-docs/` only if the user explicitly requests cleanup.

## Phase 5. Summary

Present the final result in this shape:

```markdown
## Harness-Docs Complete

**Rounds**: {N}/3
**Status**: PASS / PARTIAL

### Final Scores
| Criterion         | Score | Status |
|-------------------|-------|--------|
| Completeness      | X/10  |        |
| Accuracy          | X/10  |        |
| Logical Coherence | X/10  |        |
| Clarity           | X/10  |        |

### Document Stats
- Sections: X
- Approximate length: X lines / X words
- Source files referenced: X

### Artifacts
- Research: `.harness-docs/research.md`
- Final document: `{final path}`
- Last review: `.harness-docs/round-{N}-review.md`
```

## Execution Rules

1. Each phase agent must be a separate `spawn_agent` call with fresh context.
2. Never pass state between agents in chat. Use `.harness-docs/` files only.
3. Always load the prompt templates from `references/` before composing each agent task.
4. Always wait for explicit user approval after the research phase.
5. The reviewer must fact-check against actual files, not just read the draft.
6. The researcher must explore the actual codebase, not infer from filenames alone.
7. Match the document language to the user's request language.
8. If subagents are unavailable, stop and say the harness cannot run as designed. Do not fake the loop in one pass.
