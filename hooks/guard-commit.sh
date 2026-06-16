#!/bin/bash
# guard-commit.sh — git pre-commit hook (claudex)
# Defense-in-depth secret/credential scanner. Runs alongside pre-commit-lint.sh
# (which checks mirror/structure). This one scans the STAGED diff for hardcoded
# secrets using the credential patterns from harness/references/agent-containment.md
# (§2 "Forbidden Filesystem Access" credential families + the whitepaper's literal
# "block a commit with a hardcoded password" example). Exits 1 (blocks the commit)
# with a file:line list of offenders, else exits 0.
#
# Install: ln -sf ../../hooks/guard-commit.sh .git/hooks/pre-commit
#   (If pre-commit-lint.sh already occupies .git/hooks/pre-commit, chain both from a
#    small wrapper, or symlink this as .git/hooks/pre-commit and call lint from it.)

set -euo pipefail

PLUGIN_ROOT="$(git rev-parse --show-toplevel)"
cd "$PLUGIN_ROOT"

# Only added lines in the staged diff (so we don't re-flag pre-existing/removed lines).
# --no-color keeps the marker columns predictable.
DIFF=$(git diff --cached --no-color -U0 2>/dev/null || true)
if [ -z "$DIFF" ]; then
  exit 0
fi

# Credential patterns (case-insensitive where noted). Each entry: "LABEL|||REGEX".
# Patterns intentionally target HARDCODED literal values, not env-var reads.
PATTERNS=(
  "AWS access key ID|||AKIA[0-9A-Z]{16}"
  "AWS secret access key|||aws_secret_access_key[[:space:]]*[:=][[:space:]]*['\"][A-Za-z0-9/+=]{40}['\"]"
  "Private key header|||-----BEGIN[[:space:]]+(RSA|EC|OPENSSH|DSA|PGP|ENCRYPTED)?[[:space:]]*PRIVATE[[:space:]]+KEY-----"
  "Hardcoded password|||(password|passwd|pwd)[[:space:]]*[:=][[:space:]]*['\"][^'\"[:space:]]{4,}['\"]"
  "Hardcoded secret/token|||(secret|token|api[_-]?key|apikey|access[_-]?token|auth[_-]?token|client[_-]?secret)[[:space:]]*[:=][[:space:]]*['\"][A-Za-z0-9_./+=-]{8,}['\"]"
  "Slack token|||xox[abprs]-[A-Za-z0-9-]{10,}"
  "GitHub token|||gh[pousr]_[A-Za-z0-9]{36,}"
  "Google API key|||AIza[0-9A-Za-z_-]{35}"
  "Generic bearer secret|||[Bb]earer[[:space:]]+[A-Za-z0-9_.=-]{20,}"
)

OFFENDERS=()
CUR_FILE=""
CUR_LINE=0

# Walk the unified diff. Track current file + new-file line numbers from @@ hunks,
# and test each added ('+') line against every credential pattern.
while IFS= read -r line; do
  case "$line" in
    "+++ "*)
      # +++ <prefix>/path/to/file  ("/dev/null" => deletion).
      # git uses a single-letter prefix (b/, i/ for --cached, w/, c/, o/) — strip it.
      f="${line#+++ }"
      case "$f" in
        [abciwo]/*) f="${f#?/}" ;;
      esac
      CUR_FILE="$f"
      ;;
    "@@ "*)
      # @@ -old,cnt +new,cnt @@  — extract the new-file start line.
      newpart="${line#*+}"
      newpart="${newpart%% *}"
      newpart="${newpart%%,*}"
      if printf '%s' "$newpart" | grep -Eq '^[0-9]+$'; then
        CUR_LINE="$newpart"
      else
        CUR_LINE=0
      fi
      ;;
    "+"*)
      # Added content line (but not the +++ header, handled above).
      content="${line#+}"
      for entry in "${PATTERNS[@]}"; do
        label="${entry%%|||*}"
        regex="${entry##*|||}"
        if printf '%s' "$content" | grep -Eiq -- "$regex"; then
          OFFENDERS+=("${CUR_FILE}:${CUR_LINE}: ${label}")
          break
        fi
      done
      CUR_LINE=$((CUR_LINE + 1))
      ;;
    "-"*)
      # Removed line: does not advance new-file line counter.
      :
      ;;
    *)
      # Context line (only present if -U context > 0; advances new-file counter).
      if [ "$CUR_LINE" -gt 0 ]; then
        CUR_LINE=$((CUR_LINE + 1))
      fi
      ;;
  esac
done <<< "$DIFF"

if [ "${#OFFENDERS[@]}" -eq 0 ]; then
  exit 0
fi

echo "[guard-commit] BLOCKED: hardcoded secret(s) detected in staged changes:" >&2
echo "" >&2
for o in "${OFFENDERS[@]}"; do
  echo "  $o" >&2
done
echo "" >&2
echo "  Move secrets to environment variables (process.env / os.environ) and re-stage." >&2
echo "  See harness/references/agent-containment.md §2 (credential families)." >&2
echo "  Override (NOT recommended) only with an explicit human decision: git commit --no-verify" >&2
exit 1
