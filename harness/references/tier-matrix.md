# Tier × Scale × Parameter Matrix

> One-page reference card for capability-tier-aware behavior across the harness pipeline.
> Loaded on demand by orchestrators and agents that need tier-conditional logic.
> Authoritative tier definitions: `session-protocol.md` §9.

---

## Tier Summary

| Tier | Typical Models | Risk Profile |
|------|----------------|--------------|
| Standard | small/fast general-purpose | Lower autonomy, obvious mistakes |
| Advanced | mid-size reasoning | Reliable, standard mistake patterns |
| Elite | high-capability frontier | High autonomy; mistakes are subtler; stricter alignment posture required |

Detection order:
1. `CLAUDEX_TIER_OVERRIDE` env var (`standard|advanced|elite`)
2. `CLAUDEX_ELITE_MODELS` env var contains current runtime identifier → Elite
3. Name-based fallback: `sonnet|haiku` → Standard, `opus` → Advanced, else → Standard

---

## Scale File Thresholds

| Scale | Standard | Advanced | Elite |
|-------|----------|----------|-------|
| S | 1–2 files | 1–2 files | 1–5 files |
| M | 3–5 files | 3–5 files | 3–10 files |
| L | 6+ files | 6+ files | 11+ files |

**Rationale**: Elite-tier models handle long contexts 2× better, so the file-count thresholds for each scale relax. This saves one Worker/Scout pass on borderline requests.

---

## Round Limits (phase-internal build loop)

| Scale | Standard | Advanced | Elite |
|-------|----------|----------|-------|
| S | 1 | 1 | 1 |
| M | 2 | 2 | 1 |
| L | 3 | 3 | 2 |

**Escape hatch**: If the Diagnostician explicitly signals `needs_extra_round: true` in its report, the orchestrator may permit one additional round beyond the tier-scale cap. Used sparingly for genuinely hard root-cause situations.

---

## QA Pass Threshold

| Tier | Pass Threshold | Rationale |
|------|---------------|-----------|
| Standard | All criteria ≥ 7/10 | Baseline quality |
| Advanced | All criteria ≥ 7/10 | Same baseline, proven reliable |
| Elite | All criteria ≥ 8/10 | Subtler mistakes require a higher bar |

---

## Sentinel Activation

| Tier | LOW sensitivity | MEDIUM sensitivity | HIGH sensitivity |
|------|----------------|-------------------|-----------------|
| Standard | off | off | on |
| Advanced | off | on (Scale L only) | on |
| Elite | on (Scale L only) | on | on (expanded checks) |

**Elite expansion**: Elite-tier Sentinel adds the following checks beyond the standard patterns:
- Silent scope creep (sub-agent spawning without main-orchestrator notification)
- Evidence backdating (file timestamp manipulation)
- Reinforced watch on `--no-verify`, force-push, amend operations

---

## Auditor Activation

| Tier | When Active |
|------|-------------|
| Standard | Security HIGH only |
| Advanced | Scale M/L always |
| Elite | Always (all scales) |

**Rationale**: Elite-tier models show higher rates of confidently stated but factually incorrect claims in their own reports. The Auditor's ~2–4 min cost is justified on every Elite invocation.

---

## Long-Context Scale Adjustment (Elite only)

| Context Tier | Standard / Advanced | Elite |
|--------------|---------------------|-------|
| Scout (Scale S) | 2–5 files | 10–15 files |
| Scout (Scale M) | 5–15 files | 15–30 files |
| Selective Context ON-DEMAND | on-demand only | promoted to SECONDARY (all artifacts readable) |

---

## Agent Model Selection Under Each Tier

The `model` parameter passed to sub-Agent calls is **not** the same as the parent tier. Agents still follow the role-based recommendations in `session-protocol.md` §4. However, under the **Elite** parent tier:

- Do NOT downgrade Builder (L) or Worker (complex) to `sonnet`. Inherit parent.
- Planner, Architect, Diagnostician always inherit parent.
- Sentinel, Auditor remain `sonnet` (checklist-driven work, downgrading is appropriate).

---

## Phase Verification (Meta-Loop) Under Each Tier

| Tier | Retry Cap per Phase | Evidence Threshold |
|------|--------------------|-------------------|
| Standard | 3 | Basic (DoD + verify commands pass) |
| Advanced | 3 | Basic |
| Elite | 3 | Enhanced — Auditor must cross-verify each `phase-evidence-{N}.md` against artifacts |

---

## Quick Decision Checklist (for orchestrators)

When a capability-conditional branch is needed:

1. Read `.harness/session-state.md` → `tier:` field.
2. Consult this matrix for the parameter in question.
3. If the matrix does not cover the parameter, apply tier-neutral defaults.
4. Never expose the underlying model identifier to the user; reference the tier label only.
