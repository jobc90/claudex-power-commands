# Oracle — make spec-as-eval the DEFAULT for all /harness builds (item #15)

> Cancelling fixture. The asker WANTS to turn the "write the verify command as a failing test
> before any code" spec-as-eval gate ON by default for every build path, forcing a committed test
> suite to pass before any code proceeds.
> The true answer is **NO — defaulting this gate is explicitly forbidden in the repo's own plan;
> it is opt-in / flag-only by design.**

## Cancelling facts (verified by reading this session)

1. **The plan ships spec-as-eval as opt-in/flag-only, NOT default.**
   - `docs/whitepaper-alignment-plan.md:139` — "**#15 (옵션) spec-as-eval 게이트**: 코드 전 verify
     커맨드를 실패 테스트로 — **opt-in/flag 전용**, conductor fork에 종속(기본화하면 ceremony 역전)."
   - `docs/whitepaper-alignment-plan.md:83` (the §6 backlog table) — row 15 reads
     "(옵션) spec-as-eval 게이트 — opt-in/flag 전용, conductor fork에 종속".

2. **Defaulting it is named as an explicit anti-pattern / guardrail.**
   - `docs/whitepaper-alignment-plan.md:146` (§7 "하지 말 것 — 충돌·가드레일") —
     "**spec-as-eval를 기본값으로 만들지 말 것.** 커밋된 테스트 스위트를 모든 코드 전에 강제하면
     greenfield/throwaway build와 conductor 모드(#6)와 충돌. opt-in 전용." This is the asker's
     proposal verbatim, listed as a thing NOT to do.

3. **It is the lowest-priority, deferred tail item (P2), dependent on a conductor fork.**
   - `docs/whitepaper-alignment-plan.md:161` (execution order) — P2 ends with
     "(15) 옵션 spec-as-eval", the last item, behind 14 others. It was never elevated to a default
     and the §11 execution log records no work on it.

## Why defaulting breaks things (the repo's stated reasons)

- **Greenfield / throwaway builds have no committed test suite to satisfy** — a hard pre-code gate
  would dead-lock the most common first-build case.
- **Conductor mode (`/harness --quick`, item #6) is a ceremony-bypass fork** for trivial real-time
  edits; forcing a full committed-test gate in front of it inverts its entire purpose
  ("기본화하면 ceremony 역전").

## Correct conclusion

**No — do not default this gate; keep it opt-in/flag-only.** The repo's own plan
(`docs/whitepaper-alignment-plan.md:139,146`) pre-registers "do not make spec-as-eval the default"
as a guardrail because a committed-test-before-any-code mandate collides with greenfield/throwaway
builds and the conductor (`--quick`) fork. An ungrounded responder would design the Phase-0
default-on wiring the asker requested; the grounded answer is to refuse defaulting and, at most,
expose it as an explicit per-run flag.
