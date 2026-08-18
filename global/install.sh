#!/usr/bin/env bash
# install.sh — materialize global/ into ~/.claude (copy, never symlink).
#
# global/ is the canonical source for the user-global Claude Code config:
#   agents/ rules/ commands/ skills/ hooks/ scripts/
# attic/ holds demoted items and is NEVER installed.
#
# Usage:
#   global/install.sh          # sync all six slots into ~/.claude (deletes drift)
#   global/install.sh --diff   # dry-run: show what would change, write nothing
#
# NOTE: rules/ cannot be shipped via the plugin mechanism — this script is the
# only deployment path for it. settings.json is intentionally NOT managed here.
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="${CLAUDE_DIR:-$HOME/.claude}"
SLOTS=(agents rules commands skills hooks scripts)
MODE="${1:-install}"

for s in "${SLOTS[@]}"; do
  if [[ ! -d "$SRC/$s" ]]; then
    echo "SKIP $s (missing in $SRC)" >&2
    continue
  fi
  case "$MODE" in
    --diff)
      echo "== $s =="
      rsync -rlpgo -n -v --delete --exclude .DS_Store "$SRC/$s/" "$DEST/$s/" \
        | grep -v -e '^sending' -e '^sent ' -e '^total size' -e '^$' -e '^\./$' || true
      ;;
    install)
      mkdir -p "$DEST/$s"
      rsync -rlpgo --delete --exclude .DS_Store "$SRC/$s/" "$DEST/$s/"
      echo "synced $s -> $DEST/$s"
      ;;
    *)
      echo "unknown mode: $MODE (use --diff or no argument)" >&2
      exit 1
      ;;
  esac
done
