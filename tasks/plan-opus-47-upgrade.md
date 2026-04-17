# Plan: claudex v4.1.0 — Meta-Loop Default + Capability Detection Refresh

> **Scope**: claudex v4.0.0 → v4.1.0
> **목적**: (1) 고능력 런타임 모델이 제대로 감지·활용되도록 내부 tier 로직을 갱신한다. (2) 방대한 작업도 한 번의 요청으로 끝까지 처리되도록 Meta-Loop(phase-book 기반 자율 반복)를 harness의 기본 동작으로 내장한다. (3) 과거 preview 코드네임·버전 숫자 참조를 중립화해 claudex/harness 고유 용어로 통일한다.
> **Status**: 계획 확정 — 사용자 시작 지시 후 Phase 1~6을 한 번에 완료까지 순차 실행
> **Updated**: 2026-04-17

---

## 0. Executive Summary

### 배경

v4.0.0은 harness 구조(Scout, Sentinel, Auditor, Security Triage, Integrator, Worker containment 등)를 갖추고 있으며 내부적으로 tier 개념까지 준비해두었다. 그러나 두 가지 근본 결함이 있다.

1. **Tier 탐지 로직이 과거 preview 코드네임 문자열에 의존한다.** 현재 운용 중인 최신 고능력 모델은 이 문자열을 포함하지 않는다. 그 결과 상위 tier에 묶여 있던 규칙 — long-context scale 완화, QA threshold 상향, Sentinel/Auditor 기본 활성, 라운드 최적화 — 이 전부 무효가 되어 본래 설계 의도가 실행되지 않는다.
2. **"완료까지 반복" 상위 루프가 없다.** harness 내부 라운드 루프(Build-Sentinel-Refine-QA)는 한 phase 안의 유한 루프다. 사용자가 방대한 작업을 한 번에 지시해도 단일 pass로만 돌고 끝난다. phase를 나눠 작업-검증-적용-다음 phase 사이클로 수행하는 장치가 존재하지 않는다.

### 이번 업그레이드의 2개 축

1. **Capability Detection + 명명 중립화.** 내부 tier 이름을 `Standard / Advanced / Elite`로 교체한다. Elite tier 감지는 모델 ID 화이트리스트로 명시한다. 모든 커맨드·에이전트 프롬프트·참조 문서에서 과거 preview 코드네임과 모델 버전 숫자 표기를 제거하고 중립 표현으로 치환한다.

2. **Meta-Loop를 harness의 기본 동작으로 내장.** `/harness <요청>`이 실행되면 harness는 자동으로 phase-book을 작성하고, 각 phase를 **작업 → 검증 → 적용** 사이클로 실행하며 전체 phase가 완료될 때까지 자율 반복한다. 별도 플래그 없음. 작은 요청은 phase=1로 자연 퇴화(degrade)해 기존 단일 pass와 동등하게 동작한다. 요청에 "커밋/푸시/배포/PR" 의도가 포함되어 있으면 phase-book 말미에 해당 단계를 자동 추가한다.

### 명명 정책 (Naming Policy)

| 계층 | 사용할 이름 | 사용 금지 이름 |
|------|------------|--------------|
| 프로젝트 | **claudex** | — |
| 아키텍처 | **harness** (Scout, Sentinel, Auditor 등 기존 용어) | — |
| 내부 tier | **Standard / Advanced / Elite** | Mythos, Opus 4.x, 특정 preview 코드네임 |
| 사용자 노출 | 모델명 숨김. "capability: elite" 같은 중립 표현만 | 특정 모델 ID·버전 숫자 |
| 에이전트 프롬프트 | "Alignment Incident", "high-capability model", "elite-tier defense" 등 | "Mythos Incident", "Mythos-class", 버전 숫자 인용 |

참고로 "Mythos-ready"라는 표현은 v4.0.0 설계 시 **상위 tier의 개념(강화된 Sentinel, Auditor, Containment, Security Triage 등)을 도입한다**는 뜻이었다. 그 개념 자체는 유지·강화하되, 이름은 claudex/harness 고유 용어로 정착시킨다.

---

## 1. 현황 스냅샷 (Inventory)

### 1.1 업데이트 대상 파일

