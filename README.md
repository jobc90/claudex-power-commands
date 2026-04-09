# claudex-power-commands

[English](README.en.md) | **한국어**

> Claude Code용 harness commands와 Codex용 harness skills를 같은 구조로 맞춘 7종 세트

이 저장소는 `harness` 계열 중심 구조를 기준으로 운영합니다.

- Claude Code 기준 진실: `commands/` 7개
- Codex 포트: `codex-skills/` 7개
- 하네스 프롬프트 번들: `harness/` 23개 에이전트
- 참조 체크리스트: `harness/references/` 4개

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
| `/harness` | Scout -> Planner -> Builder -> Refiner -> QA | 단일 빌더 구현 (S/M/L) |
| `/harness-docs` | Researcher -> Outliner -> Writer -> Reviewer + Validator | 문서 생성 (S/M/L) |
| `/harness-review` | Scanner -> Analyzer -> Fixer -> Verifier -> Reporter | 코드 리뷰 + git 핸드오프 |
| `/harness-team` | Scout -> Architect -> Workers(N) -> Integrator -> QA | 병렬 팀 빌드 |
| `/harness-qa` | Scout -> Scenario Writer -> Test Executor -> Analyst -> Reporter | 기능 QA 테스트 |
| `/design` | 설정 도구 | 디자인 시스템 3-dial 설정 |
| `/claude-dashboard` | 설정 도구 | statusline 설정 |

## Harness Agents

| 소속 | 에이전트 |
|---|---|
| `/harness` | `scout`, `planner`, `builder`, `refiner`, `qa`, `diagnostician` |
| `/harness-docs` | `researcher`, `outliner`, `writer`, `reviewer`, `validator` |
| `/harness-review` | `scanner`, `analyzer`, `fixer`, `verifier`, `reporter` |
| `/harness-team` | `architect`, `worker`, `integrator` + `scout`, `qa`, `diagnostician` 재사용 |
| `/harness-qa` | `scenario-writer`, `test-executor`, `analyst`, `qa-reporter` + `scout` 재사용 |

총 23개 에이전트 프롬프트 + INDEX가 `harness/` 아래에 들어 있습니다.

---

## Codex Ports

Codex에서는 slash command 대신 같은 이름의 skill로 호출합니다.

```text
Use $harness ...
Use $harness-docs ...
Use $harness-review ...
Use $harness-team ...
Use $harness-qa ...
Use $design ...
Use $claude-dashboard ...
```

현재 Codex 포트는 Claude 구조를 그대로 따라갑니다.

- `codex-skills/harness`
- `codex-skills/harness-docs`
- `codex-skills/harness-review`
- `codex-skills/harness-team`
- `codex-skills/harness-qa`
- `codex-skills/design`
- `codex-skills/claude-dashboard`

예전 Codex 스킬인 `check`, `cowork`, `docs`, `super` 는 legacy로 남겨두지 않고 제거했습니다.

### Codex 사용 예시

```text
Use $harness to implement this app.
Use $harness-docs to document this repository.
Use $harness-review --dry-run on the current diff.
Use $harness-review --pr after verification passes.
Use $harness-team --agents 4 for this multi-module feature.
Use $harness-qa --quick on the staging URL.
Use $design init for this frontend project.
Use $claude-dashboard to configure the statusline.
```

### Codex 포트 원칙

- Claude 커맨드와 동일한 7개 이름으로 맞춘다.
- 각 Codex 스킬은 대응하는 Claude 커맨드의 하네스 파이프라인을 그대로 따른다.
- 에이전트 프롬프트는 `codex-skills/*/references/` 에 번들링한다.
- `design` 은 `$harness`, `$harness-team` 과 함께 동작하는 디자인 컨트롤러다.
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
# 새 세션에서 /harness /harness-docs /harness-review /harness-team /harness-qa /design /claude-dashboard 가 보이면 성공
```

### Codex

```bash
# 1. Clone
git clone https://github.com/jobc90/claudex-power-commands.git

# 2. Skill 디렉토리 생성
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills"

# 3. 7개 스킬 복사
cp -R claudex-power-commands/codex-skills/harness "${CODEX_HOME:-$HOME/.codex}/skills/"
cp -R claudex-power-commands/codex-skills/harness-docs "${CODEX_HOME:-$HOME/.codex}/skills/"
cp -R claudex-power-commands/codex-skills/harness-review "${CODEX_HOME:-$HOME/.codex}/skills/"
cp -R claudex-power-commands/codex-skills/harness-team "${CODEX_HOME:-$HOME/.codex}/skills/"
cp -R claudex-power-commands/codex-skills/harness-qa "${CODEX_HOME:-$HOME/.codex}/skills/"
cp -R claudex-power-commands/codex-skills/design "${CODEX_HOME:-$HOME/.codex}/skills/"
cp -R claudex-power-commands/codex-skills/claude-dashboard "${CODEX_HOME:-$HOME/.codex}/skills/"

# 4. 확인
# 새 Codex 세션에서 $harness $harness-docs $harness-review $harness-team $harness-qa $design $claude-dashboard 를 호출하면 된다
```

---

## File Structure

```text
claudex-power-commands/
├── commands/
│   ├── harness.md
│   ├── harness-docs.md
│   ├── harness-review.md
│   ├── harness-team.md
│   ├── harness-qa.md
│   ├── design.md
│   └── claude-dashboard.md
├── harness/
│   ├── INDEX.md                  # Agent cross-reference map
│   ├── references/
│   │   ├── session-protocol.md   # Session state, event log, model routing, execution audit
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
│   ├── harness-team/
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
| `harness/INDEX.md` | 23 에이전트 교차참조 맵 |
| `hooks/pre-commit-lint.sh` | 커밋 시 자동 미러 동기화 체크 |

---

## Notes

- `commands/` 와 `codex-skills/` 는 이제 같은 7개 세트를 공유합니다.
- Codex 포트는 각 스킬 내부에 필요한 `references/` 프롬프트를 포함합니다.
- `claude-dashboard` 는 Codex에서 실행하더라도 `~/.claude/settings.json` 을 수정하는 설정 스킬입니다.

## License

MIT
