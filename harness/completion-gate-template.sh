#!/usr/bin/env bash
# completion-gate-template.sh — Project-agnostic stale iteration artifact scanner.
#
# Purpose
# -------
# Prevent "declare complete → user discovers stale state" failure mode
# in multi-iteration workflows (infra provisioning, doc editing, refactors).
# See harness/references/completion-gate-protocol.md for the full rationale.
#
# Usage
# -----
# Copy this file to your project as `scripts/completion-gate.sh`, chmod +x,
# and invoke it before declaring work complete:
#
#   bash scripts/completion-gate.sh              # full scan (AWS included)
#   bash scripts/completion-gate.sh --quick      # skip AWS calls
#   bash scripts/completion-gate.sh docs/        # scan specific subdir
#
# Agents in the harness pipeline (Reporter, QA Reporter, Integrator,
# Refiner, Auditor) check for this script's existence and invoke it
# automatically. If absent, they fall back to the inline scan from
# completion-gate-protocol.md §3.
#
# Customization
# -------------
# Add project-specific patterns in the sections marked "PROJECT CUSTOM".
# Examples: internal URLs that should be active, database names that
# should exist, Anthropic agent IDs that should be provisioned.

set -u

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$PROJECT_ROOT" || exit 2

QUICK=false
SCAN_ROOT="docs"
for arg in "$@"; do
  case "$arg" in
    --quick) QUICK=true ;;
    -*) ;;
    *) SCAN_ROOT="$arg" ;;
  esac
done

declare -i ISSUES=0
declare -i WARNINGS=0

say()  { printf '%s\n' "$*"; }
err()  { say "  ❌ $*"; ISSUES=$((ISSUES+1)); }
warn() { say "  ⚠️  $*"; WARNINGS=$((WARNINGS+1)); }
ok()   { say "  ✅ $*"; }

# Build scan target list
scan_glob=()
[ -d "$SCAN_ROOT" ] && scan_glob+=("$SCAN_ROOT")
[ -f "CLAUDE.md" ] && scan_glob+=("CLAUDE.md")
[ -f "README.md" ] && scan_glob+=("README.md")
[ -f "AGENT.md" ] && scan_glob+=("AGENT.md")
if [ ${#scan_glob[@]} -eq 0 ]; then
  say "Completion Gate: no scan targets found (no docs/, CLAUDE.md, README.md, or AGENT.md)"
  exit 0
fi

say "━━━ Completion Gate — stale iteration artifact scan ━━━"
say "Target: ${scan_glob[*]}"
say ""

# ───────────────────────────────────────────────────────────
# 1. EC2 instance IDs — live state cross-check
# ───────────────────────────────────────────────────────────
say "▸ 1. EC2 instance IDs vs AWS live state"
if $QUICK; then
  say "  (quick mode: skipping AWS calls)"
elif ! command -v aws >/dev/null 2>&1; then
  say "  (aws CLI not found — skip)"
else
  doc_ids=$(grep -rohE "\\bi-[0-9a-f]{17}\\b" "${scan_glob[@]}" 2>/dev/null | sort -u || true)
  if [ -z "$doc_ids" ]; then
    ok "no EC2 IDs referenced"
  else
    while IFS= read -r id; do
      state=$(aws ec2 describe-instances --instance-ids "$id" \
        --query 'Reservations[].Instances[].State.Name' \
        --output text 2>/dev/null || true)
      case "$state" in
        running|pending|stopping|stopped) ok "$id — $state" ;;
        terminated|shutting-down)
          files=$(grep -rl "$id" "${scan_glob[@]}" 2>/dev/null | tr '\n' ' ')
          err "TERMINATED/SHUTTING-DOWN: $id  (files: $files)"
          ;;
        "") warn "UNKNOWN state for $id (invalid or in a different account?)" ;;
        *)  warn "Unexpected state '$state' for $id" ;;
      esac
    done <<< "$doc_ids"
  fi
fi
say ""

# ───────────────────────────────────────────────────────────
# 2. WIP markers
# ───────────────────────────────────────────────────────────
say "▸ 2. Work-in-progress markers"
found_wip=false
for pat in "진행 중" "진행중" "in progress" "TBD" "TODO: update" "TODO: fix" "(추정)" "<PLACEHOLDER>" "<FILL IN>"; do
  hits=$(grep -rn "$pat" "${scan_glob[@]}" 2>/dev/null | head -5 || true)
  if [ -n "$hits" ]; then
    found_wip=true
    say "  '$pat':"
    echo "$hits" | while IFS= read -r line; do say "    $line"; done
    WARNINGS=$((WARNINGS+1))
  fi
done
$found_wip || ok "no WIP markers"
say ""

# ───────────────────────────────────────────────────────────
# 3. Managed Agents / API artifacts
# ───────────────────────────────────────────────────────────
say "▸ 3. Anthropic API artifact IDs (sesn_ / vlt_ / agent_)"
found_api=false
for prefix in sesn_ vlt_ agent_; do
  ids=$(grep -rohE "${prefix}[0-9A-Za-z]{15,}" "${scan_glob[@]}" 2>/dev/null | sort -u || true)
  if [ -n "$ids" ]; then
    found_api=true
    say "  ${prefix}:"
    echo "$ids" | while IFS= read -r id; do say "    $id"; done
  fi
done
$found_api || ok "no API artifact IDs"
say ""

# ───────────────────────────────────────────────────────────
# 4. Step status contradictions (M/F/S/D/Phase<N>)
# ───────────────────────────────────────────────────────────
say "▸ 4. Step status contradictions (same label '진행 중' + '완료')"
contradictions=false
for prefix in M F S D Phase; do
  for n in 1 2 3 4 5 6 7 8 9 10; do
    label="${prefix}${n}"
    in_prog=$(grep -l "${label}.*진행 중\|${label}.*in progress" "${scan_glob[@]}" 2>/dev/null | head -3 || true)
    done_f=$(grep -l "${label}.*완료\|${label}.*complete\|${label}.*done" "${scan_glob[@]}" 2>/dev/null | head -3 || true)
    if [ -n "$in_prog" ] && [ -n "$done_f" ]; then
      contradictions=true
      warn "${label} has both '진행 중' ($(echo $in_prog | tr '\n' ' ')) and '완료' ($(echo $done_f | tr '\n' ' '))"
    fi
  done
done
$contradictions || ok "no step-status contradictions"
say ""

# ───────────────────────────────────────────────────────────
# PROJECT CUSTOM — add your own checks below this line
# ───────────────────────────────────────────────────────────
# Example:
# say "▸ 5. Custom: internal URLs resolve"
# for url in $(grep -rohE 'https://internal\.[^ ]+' "${scan_glob[@]}" | sort -u); do
#   curl -sf -o /dev/null "$url" || warn "Dead URL: $url"
# done

# ───────────────────────────────────────────────────────────
# Summary
# ───────────────────────────────────────────────────────────
say "━━━ Result ━━━"
if [ $ISSUES -eq 0 ] && [ $WARNINGS -eq 0 ]; then
  say "✅ PASS — no stale artifacts. Safe to declare completion."
  exit 0
elif [ $ISSUES -eq 0 ]; then
  say "🟡 PASS with $WARNINGS warning(s) — review above. WIP markers in"
  say "    'describe-the-process' context are benign; verify intentional."
  exit 0
else
  say "❌ FAIL — $ISSUES critical, $WARNINGS warning(s). DO NOT declare"
  say "   completion. Reconcile affected files and re-run."
  exit 1
fi
