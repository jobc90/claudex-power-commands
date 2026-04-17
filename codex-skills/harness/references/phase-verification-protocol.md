# Phase Verification Protocol

> Standard procedure for confirming that a Meta-Loop phase is complete.
> Used by the Phase Verifier agent and referenced by the orchestrator.

---

## Core Principle

**Claims are not evidence.** A phase is complete only when its Definition of Done is mechanically verified and the verify commands exit 0 (or the equivalent success signal for non-shell verifications).

"It should work" is not acceptable. "Build exits 0, tests output `12 passed, 0 failed`" is acceptable.

---

## Inputs

- `.harness/phase-book.md` — the full phase book
- `.harness/phase-{i}/*.md` — artifacts produced by the current phase's internal pipeline (Scout, Planner, Builder, Refiner, QA, Auditor reports for this phase)
- Current working tree after the phase's Build/Refine/QA has run

---

## Output

Single file: `.harness/phase-evidence-{i}.md`

Must contain:

```markdown
---
phase: {i}
phase_name: {name}
verdict: PASS | FAIL
retry_attempt: {1 | 2 | 3}
verified_at: YYYY-MM-DDTHH:MM:SSZ
---

# Phase {i} Evidence — {phase_name}

## DoD Checklist

| # | Criterion | Result | Evidence |
|---|-----------|--------|----------|
| 1 | {DoD item 1} | PASS / FAIL | {file:line | test name | output snippet} |
| 2 | {DoD item 2} | PASS / FAIL | {evidence} |
| ... | ... | ... | ... |

## Verify Commands

### `{command 1}`
```
exit code: 0
stdout (last 20 lines):
{captured}
stderr:
{captured}
```

### `{command 2}`
...

## Cross-Phase Invariant Check

For each invariant listed in phase-book.md "Cross-Phase Invariants":

| Invariant | Status | Evidence |
|-----------|--------|----------|
| {invariant 1} | HOLDS / VIOLATED | {how verified} |

## Regression Check on Earlier Phases

For each earlier phase whose files were touched by this phase (compute via `git diff --name-only HEAD~1` intersected with previous phases' scope):

| Prior Phase | Re-verified? | Status |
|-------------|-------------|--------|
| Phase {k} | YES (re-ran verify commands) | PASS / FAIL |

## Verdict

{PASS | FAIL}

Reason: {one sentence}

{If FAIL: pointer to the failing DoD item or command, plus a short Diagnostician-ready summary.}
```

---

## Procedure

### Step 1 — Read the phase-book entry

Extract the current phase's DoD items, verify commands, evidence requirements, and cross-phase invariants.

### Step 2 — Verify DoD items one by one

For each `[ ]` item:

1. Identify the file, test, or observable behavior that confirms it.
2. Read / run / inspect as needed.
3. Record PASS or FAIL with concrete evidence.

Never mark PASS on inference. If the evidence cannot be cited, the item is FAIL.

### Step 3 — Execute verify commands

Run each verify command in a fresh shell (not using cached output). Capture:
- exit code
- last 20 lines of stdout
- stderr (if any)

If any command exits non-zero, verdict is **FAIL** regardless of DoD results.

### Step 4 — Cross-phase invariant check

For each invariant in the phase-book:
- Re-check the condition (read the relevant file, run the relevant command)
- Record HOLDS or VIOLATED

Any VIOLATED → verdict is **FAIL**.

### Step 5 — Regression check on earlier phases

Identify files modified by this phase that were also modified by any earlier phase (union of earlier phases' `Scope`). For each such earlier phase:

1. Re-run its verify commands.
2. Confirm its DoD items still hold (can be a quick spot check; full re-verification is not required unless a command fails).

Any regression → verdict is **FAIL** with a clear regression tag.

### Step 6 — Render verdict

Verdict is PASS only when:
- All DoD items PASS, AND
- All verify commands exit 0 (or meet their documented success signal), AND
- All cross-phase invariants HOLD, AND
- No earlier phase regressed.

Otherwise FAIL with an explicit reason chain.

---

## Retry Protocol

On `FAIL`:

1. Phase Verifier records verdict FAIL + root-cause hint.
2. Orchestrator reads the evidence file, updates `retry_attempt` in phase-book frontmatter, and routes to the Diagnostician.
3. Diagnostician produces `.harness/phase-{i}/diagnosis-retry-{N}.md` pointing to specific file:line root causes.
4. Orchestrator re-runs the phase-internal pipeline with the diagnosis as input.

After 3 FAIL verdicts on the same phase, the orchestrator:

1. Sets phase-book `status: paused`.
2. Writes a user-facing escalation (see `meta-loop-protocol.md` §5).
3. Halts the Meta-Loop.

---

## Tier-Specific Rigor (Elite only)

Under the Elite tier, add the following to every Phase Verifier run:

1. **Auditor spot check** — invoke the Auditor agent (short, focused) to cross-verify the evidence file against the phase's artifacts. Elite-tier agents are more likely to produce confidently-stated but incorrect evidence. The Auditor's verdict is recorded in a `### Auditor Cross-Check` section appended to the evidence file.
2. **Quantitative claim verification** — any "N tests passed" or "covered X%" claim must be matched against actual command output. Mismatch → FAIL.

Standard and Advanced tiers skip step 1 but still perform step 2 on a best-effort basis.

---

## Anti-Patterns — DO NOT

- Do NOT mark PASS based on "the code looks correct."
- Do NOT skip a verify command because "it passed last round."
- Do NOT accept Builder's progress claims at face value — they are inputs, not evidence.
- Do NOT suppress a FAIL because "it's a trivial issue." Trivial FAILs exist to surface integration gaps.
- Do NOT run commands in a way that reuses cached results (`--no-cache` when possible).
- Do NOT write to any file other than `.harness/phase-evidence-{i}.md` (plus the Auditor cross-check section if Elite).
