# Team Build Protocol

> Reference for /harness TEAM mode (Scale L).
> Read by the orchestrator when Planner recommends TEAM mode or `--workers N` flag is used.
> Architect -> Workers(N, worktree) -> per-Worker Sentinel -> Merge -> Integrator -> QA

---

## Arguments

- First argument: task description (required)
- `--agents N`: number of parallel Workers in Wave 2 (default 3, max 5)

---

## Wave 1 -- Foundation (Sequential)

If the Architect's plan includes Wave 1 tasks:

Launch a **general-purpose Agent**:
- **prompt**: The worker prompt template (`~/.claude/harness/worker-prompt.md`) + the Wave 1 brief from `plan.md`:
  - "You are Worker 0 (Foundation). Your brief is in `.harness/team-plan.md` under Wave 1."
  - "Codebase context: `.harness/team-context.md`"
  - "Write progress to `.harness/team-worker-0-progress.md`"
  - If R > 1: "Read QA feedback at `.harness/team-round-{R-1}-feedback.md` and fix relevant issues."
- **description**: "harness-team wave1 foundation"

After completion, verify Wave 1 outputs exist before proceeding to Wave 2.

---

## Wave 2 -- Implementation (Parallel + Worktree Isolation)

Launch N Worker agents **simultaneously in a single message**, each with **`isolation: "worktree"`**:

For each Worker i (1 to N):
- **prompt**: The worker prompt template (`~/.claude/harness/worker-prompt.md`) + Worker i's brief from `plan.md`:
  - "You are Worker {i}. Your brief is in `.harness/team-plan.md` under Worker {i}."
  - "Codebase context: `.harness/team-context.md`"
  - "Wave 1 outputs are available -- read-only."
  - "You are running in an isolated worktree. Implement your files, run build/test to verify, and return your progress report as your final message."
  - If R > 1 (**Selective Context Protocol**):
    - "**PRIMARY**: `.harness/team-diagnosis-round-{R-1}.md` -- root cause analysis for your files."
    - "**SECONDARY**: `.harness/team-plan.md` -- your brief."
    - "**ON-DEMAND**: `.harness/team-round-{R-1}-feedback.md` -- only if diagnosis is insufficient."
    - "Fix ROOT CAUSES from the diagnosis, not symptoms."
  - If R == 1: "Write progress to `.harness/team-worker-{i}-progress.md`"
