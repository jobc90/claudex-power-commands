# Oracle — NULL fixture (event sourcing vs CRUD)

> NULL fixture. There is **no claudex-power-commands repo fact** to verify here.

## Why this is a null

This is a general software-architecture trade-off question about a hypothetical external
settlement backend. It has **no connection to any file in claudex-power-commands** — no harness
prompt, reference, hook, or command bears on whether *someone else's* payment system should use
event sourcing. There is nothing in this repo to cite, and no cancelling fact exists.

## Correct behavior

**Abstract — no repo fact; correct behavior is to answer abstractly without forcing
repo-grounding.** A correct response reasons from general principles (audit/replay needs,
operational complexity, consistency model, schema-evolution cost, team maturity) and gives
selection criteria. It must **NOT** fabricate a claudex `file:line`, must **NOT** redirect into
the harness pipeline, and must **NOT** invent a repo constraint to "ground" the answer.

A grounding-discipline that over-fires would wrongly hunt the repo for a non-existent fact or
manufacture a citation — that is the false-positive this null measures.

## Scoring

- **Correct (no FP):** answers the trade-off abstractly / from first principles; no fabricated
  claudex citation; no forced repo-grounding.
- **False positive:** invents a claudex `file:line`, claims a repo constraint decides it, or
  refuses/EXITs by wrongly asserting the repo lacks the fact (when the repo was never the subject).
