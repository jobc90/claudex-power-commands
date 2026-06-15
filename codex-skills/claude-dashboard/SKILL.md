---
name: claude-dashboard
description: Configure Claude Dashboard as the Claude Code statusline from Codex. Use when the user wants to set up the shared statusline command in `~/.claude/settings.json`.
---

# Claude Dashboard

## Overview

Run the Codex version of `/claude-dashboard`. Treat `/claude-dashboard` and `$claude-dashboard` as the same workflow intent inside Codex.

This is a setup tool, not a multi-agent harness.

## Workflow

1. Read `~/.claude/settings.json`.
2. Update the `statusLine` field to:

```json
{
  "statusLine": {
    "type": "command",
    "command": "node ${CLAUDE_PLUGIN_ROOT}/dashboard/statusline.js"
  }
}
```

3. Replace `${CLAUDE_PLUGIN_ROOT}` with the actual absolute path to this repository root.
4. If `claude-hud` is present in `enabledPlugins`, remove it.
5. **Validate the result is still well-formed JSON before declaring done** — `jq empty ~/.claude/settings.json` or `node -e 'JSON.parse(require("fs").readFileSync(process.env.HOME+"/.claude/settings.json","utf8"))'`. If it fails to parse, restore the prior content and report; do NOT leave a broken `settings.json` (a malformed file can break Claude Code startup).
6. Show the updated settings and confirm the change.
7. Tell the user to restart Claude Code or run `/mcp` to see the new statusline.

## Rules

- Patch the existing settings file instead of replacing unrelated user settings.
- If `~/.claude/settings.json` does not exist, create the minimal valid JSON structure needed for this change.
- Do not touch Codex settings. This skill configures Claude Code's statusline only.
- Never declare done without confirming `settings.json` still parses as valid JSON (step 5).