- **description**: "harness-team worker {i}"
- **isolation**: `"worktree"`
- **model**: Use `haiku` for 1-2 file mechanical tasks, `sonnet` for standard work, inherit parent for complex judgment calls (per Architect's plan complexity rating).

**All N Workers must complete before proceeding.**

### Post-Wave 2 Processing

After all Workers complete:

1. **Collect worktree results**: Each Worker returns `{ path, branch }` if changes were made.
2. **Write progress files**: For each Worker, write `.harness/team-worker-{i}-progress.md` from the Worker's result message.
3. **Merge Worker branches** into main working tree:
   - **If Sentinel is active** (`sentinel_active: true` in `.harness/security-triage.md`): **DO NOT merge yet.** Proceed to Per-Worker Sentinel Gate first. Merging happens there after Sentinel clearance.
   - **If Sentinel is inactive**: Merge directly:
     ```bash
     # For each Worker branch with changes:
     git merge {worker-branch} --no-ff -m "Merge Worker {i}: {brief description}"
     ```
     If merge conflicts occur (should be rare with proper file ownership), note them for the Integrator.
4. **Update event log**:
   ```bash
   echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] workers:r{R} | done | team-worker-{1..N}-progress.md | {N} workers, {merged_count} branches merged" >> .harness/session-events.md
   ```
5. **Check statuses** (see Worker Status Handling below).

---

## Wave 2-post -- Per-Worker Sentinel Gate (Conditional)

**Skip if**: `.harness/security-triage.md` shows `sentinel_active: false`

**CRITICAL**: Sentinel runs BEFORE merging Worker branches. This ensures contaminated changes never reach the main tree.

After all Workers complete but BEFORE merging any Worker branches:

For each Worker i that returned changes (has a branch):

Launch a **general-purpose Agent** with **model `sonnet`**:
- **prompt**: The sentinel prompt template (`~/.claude/harness/sentinel-prompt.md`) + context:
  - "Team plan: `.harness/team-plan.md` -- file ownership assignments for Worker {i}"
  - "Worker {i} branch: `{worker-branch-i}` at path `{worktree-path-i}`"
  - "Worker {i} progress (from agent result): `{worker-i-result-text}`"
  - "Containment reference: `~/.claude/harness/references/agent-containment.md`"
  - "Security triage: `.harness/security-triage.md`"
  - "Round number: {R}"
  - "Mode: TEAM_PER_WORKER -- inspect this single Worker's branch diff. Check:"
  - "  1. Files changed are within Worker {i}'s assigned ownership from team-plan.md"
  - "  2. No forbidden commands in the branch diff (grep the diff, not just progress)"
  - "  3. No credential exposure in changed files"
  - "  4. No prompt injection patterns in source code"
  - "  5. No external network calls (curl, wget, gh gist) in the diff"
  - "  6. git diff --stat of branch matches Worker's claimed file list"
  - "Write report to `.harness/sentinel-worker-{i}-round-{R}.md`"
- **description**: "harness-team sentinel worker {i} round {R}"
- **model**: `sonnet`

**Note**: Per-Worker Sentinels can run in **parallel** (multiple Agent calls in one message), since each inspects an independent branch.

### Sentinel Verdict Actions

After all per-Worker Sentinels complete, collect verdicts:

| Verdict | Action |
|---------|--------|
| **CLEAR** | Merge: `git merge {worker-branch-i} --no-ff -m "Merge Worker {i}: {brief description}"` |
| **WARN** | Merge, note warnings for Integrator context |
| **BLOCK** | **Do NOT merge.** Discard branch: `git branch -D {worker-branch-i}`. Report to user. |

If any Worker is BLOCKed:
```bash
# Discard offending branch (changes never reach main tree)
git branch -D {blocked-worker-branch} 2>/dev/null
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] sentinel:worker-{i}:r{R} | BLOCK | sentinel-worker-{i}-round-{R}.md | {violation summary}" >> .harness/session-events.md
```
- Report to user: **"Sentinel BLOCK: Worker {i}가 보안 경계를 위반했습니다. 해당 브랜치는 폐기됩니다."**
- If BLOCKed Worker's files are critical for integration: re-dispatch that Worker only (fresh worktree) with Sentinel report as context
- If non-critical: proceed without them, note in Integrator context

Only CLEAR/WARN branches are merged. Update session state:
```bash
sed -i '' 's/last_completed_agent: .*/last_completed_agent: sentinel/' .harness/session-state.md
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] sentinel:team:r{R} | done | sentinel-worker-{1..N}-round-{R}.md | CLEAR:{X} WARN:{Y} BLOCK:{Z}" >> .harness/session-events.md
```

---

## Wave 3 -- Integration

Launch a **general-purpose Agent** with **model `sonnet`**:
- **prompt**: The integrator prompt template (`~/.claude/harness/integrator-prompt.md`) + context:
  - "Architect's plan: `.harness/team-plan.md`"
  - "Worker progress reports: `.harness/team-worker-{0..N}-progress.md`"
  - "Codebase context: `.harness/team-context.md`"
  - "Write output to `.harness/team-integration-report.md`"
  - If R > 1: "Previous QA feedback: `.harness/team-round-{R-1}-feedback.md`"
  - "NOTE: Worker branches have already been merged by the orchestrator. If merge conflicts were noted, resolve them as part of integration."
  - "IMPORTANT: Perform CODE HYGIENE on all Worker-changed files: remove console.log/debug, remove TODO/FIXME comments, remove commented-out code, verify naming matches context.md conventions, check for unused imports. Report hygiene issues found/fixed in the integration report."
- **description**: "harness-team integrator"
- **model**: `sonnet`

After Integrator completes:
- Read `.harness/team-integration-report.md`
- Verify: "Ready for QA: YES/NO"
- If NO: report issues to user and assess whether to proceed

Update event log:
```bash
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] integrator:r{R} | done | team-integration-report.md | {summary}" >> .harness/session-events.md
```

---

## Worker Status Handling

After Wave 2 Workers complete, check each Worker's reported status:

| Status | Action |
|--------|--------|
| **DONE** | Proceed to Sentinel Gate or Wave 3 |
| **DONE_WITH_CONCERNS** | Note concerns for Integrator context |
| **NEEDS_CONTEXT** | Provide context and re-dispatch that Worker (without worktree) |
| **BLOCKED** | Assess and escalate to user if needed |

---

## Round 2 Re-dispatch Logic (Diagnosis-Enhanced)

If round R failed and R < max rounds (2), run the Diagnostician before re-dispatching.

Read the diagnostician prompt template: `~/.claude/harness/diagnostician-prompt.md`

Launch a **general-purpose Agent** (inherit parent model) with **`run_in_background: true`**:
- **prompt**: The diagnostician prompt template + context:
  - "QA feedback: `.harness/team-round-{R}-feedback.md`"
  - "QA evidence traces: `.harness/traces/round-{R}-qa-evidence.md`"
  - "Event log: `.harness/session-events.md`"
  - "Architect plan: `.harness/team-plan.md`"
  - "Codebase context: `.harness/team-context.md`"
  - "Round: {R}"
  - "Write diagnosis to `.harness/team-diagnosis-round-{R}.md`"
  - "IMPORTANT: Map each root cause to the Worker who owns the affected files (use file ownership from team-plan.md). This helps the orchestrator re-dispatch only the relevant Workers."
- **description**: "harness-team diagnostician round {R}"
- **run_in_background**: `true`

While Diagnostician runs in background:
1. Write History entry
2. Report QA scores to user
3. When Diagnostician notification arrives -> read diagnosis, report root cause summary

Update event log:
```bash
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] diagnostician:r{R} | done | team-diagnosis-round-{R}.md | {root_cause_count} root causes" >> .harness/session-events.md
```

### Re-dispatch Decision

After diagnosis completes:

1. Read `.harness/team-diagnosis-round-{R}.md` for root cause -> file mapping
2. Map each root cause to the Worker who owns the affected file(s) (from Architect's plan file ownership map)
3. Re-dispatch ONLY Workers whose files have root causes. Workers with all-PASS files are NOT re-dispatched.
4. Include the relevant root cause analysis (not just symptoms) in each re-dispatched Worker's prompt:
   - "Read the diagnosis at `.harness/team-diagnosis-round-{R}.md` -- fix the ROOT CAUSES identified for your files, not just the symptoms."
5. If a root cause spans files owned by multiple Workers, assign it to the Integrator instead.

---

## Team-Specific Artifact Naming

All team build artifacts use the `team-` prefix:

| Artifact | Path |
|----------|------|
| User prompt | `.harness/team-prompt.md` |
| Scout context | `.harness/team-context.md` |
| Architect plan | `.harness/team-plan.md` |
| Worker 0 (Foundation) progress | `.harness/team-worker-0-progress.md` |
| Worker i progress | `.harness/team-worker-{i}-progress.md` |
| Integration report | `.harness/team-integration-report.md` |
| QA feedback (per round) | `.harness/team-round-{R}-feedback.md` |
| Diagnosis (per round) | `.harness/team-diagnosis-round-{R}.md` |
| Build history | `.harness/team-history.md` |
| Sentinel reports | `.harness/sentinel-worker-{i}-round-{R}.md` |
| QA evidence traces | `.harness/traces/round-{R}-qa-evidence.md` |
| Auditor report | `.harness/auditor-report.md` |

---

## Team-Specific Auditor Inputs

When the Auditor is active (`auditor_active: true`), provide these team-specific artifacts:

- "Team plan: `.harness/team-plan.md`"
- "Worker progress reports: `.harness/team-worker-{0..N}-progress.md`"
- "Integration report: `.harness/team-integration-report.md`"
- "QA feedback files: `.harness/team-round-{1..R}-feedback.md`"
- "Sentinel reports: `.harness/sentinel-worker-{i}-round-{R}.md` (if exist)"
- "Build history: `.harness/team-history.md`"
- "Total rounds completed: {R}"
- "Write your report to `.harness/auditor-report.md`"

### Artifact Validation (Phase 4-post)

```bash
MISSING=0
# Core artifacts
for f in team-prompt.md team-context.md team-plan.md team-integration-report.md; do
  [ ! -f ".harness/$f" ] && echo "MISSING: .harness/$f" && MISSING=$((MISSING+1))
done
# Worker progress files
for i in $(seq 0 {N}); do
  [ ! -f ".harness/team-worker-${i}-progress.md" ] && echo "MISSING: .harness/team-worker-${i}-progress.md" && MISSING=$((MISSING+1))
done
# QA per round
for R in $(seq 1 {completed_rounds}); do
  [ ! -f ".harness/team-round-${R}-feedback.md" ] && echo "MISSING: .harness/team-round-${R}-feedback.md" && MISSING=$((MISSING+1))
done
# History
[ ! -f ".harness/team-history.md" ] && echo "MISSING: .harness/team-history.md" && MISSING=$((MISSING+1))
# Auditor artifact (if auditor was active)
if grep -q 'auditor_active: true' .harness/security-triage.md 2>/dev/null; then
  [ ! -f ".harness/auditor-report.md" ] && echo "MISSING: .harness/auditor-report.md" && MISSING=$((MISSING+1))
fi
echo "Artifacts: $MISSING missing"
```

---

## History Accumulation (Every Round)

Append to `.harness/team-history.md`:

```markdown
## Round {R}
- **Scores**: [criterion: score pairs]
- **Workers dispatched**: [which workers ran this round]
- **Root causes identified**: [from diagnosis if available]
- **Decision**: PASS -> Phase 5 / Continue to Round {R+1}
```

---

## Model Selection Directives

| Agent | Model | Rationale |
|-------|-------|-----------|
| Architect | inherit parent | Architectural decisions are critical |
| Worker (1-2 file mechanical) | `haiku` | Simple, fast, cost-efficient |
| Worker (standard) | `sonnet` | Balanced capability |
| Worker (complex judgment) | inherit parent | Needs deep reasoning |
| Integrator | `sonnet` | Merge verification, hygiene |
| Sentinel (per-Worker) | `sonnet` | Checklist-driven pattern matching |
| Diagnostician | inherit parent | Root cause analysis needs deep reasoning |
| QA | `sonnet` | Test execution, scoring |
| Auditor | `sonnet` | Cross-verification |

---

## Cost Awareness

| Workers | Typical Duration | Agent Calls |
|---------|-----------------|-------------|
| 2 | 15-30 min | 6-10 (scout + architect + [W0 + W1-2 + integrator + QA] x 1-2) |
| 3 | 20-40 min | 7-12 |
| 5 | 25-50 min | 9-16 |

---

## Critical Rules (Team-Specific)

1. **Wave 2 Workers are launched SIMULTANEOUSLY in one message.** This is the core parallelism.
2. **No two Workers may modify the same file.** The Architect ensures this; the Integrator verifies.
3. **Wave 1 MUST complete before Wave 2 starts.** Foundation dependencies are sequential.
4. **Workers CANNOT self-certify.** The Integrator verifies integration; QA verifies quality.
5. **Worker model selection**: Use `haiku` for 1-2 file mechanical tasks, `sonnet` for standard work, inherit parent for complex judgment calls. Pass `model` parameter in Agent tool call.
6. **Wave 2 Workers use `isolation: "worktree"`** for true parallel safety. Orchestrator merges branches before Integrator runs.
7. **Round 2 Workers use Selective Context**: PRIMARY (diagnosis), SECONDARY (plan), ON-DEMAND (feedback).
8. **Diagnostician runs in background** (`run_in_background: true`). History and user reporting proceed in parallel.
9. **Per-Worker Sentinel runs AFTER Workers complete, BEFORE branch merging** (when active). A BLOCK verdict discards the Worker's branch -- contaminated code never reaches the main tree.
10. **Sentinel agents for different Workers run in parallel** -- each inspects an independent branch, no cross-dependencies.
