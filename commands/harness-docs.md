---
description: "Autonomous 5-agent documentation pipeline (Researcher → Outliner → Writer → Reviewer + Validator) for document generation tasks (S/M/L scale)."
---

# Harness-Docs: Autonomous Documentation Builder (v3)

> Anthropic harness pattern adapted for ALL documentation and analysis tasks.
> Researcher → Outliner → Writer → Reviewer + Validator (5-agent architecture).

## User Request

$ARGUMENTS

## Phase 0: Triage

Classify the request into one of three scales. This determines the entire protocol path.

### Non-Documentation Requests (EXIT)

If the request is:
- A question about harness-docs itself ("how does this work?")
- A request to build/code an application (use `/harness` instead)
- An unrelated task

Then: **Do NOT execute the protocol.** Respond directly to the user.

### What Qualifies as Documentation

Proceed when the user asks to create ANY structured written output:
- Full documentation: project docs, architecture overviews, onboarding guides, migration guides
- Specs and plans: PRDs, technical specs, API docs
- Lists and checklists: QA checklists, test plans, audit lists, review criteria
- Analysis outputs: codebase analysis reports, dependency audits, security reviews
- Summaries: meeting notes, decision records, changelog summaries

### Scale Classification

| Scale | Criteria | Examples |
|-------|----------|---------|
| **S** (Small) | Single-focus output, 1-2 sources, <100 lines expected | "QA checklist for the auth module", "List all API endpoints", "Summarize recent changes" |
| **M** (Medium) | Multi-section document, 3-5 sources, 100-500 lines | "API documentation for the orders module", "Migration guide from v1 to v2" |
| **L** (Large) | Comprehensive document, full codebase scan, 500+ lines | "Full project architecture documentation", "Complete onboarding guide" |

**Decision rule**: When in doubt between two scales, pick the smaller one. The review loop will catch if more depth is needed.

Announce the classification:

```
Scale: [S/M/L] — [one-line rationale]
```

---

## Architecture Overview

```
/harness-docs <request>
  |
  +- Phase 0: Triage            -> Scale S/M/L classification
  +- Phase 1: Setup             -> .harness/docs- directory
  +- Phase 2: Research           -> Researcher agent -> .harness/docs-research.md
  +- Phase 3: Outline            -> Outliner agent  -> .harness/docs-outline.md
  |                              -> User reviews scope + structure
  +- Phase 4: Write-Review Loop  -> Up to S=1, M=2, L=3 rounds:
  |   +- Writer agent           -> drafts/revises  -> .harness/docs-draft.md
  |   +- Reviewer agent         -> fact-checks     -> .harness/docs-round-N-review.md
  |   +- Validator agent        -> executes/tests  -> .harness/docs-round-N-validation.md
  |   +- Score check            -> all >= 7? done : next round
  +- Phase 5: Finalize           -> Copy to user-specified location
  +- Phase 6: Summary
```

---

## Phase 1: Setup

1. Identify the target project directory. If the user specifies a project, `cd` there first.
2. Create the working directory:
   ```bash
   mkdir -p .harness
   ```
3. Write the user's request and classified scale to `.harness/docs-request.md`.

---

## Phase 2: Research

Read the researcher prompt template: `~/.claude/harness/researcher-prompt.md`

### Scale S — Quick Scan

Do NOT spawn a Researcher agent. The orchestrator directly:
1. Read only the specific files/modules relevant to the request
2. Write a brief `.harness/docs-research.md` with:
   - Target files/modules identified
   - Key facts extracted

No approval needed — proceed directly to Phase 3.

### Scale M — Focused Research

Launch a **general-purpose Agent** with subagent_type `Explore`:
- **prompt**: The researcher prompt template + `"MODE: FOCUSED. Scale is M."` + context:
  - "Project directory: `{cwd}`"
  - "User's request: `{$ARGUMENTS}`"
  - "Focus ONLY on modules/files relevant to the request. Do NOT scan the entire codebase."
  - "Write output to `.harness/docs-research.md`"
- **description**: "harness-docs focused research"

### Scale L — Full Research

Launch a **general-purpose Agent** with subagent_type `Explore`:
- **prompt**: The researcher prompt template + `"MODE: FULL. Scale is L."` + context:
  - "Project directory: `{cwd}`"
  - "User's request: `{$ARGUMENTS}`"
  - "Write output to `.harness/docs-research.md`"
- **description**: "harness-docs full research"

---

## Phase 3: Outline

Read the outliner prompt template: `~/.claude/harness/outliner-prompt.md`

