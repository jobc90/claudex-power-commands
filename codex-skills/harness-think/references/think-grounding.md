# Think-Grounding: Cite-or-Abstain (reference)

> Loaded on demand by `/harness-think` (Surveyor) when the Scope-Gate = IN. Defines the cite-or-abstain rule, the 4-state ledger, and the anti-over-grounding bound in **one** place — they are one discipline, not several.
> Status: **A/B-measured KEEP** (M8, 2026-06-17) — both an in-author and an independent-author held-out split (margin +4 each, null FP 1/2; model `sonnet`/`xhigh`, results do not port). Honest ceiling: grounding lowers repo-fact escape but does not eliminate it (one held-out miss; citation-presence ≠ citation-support). See `tests/ab-results/RESULTS-grounding.md`.

## When this applies (the trigger)

Apply ONLY to a **codebase-anchored decision/feasibility** question — one whose answer turns on a fact that lives in THIS repo/workspace (a file's existence, a flag's value, an entity's shape, a branch's ahead/behind state, whether something was deprecated/cancelled). Self-test: **"could a wrong belief about this repo make my answer confidently wrong?"** If yes → ground. Abstract, product, or market questions have no repo fact to verify — grounding adds nothing there, so they EXIT. Do not force grounding onto them; that is the heavy-process-on-small-tasks anti-pattern.

## The one rule: cite-or-abstain

Every sentence that asserts a repo-specific fact carries an inline `[path:line]` captured from a Read/Grep performed **THIS session** — or it degrades to `[Unknown — not found: <what you searched>]`. A repo claim with no citation is forbidden. **`[Unknown]` beats a confident guess** — the measured failure mode (2026-06-16) was a fluent, uncited recommendation to build two already-cancelled items. "I grounded it" is not grounding; the `[path:line]` tag is.

This is the decision-layer twin of `observation-grounding.md`: there, `exit 0` proves *well-formed, not correct*; here, **a fluent answer proves *well-formed, not grounded*.**

## The 4-state ledger

Resolve every load-bearing repo noun to a row:

```
| # | repo 명사 | 증거 (path:line) | state | as-of (git short-sha) |
```

- **VERIFIED** — read it this session; the cited line backs the claim.
- **NOT-FOUND** — searched, does not exist (an absence can itself be the answer).
- **STALE** — exists but the file marks it deprecated / cancelled / frozen / superseded. A STALE noun is **barred from being treated as a live target** (e.g. grounding `console-solution-app` hits its "Deprecated 예정 / 모노레포 이전" lines → STALE → "build it new" is blocked).
- **UNKNOWN** — could not resolve; the conclusion must not depend on it.

Record an **as-of git short-sha** so a later reader knows the citation's vintage.

## Citation presence ≠ citation support

The rule forces a `[path:line]` to exist; it does not guarantee the line backs the claim. For each **load-bearing** citation, add a one-line "why this line settles it." A real-but-irrelevant citation satisfies the format while the reasoning is still wrong — pair the citation with its relevance, and let the opt-in red-team re-read contested citations. (This is the decision-layer analog of `observation-grounding.md`'s "observation needs a success criterion": a citation needs a stated relevance.)

## Doc-vs-tree drift hazard

For **CODE** questions, verify against the **tree** (the actual files), not an authoritative-sounding summary doc — a workspace `CLAUDE.md` can lag the code (e.g. main-vs-develop drift). If you must cite a doc, tag it `[doc — may lag tree]` and prefer a tree citation for anything load-bearing.

## Branch-state awareness

"Should we merge X first?" depends on ahead/behind counts and migration order that a single-file Read won't surface. Run `git` / branch reads explicitly and cite their output. Branch state is a repo fact like any other — cite or abstain.

## Stop condition (anti-over-grounding)

**One citation per claim is enough.** Do NOT re-read unchanged files to pad confidence — it spends tokens without changing the answer. Ground each load-bearing claim once; if a fact is already VERIFIED, move on. The goal is **"I checked the file that decides this," not "I read N files."**
