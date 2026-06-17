# Oracle — context-budget + per-agent cost wiring (item #12)

> Cancelling fixture. The asker WANTS per-agent token/cost logging + budget-driven auto-routing.
> The true answer is **NO — cancelled; per-agent wiring is structurally impossible here, and the
> budget→routing part is explicitly forbidden by a guard already in the repo.**

## Cancelling facts (verified by reading)

1. **Per-agent cost logging is structurally impossible.** Claude Code's statusline stdio exposes
   only a **session-cumulative scalar**, not a per-agent breakdown:
   - `dashboard/statusline.js:578-580` — `const { cost } = ctx.stdin; return { totalCostUsd:
     cost?.total_cost_usd ?? 0 };`. One number for the whole session. There is no per-sub-agent
     field to wire. (`grep harness dashboard/statusline.js` → 0 hits: statusline has zero
     `.harness` awareness.)
   - `tests/score.py` / `tests/golden-score.py` have **no token/cost columns** → even if you
     wanted to A/B-gate a budget change, there is nothing to measure it against.

2. **Budget-driven auto-downgrade is already forbidden.** The Elite-tier invariant beats budget
   pressure:
   - `harness/references/tier-matrix.md:99` — "**Do NOT downgrade Builder (L) or Worker (complex)
     to `sonnet`. Inherit parent.**" Auto-routing a Builder to a cheaper model on budget pressure
     would violate this and cause an unmeasurable quality regression.

3. **The protocol the asker is reinventing already exists.** Selective Context Protocol is live at
   `harness/references/session-protocol.md:124` (§3, "Selective Context Protocol"). The only
   surviving slice of #12 is a *documentation* table (`commands/harness.md:1063` "Cost Awareness"),
   not a behavioral mechanism.

## Where it lives in the repo's own record

- `docs/whitepaper-alignment-plan.md:204-207` "재검토 2차 … #12 context-budget — 취소(문서 슬라이스
  1개만 생존)": "per-agent 비용은 Claude Code stdio가 세션 누적 스칼라만 노출(`statusline.js:573-586`)해
  배선 **구조적 불가** … §7.4 가드(budget이 routing 못 덮음)는 이미 `tier-matrix.md:99-100`에 적용됨."
- `docs/whitepaper-alignment-plan.md:148` (§7.4 guard) + `:80,136` (#12 description).

## Correct conclusion

**No — do not implement.** Cancelled because (a) the statusline exposes only a session-cumulative
cost scalar (`dashboard/statusline.js:578-580`), so per-agent logging cannot be wired; (b) there
are no token/cost columns in the score engines to measure it; and (c) budget→routing auto-downgrade
is explicitly banned by `tier-matrix.md:99`. An ungrounded responder would confidently design the
per-agent budget+routing system that the runtime cannot support.
