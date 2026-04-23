# Completion Gate Protocol

> Prevent "declare complete → user discovers stale state" failure mode
> through mandatory stale-iteration-artifact scanning before any
> done/complete/finalize declaration.

**Status**: MANDATORY for all pipeline-finalizing agents (Reporter, QA
Reporter, Integrator) — added v4.2.0.

**Origin**: Real incident 2026-04-23 — multi-iteration provisioning work
left an obsolete resource ID in a status document. Multi-layer audits
(plan audit 18/18 + 5-agent review) all passed because each checked
*cross-document* consistency but none checked *intra-document temporal*
consistency. The user had to catch it during final cleanup — exactly
the "N-round rework" problem this protocol prevents.

---

## 1. When to apply (MANDATORY trigger points)

Before producing any of the following user-facing artifacts, the agent
MUST execute the Completion Gate scan:

| Artifact | Agent | Timing |
|----------|-------|--------|
| Final pipeline summary (harness Phase 5, review Phase 6, qa Phase 5) | Reporter / QA Reporter | Before writing `.harness/*-report.md` |
| Worker-merge integration report (TEAM mode) | Integrator | Before closing `.harness/integration-result.md` |
| Auditor cross-verification report | Auditor | Before writing `.harness/auditor-report.md` |
| Commit message at milestone boundary | Refiner / Reporter | Before `git commit` |
| PR description at handoff | Reporter | Before `gh pr create` |
| "Phase N complete" / "Round N complete" | Any orchestrator | Before state transition |

A response that uses any of these phrases **without** a completed
Completion Gate is considered a protocol violation:

- "complete" / "done" / "finished" / "finalized" / "✅ 완료"
- "session handoff ready" / "next step ready"
- "pass" / "ship" / "ready to merge"

---

## 2. What to scan (six categories)

### 2.1 Infrastructure resource IDs (live state cross-check)
Any AWS / cloud resource ID referenced in docs or reports MUST point to
a currently-existing, non-terminated resource.

Patterns to scan:
- EC2 instances: `\bi-[0-9a-f]{17}\b` (word boundary excludes `ami-…`)
- RDS instances: referenced DB identifiers
- Security groups: `\bsg-[0-9a-f]{17}\b`
- IAM roles / policies: ARNs
- S3 buckets: `s3://…` references

For each ID found in docs, run the corresponding `describe-*` call.
Terminated / non-existent → CRITICAL.

### 2.2 Managed Agents / API session artifacts
Patterns:
- Session IDs: `sesn_[0-9A-Za-z]{15,}`
- Vault IDs: `vlt_[0-9A-Za-z]{15,}`
- Agent IDs: `agent_[0-9A-Za-z]{15,}`

These are long-lived but may be purged. Presence in long-term docs
(plans, architecture) without explanation is suspicious.

### 2.3 Work-in-progress markers
Text patterns that indicate intermediate state never reconciled:
- Korean: `진행 중`, `진행중`, `대기 중`, `작업중`, `(추정)`
- English: `in progress`, `TBD`, `TODO: update`, `TODO: fix`
- Placeholder: `<PLACEHOLDER>`, `<FILL IN>`, `<TODO>`

Occurrences in "describe the process" context are benign. Occurrences in
"this is the current state" context are stale.

### 2.4 Version reference drift
Patterns:
- Revision labels: `v1`, `v2`, `v3`, `v4.1.0` (outside a "history" section)
- Model version: `Claude 3.5`, `Opus 4.7`, etc. (if mentioned in a
  "current" section, must match the actual config)

Context-sensitive — flag only when the context implies "current version".

### 2.5 Step status contradictions (intra-document)
Within the same document set, a step cannot be both "진행 중" and
"완료" / "complete". Scan all `M<N>`, `F<N>`, `S<N>`, `D<N>`, `Phase <N>`,
`Round <N>` labels for contradictory status markers across files.

### 2.6 Date / SHA drift (optional)
- Dates in "today" context more than 7 days old
- Git SHAs that no longer resolve (`git cat-file -e <SHA>` fails)
- PR numbers in closed/merged state claimed as open

---

## 3. Inline scan (bash, project-agnostic)

The following snippet is self-contained and runs in any CWD with a
`docs/` or markdown-heavy structure. Agents should embed this as-is
in their pre-finalization sequence:

```bash
# ─── Completion Gate inline scan ───
set -u
cd "${PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}" || exit 2

declare -i ISSUES=0
declare -i WARNINGS=0
SCAN_ROOT="${1:-docs}"

scan_glob=()
[ -d "$SCAN_ROOT" ] && scan_glob+=("$SCAN_ROOT")
[ -f "CLAUDE.md" ] && scan_glob+=("CLAUDE.md")
[ -f "README.md" ] && scan_glob+=("README.md")
[ ${#scan_glob[@]} -eq 0 ] && { echo "No scan targets"; exit 0; }

# (1) EC2 IDs vs live state
if command -v aws >/dev/null 2>&1; then
  ec2_ids=$(grep -rohE "\\bi-[0-9a-f]{17}\\b" "${scan_glob[@]}" 2>/dev/null | sort -u)
  while IFS= read -r id; do
    [ -z "$id" ] && continue
    state=$(aws ec2 describe-instances --instance-ids "$id" \
      --query 'Reservations[].Instances[].State.Name' --output text 2>/dev/null)
    case "$state" in
      terminated|shutting-down)
        echo "  ❌ TERMINATED ID in docs: $id"
        ISSUES=$((ISSUES+1));;
      running|pending|stopping|stopped) echo "  ✅ $id — $state";;
      "") echo "  ⚠️  UNKNOWN: $id"; WARNINGS=$((WARNINGS+1));;
    esac
  done <<< "$ec2_ids"
fi

# (2) WIP markers
for pat in '진행 중' '진행중' 'in progress' 'TBD' 'TODO: update' '(추정)' '<PLACEHOLDER>'; do
  hits=$(grep -rn "$pat" "${scan_glob[@]}" 2>/dev/null | head -5)
  [ -n "$hits" ] && { echo "  ⚠️  WIP '$pat':"; echo "$hits" | sed 's/^/    /'; WARNINGS=$((WARNINGS+1)); }
done

# (3) Session / Vault / Agent IDs (enumerate, don't fail)
for prefix in sesn_ vlt_ agent_; do
  ids=$(grep -rohE "${prefix}[0-9A-Za-z]{15,}" "${scan_glob[@]}" 2>/dev/null | sort -u)
  [ -n "$ids" ] && { echo "  ℹ️  ${prefix} referenced:"; echo "$ids" | sed 's/^/    /'; }
done

# (4) M<N>/F<N>/S<N> contradictions
for prefix in M F S D; do
  for n in 1 2 3 4 5 6; do
    label="${prefix}${n}"
    in_prog=$(grep -l "${label}.*진행 중\|${label}.*in progress" "${scan_glob[@]}" 2>/dev/null)
    done_f=$(grep -l "${label}.*완료\|${label}.*complete\|${label}.*done" "${scan_glob[@]}" 2>/dev/null)
    if [ -n "$in_prog" ] && [ -n "$done_f" ]; then
      echo "  ⚠️  ${label} has BOTH '진행' and '완료' markers — reconcile"
      WARNINGS=$((WARNINGS+1))
    fi
  done
done

# Result
if [ $ISSUES -eq 0 ] && [ $WARNINGS -eq 0 ]; then
  echo "✅ Completion Gate: PASS"
  exit 0
elif [ $ISSUES -eq 0 ]; then
  echo "🟡 Completion Gate: PASS with $WARNINGS warning(s) (review required)"
  exit 0
else
  echo "❌ Completion Gate: FAIL — $ISSUES critical, $WARNINGS warning(s)"
  exit 1
fi
```

---

## 4. Template script (optional, project-side)

Projects may drop a persistent script at `scripts/completion-gate.sh` (or
`.claude/completion-gate.sh`) containing the above scan plus
project-specific extensions. The harness prompts accept either:

- Inline scan (always available)
- `scripts/completion-gate.sh` if it exists (preferred — projects can
  customize patterns)

The invocation protocol for agents:

```bash
if [ -x scripts/completion-gate.sh ]; then
  bash scripts/completion-gate.sh || GATE_FAIL=1
else
  # fallback: inline scan (embed snippet from §3 above)
  :
fi
```

---

## 5. Agent behavior on gate result

| Result | Agent action |
|--------|--------------|
| ✅ PASS | Proceed to finalize (write report, commit, etc.) |
| 🟡 PASS with warnings | Include warnings in report under "Completion Gate: WARN" section. Proceed. |
| ❌ FAIL (critical) | **Do NOT finalize**. Either (a) reconcile the artifact (edit stale references), re-run gate, then finalize, or (b) escalate to user with specific IDs and affected files. Never write the final report with unresolved CRITICAL. |

---

## 6. Reconciliation workflow

When the gate returns CRITICAL, the agent MUST:

1. Run `grep -rl "<stale-ref>" "${scan_glob[@]}"` to enumerate affected files
2. For each file, edit the reference to point to the current state (e.g.,
   terminated EC2 ID → current active EC2 ID)
3. Re-run the gate
4. Only when gate returns PASS, produce the final report
5. The final report MUST include a one-line attestation:

   ```
   Completion Gate: ✅ PASS (N artifacts scanned, 0 critical)
   ```

---

## 7. Integration points summary (v4.2.0)

Files updated to enforce this protocol:

- `harness/reporter-prompt.md` — pre-finalization gate call
- `harness/qa-reporter-prompt.md` — pre-report gate call
- `harness/integrator-prompt.md` — pre-merge gate call (TEAM mode)
- `harness/auditor-prompt.md` — stale-artifact scan embedded in audit scope
- `harness/refiner-prompt.md` — post-fix reconciliation reminder
- `commands/harness.md` Phase 5 — gate invocation before Summary
- `commands/harness-review.md` Phase 6 — gate invocation before Report
- `commands/harness-qa.md` Phase 5 — gate invocation before Report

Codex mirrors receive equivalent additions in v4.2.0 release.

---

## 8. Why this is in a reference, not in each prompt

Keeping the pattern centralized:
- Single source of truth for scan logic
- Agents cite `harness/references/completion-gate-protocol.md` § N
- Updates (new artifact categories, new AWS commands) affect one file
- Auditor can verify "did the agent follow the protocol?" by checking
  protocol reference + the agent's gate invocation log

---

**Protocol version**: 1.0 (2026-04-23)  
**Next revision trigger**: Every quarter, or when a new stale-artifact class is observed in the wild.
