#!/bin/bash
# Session cleanup — kill orphaned processes spawned during Claude Code sessions
# Triggered by SessionEnd hook

# Orphaned Playwright MCP + Chromium processes
pkill -f "playwright-mcp.*--browser" 2>/dev/null
pkill -f "chromium.*--remote-debugging" 2>/dev/null

# Orphaned dev servers (pnpm/npm/node dev servers on common ports)
# Only kill if started by current user, avoid killing intentional long-running servers
for port in 3000 3001 4000 5173; do
  pid=$(lsof -ti :$port -sTCP:LISTEN 2>/dev/null)
  if [ -n "$pid" ]; then
    # Only kill node/pnpm processes (not other services)
    cmd=$(ps -p $pid -o command= 2>/dev/null)
    case "$cmd" in
      *node*|*pnpm*|*npm*|*next*|*vite*|*nest*)
        kill $pid 2>/dev/null
        ;;
    esac
  fi
done

# Orphaned tmux sessions from agent teams
for sess in $(tmux ls 2>/dev/null | grep -i "claude\|agent\|team" | cut -d: -f1); do
  tmux kill-session -t "$sess" 2>/dev/null
done

exit 0
