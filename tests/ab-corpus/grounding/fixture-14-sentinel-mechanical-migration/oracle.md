# Oracle — Sentinel mechanical-check migration (item #14)

> Cancelling fixture. The asker WANTS to REMOVE the mechanical CRITICAL checks from Sentinel and
> move them to hooks. The true answer is **NO — cancelled: removing them breaks Codex (hooks are
> Claude-only) and drops Claude's defense-in-depth. The layering note is already in place; nothing
> to migrate-by-removal.**

## Cancelling facts (verified by reading)

1. **Hooks are Claude-only; on Codex the Sentinel is the ONLY enforcement.** Removing the
   mechanical checks from Sentinel would leave Codex with no enforcement at all:
   - `harness/references/agent-containment.md:28` — "(Hooks are Claude-only; **Codex has no
     PreToolUse runtime, so on Codex this deny-list stays Sentinel-enforced.**)"

2. **It is layering (defense-in-depth), not duplication to delete.** The same line already
   documents the intended split — hook = mechanical/preventive, Sentinel = judgment — *and keeps
   both*:
   - `harness/references/agent-containment.md:28` — "is now **ALSO** enforced by the deterministic
     PreToolUse hook `hooks/guard-bash.sh` … The Sentinel agent remains the judgment layer …;
     hooks handle the mechanical layer — deterministic > agent-remembered." ("ALSO", not "instead".)

3. **The work is already done as an ADD, not a migrate.** The layer-split note was added in P0-4;
   #14's "migration" had nothing left to do.

## Where it lives in the repo's own record

- `docs/whitepaper-alignment-plan.md:197` "취소 — 검증으로 전제 반박 … #14 Sentinel 기계검사 훅 이관:
  Sentinel의 CRITICAL 검사는 **Codex의 유일 enforcement**(Codex엔 PreToolUse 없음) + Claude
  defense-in-depth → 제거 불가. 계층 분담 노트는 **이미 P0-4에서 agent-containment.md에 추가됨**.
  → 실질 완료, 별도 행동 불필요."
- `docs/whitepaper-alignment-plan.md:82,138` (#14 description, P2).
- `CHANGELOG.md:34` "[4.4.0] Cancelled on verification": "**Sentinel-mechanical-check migration**
  (those checks are Codex's only enforcement + Claude defense-in-depth)".

## Correct conclusion

**No — do not implement (as a removal/migration).** Cancelled because hooks are Claude-only, so on
Codex the Sentinel is the sole enforcement (`agent-containment.md:28`); the hook ADDS a
deterministic layer ("ALSO") rather than replacing Sentinel. Removing the checks would break Codex
and drop Claude's defense-in-depth. An ungrounded responder would happily "DRY out" the overlap and
silently disarm Codex.