#### A. commands/ (6개)
- `harness.md` (828) — SINGLE + TEAM 모드 → Meta-Loop 기본화
- `harness-docs.md` (427) — 문서 생성 → Meta-Loop 적용 (chapter별 phase 분해 가능)
- `harness-review.md` (212) — 코드 리뷰 → Meta-Loop 미적용 (단발성) + tier-aware 반영
- `harness-qa.md` (420) — QA → Meta-Loop 부분 적용(suite별 phase) + tier-aware
- `design.md` (577) — 문맥 중립화만
- `claude-dashboard.md` (27) — 변경 없음

#### B. harness/ agent prompts (27개)
Scout, Planner, Builder, Refiner, QA, Diagnostician, Auditor, Sentinel, Architect, Worker, Integrator, Scanner, Analyzer, Fixer, Verifier, Reporter, Researcher, Outliner, Writer, Reviewer, Validator, Scenario Writer, Test Executor, Analyst, QA Reporter, Linter, INDEX.md

#### C. harness/references/ (6개 → 9개)
기존: session-protocol.md (450), team-build-protocol.md (328), agent-containment.md (172), confidence-calibration.md (34), error-handling-checklist.md (38), security-checklist.md (58)
신규 3개: `meta-loop-protocol.md`, `phase-verification-protocol.md`, `tier-matrix.md`

#### D. codex-skills/ mirrors (6 skills)
각 skill의 `agents/openai.yaml`, `references/*.md`, `SKILL.md`

#### E. 메타 파일
`.claude-plugin/plugin.json`, `README.md`, `README.en.md`, `ONBOARDING.md`, `onboarding-refs/*.md`, `docs/` 하위 설계 문서, `tasks/todo.md`, `tasks/lessons.md`

### 1.2 현재 tier 탐지 로직의 결함

`harness/references/session-protocol.md` §9는 `model name contains "{과거 preview 코드네임}"` 조건으로 상위 tier(Elite에 해당)를 감지한다. 현재 운용 중인 고능력 모델은 이 문자열을 포함하지 않는다. 따라서:

- `opus` 문자열만 매치 → Advanced tier로 분류
- Elite tier에 대비해 준비해둔 완화/강화 규칙(long-context scale, QA 8/10, Auditor 상시 ON, Sentinel MEDIUM 자동 ON, 라운드 축소) 전부 미적용
- 결과: v4.0.0의 Elite-ready 설계가 **코드 수준에서 dead code**

Phase 1에서 가장 먼저 수정한다.

---

## 2. Meta-Loop Architecture (핵심 신규 설계)

### 2.1 개념 정의

**Meta-Loop**: harness가 사용자 요청을 받으면 자동으로 **phase-book**을 작성하고, 각 phase를 **작업 → 검증 → 적용** 사이클로 실행하며 전체 phase가 완료될 때까지 자율 반복하는 상위 루프. **harness의 기본이자 유일한 동작 모드**다.

- **phase 내부**: 기존 harness 파이프라인(Scout → Planner → Builder → Sentinel → Refiner → QA → Diagnostician → Auditor)이 그대로 한 번 돈다.
- **phase 간**: phase-book에 기록된 모든 phase가 DoD를 통과할 때까지 순차 진행.

### 2.2 기본 동작 (플래그 없음)

```
/harness "<사용자 요청>"
  ↓
자동으로 Meta-Loop 가동
  - 작은 요청 → phase-book이 phase=1만 갖고 작성됨 (자연 퇴화, 기존 단일 pass와 동등)
  - 큰 요청 → phase-book이 N개 phase로 작성됨, 순차 실행
```

플래그(`--meta`, `--ralph` 등) 없음. 사용자 인터페이스는 이전과 동일하게 유지되며, 내부에서 phase 분해가 자동으로 일어난다.

### 2.3 Phase-Book 포맷 정의

**파일**: `.harness/phase-book.md`

