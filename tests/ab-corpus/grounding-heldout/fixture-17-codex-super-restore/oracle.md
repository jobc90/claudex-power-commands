# Oracle — (re)create a `$super` top-level router Codex skill that auto-routes the 4 harness skills

> Cancelling fixture. The asker WANTS to add a `$super` router skill under `codex-skills/` that
> auto-routes intent to `$harness` / `$harness-docs` / `$harness-review` / `$harness-qa` from one
> entry point.
> The true answer is **NO — the Codex tree explicitly forbids a global router and ships no `super`
> skill; routing is "read the requested skill's own SKILL.md directly," by design.**

## Cancelling facts (verified by reading this session)

1. **A global router is explicitly banned in the Codex tree's own rules.**
   - `codex-skills/AGENTS.md:17` — "**Do not use the global `superpower` router for work in this
     tree.**" (under "## Routing").
   - The prescribed routing model is the opposite of a top-level dispatcher:
     `codex-skills/AGENTS.md:18-19` — "Read the requested skill's own `SKILL.md` directly, then
     load only the referenced files needed for that task. If a task spans multiple skills, choose
     the smallest set of directly relevant skills."

2. **The Codex source of truth ships exactly six skills, none named `super`.**
   - `codex-skills/AGENTS.md:4-11` — the canonical list is `harness`, `harness-docs`,
     `harness-review`, `harness-qa`, `design`, `claude-dashboard`. No `super`.
   - `ls codex-skills/` confirms the six directories (plus `AGENTS.md`); `find codex-skills -iname
     '*super*'` → 0 hits.

3. **Reintroducing removed skills is gated behind an explicit project decision.**
   - `codex-skills/AGENTS.md:12` — "**Do not reintroduce stale legacy skills unless the project
     source adds them back explicitly.**" There is no such re-addition for a `super`/router skill.
   - The sync script (`codex-skills/AGENTS.md:28-31`) iterates exactly those six skills with
     `rsync --delete`, and the rule "remove installed skills no longer present" means a stray
     `super` skill would be actively deleted on the next sync.

## Why a `super` router is the wrong shape here

- `harness` itself is already the adaptive entry point (it absorbed the former `/harness-team` into
  a TEAM mode — `codex-skills/AGENTS.md:10`). The harness family is built around **single-purpose,
  directly-invoked skills**, and the harness command already auto-selects SINGLE/TEAM and EXITs
  non-build/docs/review/QA work. A meta-router would re-add the very routing indirection the tree
  deleted.

## Correct conclusion

**No — do not add a `$super` router skill.** The Codex tree explicitly bans a global router
(`codex-skills/AGENTS.md:17`), ships exactly six skills with no `super`
(`codex-skills/AGENTS.md:4-11`), and mandates direct per-skill SKILL.md reading instead of
top-level dispatch (`codex-skills/AGENTS.md:18-19`). An ungrounded responder would happily design
the router wiring; the grounded answer is that the project has deliberately chosen direct invocation
over a meta-router, and a `super` skill would be deleted on the next `rsync --delete` sync.
