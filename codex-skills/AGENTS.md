> Scope: Codex skill source tree for `claudex-power-commands`.

## Source of Truth

- This directory contains the seven Codex skills shipped by this project:
  - `harness`
  - `harness-docs`
  - `harness-review`
  - `harness-qa`
  - `harness-think`
  - `design`
  - `claude-dashboard`
- `/harness-team` is not a separate Codex skill. TEAM mode is part of `harness`.
- `harness-think` (Surveyor) is read-only and spawns no subagents — it is a grounded-discussion skill, not a pipeline.
- Do not reintroduce stale legacy skills unless the project source adds them back explicitly.

## Routing

- Do not use the global `superpower` router for work in this tree.
- Read the requested skill's own `SKILL.md` directly, then load only the referenced files needed for that task.
- If a task spans multiple skills, choose the smallest set of directly relevant skills.

## Codex Runtime

### Model

- The frontier Codex model is `gpt-5.6-sol` (`~/.codex/config.toml`: `model = "gpt-5.6-sol"`, `model_context_window = 1000000`, `model_reasoning_effort = "high"`).
- Subagents inherit the session model. Never pin Claude model names (`fable`, `opus`, `sonnet`, `haiku`) in a Codex runtime — those identifiers do not exist here.

### Tier detection

- The tier fallback in the mirrored reference files already recognizes an identifier containing `sol` → **Elite**, so `gpt-5.6-sol` resolves to Elite with no Codex-specific patch.
- The `CLAUDEX_ELITE_MODELS` env-var example includes `gpt-5.6-sol`; set it only to override detection for a model the name-based fallback does not cover.

### Translation table (Claude vocabulary → Codex)

The reference files under `codex-skills/*/references/` are **byte-identical mirrors** of `harness/references/`. Do not fork a mirrored file to fix Claude-only wording; translate it here instead.

| Reference file says | Read it as, under Codex |
| --- | --- |
| `/effort xhigh` (raise thinking mode) | Raise `model_reasoning_effort` in `~/.codex/config.toml`, or pick a higher effort in the `/model` picker |
| `Agent({...})` / "the Agent tool" / `isolation: worktree` | The Codex subagent spawn mechanism: a separate `spawn_agent` call per phase agent, with `fork_context` false for fresh context |
| `mcp__playwright__browser_*` tool ids | The Playwright MCP tools as bound under Codex — match by capability (navigate, snapshot, click, fill form, screenshot, press key, console messages, network requests), not by the literal Claude tool id |
| Paths like `~/.claude/harness/references/...` | `${CODEX_HOME:-$HOME/.codex}/skills/<skill>/references/...` (the installed copy of this source tree) |
| spawn labor agents with `model: "opus"` under an Elite-tier parent | no equivalent — omit model overrides entirely; subagents inherit the session model (`gpt-5.6-sol`) |

### Artifact dir

- Codex harness runs write to `.harness/`, the same directory the Claude pipeline uses.
- Caveat: do not run the Claude and Codex harness pipelines concurrently in the same repo — they share `.harness/` and will overwrite each other's artifacts.

## Sync

- Installed Codex skills live under `${CODEX_HOME:-$HOME/.codex}/skills`.
- Sync each source skill directory with deletion enabled so removed references do not remain installed:

```sh
for skill in harness harness-docs harness-review harness-qa harness-think design claude-dashboard; do
  rsync -a --delete "codex-skills/$skill/" "${CODEX_HOME:-$HOME/.codex}/skills/$skill/"
done
# This routing/translation doc must travel with the skills — the mirrored
# references cite it (Codex Runtime translation table):
cp -p codex-skills/AGENTS.md "${CODEX_HOME:-$HOME/.codex}/skills/AGENTS.md"
```

- After sync, remove installed skills that are no longer present in `codex-skills/`.
- Verify with `diff -qr codex-skills/$skill "${CODEX_HOME:-$HOME/.codex}/skills/$skill"` for each installed project skill.