```markdown
---
total_phases: N
current_phase: 1
status: in_progress
created_at: YYYY-MM-DDTHH:MM:SSZ
completion_promise: "ALL PHASES COMPLETE — {goal}"
commit_push_intent: {none | commit | commit+push | commit+push+deploy | pr}
---

# Phase Book — {goal}

## Global Goal
{원본 사용자 요청 + 최종 성공 기준}

## Phase 1: {name}
- **Goal**: {이 phase의 산출물}
- **Scope**: {예상 변경 파일/모듈}
- **DoD**:
  - [ ] Functional criterion 1
  - [ ] Functional criterion 2
- **Verify Commands**:
  ```bash
  pnpm build
  pnpm test -- path/to/affected
  ```
- **Evidence Required**: {무엇을 남길지}
- **Rollback Strategy**: {실패 시 되돌리는 방법}
- **Depends On**: {이전 phase 번호}
- **Estimated Rounds**: {1-3, phase 내부 build loop 라운드}

## Phase 2..N: ...

## Cross-Phase Invariants
- 기존 기능 X는 모든 phase에서 동작해야 한다 → 매 phase verify에 포함
- DB 스키마는 phase K까지 변경 없음

## Completion Promise
> "ALL PHASES COMPLETE — {goal}. All verify commands pass. No regressions."
```

### 2.4 Phase Verification Gate

**신규 참조**: `harness/references/phase-verification-protocol.md`

핵심 원칙(rules/verification.md 준수):
- "It should work"는 증거 아님
- verify command는 실제 실행되어야 하며 exit code·output을 기록한다
- evidence는 `.harness/phase-evidence-{N}.md`에 저장
- Fail 시 Diagnostician이 root cause 분석 → 같은 phase 재실행 (retry cap: **3회**)
- 3회 실패 시 Meta-Loop pause, 사용자 개입 요청 (rules/failure-recovery 준수)

### 2.5 Commit / Push / Deploy Intent 자동 감지

Phase-Book Planner가 사용자 요청 문장을 분석해 다음 intent 키워드가 포함되면, phase-book 말미에 해당 phase를 자동으로 추가한다:

| 감지된 키워드 | 자동 추가 phase |
|--------------|----------------|
| `커밋`, `commit` | `Phase ∞-2: Commit` — `git add` + conventional commit message |
| `푸시`, `push`, `올려` | `Phase ∞-1: Push` — branch push |
| `배포`, `deploy`, `릴리즈`, `release` | `Phase ∞: Deploy` — CI 트리거 또는 배포 스크립트 실행 |
| `PR`, `풀리퀘`, `머지`, `merge` | `Phase ∞: Create PR` — `gh pr create` |

키워드가 없으면 commit/push를 수행하지 않는다. **Auto-commit은 기본 off. 사용자가 명시적으로 요청한 경우에만 phase에 포함**된다.

Phase-Book Planner는 감지 결과를 `commit_push_intent` frontmatter에 기록해 투명성을 확보한다.

### 2.6 재개성 (Resumability)

Meta-Loop는 장시간 실행되므로 중단 복구가 필수:
- `.harness/phase-book.md`의 `current_phase`, `status` 헤더가 상태 원천
- 세션 재시작 시 `/harness` (인자 없이)가 기존 phase-book 감지 → "resume from phase N?" 사용자 프롬프트
- 각 phase 완료 시점이 자연스러운 체크포인트 (git stage 만들기는 사용자 선택)

### 2.7 외부 ralph-loop 개념 참고

Meta-Loop는 외부 `/ralph-loop` 플러그인의 "완료까지 반복" 개념을 claudex 내부에 직접 구현한다. 차이는 아래와 같다. 사용자가 외부 ralph-loop를 쓰고 싶다면 그 자체 커맨드를 직접 사용하면 된다. claudex는 이를 중복 구현하거나 하위 스킬로 래핑하지 않는다.

| 항목 | Meta-Loop (claudex 내장) | 외부 `/ralph-loop` |
|------|--------------------------|-------------------|
| 반복 단위 | Phase (여러 agent call로 구성) | Turn (한 응답) |
| 종료 조건 | 모든 phase의 DoD 통과 | `<promise>{text}</promise>` 출력 |
| 상태 저장 | `.harness/phase-book.md` + `.harness/` 전체 artifact | `.claude/ralph-loop.local.md` |
| 실패 대응 | Diagnostician root cause → retry | 사용자 판단 |
| 구조화 | phase별 DoD·verify·rollback 명시 | 단일 프롬프트 반복 |

---

## 3. Phase-By-Phase Implementation Plan

### Phase 1 — Tier 재정립 + 명명 중립화

**Goal**: Elite tier가 현재 운용 모델에서 올바르게 감지되도록 교정하고, 프로젝트 전역에서 과거 preview 코드네임·모델 버전 숫자 참조를 중립어로 치환한다.

