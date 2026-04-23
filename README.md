# claudex-power-commands

[English](README.en.md) | **한국어**

> Claude Code용 harness commands와 Codex용 harness skills를 같은 구조로 맞춘 6종 세트
>
> **v4.2.0**: Completion Gate protocol — Reporter / QA Reporter / Integrator / Refiner / Auditor가 **완료 선언 직전 stale iteration artifact를 자동 스캔**. terminated 리소스 ID, "진행 중" 마커, version drift, step-status 모순을 **다른 단계가 통과해도 구조적으로 차단**. 원본 사고: 다층 감사 통과 후 사용자가 stale EC2 ID를 정리작업에서 발견 — 이 패턴을 시스템적으로 재발 방지.
> **v4.1.0**: Meta-Loop is the default — `/harness` 가 요청을 phase-book으로 분해하고 모든 phase의 DoD가 통과할 때까지 work→verify→apply 루프를 자동으로 돌립니다. 작은 요청은 phase=1로 자연 퇴화 (하위 호환).
> **v4.0.0**: `/harness-team` merged into `/harness` as TEAM mode

이 저장소는 `harness` 계열 중심 구조를 기준으로 운영합니다.

- Claude Code 기준 진실: `commands/` 6개
- Codex 포트: `codex-skills/` 6개
- 하네스 프롬프트 번들: `harness/` 28개 에이전트 프롬프트 + 1개 orchestrator helper
- 참조 체크리스트: `harness/references/` 9개 (v4.2.0에 `completion-gate-protocol.md` 추가)
- 템플릿 스크립트: `harness/completion-gate-template.sh` (프로젝트에 `scripts/completion-gate.sh`로 복사)

### v4.2.0 — Completion Gate Protocol

"완료 선언 → 사용자가 stale 상태 발견" 실패 모드를 파이프라인 내 구조로 차단합니다.

| 변화 | 설명 | 효과 |
|------|------|------|
| **Completion Gate** | 모든 finalizing agent (Reporter / QA Reporter / Integrator / Refiner / Auditor)가 `.harness/*-report.md` 작성 **전** stale artifact 스캔 실행 의무 | iteration artifact (terminated 리소스 ID, WIP 마커, version drift)를 구조적으로 차단 |
| **Reference: `harness/references/completion-gate-protocol.md`** | 6개 스캔 카테고리 + inline bash + reconciliation workflow + integration points 정의 | 단일 진실 출처 — 모든 agent가 인용 |
| **Template: `harness/completion-gate-template.sh`** | 프로젝트-agnostic 스캐너. `scripts/completion-gate.sh`로 복사해 프로젝트별 패턴 추가 가능 | 재사용 가능, project-specific customization |
| **Attestation line 의무** | 모든 최종 리포트에 `Completion Gate: ✅/🟡/❌ …` 라인 포함 없으면 리포트 INVALID | Auditor가 위조/누락 감지 |
| **Git action blocking** | `/harness-review --commit/--push/--pr` 는 gate PASS 선행 조건 | 리뷰 verdict가 PASS여도 stale 발견 시 git handoff 차단 |
| **Integrator에서 Worker 리포트 cross-scan** | TEAM mode 병합 직전 Worker progress 리포트 간 stale 상호 참조 검사 | phantom bug 전파 차단 |

공식 설계 문서: `harness/references/completion-gate-protocol.md`, CHANGELOG의 v4.2.0 섹션.

### v4.1.0 — Meta-Loop + Capability Detection

| 변화 | 설명 | 효과 |
|------|------|------|
| **Meta-Loop (default)** | `/harness` 가 `phase-book.md` 를 자동 작성하고 phase별로 work → verify → apply 사이클을 반복 | 한 번의 요청으로 방대한 작업을 끝까지 실행 |
| **Phase Verifier** | 각 phase의 DoD + verify command를 실제 실행하여 `phase-evidence-{i}.md` 생성 | 무증거 PASS 차단, retry 3회 cap |
| **Intent auto-detection** | 요청에 "커밋/푸시/배포/PR" 포함 시 terminal phase 자동 추가 | Auto-commit 기본 off, 사용자가 명시하면 그대로 수행 |
| **Capability Tier (Standard / Advanced / Elite)** | `CLAUDEX_ELITE_MODELS` env allowlist + `CLAUDEX_TIER_OVERRIDE` | tier별 round limit, QA threshold, Sentinel/Auditor 활성화 자동 조정 |
| **Elite-tier 보강 체크** | Sentinel(scope creep / 증거 조작), Auditor(정량 주장 실측), QA(anti-sycophancy) 확장 | 자율성 높은 모델의 미묘한 실수 패턴 대응 |
| **Cross-Phase Integrity** | 새 phase가 이전 phase의 파일을 수정하면 자동 회귀 검증 | 다중 phase간 일관성 유지 |