The Outliner transforms raw research into a deliberate document blueprint.

### Scale S — Inline Outline

Do NOT spawn an Outliner agent. The orchestrator writes a simple structure directly to `.harness/docs-outline.md`:

```markdown
# Document Blueprint

## Type: [checklist / list / summary / ...]
## Sections:
1. [Section name] — [what it covers]
2. [Section name] — [what it covers]
```

Present to user: **"문서 범위와 구조를 검토해주세요. 진행할까요?"**
**WAIT for user approval.**

### Scale M — Focused Outline

Launch a **general-purpose Agent**:
- **prompt**: The outliner prompt template + context:
  - "Research file: `.harness/docs-research.md`"
  - "User's request: `{$ARGUMENTS}`"
  - "Scale: M"
  - "Write output to `.harness/docs-outline.md`"
- **description**: "harness-docs outliner (M)"

After completion:
- Read `.harness/docs-outline.md`
- Present summary: document type, audience, section count, estimated size
- Ask: **"문서 구조를 검토해주세요. 진행할까요?"**
- **WAIT for user approval.**

### Scale L — Full Outline

Launch a **general-purpose Agent**:
- **prompt**: The outliner prompt template + context:
  - "Research file: `.harness/docs-research.md`"
  - "User's request: `{$ARGUMENTS}`"
  - "Scale: L"
  - "Write output to `.harness/docs-outline.md`"
- **description**: "harness-docs outliner (L)"

After completion:
- Read `.harness/docs-outline.md`
- Present summary: document type, audience, ToC, diagrams needed, estimated size
- Ask: **"문서 구조를 검토해주세요. 진행할까요, 조정할 부분이 있나요?"**
- **WAIT for user approval.**

---

## Phase 4: Write-Review Loop

Read the writer, reviewer, and validator prompt templates from `~/.claude/harness/`.

### Max rounds by scale

| Scale | Max Rounds | Review | Validation |
|-------|-----------|--------|------------|
| S | 1 (write only) | None (self-review) | None |
| M | 2 | Reviewer (focused) | Validator (commands + paths + env vars) |
| L | 3 | Reviewer (full) | Validator (all executable items) |

### For each round N:

#### 4a. Write

Launch a **general-purpose Agent**:
- **prompt**: The writer prompt template + context:
  - "Research file: `.harness/docs-research.md`"
  - "Document blueprint: `.harness/docs-outline.md` — follow this structure."
  - "User's request: `{$ARGUMENTS}`"
  - "Scale: {S/M/L}"
  - If N == 1: "Write the full document to `.harness/docs-draft.md`."
  - If N > 1: "Read reviewer feedback at `.harness/docs-round-{N-1}-review.md` and validator report at `.harness/docs-round-{N-1}-validation.md`. Revise `.harness/docs-draft.md` to address ALL issues."
  - Scale S: "This is a focused output. Keep it concise and actionable. Self-review before finishing."
  - "You may read source code files directly to fill gaps in the research."
- **description**: "harness-docs writer round {N}"

#### 4b. Review + Validate (Scale M/L only — PARALLEL)

**Scale S**: Skip. Proceed directly to Phase 5.

Launch BOTH agents in parallel:

**Reviewer:**
- **prompt**: The reviewer prompt template + context:
  - "Document to review: `.harness/docs-draft.md`"
  - "Research baseline: `.harness/docs-research.md`"
  - "Document blueprint: `.harness/docs-outline.md`"
  - "User's original request: `{$ARGUMENTS}`"
  - "Scale: {S/M/L}"
  - "Round number: {N}"
  - "Write your review to `.harness/docs-round-{N}-review.md`"
  - Scale M: `"REVIEW_MODE: FOCUSED. Verify claims related to the specific modules in scope."`
  - Scale L: `"REVIEW_MODE: FULL. Verify ALL factual claims against actual source code."`
- **description**: "harness-docs reviewer round {N}"

**Validator:**
- **prompt**: The validator prompt template + context:
  - "Document to validate: `.harness/docs-draft.md`"
  - "Research baseline: `.harness/docs-research.md`"
  - "User's original request: `{$ARGUMENTS}`"
  - "Scale: {S/M/L}"
  - "Round number: {N}"
  - "Write your validation report to `.harness/docs-round-{N}-validation.md`"
- **description**: "harness-docs validator round {N}"

#### 4c. Evaluate (Scale M/L only)

After BOTH reviewer and validator complete:
1. Read `.harness/docs-round-{N}-review.md` — extract review scores
2. Read `.harness/docs-round-{N}-validation.md` — extract validation results
3. Report to user briefly:
   - Round number
   - Review scores per criterion
   - Validation summary: X pass / X fail / X conditional
   - Key issues from both