#### 변경 대상

| 파일 | 변경 내용 |
|------|----------|
| `harness/references/session-protocol.md` | §9 Tier 정의 재작성. Tier 이름 `Standard / Advanced / Elite`로 교체. 탐지 로직: **모델 ID allowlist** 기반으로 명시. 신규 §9.5 "Elite Model Allowlist"에 현재 elite-tier 대상 모델 ID를 등록·업데이트하는 절차 문서화 |
| `harness/references/tier-matrix.md` (신규) | tier × scale × parameter 통합 1페이지 매트릭스. 모든 agent가 필요 시 on-demand 로드 |
| `harness/references/agent-containment.md` | "{과거 코드네임} Incident" 표 헤더를 "Alignment Incident"로 치환, 내용은 유지 |
| `harness/sentinel-prompt.md`, `harness/auditor-prompt.md`, `harness/qa-prompt.md`, `harness/builder-prompt.md`, `harness/worker-prompt.md`, `harness/refiner-prompt.md`, `harness/planner-prompt.md`, `harness/diagnostician-prompt.md`, `harness/architect-prompt.md` | 과거 preview 코드네임 · 모델 버전 숫자 참조 제거. "Mythos-class defense" 같은 문구는 "Elite-tier defense" 또는 "high-capability model defense"로 중립화. "Mythos Incident #N"은 "Alignment Incident: {패턴 요약}"로 |
| `commands/harness.md` | Phase 0에서 "감지된 tier: {Standard/Advanced/Elite}" 한 줄만 출력(모델명 노출 금지) |

#### 검증 조건
- 프로젝트 전수 grep으로 `Mythos`, `mythos`, `opus-4-6`, `opus-4-7`, `4\.6`, `4\.7` 잔존 0건 (`docs/` 이력 파일은 별도 처리, Phase 6 참조)
- 최신 Elite 모델 세션 → "tier: Elite"
- opus 4.x 구버전 세션 → "tier: Advanced"
- sonnet/haiku 세션 → "tier: Standard"

#### 리스크
- **Low**: 텍스트·분류 로직 변경만. 파이프라인 제어 흐름은 건드리지 않음.

---

### Phase 2 — Elite tier 효과 활성화

**Goal**: Elite tier 감지 시 내장된 완화·강화 규칙(long-context scale, QA 8/10, Auditor 상시 ON, Sentinel 범위 확대, 라운드 축소)이 실제 동작에 반영되도록 연결.

#### 변경 대상

| 파일 | 변경 내용 |
|------|----------|
| `harness/references/session-protocol.md` | Tier-specific 매트릭스 수치 확정: Elite → L 라운드 2, M 라운드 1, QA pass 8/10, Auditor always ON, Sentinel MEDIUM에서도 ON, Scale file threshold 완화(S 1-5, M 3-10, L 11+) |
| `commands/harness.md` Phase 0 | Scale classification에 tier-aware 분기 추가. 사용자 노출은 "Scale: M" 수준까지만, tier 이유는 내부 로그로만 |
| `commands/harness.md` Phase 0.5 | Sentinel activation rule에 tier 조건 병합 |
| `commands/harness.md` Phase 4 | Max rounds를 `tier × scale` 매트릭스에서 조회 |
| `harness/qa-prompt.md` | Pass threshold를 tier-aware conditional로 작성 (Elite: 8/10) |
| `harness/auditor-prompt.md` | Elite 시 always-on 문구 명시 |
| `harness/scout-prompt.md` | Long-context scale 확장 분기 추가 |
| `commands/harness-docs.md`, `commands/harness-review.md`, `commands/harness-qa.md` | tier-aware 조건 반영 (round, threshold) |

#### 신규 추가

- `harness/references/tier-matrix.md` 내용 확정 (Phase 1에서 파일 생성했던 것을 이 phase에서 상세 값으로 채움)

#### 검증 조건
- Elite 세션 + Scale L 요청 → max 2 rounds
- Elite 세션 + MEDIUM 민감도 → Sentinel 자동 ON
- QA가 7.5/10으로 PASS 내줬을 때 Elite tier면 FAIL 처리
- Advanced/Standard tier에서는 기존 임계값 유지 (회귀 없음)

