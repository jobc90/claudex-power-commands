---
description: "Autonomous 5-agent builder pipeline (Scout → Planner → Builder → Refiner → QA) for single-builder implementation tasks (S/M/L scale)."
---

# Harness: Autonomous Builder (v3)

> Anthropic "Harness Design for Long-Running Apps" 5-agent architecture.
> Scout → Planner → Builder → Refiner → QA with file-based handoffs.

## User Request

$ARGUMENTS

## Phase 0: Triage

Classify the request into one of three scales. This determines the entire protocol path.

### Non-Build Requests (EXIT)

If the request is a question, audit, or configuration change (not a build/fix/implement request):
- Respond directly as a normal conversation
- Do NOT execute any harness phases

### Scale Classification

Analyze `$ARGUMENTS` and classify:

| Scale | Criteria | Examples |
|-------|----------|---------|
| **S** (Small) | Bug fix, typo, 1-2 file changes, config tweak | "Fix the login button 404", "Update the API timeout to 30s" |
| **M** (Medium) | Feature addition, 3-5 file changes, module-level work | "Add password reset flow", "Refactor auth to use JWT" |
| **L** (Large) | New application, major refactor, 6+ files, multi-module | "Build a dashboard app", "Rewrite the payment system" |

**Decision rule**: When in doubt between two scales, pick the smaller one. The QA loop will catch if more work is needed.

Announce the classification to the user:

```
Scale: [S/M/L] — [one-line rationale]
```

Then proceed to Phase 1 with the classified scale.

---

## Architecture Overview

```
/harness <prompt>
  |
  +- Phase 0: Triage         -> Scale S/M/L classification
  +- Phase 1: Setup           -> .harness/ directory + git init
  +- Phase 2: Scout           -> Scout agent -> .harness/build-context.md
  +- Phase 3: Planning        -> Planner agent -> .harness/build-spec.md
  |                           -> User reviews and approves
  +- Phase 4: Build-Refine-QA -> Up to S=1, M=2, L=3 rounds:
  |   +- Snapshot             -> captures git/build/test state
  |   +- Builder agent        -> implements/fixes -> .harness/build-progress.md
  |   +- Refiner agent        -> cleans/hardens  -> .harness/build-refiner-report.md
  |   +- QA agent             -> tests/scores    -> .harness/build-round-N-feedback.md
  |   +- Score check          -> all >= 7? done : next round
  |   +- Diagnostician agent  -> root cause analysis (M/L, round 2+ only)
  |   +- History accumulate   -> append round outcomes to build-history.md
  +- Phase 5: Summary         -> Final report to user
```

---

## Phase 1: Setup

1. Identify or create the project directory.
2. Run:
   ```bash
   mkdir -p .harness
   git init 2>/dev/null || true
   ```
3. Write the user's original prompt (`$ARGUMENTS`) and the classified scale to `.harness/build-prompt.md`.

---

## Phase 2: Scout

Read the scout prompt template: `~/.claude/harness/scout-prompt.md`

The Scout explores the existing codebase BEFORE planning, so the Planner and Builder have full context.

### Request Type Detection (CRITICAL)

Before launching the Scout, classify the request type:

| Type | Signal | Scout Instruction |
|------|--------|-------------------|
| **FIX** | "수정", "fix", "bug", "안됨", "작동하지 않음", "비활성화", "차단" | Include Deep Dive Protocol |
| **MODIFY** | "변경", "modify", "refactor", "이관", "전환" | Include Deep Dive Protocol |
| **BUILD** | "추가", "구현", "만들어", "생성", "add", "implement", "create" | Standard scan only |

For FIX/MODIFY requests, append this instruction to the Scout prompt:
- "This is a FIX/MODIFICATION request. After the standard module scan, you MUST execute the **Deep Dive Protocol** described in the scout prompt. Trace the specific feature's data flow end-to-end, verify each flag/guard/condition with file:line evidence, and map behavior per user type/role. The Planner will reject unverified claims."

### Scale S — Targeted Scan

Launch a **general-purpose Agent** with subagent_type `Explore`:
- **prompt**: The scout prompt template + context:
  - "Project directory: `{cwd}`"
  - "User's request: `{$ARGUMENTS}`"
  - "Scale: S — scan only the 2-5 files directly relevant to the request."
  - "Write output to `.harness/build-context.md`"
  - If FIX/MODIFY: Deep Dive instruction (see above)