4. **Decision**:
   - ALL review criteria >= 7/10 AND zero FAIL validations → **PASS** → exit loop
   - ANY review criterion < 7/10 OR any FAIL validations → **FAIL** → next round
   - N == max rounds → exit loop regardless

---

## Phase 5: Finalize

1. Read the final `.harness/docs-draft.md`
2. Ask the user where to save the final document:
   - Default: project root or `docs/` directory
   - User may specify a custom path
3. Copy/move the final document to the specified location
4. Clean up or preserve `.harness/docs-` based on user preference

---

## Phase 5-post: Artifact Validation

Before generating the Summary, run a quick artifact check:

```bash
MISSING=0
# Core artifacts
for f in docs-request.md docs-research.md docs-outline.md docs-draft.md; do
  [ ! -f ".harness/$f" ] && echo "MISSING: .harness/$f" && MISSING=$((MISSING+1))
done
# Scale M/L review artifacts
if [ "{scale}" != "S" ]; then
  for N in $(seq 1 {completed_rounds}); do
    [ ! -f ".harness/docs-round-${N}-review.md" ] && echo "WARN: .harness/docs-round-${N}-review.md"
    [ ! -f ".harness/docs-round-${N}-validation.md" ] && echo "WARN: .harness/docs-round-${N}-validation.md"
  done
fi
echo "Artifacts: $MISSING missing"
```

Include artifact status in the Summary.

---

## Phase 6: Summary

### Scale S — Compact Report

```
## Harness-Docs Complete (Scale S)

**Output**: [file path]
**Lines**: ~X lines
**Sources Referenced**: [count]
```

### Scale M — Standard Report

```
## Harness-Docs Complete (Scale M)

**Rounds**: {N}/2
**Status**: PASS / PARTIAL

### Review Scores
| Criterion | Score |
|-----------|-------|
| Completeness | X/10 |
| Accuracy | X/10 |
| Clarity | X/10 |

### Validation Summary
- Validated: X items
- PASS: X | FAIL: X | CONDITIONAL: X

### Output
- Document: [file path]
- Sections: X
- Lines: ~X

### Remaining Issues
[From last review/validation if any]
```

### Scale L — Full Report

```
## Harness-Docs Complete (Scale L)

**Rounds**: {N}/3
**Status**: PASS / PARTIAL

### Review Scores
| Criterion         | Score | Status |
|-------------------|-------|--------|
| Completeness      | X/10  |        |
| Accuracy          | X/10  |        |
| Logical Coherence | X/10  |        |
| Clarity           | X/10  |        |

### Validation Summary
- Total items: X
- PASS: X | FAIL: X | SYNTAX_ONLY: X | CONDITIONAL: X

### Document Stats
- Sections: X
- Approximate length: X lines / X words
- Source files referenced: X

### Artifacts
- Research: `.harness/docs-research.md`
- Outline: `.harness/docs-outline.md`
- Final document: `{final path}`
- Last review: `.harness/docs-round-{N}-review.md`
- Last validation: `.harness/docs-round-{N}-validation.md`
```

---

## Critical Rules

1. **Each agent = separate Agent tool call** with fresh context.
2. **ALL inter-agent communication through `.harness/docs-` files only.**
3. **Outliner runs AFTER Researcher, BEFORE Writer.** The Writer follows the Outliner's blueprint.
4. **Reviewer and Validator run IN PARALLEL** after each Write round. They serve different purposes: Reviewer reads, Validator executes.
5. **The Writer CANNOT self-certify quality** (except Scale S where review is skipped).
6. **The Reviewer fact-checks by reading source code.** The Validator fact-checks by executing commands.
7. **ALWAYS present the outline to the user and wait for approval** before starting Phase 4.
8. **The Researcher explores the ACTUAL codebase**, not guesses from file names.
9. **Documents are written in the language matching the user's request.** Korean → Korean. English → English.
10. **Scale S skips Outliner agent, review loop, and validation** for efficiency.
11. **When in doubt on scale, pick smaller.**

## Cost Awareness

| Scale | Typical Duration | Agent Calls |
|-------|-----------------|-------------|
| S | 3-10 min | 1-2 (quick scan + writer) |
| M | 15-30 min | 4-7 (researcher + outliner + [writer + reviewer + validator] × 1-2) |
| L | 30-60 min | 7-14 (researcher + outliner + [writer + reviewer + validator] × 1-3) |
