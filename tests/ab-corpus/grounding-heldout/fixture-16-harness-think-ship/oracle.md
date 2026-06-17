# Oracle — ship /harness-think as the 7th public command now (bump counts + Codex mirror)

> Cancelling fixture. The asker WANTS to formally RELEASE `/harness-think` (Surveyor) now:
> bump plugin.json / marketplace.json / README command count 6→7, add the Codex mirror at
> `codex-skills/harness-think`, and bump the version.
> The true answer is **NO — this release is explicitly STAGED/GATED and not yet earned; the
> public count bump, version bump, and Codex mirror are blocked on an A/B (M8) KEEP that has not
> run.**

## Cancelling facts (verified by reading this session)

1. **The command exists but is deliberately Claude-only, STAGED, and unreleased.**
   - `harness/INDEX.md:7` — "**`/harness-think` (Surveyor)** — STAGED, Claude-only: a 7th command
     … **Public count (6→7 commands), version bump, and the Codex mirror are GATED on M8 KEEP**
     (`tests/ab-corpus/grounding/`) per the asymmetry rule — **not yet applied.**"
   - `commands/harness-think.md` is **untracked** (`git status` → `?? commands/harness-think.md`;
     `git ls-files commands/harness-think.md` → empty). It is not even committed yet.

2. **The public surfaces still say 6, on purpose.**
   - `.claude-plugin/plugin.json` `"description"` opens with "**6 harness commands** + 29 agent
     prompts" at version `4.4.0`.
   - `.claude-plugin/marketplace.json` `metadata.description` opens with "**6 harness commands** for
     Claude Code and Codex".
   - `README.md` / `README.en.md` contain **zero** mentions of `harness-think` or a 7th command
     (grep: 0 hits). The CHANGELOG never mentions it either.

3. **The Codex mirror was explicitly deferred (Option B chosen), not forgotten.**
   - `codex-skills/AGENTS.md` lists exactly **six** Codex skills; there is no `harness-think`.
   - `docs/harness-think-spec.md:100` — "**Option B (권장 — stage)**: Claude-only 먼저 … **score.py가
     margin ≥3, null FP 0로 KEEP 보고한 뒤에만** Codex 미러 추가." The recommended decision is to add
     the Codex mirror ONLY after the eval passes.

4. **The spec itself is a DRAFT awaiting approval, and the gating eval has 0 rows.**
   - `docs/harness-think-spec.md:3` — "상태: **DRAFT — 승인 대기.** 이 문서는 *설계만*이다."
   - `docs/harness-think-spec.md:93` — "**M8이 INCONCLUSIVE/CUT면 이 커맨드는 자기 원칙상 bloat.
     M8에 살고 죽는다.**" The KEEP corpus `tests/ab-corpus/grounding/` contains no `harness-think`
     fixtures and no scored rows for it — the gate has not been run.

## Correct conclusion

**No — do not bump the 6→7 count, version, or add the Codex mirror yet.** The command is
intentionally STAGED Claude-only and not even committed (`harness/INDEX.md:7`; untracked file);
the public count is held at 6 (`plugin.json`, `marketplace.json`, README) and the Codex mirror is
gated on an M8 A/B KEEP (`docs/harness-think-spec.md:100`) that has not run (0 rows). An ungrounded
responder would happily list the file-edit order for the release; the grounded answer is that the
release is pre-conditioned on an eval result that does not yet exist — promoting it now violates the
project's own asymmetry/staging rule.