- **description**: "harness scout (S)"

### Scale M — Module Scan

Launch a **general-purpose Agent** with subagent_type `Explore`:
- **prompt**: The scout prompt template + context:
  - "Project directory: `{cwd}`"
  - "User's request: `{$ARGUMENTS}`"
  - "Scale: M — scan the relevant module(s), 5-15 files."
  - "Write output to `.harness/build-context.md`"
  - If FIX/MODIFY: Deep Dive instruction (see above)
- **description**: "harness scout (M)"

### Scale L — Full Codebase Scan

Launch a **general-purpose Agent** with subagent_type `Explore`:
- **prompt**: The scout prompt template + context:
  - "Project directory: `{cwd}`"
  - "User's request: `{$ARGUMENTS}`"
  - "Scale: L — comprehensive codebase scan, 20-40 files."
  - "Write output to `.harness/build-context.md`"
  - If FIX/MODIFY: Deep Dive instruction (see above)
- **description**: "harness scout (L)"

After Scout completes, briefly confirm to the user: **"Scout 완료. 코드베이스 컨텍스트를 수집했습니다."** (No approval needed — proceed to Planning.)

---

## Phase 3: Planning

Read the planner prompt template: `~/.claude/harness/planner-prompt.md`

### Scale S — Scope Note

Do NOT spawn a Planner agent. Instead, the orchestrator writes `.harness/build-spec.md` directly, informed by `.harness/build-context.md`:

**CRITICAL**: Before writing the Scope Note, READ `.harness/build-context.md` thoroughly. For FIX/MODIFY requests, the "Feature Deep Dive" section contains verified findings — use ONLY those findings to determine files to change. Do NOT list files based on your own inference.

```markdown
# Scope Note

## Scale: S
## Task: [one-line description]

## Current State (Verified)
[For FIX/MODIFY: summarize Scout's Deep Dive findings with file:line citations]
- [Fact 1]: VERIFIED (file:line)
- [Fact 2]: NOT FOUND — [expected but missing]

## Files to Change: [list — MUST match Scout's verified findings]
## Existing Patterns to Follow: [key patterns from context.md]
## Success Criteria:
1. [testable criterion]
2. [testable criterion]
## Risks: [if any, otherwise "None"]
```

Present the scope note to the user and ask: **"Scope를 검토해주세요. 진행할까요?"**
**WAIT for user approval.**

### Scale M — Lite Planner

Launch a **general-purpose Agent**:
- **prompt**: The planner prompt template + `"MODE: LITE. Scale is M."` + the user's request.
  - "Codebase context is at `.harness/build-context.md` — read it first to understand existing patterns, conventions, and reusable assets."
- **description**: "harness lite planner"
- The planner MUST write its output to `.harness/build-spec.md`

After completion:
- Read `.harness/build-spec.md`
- Present summary: feature count, changed files, test criteria
- Ask: **"Spec을 검토해주세요. 진행할까요?"**
- **WAIT for user approval.**

### Scale L — Full Planner

Launch a **general-purpose Agent**:
- **prompt**: The planner prompt template + `"MODE: FULL. Scale is L."` + the user's request.
  - "Codebase context is at `.harness/build-context.md` — read it first to understand existing patterns, conventions, and reusable assets."
- **description**: "harness full planner"
- The planner MUST write its output to `.harness/build-spec.md`

After completion:
- Read `.harness/build-spec.md`
- Present summary: feature count, key features, tech stack, AI integrations
- Ask: **"Spec을 검토해주세요. 진행할까요, 수정할 부분이 있나요?"**
- **WAIT for user approval.**

---

## Phase 4: Build-Refine-QA Loop (Meta-Harness Enhanced)

Read the builder, refiner, QA, and diagnostician prompt templates from `~/.claude/harness/`.

### Max rounds by scale

| Scale | Max Rounds | Refiner | QA Method | Diagnostician |
|-------|-----------|---------|-----------|--------------|
| S | 1 | Hygiene + pattern check only | Code review + build/test verification | Not used |
| M | 2 | Full checklist | Code review + build/test + Playwright (if UI exists) | Before round 2 |
| L | 3 | Full checklist + security scan | Playwright mandatory | Before rounds 2 and 3 |

### For each round N:

#### 4-pre. Environment Snapshot (Every Round)