공식 설계 문서: `docs/meta-loop-design.md`, `docs/capability-detection.md`.

### v3.2.0 — Managed Agents-Inspired Session Protocol

Anthropic의 [Managed Agents](https://www.anthropic.com/engineering/managed-agents) 아키텍처에서 영감을 받아 7가지 기능을 추가했습니다:

| 기능 | 설명 | 효과 |
|------|------|------|
| **Session Protocol** | `.harness/session-state.md`로 세션 상태 추적 + 재진입 | Scale L 중단 시 처음부터 재시작 방지 |
| **Unified Event Log** | `.harness/session-events.md` append-only 타임라인 | 패턴 인식 + 정확한 디버깅 |
| **Selective Context** | Round 2+ Builder에 3단계 컨텍스트 계층 | 토큰 절약 + agent 집중도 향상 |
| **Worktree Isolation** | Team Workers에 `isolation: "worktree"` 적용 | 병렬 안전성 (Claude Code 공식 기능) |
| **Model Selection** | agent별 최적 모델 라우팅 (sonnet/opus) | 속도 향상 + 비용 절감 |
| **Execution Audit** | Builder/Refiner 실행 로그 → Diagnostician | 근본 원인 추적 정확도 향상 → 라운드 절감 |
| **Background Diagnostician** | Scale L에서 `run_in_background` 적용 | 대기 시간 절감 |

---

## Commands

| 커맨드 | 파이프라인 | 용도 |
|---|---|---|
| `/harness` | SINGLE: Scout -> Planner -> Builder -> Refiner -> QA / TEAM: Scout -> Architect -> Workers(N) -> Integrator -> QA | 적응형 빌더 (SINGLE/TEAM 자동 선택, S/M/L) |
| `/harness-docs` | Researcher -> Outliner -> Writer -> Reviewer + Validator | 문서 생성 (S/M/L) |
| `/harness-review` | Scanner -> Analyzer -> Fixer -> Verifier -> Reporter | 코드 리뷰 + git 핸드오프 |
| `/harness-qa` | Scout -> Scenario Writer -> Test Executor -> Analyst -> Reporter | 기능 QA 테스트 |
| `/design` | 설정 도구 | 디자인 시스템 3-dial 설정 |
| `/claude-dashboard` | 설정 도구 | statusline 설정 |

## Harness Agents

| 소속 | 에이전트 |
|---|---|
| `/harness` (SINGLE) | `scout`, `planner`, `builder`, `refiner`, `qa`, `diagnostician`, `sentinel`, `auditor` |
| `/harness` (TEAM) | `scout`, `architect`, `worker`, `integrator`, `sentinel`, `qa`, `diagnostician`, `auditor` |
| `/harness-docs` | `researcher`, `outliner`, `writer`, `reviewer`, `validator` |
| `/harness-review` | `scanner`, `analyzer`, `fixer`, `verifier`, `reporter` |
| `/harness-qa` | `scenario-writer`, `test-executor`, `analyst`, `qa-reporter` + `scout` 재사용 |

총 27개 에이전트 프롬프트 + 1개 orchestrator helper + INDEX가 `harness/` 아래에 들어 있습니다. Meta-Loop 에이전트: `phase-book-planner`, `phase-verifier`, `phase-orchestrator` (helper).

---

## Codex Ports

Codex에서는 slash command 대신 같은 이름의 skill로 호출합니다.

```text
Use $harness ...
Use $harness-docs ...
Use $harness-review ...
Use $harness-qa ...
Use $design ...
Use $claude-dashboard ...
```

현재 Codex 포트는 Claude 구조를 그대로 따라갑니다.

- `codex-skills/harness`
- `codex-skills/harness-docs`
- `codex-skills/harness-review`
- `codex-skills/harness-qa`
- `codex-skills/design`
- `codex-skills/claude-dashboard`

예전 Codex 스킬인 `check`, `cowork`, `docs`, `super` 는 legacy로 남겨두지 않고 제거했습니다.

### Codex 사용 예시

```text
Use $harness to implement this app.
Use $harness --team --agents 4 for this multi-module feature.
Use $harness-docs to document this repository.
Use $harness-review --dry-run on the current diff.
Use $harness-review --pr after verification passes.
Use $harness-qa --quick on the staging URL.
Use $design init for this frontend project.
Use $claude-dashboard to configure the statusline.
```

### Codex 포트 원칙

- Claude 커맨드와 동일한 6개 이름으로 맞춘다.
- 각 Codex 스킬은 대응하는 Claude 커맨드의 하네스 파이프라인을 그대로 따른다.
- 에이전트 프롬프트는 `codex-skills/*/references/` 에 번들링한다.
- `design` 은 `$harness` 와 함께 동작하는 디자인 컨트롤러다.
- 더 이상 `super` 같은 상위 라우터 스킬에 의존하지 않는다.

---

## Install

### Claude Code

```bash
# 1. Clone
git clone https://github.com/jobc90/claudex-power-commands.git

# 2. Commands 복사
cp claudex-power-commands/commands/*.md ~/.claude/commands/

# 3. Harness 프롬프트 + 참조 체크리스트 복사
mkdir -p ~/.claude/harness/references
cp claudex-power-commands/harness/*.md ~/.claude/harness/
cp claudex-power-commands/harness/references/*.md ~/.claude/harness/references/

# 4. 확인
# 새 세션에서 /harness /harness-docs /harness-review /harness-qa /design /claude-dashboard 가 보이면 성공
```

### Codex

```bash
# 1. Clone
git clone https://github.com/jobc90/claudex-power-commands.git

# 2. Skill 디렉토리 생성
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills"

# 3. 6개 스킬 복사
cp -R claudex-power-commands/codex-skills/harness "${CODEX_HOME:-$HOME/.codex}/skills/"
cp -R claudex-power-commands/codex-skills/harness-docs "${CODEX_HOME:-$HOME/.codex}/skills/"
cp -R claudex-power-commands/codex-skills/harness-review "${CODEX_HOME:-$HOME/.codex}/skills/"
cp -R claudex-power-commands/codex-skills/harness-qa "${CODEX_HOME:-$HOME/.codex}/skills/"
cp -R claudex-power-commands/codex-skills/design "${CODEX_HOME:-$HOME/.codex}/skills/"
cp -R claudex-power-commands/codex-skills/claude-dashboard "${CODEX_HOME:-$HOME/.codex}/skills/"

# 4. 확인
# 새 Codex 세션에서 $harness $harness-docs $harness-review $harness-qa $design $claude-dashboard 를 호출하면 된다
```

---

## File Structure

```text
claudex-power-commands/
├── commands/
│   ├── harness.md
│   ├── harness-docs.md
│   ├── harness-review.md
│   ├── harness-qa.md
│   ├── design.md
│   └── claude-dashboard.md
├── harness/
│   ├── INDEX.md                  # Agent cross-reference map
│   ├── references/
│   │   ├── session-protocol.md   # Session state, event log, model routing, execution audit
│   │   ├── team-build-protocol.md # TEAM mode wave execution, worker isolation, integration
│   │   ├── security-checklist.md
│   │   ├── error-handling-checklist.md
│   │   └── confidence-calibration.md
│   ├── scout-prompt.md
│   ├── planner-prompt.md
│   ├── builder-prompt.md
│   ├── refiner-prompt.md
│   ├── qa-prompt.md
│   ├── diagnostician-prompt.md
│   ├── linter-prompt.md
│   ├── researcher-prompt.md
│   ├── outliner-prompt.md
│   ├── writer-prompt.md
│   ├── reviewer-prompt.md
│   ├── validator-prompt.md
│   ├── scanner-prompt.md
│   ├── analyzer-prompt.md
│   ├── fixer-prompt.md
│   ├── verifier-prompt.md
│   ├── reporter-prompt.md
│   ├── architect-prompt.md
│   ├── worker-prompt.md
│   ├── integrator-prompt.md
│   ├── scenario-writer-prompt.md
│   ├── test-executor-prompt.md
│   ├── analyst-prompt.md
│   └── qa-reporter-prompt.md
├── codex-skills/
│   ├── harness/
│   ├── harness-docs/
│   ├── harness-review/
│   ├── harness-qa/
│   ├── design/
│   └── claude-dashboard/
├── dashboard/
├── hooks/
├── rules/
├── dev/                          # Plugin development tools (not for end users)
│   └── harness-lint.md
├── README.md
└── README.en.md
```

---

## Dev Tools (플러그인 개발자 전용)

`dev/` 디렉토리는 이 플러그인 자체를 개발/유지보수할 때 사용하는 도구입니다. 일반 사용자는 사용할 필요 없습니다.

| 도구 | 용도 |
|------|------|
| `dev/harness-lint.md` | 프롬프트 교차참조, Codex 미러 동기화, 파이프라인 구조 검증 |
| `harness/linter-prompt.md` | Lint 에이전트 프롬프트 |
| `harness/INDEX.md` | 25 에이전트 교차참조 맵 |
| `hooks/pre-commit-lint.sh` | 커밋 시 자동 미러 동기화 체크 |

---

## Notes

- `commands/` 와 `codex-skills/` 는 이제 같은 6개 세트를 공유합니다.
- Codex 포트는 각 스킬 내부에 필요한 `references/` 프롬프트를 포함합니다.
- `claude-dashboard` 는 Codex에서 실행하더라도 `~/.claude/settings.json` 을 수정하는 설정 스킬입니다.

## License

MIT
