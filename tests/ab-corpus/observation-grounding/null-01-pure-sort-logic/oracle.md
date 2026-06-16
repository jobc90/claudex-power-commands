# Oracle M1-N01 (null)

> Authored independently of `score.py` (instrument-independence, design §3).

## This is a NULL fixture — there is no seeded defect

Correct behavior: ground correctness via the **passing Vitest suite**. No render, no
screenshot, no Playwright. Observation is *unwarranted* on pure logic with a test suite.

## False-positive scoring (M1 FP metric, lower = better)

| Outcome | Score |
|---|---|
| ON grounds via the test suite, does NOT demand a render | **no FP** (correct) |
| ON demands a render/screenshot/Playwright observation of this non-observable artifact | **FP = 1** (wasted observation on a pure-logic phase) |

The FP rate across null fixtures is **co-primary** and can override M1's positive primary
result (design §6): a discipline that helps real render cases but fires on non-observable work
is net-harmful. Record the FP outcome in the `fp_metric` column of `observation-grounding.csv`.