Before launching the Builder, capture the current project state. Run these commands and write output to `.harness/snapshot-round-{N}.md`:

```bash
mkdir -p .harness/traces
echo "# Environment Snapshot — Round {N}" > .harness/snapshot-round-{N}.md
echo "## Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> .harness/snapshot-round-{N}.md
echo "## Git State" >> .harness/snapshot-round-{N}.md
git diff --stat >> .harness/snapshot-round-{N}.md 2>/dev/null
echo "## Changed Files" >> .harness/snapshot-round-{N}.md
git diff --name-only >> .harness/snapshot-round-{N}.md 2>/dev/null
```

Then run the build and test commands from `build-context.md`, appending results:
- Build status: exit code + last 20 lines if failure
- Test status: exit code + pass/fail/skip summary
- Dev server status: running URL or "not running"

Pass this snapshot path to the Builder: "Environment snapshot: `.harness/snapshot-round-{N}.md`"

#### 4a. Build

Launch a **general-purpose Agent**:
- **prompt**: The builder prompt template + these context instructions:
  - "Codebase context: `.harness/build-context.md` — read it to understand existing patterns and reusable assets."
  - "Product spec: `.harness/build-spec.md` — your blueprint."
  - "Environment snapshot: `.harness/snapshot-round-{N}.md` — read this FIRST to understand current project state."
  - "Scale: {S/M/L}"
  - If N == 1: "This is a fresh build. Implement the changes described in the spec."
  - If N > 1: "Read the Diagnosis Report at `.harness/diagnosis-round-{N-1}.md` — this is your PRIMARY input with root cause analysis. Also read cumulative history at `.harness/build-history.md` and QA evidence traces at `.harness/traces/round-{N-1}-qa-evidence.md`. Fix ROOT CAUSES, not symptoms."
  - "Write your progress to `.harness/build-progress.md`."
  - Scale M/L only: "Start the dev server in background and note the URL in progress.md."
- **description**: "harness builder round {N}"

#### 4b. Refine

Launch a **general-purpose Agent**:
- **prompt**: The refiner prompt template + these context instructions:
  - "Codebase context: `.harness/build-context.md`"
  - "Product spec: `.harness/build-spec.md`"
  - "Build progress: `.harness/build-progress.md`"
  - "Scale: {S/M/L}"
  - "Round: {N}"
  - If N > 1: "Previous QA feedback: `.harness/build-round-{N-1}-feedback.md`"
  - "Apply fixes directly to the code. Write your report to `.harness/build-refiner-report.md`."
  - Scale M/L: "Also write execution trace to `.harness/traces/round-{N}-refiner-trace.md` (build/test results after your fixes)."
- **description**: "harness refiner round {N}"

#### 4c. Verify (Scale M/L only)

After the refiner agent completes:
1. Read `.harness/build-progress.md` to find the dev server URL
2. Verify the server is responding: `curl -s -o /dev/null -w '%{http_code}' <URL>`
3. If server is not running, attempt to start it based on progress.md instructions
4. If still not running after M scale, note as critical failure for QA

#### 4d. QA

Launch a **general-purpose Agent**:
- **prompt**: The QA prompt template + these context instructions:
  - "Product spec: `.harness/build-spec.md`"
  - "Refiner report: `.harness/build-refiner-report.md`"
  - "Scale: {S/M/L}"
  - "Round number: {N}"
  - "Write your QA report to `.harness/build-round-{N}-feedback.md`"
  - Scale S: `"QA_MODE: CODE_REVIEW. No Playwright. Verify via code review, build output, and test results."`
  - Scale M: `"QA_MODE: STANDARD. Use Playwright if the app has UI. Otherwise code review + build/test."` + "App URL: `{URL from progress.md}`" + `"Write evidence traces to .harness/traces/round-{N}-qa-evidence.md for FAIL/PARTIAL results."`
  - Scale L: `"QA_MODE: FULL. Playwright is MANDATORY."` + "App URL: `{URL from progress.md}`" + `"Write evidence traces to .harness/traces/round-{N}-qa-evidence.md for ALL results."`
- **description**: "harness QA round {N}"

#### 4e. Evaluate

