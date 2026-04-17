# Harness Phase Orchestrator (Helper Reference)

> This file is a **reference for the top-level orchestrator** (the `/harness` command runner) — not an independent agent. It describes the control flow the orchestrator must execute to run the Meta-Loop correctly.
> Companion docs: `meta-loop-protocol.md`, `phase-verification-protocol.md`.

---

## When You Are Reading This

You are the orchestrator executing `/harness "<user request>"`. After Phase 0 (Triage) and Phase 0.5 (Security Triage), you must run the Meta-Loop using the procedure below. Do NOT deviate.

---

## Pre-Loop Setup

### Detect resume

At the very start of `/harness`:

```bash
if [ -f ".harness/phase-book.md" ]; then
  status=$(awk '/^status:/ {print $2; exit}' .harness/phase-book.md)
  if [ "$status" = "in_progress" ] || [ "$status" = "paused" ]; then
    # Prompt user: resume?
  fi
fi
```

Prompt format: `이전 phase-book이 감지되었습니다. Phase {current}/{total} ({status}). 이어서 진행할까요? (Y / N / reset)`

- `Y` → skip Phase 0/0.5/0.7; jump to the Meta-Loop starting at `current_phase`.
- `N` → halt; print "Meta-Loop paused. Resume any time via `/harness`." and exit.
- `reset` → `mv .harness .harness-backup-$(date +%s)`; continue fresh.

### Phase 0.7 — Phase-Book Planner

Launch the Phase-Book Planner agent (see `phase-book-planner-prompt.md`) with:
- `user_request = .harness/build-prompt.md` (write it first from $ARGUMENTS)
- `scale = {S/M/L}` (from Phase 0)
- `tier = {Standard/Advanced/Elite}` (from Phase 0)
- `security_triage = .harness/security-triage.md` (from Phase 0.5)

The planner writes `.harness/phase-book.md` and emits one announcement line.

**Approval gate (the only user gate in the whole Meta-Loop):**

- Relay the planner's announcement to the user.
- `Y` → set frontmatter `status: in_progress` (if planner set it to `pending`), proceed.
- `N` → `status: paused`, exit.
- `edit` → prompt: "phase-book.md를 수정한 후 다시 Y로 응답하세요." Wait for user.

---

## Meta-Loop Main Body

```
i = phase-book.current_phase
while i <= phase-book.total_phases:
    announce "Phase {i}/{N}: {phase_name}"

    # --- Work step: run phase-internal pipeline ---
    run_phase_internal_pipeline(
        scope = phase.scope,
        scale = infer_from(phase.estimated_rounds),
        sensitivity = security_triage.sensitivity
    )

    # --- Verify step: phase verifier ---
    launch_phase_verifier(phase = i)
    evidence = read_file(".harness/phase-evidence-{i}.md")
    verdict = evidence.frontmatter.verdict

    if verdict == "PASS":
        # --- Apply step: advance + cross-phase integrity ---
        cross_phase_integrity_check()
        if regression_detected:
            status = "paused"
            escalate("cross-phase regression at phase {i}")
            break
        if commit_push_intent_step(phase) is terminal:
            execute_terminal_phase(phase)  # commit / push / deploy / pr
        update phase-book.current_phase = i + 1
        append_to(".harness/phase-history.md", phase_i_summary)
        i = i + 1
        continue

    else:  # verdict == FAIL
        retry = evidence.frontmatter.retry_attempt
        if retry >= 3:
            status = "paused"
            escalate("phase {i} exhausted 3 retries")
            break
        # Diagnose → retry same phase
        launch_diagnostician(phase = i, retry = retry + 1)
        # move evidence aside so Phase Verifier can compare
        mv .harness/phase-evidence-{i}.md .harness/phase-evidence-{i}.md.prev
        # loop continues without incrementing i
        continue

# After loop: final Auditor + summary
if current_phase > total_phases:
    status = "complete"
    launch_final_auditor()
    print_summary()
```

---

## Phase-Internal Pipeline

Inside each phase iteration, run the classic harness pipeline with these adjustments:

- **Artifact path**: if `total_phases > 1`, write all phase-internal artifacts under `.harness/phase-{i}/`. If `total_phases == 1`, write directly under `.harness/` (backward compatibility).
- **Scale passed to Scout/Planner**: derived from the phase's `estimated_rounds` (1→S, 2→M, 3→L). Use the tier-aware file thresholds from `tier-matrix.md`.
- **Max rounds**: `min(phase.estimated_rounds, tier_matrix.max_rounds(scale, tier))`.
- **Diagnostician scope**: only the current phase's artifacts. Do NOT cross phase boundaries inside a retry.
- **Sentinel / Auditor**: activation follows the security triage + tier overrides from `commands/harness.md` Phase 0.5.

---

## Cross-Phase Integrity Check

After a phase PASS verdict, before incrementing `current_phase`:

1. Compute the set of files touched by the just-completed phase: `git diff --name-only HEAD~{commits_in_phase}`.
2. Intersect with the cumulative scope of all earlier phases (read from `phase-book.md` `Scope` fields).
3. For each intersection — meaning the current phase modified a file owned by an earlier phase:
   - Re-run that earlier phase's verify commands.
   - If any exit non-zero → regression. Mark `status: paused`, escalate.

For very small overlaps (e.g., a one-line touch of `package.json`), a light spot-check suffices. Use judgment.

---

## Terminal Phase Execution

If the phase-book's `commit_push_intent` field is non-`none` and the current phase is one of the appended terminal phases (`Phase ∞-*`), execute the corresponding git operation:

| Intent segment | Action |
|----------------|--------|
| `commit` | `git add` (files in scope) → `git commit -m "<conventional message>"` |
| `push` | `git push -u origin HEAD` if branch is new, else `git push` |
| `deploy` | Execute the deploy command from phase-book or error out |
| `pr` | `gh pr create --title "{goal}" --body "{phase-history.md summary}"` |

Each terminal phase still goes through the Phase Verifier (to capture exit codes and any URL outputs) before advancing.

**Pre-condition**: terminal phases run only after all functional phases pass. If any functional phase is `status: paused`, do not run terminal phases.

---

## Escalation Protocol

When the loop pauses:

1. Write `status: paused` to phase-book frontmatter.
2. Print a user-facing escalation block (see `meta-loop-protocol.md` §5).
3. Do not advance, retry, or alter phase-book body beyond the frontmatter fields.

Exit the `/harness` session normally. The user can `/harness` again to resume.

---

## Budget Safeguards

- At the start of each phase, estimate remaining budget. If the sum of remaining phase `Estimated Tokens` exceeds 80% of the session's remaining budget, prompt the user: "예상 비용이 세션 예산의 80%를 초과합니다. 계속할까요?"
- Hard stop at 95%. Pause the Meta-Loop.

---

## Logging

Append to `.harness/phase-history.md` after every phase transition:

```markdown
[YYYY-MM-DDTHH:MM:SSZ] Phase {i}/{N} | verdict: PASS | rounds: K | tokens: ~M | evidence: phase-evidence-{i}.md
```

This file is the Final Auditor's primary chronological input.

---

## Do / Don't

Do:
- Always update `phase-book.md` frontmatter on transitions.
- Always run Phase Verifier between phases, even for `total_phases == 1`.
- Always write evidence to `phase-evidence-{i}.md`, never skip.

Don't:
- Don't advance `current_phase` on FAIL.
- Don't retry more than 3 times per phase.
- Don't run terminal (commit/push/deploy/pr) phases if any functional phase failed.
- Don't mutate phase-book's body (phase list, DoD, verify commands) mid-run. Only frontmatter updates are allowed.
