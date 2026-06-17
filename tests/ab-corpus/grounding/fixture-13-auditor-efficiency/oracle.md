# Oracle — Auditor "Trajectory Efficiency" + cross-run ledger (item #13)

> Cancelling fixture. The asker WANTS to add an efficiency verdict to Auditor + a cross-run drift
> ledger. The true answer is **NO — cancelled: the single-run half is already owned elsewhere, and
> the cross-run half is structurally unbuildable here.**

## Cancelling facts (verified by reading)

1. **The single-run efficiency signal already ships in the Trajectory Reporter** — adding it to
   Auditor would split one signal across two agents (single-source-of-truth violation):
   - `harness/trajectory-reporter-prompt.md:61-64` — health signal `smooth / retried / drifted`
     (= EFFICIENT / ACCEPTABLE / WASTEFUL), with the exact "more severe wins" tiebreak.
   - `harness/trajectory-reporter-prompt.md:47` — retry counting ("a `CMD … → exit 1` followed by
     a re-run is one retry").
   - `harness/trajectory-reporter-prompt.md:57` — Rounds-vs-Baseline ("actual rounds used against
     the scale's max-round baseline").

2. **Auditor's mandate is honesty/integrity, not efficiency** — efficiency is off-charter:
   - `harness/auditor-prompt.md` "## Why You Exist" (≈ line 14) — fabricated progress, manipulated
     QA scores, cover-ups, selective reporting, stale artifacts. Not "wasted rounds."

3. **The cross-run drift ledger has no persistent store** — `.harness/` is discarded between runs:
   - `harness/references/session-protocol.md:58` — on restart, `mv .harness/
     .harness-backup-{timestamp}/` then a fresh `.harness/`. No durable cross-run accumulation.
   - `tests/golden/` is single-run; marketplace sessions are one-shot → statistically can't fire.

## Where it lives in the repo's own record

- `docs/whitepaper-alignment-plan.md:204-206` "재검토 2차 … #13 Auditor efficiency — 취소": "단일-run
  효율 신호는 출하된 Trajectory Reporter(`trajectory-reporter-prompt.md:60-64` …, retry 카운트 `:47`,
  Rounds-vs-Baseline `:57-58`)가 **이미 소유** … cross-run drift 원장은 영속 저장소 **부재**(`.harness/`
  gitignore + restart 시 `mv .harness/ .harness-backup/` `session-protocol.md:57-58`) … 구축·측정 불가."
- `docs/whitepaper-alignment-plan.md:81,137` (#13 description, P2).

## Correct conclusion

**No — do not implement.** Cancelled because the single-run efficiency verdict is already owned by
the shipped Trajectory Reporter (`trajectory-reporter-prompt.md:61-64`) — adding it to Auditor
splits the signal — and the cross-run ledger has no persistent store (`.harness/` is `mv`-discarded
on restart, `session-protocol.md:58`). Even the role's own charter (`auditor-prompt.md` "Why You
Exist") is integrity, not efficiency. An ungrounded responder would design the verdict + ledger
without noticing both halves are already obviated or unbuildable.
