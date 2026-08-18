# Verification Before Completion

> No completion claims without verification. Evidence first, claims second.

## Core Rule

```
If you did not run a verification command in this message, you cannot claim it passed.
Previous runs are invalid — the code may have changed since then.
```

## Verification Gate

Before claiming completion, success, or satisfaction:

```
1. IDENTIFY — What command proves this claim?
2. RUN      — Execute the full command (fresh, complete)
3. READ     — Read the entire output, check exit code, count failures
4. VERIFY   — Does the output confirm the claim?
               No  → Report actual state with evidence
               Yes → Proceed to claim with evidence
5. CLAIM    — Only now state the result
```

## Verification Checklist

| Claim | Required Evidence | Insufficient Evidence |
|-------|------------------|----------------------|
| Tests pass | Test output: 0 failures | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check, assumption |
| Build succeeds | Build command: exit 0 | "Linter passed so build will too" |
| Bug fixed | Regression test: passes | "Code changed so it's fixed" |
| Agent task complete | VCS diff confirms changes | Trusting agent self-report |
| Requirements met | Line-by-line checklist verified | "Tests pass = feature complete" |

## Red-Green Verification (Bug Fix / Regression Test)

```
1. Write test   → Run → PASS (confirms test works)
2. Revert fix   → Run → FAIL (confirms test catches the bug)
3. Restore fix  → Run → PASS (confirms fix resolves the bug)
```

If step 2 does not fail, the test is not actually testing the fix.

## Banned Expressions

| Thought | Reality |
|---------|---------|
| "It probably works" | Run verification |
| "I'm confident" | Confidence is not evidence |
| "Linter passed, so..." | Linter ≠ compiler ≠ tests |
| "The agent said it succeeded" | Verify independently |
| "Simple change, no verification needed" | Simple changes break too |
| "I already ran it earlier" | Earlier ≠ now |

## When to Apply

Always. Mandatory before:
- Claiming success/completion
- Creating commits or PRs
- Marking tasks as complete
- Moving to the next task