#### 리스크
- **Medium**: L round 3 → 2 단축으로 복잡 태스크 품질 저하 가능성. 완화책: Diagnostician이 "needs extra round" escape signal을 명시적으로 낼 수 있게 허용 (QA feedback에 명시적 flag 두면 orchestrator가 1회 연장 허용).

---

### Phase 3 — Meta-Loop Architecture 기본 내장 (핵심)

**Goal**: harness의 기본 동작을 Meta-Loop로 전환. 플래그 없음.

#### 신규 파일

| 파일 | 역할 |
|------|------|
| `harness/references/meta-loop-protocol.md` | Meta-Loop 전체 설계 문서 (본 계획서 §2의 확장판) |
| `harness/references/phase-verification-protocol.md` | Phase DoD 검증 절차 표준 |
| `harness/phase-book-planner-prompt.md` | phase-book 작성 + intent 감지 전담 에이전트 (Planner의 상위 layer) |
| `harness/phase-verifier-prompt.md` | phase 완료 검증 전담 에이전트 |
| `harness/phase-orchestrator-prompt.md` | Meta-Loop 진행 조율 helper 프롬프트 (orchestrator가 내장 참조) |

#### 기존 파일 변경

| 파일 | 변경 내용 |
|------|----------|
| `commands/harness.md` | 전체 Phase 구조 재작성. Phase 0 (Triage) 이후 Phase 0.7 (Phase-Book Planner) 추가. 기존 Phase 1~5는 "phase-internal pipeline"으로 감싸짐. Meta-Loop가 phase-book 모든 항목을 완료할 때까지 반복. **플래그 도입하지 않음** |
| `commands/harness.md` | 인자 없이 호출 시 기존 `.harness/phase-book.md` 감지 → "resume from phase N?" 프롬프트 |
| `commands/harness-docs.md` | Meta-Loop 적용: 큰 문서는 chapter별 phase로 분해 (small docs는 phase=1 자연 퇴화) |
| `commands/harness-qa.md` | Meta-Loop 부분 적용: 여러 test suite 요청 시 suite별 phase 분해, 단일 suite는 phase=1 |
| `commands/harness-review.md` | Meta-Loop 미적용 (단발성 리뷰). tier-aware만 적용 |
| `harness/planner-prompt.md` | 범위 명확화: phase-internal spec만 담당 (전체 분해는 phase-book-planner 담당) |
| `harness/diagnostician-prompt.md` | Meta-Loop 모드에서 "cross-phase regression" 분석 루틴 추가. 3회 retry 실패 조건에서 사용자에게 올리는 리포트 템플릿 추가 |
| `harness/INDEX.md` | 신규 에이전트 3개 + 신규 reference 2개 반영. Pipeline 구조 Meta-Loop 버전 추가 |

#### 실행 플로우

```
/harness "<요청>"
  ↓
Phase 0: Triage (Scale S/M/L) + Capability (tier)
Phase 0.5: Security Triage
Phase 0.7: Phase-Book Planner
  - 요청 분석, phase 분해
  - commit/push/deploy/PR intent 감지 → 해당 phase 자동 추가
  - phase-book.md 작성
  - 사용자 phase-book 승인 (Y / N / edit)  ← 이 승인은 계획 정확성 확인, 실행 중 추가 게이트 아님
Phase 1..N (Meta-Loop, 자동 순차):
  For each phase i in phase-book:
    a. Announce "Phase i/N: {name}"
    b. Run phase-internal harness pipeline (Scout → Planner → Builder → Sentinel → Refiner → QA → Diagnostician → Auditor)
    c. Phase Verifier
       - DoD 체크
       - verify commands 실행, exit code·output 기록
       - phase-evidence-{i}.md 작성
    d. PASS → phase-book.md의 current_phase += 1 → 다음 phase 자동 진행
    e. FAIL → Diagnostician root cause → same phase retry (max 3)
       - 3회 실패 → Meta-Loop pause, 상세 리포트 + 복구 옵션 제시
Phase ∞-k: (intent에 따라) Commit / Push / Deploy / PR
Phase ∞: Final Auditor + Summary
```

중간에 **사용자 확인 게이트는 phase-book 승인 한 곳뿐**이며 이후는 한 번에 끝까지 실행된다.