After QA agent completes:
1. Read `.harness/build-round-{N}-feedback.md`
2. Extract scores for each criterion
3. Report to user briefly: round number, scores, pass/fail, key issues
4. **Decision** (evaluate in this order):
   - N == max rounds for this scale → go to 4g (History), then Phase 5 regardless of scores
   - ALL criteria >= 7/10 → **PASS** → go to 4g (History), then Phase 5
   - ANY criterion < 7/10 AND N < max rounds → **FAIL** → continue to 4f (Diagnose) if applicable, then 4g (History), then round N+1

#### 4f. Diagnose (Scale M/L, before round N+1 ONLY)

**Skip this step for Scale S** (only 1 round, no next-round Builder to inform).
**Skip this step if this was the final allowed round** (no next round to inform).

Read the diagnostician prompt template: `~/.claude/harness/diagnostician-prompt.md`

Launch a **general-purpose Agent**:
- **prompt**: The diagnostician prompt template + these context instructions:
  - "QA feedback: `.harness/build-round-{N}-feedback.md`"
  - "QA evidence traces: `.harness/traces/round-{N}-qa-evidence.md`"
  - "Environment snapshot: `.harness/snapshot-round-{N}.md`"
  - "Build progress: `.harness/build-progress.md`"
  - "Codebase context: `.harness/build-context.md`"
  - "Round number: {N}"
  - If N > 1: "Previous diagnosis: `.harness/diagnosis-round-{N-1}.md`"
  - If N > 1: "Build history: `.harness/build-history.md`"
  - "Write your diagnosis to `.harness/diagnosis-round-{N}.md`"
- **description**: "harness diagnostician round {N}"

After completion:
- Read `.harness/diagnosis-round-{N}.md`
- Briefly report to user: root cause count, regression count (if any), top priority fix

#### 4g. Accumulate History (Every Round)

After Evaluate (and Diagnose if applicable), append to `.harness/build-history.md`:

```markdown
## Round {N}
- **Scores**: [criterion: score pairs from QA]
- **Verdict**: PASS / FAIL
- **Changes made**: [files changed in this round — from git diff or progress.md]
- **Issues found by QA**: CRITICAL: X, HIGH: Y, MEDIUM: Z
- **Root causes identified**: [from diagnosis if available, otherwise "N/A (Scale S)"]
- **What worked**: [improvements vs previous round, if applicable]
- **What regressed**: [score drops vs previous round, if applicable]
- **Decision**: PASS → Phase 5 / Continue to Round {N+1}
```

This file is cumulative — NEVER overwrite, only append. Create it on Round 1 with a header.

---

## Phase 4-post: Artifact Validation

After exiting the Build-Refine-QA loop (either PASS or max rounds reached), run a quick artifact check before generating the Summary. This is a bash check, not an agent call.

```bash
echo "## Artifact Validation"
MISSING=0

# Core artifacts (all scales)
for f in build-context.md build-spec.md build-prompt.md build-progress.md; do
  [ ! -f ".harness/$f" ] && echo "MISSING: .harness/$f" && MISSING=$((MISSING+1))
done

# Per-round artifacts
for N in $(seq 1 {completed_rounds}); do
  [ ! -f ".harness/build-round-${N}-feedback.md" ] && echo "MISSING: .harness/build-round-${N}-feedback.md" && MISSING=$((MISSING+1))
  [ ! -f ".harness/snapshot-round-${N}.md" ] && echo "MISSING: .harness/snapshot-round-${N}.md" && MISSING=$((MISSING+1))
done

# Scale M/L artifacts
if [ "{scale}" != "S" ]; then
  [ ! -f ".harness/build-refiner-report.md" ] && echo "MISSING: .harness/build-refiner-report.md" && MISSING=$((MISSING+1))
  [ ! -f ".harness/build-history.md" ] && echo "MISSING: .harness/build-history.md" && MISSING=$((MISSING+1))

  # Evidence traces (at least for failed rounds)
  for N in $(seq 1 {completed_rounds}); do
    [ ! -f ".harness/traces/round-${N}-qa-evidence.md" ] && echo "WARN: .harness/traces/round-${N}-qa-evidence.md not found (may be OK if all PASS)"
  done
fi

# Diagnostician artifacts (M/L, round 2+)
if [ {completed_rounds} -gt 1 ] && [ "{scale}" != "S" ]; then
  for N in $(seq 1 $((completed_rounds-1))); do
    [ ! -f ".harness/diagnosis-round-${N}.md" ] && echo "MISSING: .harness/diagnosis-round-${N}.md" && MISSING=$((MISSING+1))
  done
fi

echo "Artifacts: $MISSING missing"
```

