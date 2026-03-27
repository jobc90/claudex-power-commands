---
description: "Configure Claude Dashboard as the statusline. Shows model, context, cost, rate limits, git info, and session duration."
---

# Claude Dashboard Setup

You are setting up Claude Dashboard as the user's statusline.

## Steps

1. Read the user's `~/.claude/settings.json`
2. Update the `statusLine` field to use Claude Dashboard:

```json
{
  "statusLine": {
    "type": "command",
    "command": "node ${CLAUDE_PLUGIN_ROOT}/dashboard/statusline.js"
  }
}
```

**IMPORTANT**: Replace `${CLAUDE_PLUGIN_ROOT}` with the actual absolute path to this plugin's root directory. To find it, resolve the path of this command file's parent's parent directory.

3. If `claude-hud` is in `enabledPlugins`, remove it (claude-dashboard replaces it)
4. Show the user the updated settings and confirm the change
5. Tell the user to restart Claude Code or run `/mcp` to see the new statusline
