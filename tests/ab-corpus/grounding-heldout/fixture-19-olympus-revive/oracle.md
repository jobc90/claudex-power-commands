# Oracle — revive the `olympus` side-project (Codex control-plane + Claude CLI worker orchestrator)

> Cancelling fixture. The asker WANTS to resurrect `side-project/olympus`, finish the architecture
> reset, and wire the control-plane ↔ worker so it can drive multi-worker orchestration alongside
> the claudex harness.
> The true answer is **NO — olympus is recorded as abandoned/폐기; the workspace's own master
> reference says to ignore it.**

## Cancelling facts (verified by reading this session)

1. **The workspace master reference marks olympus as 폐기 (abandoned), "ignore in workspace".**
   - `~/dev/CLAUDE.md:651` — "| `side-project/olympus` | Codex 제어플레인 + Claude CLI 워커
     오케스트레이터 사이드 프로젝트. **아키텍처 리셋 도중 중단** | **폐기** (개발 중단, **워크스페이스에서
     무시**) |" (the "Deprecated 프로젝트" table).
   - `~/dev/CLAUDE.md:128` — in the project map under "Deprecated": "`side-project/olympus`
     # Codex 제어플레인 + Claude CLI 워커 오케스트레이터 (**아키텍처 리셋 중단, 폐기**)".

2. **The reason for death is exactly the work the asker proposes to "continue."**
   - The cancelling note says development stopped **mid architecture-reset** ("아키텍처 리셋 도중
     중단"). The asker proposes to "이어받아서 제어플레인과 워커 배선을 끝내" — i.e. resume the
     abandoned reset. The repo already classifies that resumption target as dead, not paused-for-later.

3. **olympus is not part of this plugin's scope at all.**
   - It lives outside `claudex-power-commands` (under `~/dev/side-project/olympus`), and the claudex
     repo has no integration, reference, or dependency on it. "연동해서 멀티 워커 오케스트레이션" is a
     net-new coupling to an abandoned external project, not a continuation of claudex work.

## Correct conclusion

**No — do not revive olympus.** The workspace master reference records it as 폐기/개발 중단 and
explicitly says to ignore it (`~/dev/CLAUDE.md:651`, `:128`), and the architecture-reset the asker
wants to "finish" is exactly what was abandoned mid-flight. An ungrounded responder would
enthusiastically sketch the control-plane ↔ worker protocol and a claudex-harness integration; the
grounded answer is that olympus is a dead project the workspace has decided to ignore, so building
on it is wrong.

> Note: This fact lives in the workspace-level `~/dev/CLAUDE.md`, not in the claudex tree. A grounded
> responder should tag the doc source and not over-claim repo-tree evidence — but the cancellation is
> unambiguous and recorded twice in the master reference.