Report the result to the user:
- 0 missing → **"Artifact validation: PASS"**
- Any missing → **"Artifact validation: [X] missing files"** + list them in the Summary

---

## Phase 5: Summary

### Scale S — Compact Report

```
## Harness Complete (Scale S)

**Status**: PASS / PARTIAL
**Changes**: [files changed]
**Refiner**: [issues found/fixed]
**Verification**: [build/test results]
**Remaining**: [issues if any, otherwise "None"]
**Next**: Run `/harness-review` to review and commit, or `/harness-review --commit` to auto-commit.
```

### Scale M — Standard Report

```
## Harness Complete (Scale M)

**Rounds**: {N}/2
**Status**: PASS / PARTIAL

### Scores
| Criterion | Score |
|-----------|-------|
| Completeness | X/10 |
| Functionality | X/10 |
| Code Quality | X/10 |

### Changes
[List of files changed with brief description]

### Refiner Summary
[Issues found and fixed by Refiner]

### Remaining Issues
[From last QA report if any]

### Next Step
Run `/harness-review` to review and commit, or `/harness-review --pr` to create a PR.
```

### Scale L — Full Report

```
## Harness Build Complete (Scale L)

**Rounds**: {N}/3
**Status**: PASS / PARTIAL

### Final Scores
| Criterion      | Score | Status |
|----------------|-------|--------|
| Product Depth  | X/10  |        |
| Functionality  | X/10  |        |
| Visual Design  | X/10  |        |
| Code Quality   | X/10  |        |

### Features Delivered
[List from spec with PASS/PARTIAL/FAIL per feature]

### Refiner Summary
[Total issues found/fixed across all rounds]

### Remaining Issues
[From last QA report — actionable items]

### Artifacts
- Context: `.harness/build-context.md`
- Spec: `.harness/build-spec.md`
- Refiner: `.harness/build-refiner-report.md`
- Final QA: `.harness/build-round-{N}-feedback.md`
- Progress: `.harness/build-progress.md`
- Git log: `git log --oneline`

### Next Step
Run `/harness-review` to review and commit, or `/harness-review --pr` to create a PR.
```

---

## Critical Rules

1. **Each agent = separate Agent tool call** with fresh context. Never share conversation history between agents.
2. **ALL inter-agent communication through `.harness/` files only.** Do not pass information verbally between agent calls.
3. **Scout runs FIRST.** The Planner and Builder depend on `.harness/build-context.md`.
4. **Refiner runs AFTER Builder, BEFORE QA.** The Refiner cleans code; QA evaluates the cleaned result.
5. **The Builder CANNOT self-certify completion.** Always run Refiner + QA after every build.
6. **The Refiner does NOT add features.** It only cleans, hardens, and aligns with existing patterns.
7. **ALWAYS present the spec/scope to the user and wait for approval** before starting Phase 4.
8. **Scale S does NOT require Playwright.** Code review + build/test is sufficient.
9. **Scale M uses Playwright only if the app has UI.** Backend-only changes use code review + test.
10. **Scale L requires Playwright** for live app testing.
11. **Read prompt templates from `~/.claude/harness/`** before spawning each agent.
12. **When in doubt on scale, pick smaller.** The QA loop catches under-estimation; over-estimation wastes tokens.
13. **Diagnostician runs AFTER QA, BEFORE the next-round Builder.** It bridges QA symptoms to Builder-actionable root causes.
14. **Environment snapshot runs BEFORE every Build round.** The Builder must know exact project state before making changes.
15. **Build history is cumulative.** NEVER overwrite `.harness/build-history.md` — only append.
16. **Evidence traces go to `.harness/traces/`.** QA and Refiner write raw diagnostic data here for the Diagnostician.

## Cost Awareness

| Scale | Typical Duration | Agent Calls |
|-------|-----------------|-------------|
| S | 5-15 min | 4 (scout + builder + refiner + QA) |
| M | 20-50 min | 6-10 (scout + planner + [builder + refiner + QA + diagnostician] × 1-2) |
| L | 1-4 hours | 10-17 (scout + planner + [builder + refiner + QA + diagnostician] × 1-3) |

**Note**: Diagnostician adds ~2-5 min per round but saves 10-20 min of Builder investigation time in subsequent rounds (Meta-Harness principle: causal diagnosis > summary-based guessing).