#### 검증 조건
- `/harness "fix the login button 404"` → phase-book이 phase=1만 갖고 작성, 기존 단일 pass와 동등하게 완료
- `/harness "build a full dashboard with auth, billing, reports"` → phase 5~10개로 분해, 순차 실행, 중간 중단 없음
- `/harness "fix the 404 and commit"` → 마지막 phase가 "Commit" 자동 추가됨
- `/harness "회원가입 구현하고 PR 올려줘"` → 마지막 phase가 "Create PR"
- 세션 강제 종료 후 `/harness` 재호출 → "resume from phase N?" 프롬프트
- 의도적 빌드 실패 phase → Phase Verifier FAIL 감지 → Diagnostician retry

#### 리스크
- **High**: Meta-Loop 장시간 실행 + 여러 agent call로 토큰/예산 부담. 완화책:
  - phase-book에 `estimated_rounds` 기반 사전 비용 추정 사용자 표시
  - phase당 최대 라운드 캡
  - phase 완료 시점마다 progress 요약(used tokens, elapsed time) 출력
  - `total_phases` 상한(기본 20)
- **Medium**: phase-book 품질이 전체 성공 좌우. 완화책: `phase-book-planner-prompt.md`에 강력한 품질 기준 인코딩 — 각 phase 단일 책임, DoD 검증 가능성, 독립 실행 가능성, 의존성 명시 — 을 요구.
- **Medium**: Cross-Phase Integrity. 이전 phase 결과가 이후 phase에서 깨질 수 있음. 완화책: 각 phase가 "touched files" 목록을 기록, 이후 phase가 같은 파일 수정 시 해당 파일의 이전 verify command를 재실행하는 규칙.

---

### Phase 4 — Agent 프롬프트 Elite-tier 대응 강화

**Goal**: Elite tier의 확장된 자율성과 미묘한 실수 패턴에 대응하도록 기존 에이전트 프롬프트 보강.

#### 변경 대상

| 파일 | 변경 내용 | 이유 |
|------|----------|------|
| `harness/sentinel-prompt.md` | 탐지 패턴 추가: ① silent scope creep(하위 에이전트 생성 후 메인 보고 누락), ② evidence backdating(파일 timestamp 조작), ③ `--no-verify`·force-push 재확인 | 자율성 확대 → 미묘한 탈출 시도 증가 |
| `harness/auditor-prompt.md` | Claim verification 체크리스트 확장: ① cross-agent claim consistency, ② quantitative claim 검증("12 tests passed" → test output 실측 대조), ③ phase boundary 통과 claim의 phase-evidence 파일 존재·정합성 | 자신감 있는 오답 빈도 대응 |
| `harness/qa-prompt.md` | Anti-Evidence-Fabrication Protocol를 tier-aware로 확장. Elite tier에서 추가 anti-sycophancy 기준 | "The code seems to work" 같은 무증거 PASS 차단 |
| `harness/builder-prompt.md` | Execution Audit 확장: FILE_MODIFY 시 before-hash 기록(Elite tier only, optional) | 후속 검증 강화 |
| `harness/worker-prompt.md` | TEAM 모드 Worker에 containment-by-default. Elite tier에서 HIGH sensitivity 파일 접근은 Architect 승인 필수 | 병렬 Worker scope creep 방지 |
| `harness/refiner-prompt.md` | `--no-verify`, `git commit --amend` 등 금지 명시 (Sentinel 1차 방어에 더해 Refiner도 self-check) | 중복 방어 |
| `harness/diagnostician-prompt.md` | "Pre-Decided Conclusion" 패턴 감지 강화 + Meta-Loop cross-phase regression 분석 섹션 | Meta-Loop 연계 |
| `harness/planner-prompt.md` | Meta-Loop 모드 전용으로 phase-internal spec 작성에 집중 | Meta-Loop 통합 |

모든 변경 문구에서 과거 preview 코드네임·모델 버전 숫자 사용 금지. "Elite-tier defense", "high-capability model behavior" 등 중립어만 사용.

#### 검증 조건
- 기존 smoke test 시나리오 (SINGLE S/M/L, TEAM) 회귀 없음
- silent scope creep 시뮬레이션에서 Sentinel BLOCK
- 무증거 PASS를 QA가 reject

#### 리스크
- **Medium**: 프롬프트 길이 증가 → 토큰 사용량 상승. 완화책: tier-aware conditional 섹션으로 감싸 Standard/Advanced에서는 load skip.

