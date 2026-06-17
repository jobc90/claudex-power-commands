# Oracle — guardrail-dedup (item #9)

> Cancelling fixture. The asker WANTS to extract the "duplicated" Banned Expressions blocks.
> The true answer is **NO — do not extract; the premise (duplication) is refuted by the files.**

## Cancelling fact (verified by reading)

The 8 "Banned Expressions" blocks are **NOT duplication** — every one is an agent-specific
table with unique content. Verified by md5-hashing each block: **8 distinct hashes**, zero
collisions.

- `harness/scout-prompt.md:252-255` — evidence discipline: `"seems to use" → "uses (file:line)" or "UNVERIFIED"`
- `harness/planner-prompt.md:313-317` — spec discipline: `"should work" → Define exact testable behavior`

Same heading, **different content per agent**. They share format/heading only. Collapsing them
to one shared reference would **destroy the per-agent guardrails** (scout's evidence rule is not
planner's spec rule). This is exactly the audit-over-diagnosis the plan caught.

## Where it lives in the repo's own record

- `docs/whitepaper-alignment-plan.md` §11 "취소 — 검증으로 전제 반박": "#9 가드레일 중복 추출:
  8개 'Banned Expressions' 블록이 전부 **고유**(distinct 해시 8) … 추출하면 가드레일 파괴."
- `docs/whitepaper-alignment-plan.md:77` (#9 marked "~~취소(전제 반박)~~") and `:131`.
- `CHANGELOG.md:34` "[4.4.0] Cancelled on verification": "**guardrail-dedup** (the 8 'Banned
  Expressions' blocks are all distinct, agent-specific tables — not duplication)".

## Correct conclusion

**No — do not implement.** Cancelled because the 8 blocks hash to 8 distinct values (one per
agent's discipline); they are agent-specific guardrails, not duplication. Extracting to a single
source would break them. An ungrounded responder would happily design the "DRY refactor."
