#!/bin/bash
# claudex-power-commands: pre-commit lint
# Runs quick mechanical checks when harness/commands/codex-skills files are staged.
# Install: ln -sf ../../hooks/pre-commit-lint.sh .git/hooks/pre-commit

set -euo pipefail

PLUGIN_ROOT="$(git rev-parse --show-toplevel)"
cd "$PLUGIN_ROOT"

# Check if any harness-related files are staged
STAGED=$(git diff --cached --name-only | grep -E '^(harness/|commands/|codex-skills/)' || true)
if [ -z "$STAGED" ]; then
  exit 0
fi

echo "[harness-lint] Checking staged harness files..."
ERRORS=0
WARNINGS=0

# --- Check 1: Codex Mirror Sync ---
check_mirror() {
  local original="$1"
  local mirror="$2"
  if [ ! -f "$mirror" ]; then
    echo "  MISSING: $mirror (original: $original)"
    ((ERRORS++)) || true
  elif ! diff -q "$original" "$mirror" > /dev/null 2>&1; then
    echo "  DRIFT: $original != $mirror"
    ((ERRORS++)) || true
  fi
}

echo ""
echo "## Codex Mirror Sync"

# harness pipeline
for f in scout-prompt.md planner-prompt.md builder-prompt.md refiner-prompt.md qa-prompt.md diagnostician-prompt.md; do
  [ -f "harness/$f" ] && check_mirror "harness/$f" "codex-skills/harness/references/$f"
done

# harness-review pipeline
for f in scanner-prompt.md analyzer-prompt.md fixer-prompt.md verifier-prompt.md reporter-prompt.md; do
  [ -f "harness/$f" ] && check_mirror "harness/$f" "codex-skills/harness-review/references/$f"
done

# harness-docs pipeline
for f in researcher-prompt.md outliner-prompt.md writer-prompt.md reviewer-prompt.md validator-prompt.md; do
  [ -f "harness/$f" ] && check_mirror "harness/$f" "codex-skills/harness-docs/references/$f"
done

# harness-team pipeline
for f in scout-prompt.md architect-prompt.md worker-prompt.md integrator-prompt.md qa-prompt.md diagnostician-prompt.md; do
  [ -f "harness/$f" ] && check_mirror "harness/$f" "codex-skills/harness-team/references/$f"
done

# harness-qa pipeline
for f in scout-prompt.md scenario-writer-prompt.md test-executor-prompt.md analyst-prompt.md qa-reporter-prompt.md; do
  [ -f "harness/$f" ] && check_mirror "harness/$f" "codex-skills/harness-qa/references/$f"
done

# --- Check 2: Required Files Exist ---
echo ""
echo "## Required Files"

for f in scout-prompt.md planner-prompt.md builder-prompt.md refiner-prompt.md \
         qa-prompt.md diagnostician-prompt.md scanner-prompt.md analyzer-prompt.md \
         fixer-prompt.md verifier-prompt.md reporter-prompt.md researcher-prompt.md \
         outliner-prompt.md writer-prompt.md reviewer-prompt.md validator-prompt.md \
         architect-prompt.md worker-prompt.md integrator-prompt.md \
         scenario-writer-prompt.md test-executor-prompt.md analyst-prompt.md \
         qa-reporter-prompt.md linter-prompt.md INDEX.md; do
  if [ ! -f "harness/$f" ]; then
    echo "  MISSING: harness/$f"
    ((ERRORS++)) || true
  fi
done

for f in harness.md harness-docs.md harness-review.md harness-team.md harness-qa.md harness-lint.md design.md claude-dashboard.md; do
  if [ ! -f "commands/$f" ]; then
    echo "  MISSING: commands/$f"
    ((ERRORS++)) || true
  fi
done

# --- Report ---
echo ""
if [ "$ERRORS" -gt 0 ]; then
  echo "[harness-lint] FAIL: $ERRORS error(s) found."
  echo "  Run '/harness-lint --fix' to auto-fix mirror drift."
  echo "  Or fix manually and re-stage."
  exit 1
else
  echo "[harness-lint] PASS: All checks passed."
  exit 0
fi