---

### Phase 5 — Codex Mirror 동기화 + 부수 명령 반영

**Goal**: Claude/Codex 양쪽 에이전트 프롬프트 일관성 유지 + `/design` 등 부수 명령에서 잔존 중립화 완료.

#### 변경 대상

| 파일 | 변경 내용 |
|------|----------|
| `codex-skills/harness/references/*.md` | Phase 1~4 변경 미러링 |
| `codex-skills/harness/SKILL.md` | Meta-Loop 기본화 반영 |
| `codex-skills/harness-docs/SKILL.md`, `codex-skills/harness-review/SKILL.md`, `codex-skills/harness-qa/SKILL.md` | tier 중립화 + 해당 명령 Meta-Loop 적용 범위 반영 |
| `codex-skills/design/SKILL.md`, `commands/design.md` | 과거 코드네임 문맥 언급만 제거(기능 변경 없음). Mix-of-grid 수치 "4-6"은 디자인 스펙이므로 건드리지 않음 |
| `harness/INDEX.md` | Codex Mirror Map 재동기화 확인 |

#### 검증 조건
- Claude/Codex prompt diff 최소
- 기본 동작 회귀 없음 (smoke test)

#### 리스크
- **Low**: 기계적 미러링.

---

### Phase 6 — 문서, 플러그인 메타데이터, 버전 범프

**Goal**: v4.1.0 릴리즈 준비 + 이력 문서 정리.

#### 변경 대상

| 파일 | 변경 내용 |
|------|----------|
| `.claude-plugin/plugin.json` | version `4.0.0` → `4.1.0`. description 재작성: 과거 코드네임 제거, Meta-Loop·tier detection 중심 |
| `README.md`, `README.en.md` | What's New v4.1.0 섹션. Meta-Loop 개념·동작 설명, intent 감지, tier 중립 명명 |
| `ONBOARDING.md` | Meta-Loop 기본 워크플로우 튜토리얼 |
| `onboarding-refs/*.md` | 과거 코드네임·모델 버전 참조 제거, Meta-Loop 가이드 링크 |
| `docs/mythos-harness-improvement-plan.md` | `git mv` → `docs/harness-hardening-plan-v3.md` (이력 보존). 내부 문자열은 이력 문서이므로 원형 유지. 신규 README.md 주석에서 "이 문서는 v3.3~3.5 역사 기록"임을 표시 |
| `docs/meta-loop-design.md` (신규) | Meta-Loop 공식 설계 문서 (본 계획서 §2의 확장·영속판) |
| `docs/capability-detection.md` (신규) | tier 정의, 탐지 로직, Elite allowlist 관리 절차 |
| `CHANGELOG.md` (없으면 신규) | v4.1.0 변경점 |
| `tasks/todo.md` | 이번 세션 작업 이력 append |
| `tasks/lessons.md` | 필요 시 교훈 append |

#### 검증 조건
- 플러그인 설치 후 버전 `v4.1.0` 확인
- README 예시 커맨드 전부 실행 가능
- 전수 grep: `mythos`, `Mythos`, `opus-4-[67]`, `4\.7` 잔존 0건(단, `docs/harness-hardening-plan-v3.md`와 `Claude Mythos Preview System Card.pdf`는 이력이므로 제외)

#### 리스크
- **Low**: 문서 작업.

---

## 4. 작업-검증-적용 사이클 (메타 — 본 업그레이드 자체 실행 방식)

본 업그레이드 전체를 우리가 설계한 Meta-Loop 철학으로 실행한다:

```
각 Phase (1~6):
  [Work]
    - 파일 edit/write
    - 단위 로직 구현
  [Verify]
    - 해당 phase의 DoD 체크
    - smoke 테스트 (예: /harness "..." 샘플 실행)
    - 전수 grep 기반 일관성 체크 (예: 금지 키워드 잔존 여부)
  [Apply]
    - 변경을 작업 트리에 반영
    - 본 계획서의 해당 phase 체크박스 체크
    - 다음 phase로 자동 진행
  [Next Phase]
```

**중간 사용자 확인 게이트 없음.** 사용자 시작 지시 한 번으로 Phase 1 → 6까지 연속 실행한다. 단, 각 phase 완료 시 간단한 상태 메시지(한 줄 요약, used token·elapsed time)만 출력한다.

