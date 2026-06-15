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

2b. **Validate the file is still well-formed JSON** before declaring ready — a botched merge bricks the user's config. Run a parse check, e.g.:

```bash
node -e "JSON.parse(require('fs').readFileSync(process.env.HOME + '/.claude/settings.json','utf8'))" && echo "settings.json OK"
# or: jq empty ~/.claude/settings.json && echo "settings.json OK"
```

If it does NOT parse, do NOT proceed: restore the prior content and report the failure to the user instead of leaving a broken config.

3. If `claude-hud` is in `enabledPlugins`, remove it (claude-dashboard replaces it)
4. Show the user the updated settings and confirm the change
5. Tell the user to restart Claude Code or run `/mcp` to see the new statusline
