# Capability Detection — claudex v4.1.0

> **Purpose**: define how `/harness` and its siblings classify the runtime model into a capability tier, and how that tier drives pipeline behavior.
> **Authoritative source**: `harness/references/session-protocol.md` §9 and §9.5.

---

## 1. Motivation

Pre-v4.1.0, tier classification relied on a brittle substring match against a preview codename. When the runtime identifier changed, the match silently failed, and every Elite-tier behavior (stricter QA threshold, always-on Auditor, expanded Sentinel activation, relaxed Scale thresholds, long-context scan) reverted to Advanced defaults.

v4.1.0 replaces this with an explicit allowlist + override flow. No specific model identifier or version number is hardcoded into command prompts or user-facing output.

## 2. Tier Names

Internal labels, used consistently across commands, agent prompts, references, and Codex mirrors:

| Tier | Typical Model Profile |
|------|----------------------|
| `Standard` | Small / fast general-purpose models |
| `Advanced` | Mid-size reasoning models |
| `Elite` | High-capability frontier models |

**User-facing output policy**: the orchestrator emits at most `tier: {Standard | Advanced | Elite}`. The underlying runtime model identifier is never revealed.

## 3. Detection Priority

Session start (Phase 0 of every command):

1. **Explicit override** — if `CLAUDEX_TIER_OVERRIDE` ∈ {`standard`, `advanced`, `elite`}, use that value. Intended for testing / admin-approved scenarios.
2. **Elite allowlist** — if the runtime model identifier appears in `CLAUDEX_ELITE_MODELS` (comma-separated), tier = `Elite`.
3. **Name-based fallback** — for identifiers not in the allowlist:
   - contains `sonnet` or `haiku` → `Standard`
   - contains `opus` → `Advanced`
   - otherwise → `Standard` (conservative default)

The tier is persisted to `.harness/session-state.md` so every downstream agent reads the same value.

## 4. Elite Allowlist Management

The allowlist lives in an environment variable. Project administrators maintain it locally or via CI/secrets, not in tracked source files.

```bash
export CLAUDEX_ELITE_MODELS="id-1,id-2"
```

### Criteria for inclusion

A model qualifies for Elite when it meets at least two of:

- SWE-bench Verified ≥ 90%
- Terminal-Bench ≥ 80%
- Long-context BFS (256K–1M) ≥ 75%
- Documented exceptional autonomous task completion capability

### Override flow for experiments

```bash
CLAUDEX_TIER_OVERRIDE=elite /harness "..."
```

No allowlist edit required.

## 5. Tier-Dependent Behavior

See `harness/references/tier-matrix.md` for the authoritative table. Summary of what changes under Elite:

- **Scale file thresholds** relax (S: 1–5, M: 3–10, L: 11+).
- **Max rounds** tighten (M: 2→1, L: 3→2) because elite-class models reach higher quality per round.
- **QA pass threshold** rises from 7/10 to 8/10.
- **Auditor** is always on.
- **Sentinel** activates on MEDIUM sensitivity (not just HIGH) and under Scale L even for LOW sensitivity.
- **Scout long-context scan** expands (Scale S: 10–15 files, Scale M: 15–30 files).
- **Phase Verifier rigor** adds Auditor cross-check + quantitative claim verification.

Standard and Advanced tiers are largely unchanged from pre-v4.1.0 behavior.

## 6. Why Names Are Decoupled From Model IDs

Three constraints drive the design:

1. **Durability** — runtime model identifiers change. Hardcoding them in prompts creates silent breakage on upgrade.
2. **Neutrality** — claudex positions itself as a harness framework independent of any specific model release. Prompts and user-facing docs should not advertise specific model names or versions.
3. **Deployment flexibility** — different teams may want to classify different models as Elite based on their own benchmark thresholds or cost policies. An environment-driven allowlist supports this without forking the repo.

## 7. Verifying the Detection

After updating `CLAUDEX_ELITE_MODELS` or the override variable, run:

```bash
/harness "any small task"
```

The session-start output should include exactly one line:

```
tier: Elite
```

(or `Standard` / `Advanced` depending on configuration). If the line is absent or shows the wrong tier, check:

1. `CLAUDEX_TIER_OVERRIDE` spelling (must be lowercase).
2. `CLAUDEX_ELITE_MODELS` includes the exact identifier your runtime reports.
3. `harness/references/session-protocol.md` §9 has not been modified locally.

## 8. Relationship to Prior "Mythos-ready" Design

The pre-v4.1.0 codebase contained a "ready for high-capability models" design with the correct internal knobs (round limits, threshold, activation rules) but a brittle detection path. v4.1.0 preserves the *concepts* (Sentinel, Auditor, Security Triage, Containment, tiered activation) and replaces the *naming* with neutral, maintainable labels (`Standard / Advanced / Elite`) plus an explicit allowlist.

See `docs/harness-hardening-plan-v3.md` for the original hardening plan (v3.3 / v3.4 / v3.5) that this framework builds on. That file is preserved as-is for historical context.
