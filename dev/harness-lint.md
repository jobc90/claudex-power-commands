---
description: "Lint the harness ecosystem — verify cross-references, Codex mirror sync (prompts + shared references), pipeline structure, and file reference timing across all 29 agents (+1 helper) and 7 commands."
---

# Harness-Lint: Consistency Checker

> Verifies structural integrity of the harness agent ecosystem.
> Mechanical checks (diff, file existence) + semantic checks (cross-references, timing, structure).

## User Request

$ARGUMENTS

## Guard Clause

If the request is NOT a lint/check/verify request:
- Respond directly as a normal conversation
- Do NOT execute the lint protocol

Proceed when the user wants to:
- Check harness consistency after making changes
- Verify Codex mirrors are in sync
- Find broken cross-references
- Validate pipeline structure before committing

## Architecture

```
/harness-lint [options]
  |
  +- Phase 1: Mechanical Checks (Bash)    -> diff, file existence
  +- Phase 2: Semantic Analysis (Agent)    -> cross-references, timing, structure
  +- Phase 3: Report                       -> lint-report.md or terminal output
```

## Arguments

- `--fix`: After reporting, auto-fix Codex mirror drift by copying originals
- `--quick`: Skip semantic analysis, run only mechanical checks
- (default): Full lint — mechanical + semantic

---

## Phase 1: Mechanical Checks

Run these checks via Bash and collect results:

### 1a. Codex Mirror Sync

Compare each original with its mirror. Two classes are checked:

1. **Agent prompts** — `harness/*-prompt.md` against the mirrors of each pipeline that uses them (mirror map: `harness/INDEX.md`).
2. **Shared references** — every `harness/references/*.md` that has a same-named counterpart under `codex-skills/{harness,harness-docs,harness-qa,harness-review}/references/` is diffed too. The pair list is **derived dynamically**, so a newly added shared reference is covered without editing this command. (`codex-skills/harness-think/references/think-grounding.md` is checked separately below.)

Mirrors must be **byte-identical** — ecosystem wording differences belong in `codex-skills/AGENTS.md`, never in a forked mirror.

```bash
echo "## Codex Mirror Sync Check"
echo ""

CODEX_SKILLS="harness harness-docs harness-qa harness-review"

# Agent prompts — every harness/*-prompt.md, against whichever pipeline mirrors it.
for src in harness/*-prompt.md; do
  f="$(basename "$src")"
  for skill in $CODEX_SKILLS; do
    mirror="codex-skills/$skill/references/$f"
    [ -f "$mirror" ] || continue
    if diff -q "$src" "$mirror" > /dev/null 2>&1; then
      echo "PASS: $src ($skill)"
    else
      echo "DRIFT: $src vs $mirror"
    fi
  done
done

# Shared references — same derivation, so new references are covered automatically.
for src in harness/references/*.md; do
  [ -f "$src" ] || continue
  f="$(basename "$src")"
  for skill in $CODEX_SKILLS; do
    mirror="codex-skills/$skill/references/$f"
    [ -f "$mirror" ] || continue
    if diff -q "$src" "$mirror" > /dev/null 2>&1; then
      echo "PASS: $src ($skill)"
    else
      echo "DRIFT: $src vs $mirror"
    fi
  done
done

# harness-think — reference-only skill, one dedicated mirror
if diff -q "harness/references/think-grounding.md" \
          "codex-skills/harness-think/references/think-grounding.md" > /dev/null 2>&1; then
  echo "PASS: harness/references/think-grounding.md (think)"
else
  echo "DRIFT: harness/references/think-grounding.md vs codex-skills/harness-think/references/think-grounding.md"
fi
```

Collect the output. Count PASS vs DRIFT.

### 1b. File Existence Check

Verify all prompt files listed in INDEX.md exist:

```bash
echo "## File Existence Check"

# All 29 user-facing agent prompts must exist in harness/
for f in scout-prompt.md planner-prompt.md builder-prompt.md sentinel-prompt.md \
         refiner-prompt.md qa-prompt.md diagnostician-prompt.md auditor-prompt.md \
         scanner-prompt.md analyzer-prompt.md \
         fixer-prompt.md verifier-prompt.md reporter-prompt.md researcher-prompt.md \
         outliner-prompt.md writer-prompt.md reviewer-prompt.md validator-prompt.md \
         architect-prompt.md worker-prompt.md integrator-prompt.md \
         scenario-writer-prompt.md test-executor-prompt.md analyst-prompt.md \
         qa-reporter-prompt.md trajectory-reporter-prompt.md curator-prompt.md \
         phase-book-planner-prompt.md phase-verifier-prompt.md; do
  if [ -f "harness/$f" ]; then
    echo "PASS: harness/$f"
  else
    echo "MISSING: harness/$f"
  fi
done

# INDEX.md, the orchestrator helper, and the dev-only linter prompt must exist
# (phase-orchestrator = helper, linter = /harness-lint tooling; neither counts as an agent)
for f in INDEX.md phase-orchestrator-prompt.md linter-prompt.md; do
  if [ -f "harness/$f" ]; then
    echo "PASS: harness/$f"
  else
    echo "MISSING: harness/$f"
  fi
done
```

### 1c. Quick Mode Exit

If `--quick` was specified:
- Present mechanical check results to user
- Count PASS/DRIFT/MISSING
- Report summary and EXIT

---

## Phase 2: Semantic Analysis

Read the linter prompt template: `~/.claude/harness/linter-prompt.md`

Launch a **general-purpose Agent**:
- **prompt**: The linter prompt template + context:
  - "Index file: `harness/INDEX.md`"
  - "Mechanical check results: [paste Phase 1 output]"
  - "Project directory: `{cwd}`"
  - "Read all prompt files in `harness/` and all command files in `commands/`"
  - "Also read Codex SKILL.md files: `codex-skills/harness/SKILL.md`, `codex-skills/harness-qa/SKILL.md`, `codex-skills/harness-docs/SKILL.md`, `codex-skills/harness-review/SKILL.md`"
  - "Write your report to terminal output (do not create files)"
- **description**: "harness linter"

---

## Phase 3: Report

After the Linter agent completes, present the report to the user:

```
## Harness Lint Complete

**Mechanical**: [X] PASS | [Y] DRIFT | [Z] MISSING
**Semantic**: [X] PASS | [Y] WARN | [Z] FAIL
**Critical issues**: [N]

[Full report from Linter agent]
```

### `--fix` Mode

If `--fix` was specified AND there were DRIFT findings:

1. Show the drift findings first
2. Ask: **"[X]개 Codex 미러 불일치를 자동 수정할까요?"**
3. **WAIT for user approval.**
4. If approved, run:
   ```bash
   # Copy each drifted original to its mirror
   cp harness/{file}.md codex-skills/{pipeline}/references/{file}.md
   ```
5. Re-run Phase 1a to verify all PASS

---

## Critical Rules

1. **Phase 1 is mechanical — no LLM needed.** Just bash diff and file checks.
2. **Phase 2 is semantic — needs LLM.** Cross-reference analysis requires reading and understanding prompts.
3. **`--quick` skips Phase 2.** Useful for fast mirror sync checks.
4. **`--fix` only fixes mirror drift.** Semantic issues require manual intervention.
5. **No user approval needed to run.** Lint is read-only (except `--fix`).
6. **Read `harness/INDEX.md` as the source of truth** for what should exist and how things connect.

## Cost Awareness

| Mode | Duration | Agent Calls |
|------|---------|-------------|
| `--quick` | <30 sec | 0 (bash only) |
| default | 2-5 min | 1 (linter agent) |
| `--fix` | 1-2 min | 0 (bash only, after default lint) |