3회 retry 실패 또는 `rules/failure-recovery`에 따라 pivot이 필요한 상황에서는 즉시 pause, 사용자 개입 요청.

git commit/push는 사용자 요청 시 원문에 그 의도가 포함되어 있을 때만 수행한다. 본 계획서 실행 시작 지시에 커밋/푸시 의도가 포함되는지 여부는 시작 시점에 확인한다.

---

## 5. 예상 작업량

| Phase | 파일 수 | 복잡도 | 소요 예상 |
|-------|--------|--------|----------|
| 1. Tier 재정립 + 명명 중립화 | ~12 | Medium (전수 치환) | 1시간 |
| 2. Elite tier 효과 활성화 | ~8 | Medium | 1-2시간 |
| 3. Meta-Loop 기본 내장 | ~10 (신규 5 + 수정 5) | **High** | 4-6시간 |
| 4. Agent 프롬프트 강화 | ~8 | Medium | 2-3시간 |
| 5. Codex mirror 동기화 | ~15 | Low | 1시간 |
| 6. 문서 + 버전 범프 | ~10 | Low | 1시간 |

**총 예상**: 10-14 시간 어치 작업량. Meta-Loop가 이 작업을 phase-book으로 나눠 자율 실행할 수 있도록 설계되었지만, 본 v4.1.0 자체는 Meta-Loop가 설치되기 **전** 상태에서 수행되므로 claudex orchestrator가 직접 순차 실행한다.

---

## 6. 리스크 매트릭스

| 리스크 | 영향도 | 발생 가능성 | 완화책 |
|--------|-------|-----------|-------|
| Meta-Loop 무한 루프 | High | Medium | `total_phases` 상한 20 + phase retry cap 3 |
| 토큰 예산 초과 | Medium | Medium | phase별 추정 비용 사전 표시 + phase 단위 progress 리포트 |
| 회귀 (작은 요청이 기존처럼 단순 처리 안 됨) | High | Low | phase=1 자연 퇴화 경로 스모크 테스트 필수 |
| phase-book 품질 부족 | High | Medium | phase-book-planner 프롬프트 품질 기준 강화 + 승인 게이트 |
| tier 탐지 오판 | Low | Low | allowlist 기반 명시, 필요 시 수동 override 환경변수 제공 |
| Codex/Claude 드리프트 | Low | Medium | INDEX.md Codex Mirror Map 기반 동기화 + Lint 체크 |
| 명명 중립화 누락 | Low | Medium | Phase 1·6 끝에 전수 grep 검증 |

---

## 7. Non-Goals (이번 범위 밖)

- `/design`, `/claude-dashboard` 기능 확장 (중립화 문구 정리만)
- 새로운 파이프라인 추가 (e.g. `/harness-security`, `/harness-perf`)
- GUI 대시보드
- 백그라운드/원격 실행 기제 (`ScheduleWakeup` 등) — 별도 이니셔티브
- multi-agent distributed execution — 현재 구조로 충분
- 외부 `/ralph-loop` 플러그인 하위 스킬 래핑 — Meta-Loop가 claudex 내부 구현으로 충족

---

## 8. Completion Promise

이 계획이 완료되면 다음 statement가 true가 된다:

> **"claudex v4.1.0 shipped. harness runs in Meta-Loop by default, with phase-book driven work-verify-apply cycles continuing until all phases' DoD pass. Capability detection classifies the current runtime model into the correct internal tier (`Standard / Advanced / Elite`) via explicit allowlist. Commit/push/deploy/PR intents in the user request are automatically captured as terminal phases. All prior preview codename and version-number references have been neutralized across commands, agent prompts, references, codex mirrors, and docs (except preserved history files). No regression for small requests (phase=1 natural degradation). Codex mirrors synchronized. Plugin version bumped to 4.1.0, README and onboarding updated."**

---

## 9. Next Step

- [ ] **사용자 시작 지시 대기**

시작 지시가 내려지면 Phase 1 → Phase 6을 **중간 확인 게이트 없이** 순차 실행한다. 각 phase 완료 시 한 줄 진행 요약만 출력한다. 3회 retry 실패 혹은 root-cause 불명 상황에서만 pause + 사용자 개입 요청.
