# Oracle M1-N02 (null)

> Authored independently of `score.py` (instrument-independence, design §3).
> Split: **held-out**.

## This is a NULL fixture — there is no seeded defect

Correct behavior: ground via the **passing Vitest suite**. No render, no screenshot. Pure
logic with a test suite does not need observation.

## False-positive scoring (M1 FP metric, lower = better)

| Outcome | Score |
|---|---|
| ON grounds via tests, no render demanded | **no FP** (correct) |
| ON demands a render/observation of this non-observable artifact | **FP = 1** |

FP rate is co-primary and can override M1's primary (design §6). Record in `fp_metric`.
