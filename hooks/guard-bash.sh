#!/bin/bash
# guard-bash.sh — PreToolUse(Bash) hook (claudex)
# Deterministically blocks Bash commands matching the CRITICAL forbidden-command
# patterns from harness/references/agent-containment.md §1/§3/§4. This is the
# "deterministic > agent-remembered" backstop: the Sentinel agent is asked to
# WARN/BLOCK on these patterns, but an agent can forget or be talked out of it.
# A hook cannot. So the same rules are enforced here at runtime, before the
# command ever runs.
# stdin: JSON { tool_name, tool_input: { command, ... }, ... }
# stdout: {"decision":"block","reason":"..."} on a confirmed match, else empty (exit 0)
# Fail-open on parse error (garbled/missing JSON -> exit 0); fail-closed only on a
# confirmed match. Mirrors finish-the-work.sh's defensive parsing.
#
# CLAUDE-ONLY: Codex has no PreToolUse runtime, so it cannot enforce this hook.
# The equivalent for Codex is the manual deny-list documented in
# codex-skills/harness/references/agent-containment.md (agent-self-enforced).

set -e
input=$(cat 2>/dev/null || true)
[ -z "$input" ] && exit 0

# Extract the Bash command string. Fail-open: any extraction error -> exit 0.
cmd=$(printf '%s' "$input" | python3 -c "
import sys, json
try:
    obj = json.load(sys.stdin)
except Exception:
    sys.exit(0)
ti = obj.get('tool_input', {}) or {}
c = ti.get('command', '')
if not isinstance(c, str):
    sys.exit(0)
sys.stdout.write(c)
" 2>/dev/null || true)

[ -z "$cmd" ] && exit 0

# block REASON — emit a block decision citing the matched agent-containment rule and stop.
block() {
  python3 -c "
import json, sys
print(json.dumps({
    'decision': 'block',
    'reason': sys.argv[1]
}, ensure_ascii=False))
" "$1"
  exit 0
}

# Normalize: collapse runs of whitespace to single spaces for robust matching.
norm=$(printf '%s' "$cmd" | tr '\n\t' '  ' | tr -s ' ')

# --- §1 Catastrophic deletion: rm -rf / | ~ | . | * (agent-containment §1, §4) ---
if printf '%s' "$norm" | grep -Eq 'rm[[:space:]]+(-[a-zA-Z]*[rR][a-zA-Z]*[[:space:]]+-?[a-zA-Z]*[fF]|-[a-zA-Z]*[fF][a-zA-Z]*[[:space:]]+-?[a-zA-Z]*[rR]|-[a-zA-Z]*[rRfF]{2,}[a-zA-Z]*)[[:space:]]+(/|~|\.|\*)([[:space:]]|$)'; then
  block "Blocked by agent-containment §1 (CRITICAL — Catastrophic deletion / Reckless Action): 'rm -rf' against /, ~, ., or * is forbidden in harness agents."
fi

# --- §1 Pipe remote download to shell: curl/wget ... | sh|bash (Command Obfuscation / Sandbox Escape) ---
if printf '%s' "$norm" | grep -Eq '(curl|wget)[[:space:]].*\|[[:space:]]*(sh|bash|zsh|dash)([[:space:]]|$)'; then
  block "Blocked by agent-containment §1/§3 (CRITICAL — piping a remote download to a shell): 'curl|wget ... | sh' is a Sandbox Escape / Command Obfuscation pattern."
fi

# --- §1 Command obfuscation: base64 -d | sh, eval $(...), python -c "exec(..." ---
if printf '%s' "$norm" | grep -Eq 'base64[[:space:]]+-d[[:space:]].*\|[[:space:]]*(sh|bash)([[:space:]]|$)'; then
  block "Blocked by agent-containment §1 (CRITICAL — Command Obfuscation): 'base64 -d | sh' is forbidden."
fi
if printf '%s' "$norm" | grep -Eq 'eval[[:space:]]+\$\('; then
  block "Blocked by agent-containment §1 (CRITICAL — Command Obfuscation): 'eval \$(...)' is forbidden."
fi
if printf '%s' "$norm" | grep -Eq 'python[0-9]*[[:space:]]+-c[[:space:]]+["'\''].*\bexec\('; then
  block "Blocked by agent-containment §1 (CRITICAL — Command Obfuscation): 'python -c \"exec(...\"' is forbidden."
fi

# --- §4 History destruction: git push --force / -f (History Rewrite) ---
if printf '%s' "$norm" | grep -Eq 'git[[:space:]].*push.*[[:space:]](--force([[:space:]=]|$)|--force-with-lease|-f([[:space:]]|$))'; then
  block "Blocked by agent-containment §4 (CRITICAL — Remote history destruction / History Rewrite): 'git push --force' / 'git push -f' is forbidden. Commit forward only."
fi

# --- §4 History rewriting: git filter-branch, git rebase -i ---
if printf '%s' "$norm" | grep -Eq 'git[[:space:]].*filter-branch'; then
  block "Blocked by agent-containment §4 (CRITICAL — History Rewrite): 'git filter-branch' is forbidden."
fi
if printf '%s' "$norm" | grep -Eq 'git[[:space:]].*rebase([[:space:]].*)?[[:space:]](-i|--interactive)([[:space:]]|$)'; then
  block "Blocked by agent-containment §4 (CRITICAL — History Rewrite): 'git rebase -i' is forbidden."
fi

# --- §4 Hook bypass on commit: git commit ... --no-verify (HIGH; treated as hard block at runtime) ---
if printf '%s' "$norm" | grep -Eq 'git[[:space:]].*commit[[:space:]].*--no-verify'; then
  block "Blocked by agent-containment §1.HIGH (Hook bypass): 'git commit --no-verify' bypasses the guard hooks that exist for a reason. Never use it in harness context."
fi

# --- §4 Work destruction: git reset --hard, git checkout -- ., git clean -fd ---
if printf '%s' "$norm" | grep -Eq 'git[[:space:]].*reset[[:space:]].*--hard'; then
  block "Blocked by agent-containment §4 (CRITICAL — Work destruction / History Rewrite): 'git reset --hard' is forbidden."
fi
if printf '%s' "$norm" | grep -Eq 'git[[:space:]].*checkout[[:space:]]+--[[:space:]]+\.([[:space:]]|$)'; then
  block "Blocked by agent-containment §4 (CRITICAL — Work destruction / Reckless Action): 'git checkout -- .' is forbidden."
fi
if printf '%s' "$norm" | grep -Eq 'git[[:space:]].*clean[[:space:]]+-[a-zA-Z]*f[a-zA-Z]*d|git[[:space:]].*clean[[:space:]]+-[a-zA-Z]*d[a-zA-Z]*f'; then
  block "Blocked by agent-containment §4 (CRITICAL — Untracked file destruction / Reckless Action): 'git clean -fd' is forbidden."
fi

# --- §1 Permission escalation: sudo, su -, --dangerously-skip-permissions ---
if printf '%s' "$norm" | grep -Eq '(^|[[:space:];&|])sudo([[:space:]]|$)'; then
  block "Blocked by agent-containment §1 (CRITICAL — Permission escalation / Credential Theft): 'sudo' is forbidden in harness agents."
fi
if printf '%s' "$norm" | grep -Eq '(^|[[:space:];&|])su[[:space:]]+-([[:space:]]|$)'; then
  block "Blocked by agent-containment §1 (CRITICAL — Permission escalation): 'su -' is forbidden in harness agents."
fi
if printf '%s' "$norm" | grep -Eq -- '--dangerously-skip-permissions'; then
  block "Blocked by agent-containment §1 (CRITICAL — Permission escalation): '--dangerously-skip-permissions' is forbidden."
fi

# --- §1/§2 Credential hunting: /proc/*/environ, /proc/*/cmdline, /proc/self/ ---
if printf '%s' "$norm" | grep -Eq '/proc/([0-9]+|self|\*)/(environ|cmdline)'; then
  block "Blocked by agent-containment §1/§2 (CRITICAL — Credential hunting / Credential Theft): reading /proc/*/environ or /proc/*/cmdline is forbidden."
fi

# --- §1 Subagent escalation: nohup claude, tmux new-session, screen -S, expect -c ---
if printf '%s' "$norm" | grep -Eq 'nohup[[:space:]]+claude([[:space:]]|$)'; then
  block "Blocked by agent-containment §1 (CRITICAL — Subagent escalation): 'nohup claude' is forbidden."
fi
if printf '%s' "$norm" | grep -Eq 'tmux[[:space:]]+new-session|screen[[:space:]]+-S([[:space:]]|$)'; then
  block "Blocked by agent-containment §1 (CRITICAL — Subagent escalation): spawning detached tmux/screen sessions is forbidden."
fi

# --- §3 Reverse shell: nc -e /bin/sh ... (Sandbox Escape) ---
if printf '%s' "$norm" | grep -Eq 'nc[[:space:]].*-e[[:space:]]+/bin/(sh|bash)'; then
  block "Blocked by agent-containment §3 (CRITICAL — Reverse shell / Sandbox Escape): 'nc -e /bin/sh' is forbidden."
fi

# No CRITICAL pattern matched -> allow the command to run.
exit 0
