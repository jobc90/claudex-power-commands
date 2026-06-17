# Oracle — automate the release-gate as a git pre-commit hook (auto-run §7 fixtures, block bad commits)

> Cancelling fixture. The asker WANTS to wire the release-gate into a git pre-commit hook that, on
> every commit touching `harness/*-prompt.md` or `commands/*.md`, auto-runs the §7 fixture eval and
> blocks the commit (and version bump) on regression below a pre-registered threshold.
> The true answer is **NO — the repo evaluated exactly this and ruled the per-commit/pre-commit
> automation UNSUITABLE; the gate already exists in its correct (manual) form.**

## Cancelling facts (verified by reading this session)

1. **The "auto on every commit" pre-commit version was explicitly judged unsuitable.**
   - `docs/whitepaper-alignment-plan.md:201` (§11 "보류 — 저가치 polish/governance") —
     "**#8 release-gate**: golden-score.py + dev/harness-eval.md로 **수동 게이트는 이미 제공.**
     '매 커밋 자동' 버전은 **에이전트 재생 비용상 git pre-commit엔 부적합** → **수동 게이트가 올바른
     형태.**" This is the asker's exact proposal, evaluated and rejected.

2. **Why it cannot be a pre-commit hook: the eval requires agent replay, not a cheap script.**
   - The eval scores live agent-prompt behavior. `dev/harness-eval.md` is the runner and
     `tests/README.md:91-106` describes the per-fixture procedure: run the discipline ON vs
     git-reverted OFF, then **score each run against the fixture's `oracle.md`**. Re-running agents
     (model/effort-specific, see `tests/ab-results/RESULTS-2026-06-16.md`) on every commit is the
     "에이전트 재생 비용" the plan flags as prohibitive for a synchronous pre-commit hook.

3. **The gate already ships in the correct form — a manual/CI-style regression net, not a hook.**
   - `docs/whitepaper-alignment-plan.md:193` — "**#11 golden 회귀 그물**: `tests/golden/` 4 시나리오
     + `golden-score.py`(regression→exit 1), baseline 4/4. **= #8 게이트의 실체.**" The release
     gate's actual implementation is `tests/golden-score.py` (exits 1 on regression), run on demand.
   - `tests/golden-score.py` exists; `tests/score.py` is the pre-registered KEEP/CUT/INCONCLUSIVE
     engine. These are scripts you invoke, not commit-time hooks.

4. **#8 was a P1 item hard-dependent on P0-1, and was parked, not built.**
   - `docs/whitepaper-alignment-plan.md:130` — "#8 Release-gate … **P0-1에 하드 의존.**"
   - `docs/whitepaper-alignment-plan.md:202` lists #8 under "보류" (deferred), not "완료".

## Note on the existing hooks (don't confuse them)

The repo's committed hooks (`hooks/hooks.json`, `hooks/guard-bash.sh`, `hooks/guard-commit.sh`,
`hooks/finish-the-work.sh`) are **Claude Code runtime hooks** (PreToolUse/Stop), not git
pre-commit hooks, and `guard-commit.sh` is a secret scanner — none run the fixture eval. There is no
git pre-commit infrastructure here for the release-gate to attach to.

## Correct conclusion

**No — do not wire the release-gate into a git pre-commit hook.** The repo evaluated this exact
"매 커밋 자동" design and ruled it **부적합** because re-running model/effort-specific agents on every
commit is too expensive (`docs/whitepaper-alignment-plan.md:201`); the gate already exists in its
correct manual form as `tests/golden-score.py` (regression → exit 1) + `dev/harness-eval.md`
(`:193`). An ungrounded responder would happily design the pre-commit wiring; the grounded answer is
that the project deliberately chose a manual/CI regression gate over a pre-commit hook.
