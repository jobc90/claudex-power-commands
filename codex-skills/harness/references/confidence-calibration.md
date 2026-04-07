# Confidence Calibration Guide

Shared reference for Analyzer, Fixer, Refiner, and Integrator agents.
All harness agents use the same 0-100 confidence scale.

## Scoring Table

| Score | Meaning | Examples |
|-------|---------|---------|
| **95-100** | Undeniable — can be verified mechanically | Hardcoded API key in source code; `console.log("debug")` left in production path; unused import (no references found); SQL string concatenation with user input |
| **90-94** | Near-certain — strong structural evidence | Missing try/catch on async API call (verified no error boundary exists); function exceeds 50 lines (counted); naming violates documented convention in CLAUDE.md |
| **85-89** | High confidence — clear pattern violation | Return value ignored from function that returns error status; duplicate utility exists in codebase (verified by reading both); missing null check where upstream can return null (traced data flow) |
| **80-84** | Confident — evidence supports but edge cases possible | Error message exposes internal details (could be intentional for dev mode); nested ternary could be simplified (readability is subjective); function could be extracted (judgment call on boundary) |
| **70-79** | Probable — more likely correct than not | Code structure suggests a race condition (not proven); redundant code might serve a purpose not visible in diff; type assertion might be intentional workaround |
| **60-69** | Uncertain — could go either way | Design pattern choice might be suboptimal (alternative unclear); performance concern without profiling data; naming is unusual but might be domain-specific |
| **Below 60** | Speculative — insufficient evidence | "This feels wrong"; "Probably should use X instead"; assumption about intent without reading surrounding code |

## Action Thresholds

| Agent | Report threshold | Fix threshold |
|-------|-----------------|---------------|
| **Analyzer** | >= 80 (report findings) | N/A (doesn't fix) |
| **Fixer** | N/A | >= 70 (fix), >= 90 (fix immediately) |
| **Refiner** | N/A | >= 70 (fix), < 70 (defer to QA) |
| **Integrator** | N/A | >= 70 (fix), < 70 (flag for QA) |

## Key Principle

If you need to use "probably", "might", or "seems like" to describe the issue, your confidence is below 80. Investigate further or don't report/fix.

## Special Rules

- **Security findings**: CRITICAL security findings (hardcoded secrets, injection vectors) MUST be fixed regardless of confidence. The risk of not fixing > risk of wrong fix.
- **Below 70**: Never fix. Note in "Recommendations for QA" or "Deferred" section for human judgment.
