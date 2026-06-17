# M8 — Grounding (cite-or-abstain) A/B results

> Mechanism: `/harness-think` (Surveyor) **cite-or-abstain grounding**. Metric: **repo-fact escape rate**.
> Date 2026-06-17. model=`sonnet`, effort=`xhigh`. Data: `tests/ab-results/grounding.csv`, corpus `tests/ab-corpus/grounding/`.
> Verdict (score.py): **KEEP on BOTH splits** — in-author **+4**, independent-author held-out **+4**, null FP **1/2** each. Matches the observation-grounding bar (in-author + held-out).

## What was measured

Blind, mechanism-level A/B (not a full-command run):
- **ON** = the cite-or-abstain rule: read repo files, cite `[path:line]` or abstain (`[Unknown]`); a cancelled/deprecated thing is STALE and cannot be a build target.
- **OFF** = persona-only (the realistic baseline = "ask Claude in chat"): same model, tool access available, **no grounding mandate**.
- **Fixtures** = 5 cancelling-fact + 2 null, authored against **real** claudex cancellations (`whitepaper-alignment-plan.md` §11 + CHANGELOG [4.4.0]): #9 guardrail-dedup, #10 mirror-collapse, #12 context-budget, #13 Auditor-efficiency, #14 Sentinel-migration. Each cancelling question is phrased to *invite a confident "yes, here's how"* from an ungrounded responder.
- **Scoring** = blind judge (order-randomized, oracle-supplied) → `score.py`. Primary `caught` = surfaced the cancellation / did-not-build; `escape` = confidently recommended building the cancelled item.

## Per-fixture outcome

| fixture | ON | OFF | note |
|---|---|---|---|
| #09 guardrail-dedup | caught | **escape** | OFF explained how to extract; never surfaced the 8-distinct-hash fact |
| #10 mirror-collapse | caught | **escape** | OFF proposed a structure; never surfaced the 16-consumer-rewire risk |
| #12 context-budget | caught | caught | OFF *reasoned* the statusline structural barrier (uncited) |
| #13 Auditor-efficiency | caught | caught | OFF *reasoned* the Trajectory Reporter overlap (uncited) |
| #14 Sentinel-migration | caught | caught | OFF *reasoned* Codex-has-no-PreToolUse (uncited) |
| null-01 event-sourcing | — (**FP**) | — | ON forced a spurious repo citation on an abstract arch question |
| null-02 freemium-vs-trial | — (ok) | — | ON answered abstractly; no FP |

`primary ON good/bad = 5/0 · OFF good/bad = 3/2 · margin = (5−0)−(3−2) = +4 · null FP (ON) = 1/2`

## Held-out split (independent author + separate oracle)

An independent author wrote 5 NEW cancelled-fact questions (distinct from the in-author set) + 2 new nulls, blind to the scoring; a **separate verifier** supplied the oracle. Same ON/OFF rig.

| fixture | ON | OFF | note |
|---|---|---|---|
| #15 spec-as-eval default | caught | caught | both reasoned the "don't default it" guard |
| #16 ship `/harness-think` now | caught | **escape** | self-referential: ON caught its OWN staging gate; OFF explained the 6→7 release |
| #17 restore `$super` router | caught | caught | both knew the router ban |
| #18 release-gate → pre-commit | **escape** | **escape** | **honest ON miss**: ON cited files but still concluded build-it (citation ≠ correct conclusion) |
| #19 revive olympus | caught | **escape** | ON read workspace `CLAUDE.md:651` (폐기) + cited; OFF never looked — cross-repo win |
| null-03 pagination | — (**FP**) | — | ON over-grounded an abstract question |
| null-04 idempotency | — (ok) | — | clean |

`primary ON good/bad = 4/1 · OFF good/bad = 2/3 · margin = +4 · null FP (ON) = 1/2` → **KEEP**

**Held-out confirms the pattern AND surfaces the honest ceiling.** The edge is again the un-inferable / cross-repo facts (#16 own-gate, #19 workspace-only); OFF caught the reasoning-derivable ones (#15, #17). But **#18 is a real ON failure** — grounding read related files yet still recommended building the pre-commit gate, proving **citation-presence does not guarantee a correct conclusion** (the spec's open-risk #2, now measured). Grounding lowers escape; it does not eliminate it.

## Findings

1. **The grounding edge concentrates where the cancellation is NOT reasoning-derivable.** OFF escaped exactly the two fixtures (#09, #10) whose cancelling fact is empirical/structural and invisible from the question's framing (8 distinct md5 hashes; 16 path-consumers). It *caught* #12/#13/#14 because a strong reasoner can infer those structural barriers without opening a file — but it did so **uncited**. So the durable ON-only advantage is narrower than +4 suggests: it is the un-inferable repo facts, not all of them.
2. **M8 is intrinsically noisier than M1 (render-leak).** A render-only defect is a *hard capability barrier* (you cannot see it without rendering); a repo fact is "could read but might not" — a **behavioral tendency**. The grounding discipline's value is precisely converting "might read" into "must read." A small margin here would mean OFF reads anyway; +4 means forcing the read changed 2/5 outcomes.
3. **The null FP validates the scope-gate as load-bearing, not optional.** ON over-grounded null-01 (forced a citation on an abstract event-sourcing question). **This tested the cite-or-abstain rule in ISOLATION, without the command's Phase-0 scope-gate** — which EXITs abstract questions *before* grounding. So (a) the measured FP=1/2 is a conservative **upper bound** on the real command, and (b) it confirms grounding-without-the-scope-gate over-fires — the design's ordering (gate → ground) is correct.

## Caveats (travel with the claim)

- **Two splits done** (in-author + independent-author held-out), both KEEP. The held-out author and a separate oracle verifier were blind to the in-author set.
- **Model/effort-specific** (`sonnet`/`xhigh`); results do not port to other combinations.
- **Mechanism-level**, not a full `/harness-think` run; the rule was tested without the scope-gate (see finding 3) — so the null FP is a conservative upper bound and the real command would EXIT the abstract nulls.

## Status

- **Both splits KEEP** — in-author +4, independent-author held-out +4, FP 1/2 each. Matches the observation-grounding bar.
- **Measured.** The grounding discipline is no longer "unproven" — it has a measured KEEP on two blind splits (model `sonnet`, effort `xhigh`; results do not port).
- **Clears the gate** for the public release (6→7 commands, v4.5.0, Codex mirror) per Option B.
- **Honest ceiling**: ON still escaped 1/5 held-out (#18 — citation present, conclusion wrong) and over-grounded 1/2 nulls (the scope-gate, absent in this isolation test, would EXIT those). Grounding lowers escape; it does not eliminate it — the CHANGELOG claim must carry this caveat.
