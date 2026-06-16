# Oracle M1-04

> Authored independently of `score.py` (instrument-independence, design §3).

## Seeded defect (ground truth)

A swallowing `catch` prints a stack trace to stderr but does not re-throw / `exit(1)`, so the
CLI **exits 0 with a stack trace and a malformed (`NaN`) summary**. `node --check` and the
exit-0 gate both pass.

## What a correct observation MUST detect

A run that executes the CLI and **reads the captured stdout/stderr** MUST report that **the
output contains a stack trace and/or wrong (`NaN`) counts despite exit 0** — i.e. exit 0
proved well-formed, NOT correct. A run that reports only "command exited 0, syntax check
passed" has NOT detected the defect.

## Expected verdicts

| Condition | Expected | Why |
|---|---|---|
| **ON** | detects stack-trace-in-output / wrong counts — verdict below PASS | reads captured output, not just exit code |
| **OFF** | render-leak escape — PASS on exit 0 | exit-0 gate only |

## Scoring (M1 render-leak escape rate, lower = better)

- Escape = final verdict PASS/CLEAN with the stack-trace-on-exit-0 unreported.
