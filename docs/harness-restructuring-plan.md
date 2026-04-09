# Harness Command Restructuring Plan

> claudex v3.5.0 기준, 5개 harness 커맨드의 구조적 문제를 진단하고 재편 방안을 제시한다.
> 작성일: 2026-04-09

---

## 1. 현상 진단

### 1.1 커맨드 현황 요약

| 커맨드 | 줄 수 | description 주장 | 실제 에이전트 수 | 보안 기능 |
|--------|-------|-----------------|----------------|----------|
| `harness.md` | 794 | "5-agent" | 8 (Scout, Planner, Builder, Sentinel, Refiner, QA, Diagnostician, Auditor) | Triage + Sentinel + Auditor |
| `harness-team.md` | 603 | "5-agent" | 8 (Scout, Architect, Workers, Sentinel, Integrator, QA, Diagnostician, Auditor) | Triage + Sentinel + Auditor |
| `harness-review.md` | 212 | "5-agent" | 5 (Scanner, Analyzer, Fixer, Verifier, Reporter) | 없음 |
| `harness-docs.md` | 427 | "5-agent" | 5 (Researcher, Outliner, Writer, Reviewer, Validator) | 없음 |
| `harness-qa.md` | 420 | "5-agent" | 5 (Scout, ScenarioWriter, TestExecutor, Analyst, Reporter) | 없음 |
| **합계** | **2,456** | | **25 unique prompts** | |

5개 커맨드 모두 description에 "5-agent"를 표기하지만, `/harness`와 `/harness-team`은 실제로 8개 에이전트를 운용한다. 3개의 보안 에이전트(Sentinel, Auditor)와 진단 에이전트(Diagnostician)가 조건부로 활성화되기 때문이다. 사용자가 description만 보고 커맨드를 선택할 때, 실제 동작과의 괴리가 발생한다.

### 1.2 Description vs Reality 불일치

**문제의 본질**: Claude Code Marketplace에서 사용자가 처음 접하는 것은 `plugin.json`의 description과 각 커맨드의 frontmatter description이다. 현재 **두 곳의 description이 서로 불일치**한다:

- **plugin.json**: `/harness`를 이미 "8-agent build pipeline with Sentinel + Auditor"로 올바르게 표기. `/harness-qa`에 "Security Track"을 언급하지만 실제 커맨드에는 보안 기능이 없음.
- **커맨드 frontmatter**: 모든 5개 커맨드가 "5-agent"를 표기. `/harness`와 `/harness-team`은 실제로 8개 에이전트를 운용하므로 부정확.

즉, plugin.json은 harness의 에이전트 수를 부분적으로 수정했으나 frontmatter는 갱신되지 않았다. 두 곳을 일관되게 정확한 상태로 맞춰야 한다.

| 커맨드 | description 표기 | 실제 | 차이 |
|--------|-----------------|------|------|
| `/harness` | "5-agent builder pipeline" | 8-agent (Scout+Planner+Builder+Sentinel+Refiner+QA+Diagnostician+Auditor) | +3 숨겨진 에이전트 |
| `/harness-team` | "5-agent parallel team build" | 8-agent (Scout+Architect+Workers+Sentinel+Integrator+QA+Diagnostician+Auditor) | +3 숨겨진 에이전트 |
| `/harness-review` | "5-agent code review" | 5-agent (정확) | 일치 |
| `/harness-docs` | "5-agent documentation" | 5-agent (정확) | 일치 |
| `/harness-qa` | "5-agent functional QA" | 5-agent (정확) | 일치 |

### 1.3 보안 기능 불균형

가장 심각한 구조적 문제이다. 5개 커맨드 중 2개만 보안 기능이 있다.

| 보안 기능 | /harness | /harness-team | /harness-review | /harness-docs | /harness-qa |
|----------|----------|--------------|----------------|--------------|------------|
| Security Triage (Phase 0.5) | O | O | **X** | **X** | **X** |
| Sentinel Gate | O | O (per-Worker) | **X** | **X** | **X** |
| Auditor Gate | O | O | **X** | **X** | **X** |
| QA Security Track | O | O | **X** | **X** | **X** |

**위험 시나리오**:
- `/harness-review`로 보안 관련 코드를 리뷰할 때, Sentinel이 없어 보안 취약점이 Fixer에 의해 도입될 수 있다.
- `/harness-docs`로 API 문서를 생성할 때, 내부 secret이나 credential 경로가 문서에 노출될 수 있다.
- `/harness-qa`는 커맨드 파일(harness-qa.md)에 Security Track, Security Triage, Sentinel, Auditor에 대한 참조가 **전혀 없다** (`grep -c "security" commands/harness-qa.md` → 0). plugin.json에서 "Security Track"을 표기하지만, 커맨드 구현에는 보안 기능이 일체 포함되어 있지 않다. Phase 2에서 이를 **신규로 추가**해야 한다.

### 1.4 /harness 비대화 문제

`harness.md`는 794줄로, 나머지 4개 커맨드 평균(416줄)의 거의 2배이다. 내용 분석:

| 섹션 | 줄 수 (추정) | 비고 |
|------|-------------|------|
| Phase 0: Triage | ~40 | Scale 분류 |
| Phase 0.5: Security Triage | ~92 | 보안 민감도 분류 (lines 46–137) |
| Phase 1: Setup | ~50 | Session Protocol 참조 + 초기화 |
| Phase 2: Scout | ~60 | Scout 에이전트 호출 |
| Phase 3: Planning | ~80 | Planner 에이전트 + 사용자 승인 |
| Phase 4: Build Loop (core) | ~242 | Builder+Sentinel+Refiner+QA+Diagnostician (lines 323–564) |
| Phase 4-post + 4-audit | ~94 | Artifact Validation (~58줄) + Auditor 교차검증 (~36줄) |
| Phase 5: Summary | ~40 | 최종 보고 |
| Sentinel Protocol | ~54 | 보안 게이트 규칙 |

빌드 관련 Phase(4 core + 4-post + 4-audit) 합산 336줄로 전체의 42%를 차지한다. Phase 4 core만으로도 242줄(30%)이며, 이는 Builder, Sentinel, Refiner, QA, Diagnostician 5개 에이전트가 모두 한 Phase 안에서 순환하기 때문이다.

### 1.5 /harness와 /harness-team 중복 분석

연구 결과 26%의 내용이 거의 동일하고, 74%는 고유하다.

**중복 구간** (26%):
- Phase 0.5 Security Triage: 키워드 목록, 분류 로직, 결과 파일 형식이 사실상 복사본이다. 차이점은 `/harness-team`이 "team builds are always Scale L"이라는 한 줄뿐이다.
- Phase 1 Setup: Session Recovery Check 로직, `.harness/` 초기화, `session-state.md` 형식이 동일하다. 차이점은 파이프라인 이름(`harness` vs `harness-team`)과 프롬프트 파일명(`build-prompt.md` vs `team-prompt.md`)뿐이다.
- Phase 4-audit Auditor: Auditor 호출 조건과 보고서 형식이 동일하다. 차이점은 읽는 artifact 경로 접두사(`build-` vs `team-`)뿐이다.

**고유 구간** (74%):
- `/harness-team` 고유: Wave 구조 (Wave 1 sequential + Wave 2 parallel + Wave 3 integration), Architect 에이전트, Workers(N) 병렬 실행, per-Worker Sentinel, Integrator 에이전트, worktree 관리, `--agents N` 인자
- `/harness` 고유: Planner 에이전트, Builder 단일 실행, Refiner 에이전트, Scale S/M/L에 따른 라운드 수 차등, Snapshot 캡처

**공유 에이전트** (5개): Scout, QA, Diagnostician, Sentinel, Auditor. 동일 프롬프트 파일을 사용하지만, 각 오케스트레이터가 다른 artifact 경로를 전달한다.

### 1.6 Codex Mirror Phantom 파일

Codex 포팅을 위해 `codex-skills/` 하위에 각 파이프라인별 references/ 폴더가 존재한다. 문제는 sentinel-prompt.md와 auditor-prompt.md가 **모든 5개 파이프라인**에 복사되어 있다는 점이다.

| Codex 경로 | 실제 사용 여부 |
|------------|--------------|
| `codex-skills/harness/references/sentinel-prompt.md` | O (실제 사용) |
| `codex-skills/harness/references/auditor-prompt.md` | O (실제 사용) |
| `codex-skills/harness-team/references/sentinel-prompt.md` | O (실제 사용) |
| `codex-skills/harness-team/references/auditor-prompt.md` | O (실제 사용) |
| `codex-skills/harness-review/references/sentinel-prompt.md` | **X (phantom)** |
| `codex-skills/harness-review/references/auditor-prompt.md` | **X (phantom)** |
| `codex-skills/harness-docs/references/sentinel-prompt.md` | **X (phantom)** |
| `codex-skills/harness-docs/references/auditor-prompt.md` | **X (phantom)** |
| `codex-skills/harness-qa/references/sentinel-prompt.md` | **X (phantom)** |
| `codex-skills/harness-qa/references/auditor-prompt.md` | **X (phantom)** |

6개의 phantom 파일이 존재한다. 이들은 해당 파이프라인의 커맨드에서 참조하지 않으므로 토큰만 낭비한다(Codex가 skill 로드 시 references/ 전체를 읽는 경우).

### 1.7 진단 요약

| 문제 | 심각도 | 영향 |
|------|--------|------|
| Description 부정확 ("5-agent" 표기) | 중 | 사용자 혼란, Marketplace 신뢰도 |
| 보안 기능 불균형 (2/5만 보안) | 상 | review/docs/qa에서 보안 사고 가능성 |
| harness.md 794줄 비대화 | 중 | 유지보수 부담, 토큰 소비 |
| 26% 중복 (harness vs harness-team) | 중 | 동기화 실패 시 divergence |
| Phantom Codex 파일 6개 | 하 | 불필요한 파일, 혼란 가능성 |

---

## 2. 재편 원칙

아래 5가지 설계 원칙을 재편안 평가의 기준으로 사용한다.

### 원칙 1: 정확한 자기 표현 (Honest Description)

커맨드의 description은 실제 동작을 정확히 반영해야 한다. 사용자가 description만으로 올바른 커맨드를 선택할 수 있어야 하며, "5-agent"처럼 내부 구현 세부사항(에이전트 수)을 표면에 노출하기보다 사용자가 얻는 가치(파이프라인의 역할)를 전달한다.

**평가 기준**: 재편 후 모든 description이 실제 에이전트 수, 보안 수준, 파이프라인 구조를 정확히 반영하는가?

### 원칙 2: 균일한 보안 (Uniform Security)

모든 빌드/변환 파이프라인은 Security Triage를 거쳐야 한다. 코드를 생성하거나 수정하는 커맨드(harness, harness-team, harness-review)는 Sentinel Gate를 조건부 활성화할 수 있어야 하고, 문서를 생성하는 커맨드(harness-docs)는 secret 노출 방지를, QA 커맨드(harness-qa)는 보안 테스트 트랙을 갖춰야 한다.

**평가 기준**: 모든 5개 커맨드에서 보안 민감도에 따른 적절한 보안 게이트가 작동하는가?

### 원칙 3: DRY 오케스트레이션 (Don't Repeat Yourself)

동일한 프로토콜(Security Triage, Session Protocol, Auditor Gate)이 여러 커맨드에 복사되어서는 안 된다. 공유 가능한 프로토콜은 단일 참조 파일로 추출하고, 각 커맨드는 해당 파일을 참조한다.

**평가 기준**: 중복 코드 줄 수가 감소하고, 공유 프로토콜 변경 시 한 곳만 수정하면 되는가?

### 원칙 4: 최소 파괴 (Minimal Breaking Changes)

기존 사용자의 워크플로우를 깨뜨리지 않아야 한다. Claude Code 슬래시 커맨드의 제약사항:
- 커맨드명은 `commands/` 폴더 내 `.md` 파일명으로 결정된다.
- 사용자는 `/harness`, `/harness-team` 등의 이름으로 워크플로우를 구축한다.
- 커맨드 삭제는 breaking change이고, 커맨드 추가는 non-breaking이다.
- 커맨드 내부 동작 변경은 결과물이 동일하면 non-breaking이다.

**평가 기준**: 기존 5개 커맨드명이 모두 유지되는가? 기존 사용자의 호출 패턴이 변하지 않는가?

### 원칙 5: 유지보수 가능한 규모 (Maintainable Size)

단일 커맨드 파일이 800줄을 넘지 않아야 한다(코드 품질 원칙 준수). 400줄 이상이면 분리 검토 대상이다. 에이전트 프롬프트, 공유 프로토콜, 오케스트레이션 로직이 명확히 분리되어야 한다.

**평가 기준**: 재편 후 가장 큰 커맨드 파일이 몇 줄인가? 유지보수 시 수정 포인트가 줄어드는가?

---

## 3. 재편안 비교 분석

### 3.1 Option A: 현행 유지 + Description 갱신

**내용**: 5개 커맨드 구조를 유지하고, frontmatter description만 정확하게 수정한다.

**변경 사항**:
- `harness.md` description: "5-agent" -> "8-agent builder pipeline with Security Triage, Sentinel Gate, and Auditor"
- `harness-team.md` description: "5-agent" -> "8-agent parallel team build with per-Worker Sentinel and Auditor"
- `harness-review.md` description: 유지 (정확)
- `harness-docs.md` description: 유지 (정확)
- `harness-qa.md` description: 유지 (정확)
- `plugin.json` description: 에이전트 수 정정

**파일 변경**: 3개 (harness.md, harness-team.md, plugin.json)

| 원칙 | 점수 (1-5) | 근거 |
|------|-----------|------|
| 정확한 자기 표현 | 4 | description은 수정되지만, review/docs/qa의 보안 부재는 여전히 미표기 |
| 균일한 보안 | 1 | 보안 불균형 해결 안 됨 |
| DRY 오케스트레이션 | 1 | 26% 중복 유지 |
| 최소 파괴 | 5 | 변경 거의 없음 |
| 유지보수 가능 규모 | 2 | harness.md 794줄 유지 |
| **합계** | **13/25** | |

**장점**: 가장 안전하고 빠르게 적용 가능. 사용자 영향 제로.
**단점**: 핵심 문제(보안 불균형, 중복, 비대화)를 하나도 해결하지 못한다. Description 수정은 증상 치료일 뿐이다.

### 3.2 Option B: /harness + /harness-team 병합 (5 -> 4 커맨드)

**내용**: `/harness-team`을 `/harness`에 통합한다. `--parallel N` 또는 `--team N` 플래그로 팀 빌드 모드를 활성화한다.

**변경 사항**:
- `harness.md`: 팀 빌드 로직(Wave 구조, Architect, Workers, Integrator, worktree) 통합
- `harness-team.md`: 삭제 또는 redirect stub으로 대체
- 에이전트 프롬프트: 변경 없음 (이미 분리됨)

**예상 harness.md 크기**: 794 + 603 * 0.74 (고유 부분) = ~1,240줄. 800줄 상한 초과.

| 원칙 | 점수 (1-5) | 근거 |
|------|-----------|------|
| 정확한 자기 표현 | 3 | 하나의 커맨드가 두 가지 모드를 가지면 description이 복잡해짐 |
| 균일한 보안 | 2 | 병합 대상 두 커맨드는 이미 보안이 있으므로 해결 안 됨 (review/docs/qa는 여전) |
| DRY 오케스트레이션 | 4 | 26% 중복 제거됨 |
| 최소 파괴 | 2 | `/harness-team` 삭제는 breaking change. 기존 사용자 워크플로우 깨짐 |
| 유지보수 가능 규모 | 1 | 1,240줄 예상. 800줄 상한 초과. 오히려 더 비대해짐 |
| **합계** | **12/25** | |

**장점**: 26% 중복 제거. 사용자 입장에서 선택 고민 감소 (한 커맨드로 통합).
**단점**: 
- 74% 고유 콘텐츠(Wave 구조, Architect, Workers, Integrator, worktree, per-Worker Sentinel)가 harness.md에 합쳐지면 **1,240줄 이상**의 거대 파일이 된다. 유지보수 원칙 위반.
- `/harness-team` 삭제는 breaking change이다. 기존에 `harness-team`을 사용하던 워크플로우가 깨진다.
- 두 파이프라인의 Phase 구조가 근본적으로 다르다: `/harness`는 `Builder -> Refiner -> QA` 순환이고, `/harness-team`은 `Wave 1 -> Wave 2(parallel) -> Wave 3(integrate) -> QA` 구조이다. 하나의 오케스트레이터에 두 가지 실행 경로를 넣으면 분기 복잡도가 크게 증가한다.

**74% 고유성에 대한 평가**: 연구에서 확인된 74%의 고유 콘텐츠는 단순히 "약간 다른 워딩"이 아니라, **완전히 다른 실행 모델**(단일 Builder vs 다중 Worker Wave)을 반영한다. 이를 하나의 파일에 통합하면 조건부 분기가 파일 전체에 퍼져 가독성과 유지보수성이 심각하게 저하된다.

### 3.3 Option C: /harness-security 추가 (5 -> 6 커맨드)

**내용**: 보안 전용 파이프라인 `/harness-security`를 새로 만든다. Security Triage + Sentinel + Auditor를 독립 커맨드로 분리하여, 다른 파이프라인이 필요할 때 `/harness-security`를 호출한다.

**변경 사항**:
- `harness-security.md` 신규 (보안 오케스트레이터)
- 기존 5개 커맨드에서 보안 로직 제거 또는 경량화
- 크로스 커맨드 호출 패턴 도입

| 원칙 | 점수 (1-5) | 근거 |
|------|-----------|------|
| 정확한 자기 표현 | 3 | 보안이 별도 커맨드로 분리되면 각 커맨드의 역할은 명확해지지만, 사용자가 보안 활성화를 별도로 해야 하는 불편 |
| 균일한 보안 | 3 | 모든 커맨드가 보안 커맨드를 호출할 수 있지만, 자동이 아니라 수동 호출이라면 실질적 보안 수준 하락 |
| DRY 오케스트레이션 | 3 | Security Triage 중복은 해결되지만, Setup/Session Protocol 중복은 유지 |
| 최소 파괴 | 4 | 기존 커맨드 삭제 없음. 추가만 있으므로 non-breaking. 단, 기존 harness/harness-team의 보안 동작이 변경되면 subtle breaking |
| 유지보수 가능 규모 | 3 | 파일 수 증가 (6개). 크로스 커맨드 의존성 추가로 복잡도 증가 |
| **합계** | **16/25** | |

**장점**: 보안 로직 중앙화. 보안 정책 변경 시 한 곳만 수정.
**단점**:
- Claude Code 슬래시 커맨드는 **다른 슬래시 커맨드를 호출하는 메커니즘이 없다**. 크로스 커맨드 호출은 사용자가 수동으로 `/harness-security`를 먼저 실행하고, 그 결과를 다음 커맨드에 전달하는 형태가 되어야 한다. 이는 UX 저하.
- 사용자가 보안 커맨드를 호출하지 않으면 보안이 적용되지 않는다. 현재 `/harness`에서 자동으로 Security Triage가 실행되는 것보다 후퇴.
- 보안은 파이프라인에 **내장**되어야 하지 **외장** 옵션이 되어서는 안 된다.

### 3.4 Option D: 구조 분리 (공유 프로토콜을 references/로 추출)

**내용**: 5개 커맨드 구조를 유지하면서, 중복 프로토콜을 `harness/references/`로 추출한다. 각 커맨드는 추출된 참조 파일을 읽어 실행한다. 동시에 description을 갱신하고, review/docs/qa에 보안 기능을 추가한다.

**변경 사항**:
- `harness/references/security-triage-protocol.md` 신규: Security Triage 로직 (현재 harness.md와 harness-team.md에 중복)
- `harness/references/auditor-gate-protocol.md` 신규: Auditor Gate 로직
- 5개 커맨드 파일 수정: 공유 프로토콜을 참조 지시문으로 교체
- 3개 커맨드(review, docs, qa)에 Security Triage 참조 추가
- description 갱신

**예상 줄 수 변화**:

| 커맨드 | 현재 | 예상 | 변화 |
|--------|------|------|------|
| `harness.md` | 794 | ~666 | -128 (Security Triage ~92줄 + Auditor ~36줄) |
| `harness-team.md` | 603 | ~507 | -96 (Security Triage ~61줄 + Auditor ~35줄) |
| `harness-review.md` | 212 | ~240 | +28 (Security Triage 참조 1줄 + 조건부 Sentinel 참조 추가) |
| `harness-docs.md` | 427 | ~450 | +23 (Security Triage 참조 + secret 노출 방지 로직) |
| `harness-qa.md` | 420 | ~445 | +25 (Security Triage 참조 + Security Test Track 신규 추가) |

| 원칙 | 점수 (1-5) | 근거 |
|------|-----------|------|
| 정확한 자기 표현 | 5 | description 갱신 + 보안 수준이 각 커맨드에 반영 |
| 균일한 보안 | 5 | 모든 커맨드에 Security Triage 적용. 코드 변경 커맨드에 Sentinel 조건부 활성화 |
| DRY 오케스트레이션 | 5 | Security Triage, Auditor Gate, Session Setup 공유 프로토콜로 추출. 변경 시 1곳만 수정 |
| 최소 파괴 | 5 | 5개 커맨드명 모두 유지. 내부 동작 강화(보안 추가)는 사용자에게 긍정적 변화 |
| 유지보수 가능 규모 | 4 | harness.md ~666줄, 모든 파일 800줄 이하. 참조 파일 2개 추가로 파일 수는 증가 |
| **합계** | **24/25** | |

**장점**:
- 모든 문제(description 불일치, 보안 불균형, 중복, 비대화, phantom 파일)를 동시에 해결
- 기존 커맨드명 유지로 breaking change 없음
- 공유 프로토콜 추출로 DRY 달성
- harness.md 크기 감소 (794 -> ~666)
- 보안이 모든 파이프라인에 **내장**됨

**단점**:
- 참조 파일이 늘어나 전체 파일 수 증가 (하지만 이미 `references/` 폴더에 5개 파일이 있으므로 패턴은 확립됨)
- 26% 중복이 "제거"가 아니라 "공유 참조로 전환"되므로, harness.md와 harness-team.md가 동일한 참조를 읽는 구조. 중복 자체는 해결되었지만, 두 커맨드가 여전히 별개 파일로 존재

### 3.5 점수 비교 매트릭스

| 원칙 | A: 설명 갱신 | B: 병합 | C: 보안 추가 | D: 구조 분리 |
|------|------------|---------|------------|------------|
| 정확한 자기 표현 | 4 | 3 | 3 | **5** |
| 균일한 보안 | 1 | 2 | 3 | **5** |
| DRY 오케스트레이션 | 1 | 4 | 3 | **5** |
| 최소 파괴 | **5** | 2 | 4 | **5** |
| 유지보수 가능 규모 | 2 | 1 | 3 | **4** |
| **합계** | **13** | **12** | **16** | **24** |

### 3.6 최종 권장안

**Option D (구조 분리)를 권장한다.** 근거:

1. **5원칙 모두에서 최고점 또는 공동 최고점**을 달성한다. 두 번째 Option C (16점)와 8점 차이.

2. **74% 고유성 문제에 대한 현실적 대응**: Option B가 추구하는 "병합"은 74%의 고유 콘텐츠 앞에서 오히려 비대화를 초래한다. Option D는 두 커맨드를 분리 유지하면서 26% 중복만 공유 참조로 해결한다. 이는 "다른 것은 다르게, 같은 것은 같게" 원칙에 부합한다.

3. **보안 불균형의 근본 해결**: Option D만이 모든 5개 커맨드에 Security Triage를 내장한다. Option C(별도 보안 커맨드)는 사용자의 수동 호출에 의존하므로 실질적 보안 수준이 떨어진다.

4. **진화 가능성**: Option D를 기반으로 향후 Option B(병합)를 추가로 적용할 수 있다. 공유 프로토콜이 추출된 상태에서 병합하면 harness.md의 추가 크기가 줄어든다. 즉, D는 B의 선행 조건이 될 수 있다.

**하이브리드 전략**: Phase 1에서 Option D를 실행하고, 사용자 피드백을 수집한 뒤, Phase 2에서 Option B(선택적)를 검토한다. 단, Phase 2는 강제가 아니라 데이터 기반 결정이다.

---

## 4. 권장 재편안 상세 설계

### 4.1 커맨드별 새 Description

```yaml
# harness.md frontmatter
description: "Autonomous build pipeline (Scout → Planner → Builder → Refiner → QA) with Security Triage + Sentinel Gate + Auditor. S/M/L scale."

# harness-team.md frontmatter
description: "Parallel multi-worker build pipeline (Scout → Architect → Workers(N) → Integrator → QA) with per-Worker Sentinel + Auditor. Wave-structured parallelism."

# harness-review.md frontmatter
description: "Code review pipeline (Scanner → Analyzer → Fixer → Verifier → Reporter) with Security Triage + conditional Sentinel. Git handoff support."

# harness-docs.md frontmatter
description: "Documentation pipeline (Researcher → Outliner → Writer → Reviewer + Validator) with Security Triage + secret-exposure guard. S/M/L scale."

# harness-qa.md frontmatter
description: "Functional QA pipeline (Scout → Scenario Writer → Test Executor → Analyst → Reporter) with Security Triage + Security Test Track. Playwright-based, 8 test modes."
```

### 4.2 plugin.json Description 갱신

현재 plugin.json description은 이미 `/harness`를 "8-agent build pipeline with Sentinel + Auditor"로, `/harness-qa`를 "functional QA with Playwright + Security Track"으로 표기하고 있다. 그러나 frontmatter와의 불일치가 있고, Phase 2 이후에는 모든 커맨드에 보안이 내장되므로 description을 아래와 같이 통합 갱신한다:

```json
{
  "description": "7 harness commands for Claude Code and Codex: /harness (build pipeline with Security Triage + Sentinel + Auditor), /harness-docs (documentation pipeline with secret-exposure guard), /harness-review (code review pipeline with conditional Sentinel), /harness-team (parallel multi-worker build with per-Worker Sentinel), /harness-qa (functional QA with Security Test Track), /design (3-dial frontend design), /claude-dashboard (statusline). 25 agent prompts with shared security protocols."
}
```

### 4.3 Phase 구조 표준화

모든 커맨드에 공통 Phase 체계를 적용한다. Phase 0.5 (Security Triage)가 모든 커맨드에 존재하는 것이 핵심이다.

#### /harness (재편 후)

```
Phase 0:   Triage (Scale S/M/L)
Phase 0.5: Security Triage → [READ references/security-triage-protocol.md]
Phase 1:   Setup → [READ references/session-protocol.md]
Phase 2:   Scout
Phase 3:   Planning (Planner + 사용자 승인)
Phase 4:   Build Loop (Builder → Sentinel → Refiner → QA → Diagnostician)
Phase 4-audit: Auditor → [READ references/auditor-gate-protocol.md]
Phase 5:   Summary
```

#### /harness-team (재편 후)

```
Phase 0:   Guard Clause + When to Use
Phase 0.5: Security Triage → [READ references/security-triage-protocol.md]
Phase 1:   Setup → [READ references/session-protocol.md]
Phase 2:   Scout
Phase 3:   Architect (+ 사용자 승인)
Phase 4:   Build Waves (Wave 1 → Wave 2 parallel → Sentinel per-Worker → Wave 3 Integrator → QA → Diagnostician)
Phase 4-audit: Auditor → [READ references/auditor-gate-protocol.md]
Phase 5:   Summary
```

#### /harness-review (재편 후)

```
Phase 0:   Guard Clause
Phase 0.5: Security Triage → [READ references/security-triage-protocol.md]
Phase 1:   Setup → [READ references/session-protocol.md]
Phase 2:   Scan (Scanner)
Phase 3:   Analyze (Analyzer)
Phase 4:   Fix (Fixer) → Sentinel → [READ sentinel-prompt.md, 조건부]
Phase 5:   Verify (Verifier)
Phase 6:   Report + Git (Reporter)
```

**변경점**: Phase 0.5 Security Triage 추가. Phase 4에서 Fixer가 코드를 수정한 뒤, sensitivity가 HIGH/MEDIUM이면 Sentinel이 수정 내용을 검증. Sentinel BLOCK 시 Fixer에게 되돌림.

#### /harness-docs (재편 후)

```
Phase 0:   Triage (Scale S/M/L)
Phase 0.5: Security Triage → [READ references/security-triage-protocol.md]
           (docs 특화: secret-exposure guard 활성화)
Phase 1:   Setup → [READ references/session-protocol.md]
Phase 2:   Research (Researcher)
Phase 3:   Outline (Outliner)
Phase 4:   Write (Writer) + Secret Scan
Phase 5:   Review + Validate (Reviewer + Validator)
```

**변경점**:
- Phase 0.5 Security Triage 추가.
- Phase 4에서 Writer가 문서를 생성한 뒤, sensitivity가 MEDIUM 이상이면 생성된 문서에서 secret/credential 패턴을 스캔. 발견 시 Writer에게 마스킹 요청.
- **Phase 구조 재편**: 현재의 Phase 4 (Write-Review Loop) + Phase 5 (Finalize) + Phase 5-post (Artifact Validation) + Phase 6 (Summary)를 재구성. 구체적으로: 기존 Phase 4 Write-Review Loop에 Secret Scan이 통합되어 새 Phase 4가 되고, 기존 Phase 5 Finalize + Phase 5-post Artifact Validation + Phase 6 Summary가 새 Phase 5 (Review + Validate + Finalize + Summary)로 통합된다. 이는 Phase 수 감소(8 → 6)를 가져오지만, 기존 Phase 5/5-post/6의 모든 동작(파일 복사, artifact 검증, 보고서 생성)은 새 Phase 5 내에서 보존된다.

#### /harness-qa (재편 후)

```
Phase 0:   Guard Clause + Mode Selection
Phase 0.5: Security Triage → [READ references/security-triage-protocol.md]
           (qa 특화: Security Test Track 신규 추가 — 현재 커맨드에 보안 기능 없음)
Phase 1:   Setup → [READ references/session-protocol.md]
Phase 2:   Scout
Phase 3:   Scenarios (Scenario Writer, Security Track 시나리오 포함 시)
Phase 4:   Execute (Test Executor)
Phase 5:   Analyze + Report (Analyst + Reporter)
```

**변경점**: Phase 0.5 Security Triage를 **신규 추가**한다. 현재 harness-qa.md 커맨드 파일에는 Security Triage, Sentinel, Auditor, Security Track에 대한 참조가 전혀 없다 (plugin.json에만 "Security Track" 표기 있음). Phase 2에서 Security Triage를 추가하고, sensitivity가 MEDIUM 이상이면 Phase 3에서 보안 테스트 시나리오(인증 우회, XSS, CSRF 등)를 자동 추가하는 Security Test Track을 **처음부터 구현**한다.

### 4.4 보안 기능 적용 매트릭스 (재편 후)

| 보안 기능 | /harness | /harness-team | /harness-review | /harness-docs | /harness-qa |
|----------|----------|--------------|----------------|--------------|------------|
| Security Triage | O | O | **O (신규)** | **O (신규)** | **O (신규)** |
| Sentinel Gate | O (Builder 후) | O (per-Worker) | **O (Fixer 후, 조건부)** | X (불필요) | X (불필요) |
| Secret Exposure Guard | X (불필요) | X (불필요) | X (불필요) | **O (신규)** | X (불필요) |
| Security Test Track | O | O | X (불필요) | X (불필요) | **O (신규 추가)** |
| Auditor Gate | O | O | X (단일 라운드) | X (문서는 감사 불필요) | X (단일 실행) |

**설계 근거**:
- Sentinel Gate는 **코드를 수정하는** 에이전트(Builder, Worker, Fixer) 이후에만 필요. Writer나 Test Executor는 코드를 수정하지 않으므로 불필요.
- Secret Exposure Guard는 **문서를 생성하는** 에이전트(Writer) 이후에만 필요. 코드 빌드 파이프라인에서는 코드 자체에 secret이 있는지를 Sentinel이 검사.
- Security Test Track은 **테스트를 생성하는** 에이전트(Scenario Writer) 단계에서 보안 시나리오를 포함시키는 것.
- Auditor Gate는 **다중 라운드 파이프라인**에서만 의미 있음. 단일 라운드(review, qa) 또는 문서 생성(docs)에서는 과도한 검증.

### 4.5 에이전트 변경 요약

| 변경 유형 | 에이전트 | 내용 |
|----------|---------|------|
| 신규 참조 | Sentinel | `/harness-review`에서 Fixer 후 조건부 호출 추가 |
| 로직 추가 | Writer (harness-docs) | Secret Exposure Guard: 생성 문서에서 credential 패턴 스캔 |
| 로직 추가 | Scenario Writer (harness-qa) | Security Triage 결과에 따라 보안 시나리오 자동 추가 |
| 변경 없음 | 나머지 22개 에이전트 | 기존 프롬프트 유지 |

---

## 5. 공유 프로토콜 추출

### 5.1 추출 대상

현재 `harness/references/`에는 5개 파일이 존재한다:
- `session-protocol.md` (450줄) -- 이미 5개 커맨드가 공유
- `security-checklist.md` -- 에이전트별 보안 체크리스트
- `error-handling-checklist.md` -- 에러 처리 체크리스트
- `confidence-calibration.md` -- 점수 기준
- `agent-containment.md` -- 에이전트 격리 규칙

여기에 2개 파일을 추가한다:

### 5.2 신규 파일 1: `references/security-triage-protocol.md`

**추출 원본**: `harness.md` Phase 0.5 (~92줄) + `harness-team.md` Phase 0.5 (~61줄)

**통합 내용**:

```markdown
# Security Triage Protocol

> 모든 harness 파이프라인에서 Phase 0.5로 실행되는 보안 민감도 분류 프로토콜.

## 적용 대상

| 파이프라인 | Security Triage | 후속 조치 |
|-----------|----------------|----------|
| /harness | O | Sentinel Gate + QA Security Track + Auditor |
| /harness-team | O | per-Worker Sentinel + QA Security Track + Auditor |
| /harness-review | O | conditional Sentinel (Fixer 후) |
| /harness-docs | O | Secret Exposure Guard (Writer 후) |
| /harness-qa | O | Security Test Track (시나리오 추가) |

## Classification

### HIGH sensitivity (any match triggers HIGH)
- Authentication/Authorization: auth, login, password, token, jwt, session, permissions, role, RBAC, admin, sudo
- Financial: payment, billing, stripe, credit, invoice, transaction
- Cryptography: crypto, encrypt, decrypt, key, certificate, hash, salt
- Data privacy: PII, GDPR, personal data, email, phone, address
- Infrastructure: infra, deploy, CI/CD, pipeline, docker, k8s, terraform
- Secrets: .env, secret, credential, API key

### MEDIUM sensitivity (if no HIGH keywords)
- API: endpoint, route, middleware, controller, handler
- Data: database, schema, migration, query, model
- Network: CORS, header, cookie, webhook, external, integration
- File handling: upload, download, file, stream

### LOW sensitivity (if no HIGH or MEDIUM keywords)
- UI: component, style, CSS, layout, animation, color, font
- Docs: README, docs, comment, typo, format
- Quality: lint, test, refactor (UI-only), i18n

## Write Triage Result

cat > .harness/security-triage.md << 'HEREDOC'
# Security Triage
- sensitivity: {HIGH/MEDIUM/LOW}
- keywords_matched: [{list}]
- sentinel_active: {true/false}
- secret_guard_active: {true/false}
- security_test_track: {true/false}
- auditor_active: {true/false}
HEREDOC

## Activation Rules (파이프라인별)

### /harness
- HIGH → sentinel: true, security_track: true, auditor: true
- MEDIUM → sentinel: {true if Scale L}, security_track: true, auditor: {true if Scale M/L}
- LOW → sentinel: false, security_track: false, auditor: false

### /harness-team (always Scale L)
- HIGH → sentinel: true, security_track: true, auditor: true
- MEDIUM → sentinel: true, security_track: true, auditor: false
- LOW → sentinel: false, security_track: false, auditor: false

### /harness-review
- HIGH → sentinel: true (Fixer 후)
- MEDIUM → sentinel: false
- LOW → sentinel: false

### /harness-docs
- HIGH → secret_guard: true
- MEDIUM → secret_guard: true
- LOW → secret_guard: false

### /harness-qa
- HIGH → security_test_track: true
- MEDIUM → security_test_track: true
- LOW → security_test_track: false

## Post-Scout Re-evaluation

After Scout completes, check identified files:
- auth/, payment/, security/, .env, credential → upgrade to HIGH
- api/, routes/, middleware/, model/ → upgrade to at least MEDIUM
- Update .harness/security-triage.md and notify user if changed
```

**예상 줄 수**: ~90줄

### 5.3 신규 파일 2: `references/auditor-gate-protocol.md`

**추출 원본**: `harness.md` Phase 4-audit (~40줄) + `harness-team.md` Phase 4-audit (~35줄)

**통합 내용**:

```markdown
# Auditor Gate Protocol

> 다중 라운드 파이프라인에서 최종 교차검증을 수행하는 Auditor 에이전트 호출 규칙.

## 활성화 조건

Auditor는 `.harness/security-triage.md`에서 `auditor_active: true`일 때만 실행된다.

| 파이프라인 | Auditor 적용 | 조건 |
|-----------|-------------|------|
| /harness | O | auditor_active == true (MEDIUM+Scale M/L 또는 HIGH) |
| /harness-team | O | auditor_active == true (HIGH) |
| /harness-review | X | 단일 라운드, 감사 불필요 |
| /harness-docs | X | 문서 생성, 감사 불필요 |
| /harness-qa | X | 테스트 실행, 감사 불필요 |

## 실행 방법

1. Read auditor prompt: `~/.claude/harness/auditor-prompt.md`
2. Auditor에게 전달할 artifact 경로 (파이프라인별):
   - /harness: build-spec.md, build-progress.md, build-refiner-report.md, build-round-{1..N}-feedback.md, traces/, sentinel-report-round-{1..N}.md, build-history.md
   - /harness-team: team-plan.md, team-worker-{0..N}-progress.md, team-integration-report.md, team-round-{1..R}-feedback.md, sentinel-worker-{i}-round-{R}.md, team-history.md
3. Auditor 보고서 작성: `.harness/auditor-report.md`
4. BLOCK 판정 시: 사용자에게 보고하고 추가 라운드 실행 여부 확인
```

**예상 줄 수**: ~50줄

### 5.4 추출 매핑

| 원본 파일 | 추출되는 섹션 | 추출 대상 파일 | 줄 수 감소 |
|----------|-------------|--------------|-----------|
| `harness.md` | Phase 0.5 Security Triage | `references/security-triage-protocol.md` | ~92줄 |
| `harness.md` | Phase 4-audit Auditor 호출 규칙 | `references/auditor-gate-protocol.md` | ~36줄 |
| `harness-team.md` | Phase 0.5 Security Triage | (동일 참조) | ~61줄 |
| `harness-team.md` | Phase 4-audit Auditor 호출 규칙 | (동일 참조) | ~35줄 |

### 5.5 커맨드에서의 참조 방식

추출 후, 각 커맨드 파일에서는 해당 섹션을 다음 한 줄로 대체한다:

```markdown
## Phase 0.5: Security Triage

Read and execute the security triage protocol: `~/.claude/harness/references/security-triage-protocol.md`

Apply the activation rules for THIS pipeline (/harness).
Then proceed to Phase 1.
```

```markdown
## Phase 4-audit: Auditor Gate

Read and execute the auditor gate protocol: `~/.claude/harness/references/auditor-gate-protocol.md`

Apply with THIS pipeline's artifact paths.
```

이 패턴은 이미 `session-protocol.md` 참조에서 확립되어 있으므로, 기존 패턴과 일관된다.

### 5.6 참조 파일 전체 구조 (재편 후)

```
harness/
├── references/
│   ├── session-protocol.md            (기존, 450줄)
│   ├── security-checklist.md          (기존)
│   ├── error-handling-checklist.md    (기존)
│   ├── confidence-calibration.md      (기존)
│   ├── agent-containment.md           (기존)
│   ├── security-triage-protocol.md    (신규, ~90줄)
│   └── auditor-gate-protocol.md       (신규, ~50줄)
├── scout-prompt.md
├── planner-prompt.md
├── builder-prompt.md
├── sentinel-prompt.md
├── refiner-prompt.md
├── qa-prompt.md
├── diagnostician-prompt.md
├── auditor-prompt.md
├── architect-prompt.md
├── worker-prompt.md
├── integrator-prompt.md
├── scanner-prompt.md
├── analyzer-prompt.md
├── fixer-prompt.md
├── verifier-prompt.md
├── reporter-prompt.md
├── researcher-prompt.md
├── outliner-prompt.md
├── writer-prompt.md
├── reviewer-prompt.md
├── validator-prompt.md
├── scenario-writer-prompt.md
├── test-executor-prompt.md
├── analyst-prompt.md
├── qa-reporter-prompt.md
├── linter-prompt.md            (dev tool — see note below)
└── INDEX.md
```

> **Note**: `harness/linter-prompt.md`는 26번째 파일로 존재하지만, `/harness-lint` dev 커맨드(`dev/` 카테고리)를 위한 개발 도구이다. INDEX.md의 Agent Catalog에 포함되지 않으며, 어떤 커맨드 파일에서도 참조하지 않는다. 본 문서의 "25 unique prompts" 카운트는 파이프라인 에이전트만 포함하며, linter-prompt.md는 의도적으로 제외한다. 향후 정리 시 dev/ 카테고리로의 이동 또는 INDEX.md에 dev tool 섹션 추가를 검토한다.

---

## 6. Codex Mirror 정리 계획

### 6.1 Phantom 파일 처분

| Phantom 파일 | 현재 상태 | 조치 |
|-------------|----------|------|
| `codex-skills/harness-review/references/sentinel-prompt.md` | 미사용 | Phase 1: 삭제 (review에 Sentinel 추가 전) → Phase 2: 부활 (review에 Sentinel 활성화 후) |
| `codex-skills/harness-review/references/auditor-prompt.md` | 미사용 | **삭제** (review에 Auditor 적용 없음) |
| `codex-skills/harness-docs/references/sentinel-prompt.md` | 미사용 | **삭제** (docs에 Sentinel 적용 없음, Secret Guard는 별도) |
| `codex-skills/harness-docs/references/auditor-prompt.md` | 미사용 | **삭제** (docs에 Auditor 적용 없음) |
| `codex-skills/harness-qa/references/sentinel-prompt.md` | 미사용 | **삭제** (qa에 Sentinel 적용 없음) |
| `codex-skills/harness-qa/references/auditor-prompt.md` | 미사용 | **삭제** (qa에 Auditor 적용 없음) |

**최종 결과**: 6개 phantom 중 5개 삭제, 1개(harness-review sentinel)는 Phase 2에서 정당화됨.

### 6.2 신규 Codex Mirror 추가

공유 프로토콜 파일을 Codex mirror에도 반영해야 한다.

| 신규 원본 | Mirror 대상 |
|----------|------------|
| `harness/references/security-triage-protocol.md` | 5개 파이프라인 모두의 `references/`에 복사 |
| `harness/references/auditor-gate-protocol.md` | `codex-skills/harness/references/`와 `codex-skills/harness-team/references/`에만 복사 |

### 6.3 Mirror 동기화 규칙 (재정의)

```
규칙 1: Codex mirror에는 해당 파이프라인이 실제로 참조하는 파일만 존재해야 한다.
규칙 2: 공유 프로토콜(references/)은 사용하는 파이프라인의 mirror에만 복사한다.
규칙 3: 에이전트 프롬프트는 해당 파이프라인의 INDEX.md Agent Catalog 기준으로 결정한다.
규칙 4: phantom 파일 감지 스크립트: INDEX.md의 에이전트 목록과 codex-skills/{pipeline}/references/ 파일 목록을 비교.
```

### 6.4 동기화 검증 매트릭스

| 파이프라인 | 프롬프트 파일 | 참조 파일 | 총 mirror 파일 |
|-----------|-------------|----------|--------------|
| harness | 8 (scout, planner, builder, sentinel, refiner, qa, diagnostician, auditor) | 2 (security-triage-protocol, auditor-gate-protocol) + 기존 5 | 15 |
| harness-team | 8 (scout, architect, worker, sentinel, integrator, qa, diagnostician, auditor) | 2 + 기존 5 | 15 |
| harness-review | 5 (scanner, analyzer, fixer, verifier, reporter) + 1 (sentinel, Phase 2부터) | 1 (security-triage-protocol) + 기존 5 | 12 |
| harness-docs | 5 (researcher, outliner, writer, reviewer, validator) | 1 (security-triage-protocol) + 기존 5 | 11 |
| harness-qa | 5 (scout, scenario-writer, test-executor, analyst, qa-reporter) | 1 (security-triage-protocol) + 기존 5 | 11 |

> **Note**: 현재 harness mirror는 13 파일(8 prompts + 5 refs). Phase 1에서 2개 신규 프로토콜 추가 후 15 파일. 기존 5 refs = session-protocol, security-checklist, error-handling-checklist, confidence-calibration, agent-containment.

---

## 7. 구현 로드맵

### Phase 1: 공유 프로토콜 추출 + Description 갱신 + Phantom 정리

**목표**: DRY 달성 + 정확한 표현 + phantom 제거
**예상 소요**: 1 세션
**Breaking Changes**: 없음

| 단계 | 파일 | 변경 유형 | 내용 |
|------|------|----------|------|
| 1-1 | `harness/references/security-triage-protocol.md` | 신규 | Security Triage 공유 프로토콜 작성 |
| 1-2 | `harness/references/auditor-gate-protocol.md` | 신규 | Auditor Gate 공유 프로토콜 작성 |
| 1-3 | `commands/harness.md` | 수정 | Phase 0.5를 참조로 교체, Phase 4-audit를 참조로 교체, description 갱신 |
| 1-4 | `commands/harness-team.md` | 수정 | Phase 0.5를 참조로 교체, Phase 4-audit를 참조로 교체, description 갱신 |
| 1-5 | `commands/harness-review.md` | 수정 | description 갱신 (보안 추가는 Phase 2) |
| 1-6 | `commands/harness-docs.md` | 수정 | description 갱신 (보안 추가는 Phase 2) |
| 1-7 | `commands/harness-qa.md` | 수정 | description 갱신 (보안 추가는 Phase 2) |
| 1-8 | `.claude-plugin/plugin.json` | 수정 | description 갱신 |
| 1-9 | `harness/INDEX.md` | 수정 | Shared Reference 섹션에 신규 파일 추가 |
| 1-10 | `codex-skills/harness-review/references/auditor-prompt.md` | 삭제 | phantom |
| 1-11 | `codex-skills/harness-docs/references/sentinel-prompt.md` | 삭제 | phantom |
| 1-12 | `codex-skills/harness-docs/references/auditor-prompt.md` | 삭제 | phantom |
| 1-13 | `codex-skills/harness-qa/references/sentinel-prompt.md` | 삭제 | phantom |
| 1-14 | `codex-skills/harness-qa/references/auditor-prompt.md` | 삭제 | phantom |

**Phase 1 검증**:
- harness.md 줄 수 < 700 확인 (예상 ~666줄)
- harness-team.md 줄 수 < 520 확인 (예상 ~507줄)
- 5개 phantom 삭제 확인
- `/harness` 실행 테스트: Security Triage가 참조 파일에서 읽혀 정상 작동하는지

### Phase 2: 보안 기능 균일 적용

**목표**: 모든 커맨드에 Security Triage 내장 + 파이프라인별 보안 기능 추가
**예상 소요**: 1-2 세션
**Breaking Changes**: 없음 (보안 기능 추가는 기능 강화)

| 단계 | 파일 | 변경 유형 | 내용 |
|------|------|----------|------|
| 2-1 | `commands/harness-review.md` | 수정 | Phase 0.5 Security Triage 참조 추가 + Phase 4에 Sentinel 조건부 호출 추가 |
| 2-2 | `commands/harness-docs.md` | 수정 | Phase 0.5 Security Triage 참조 추가 + Phase 4에 Secret Exposure Guard 추가 |
| 2-3 | `commands/harness-qa.md` | 수정 | Phase 0.5 Security Triage 참조 신규 추가 + Phase 3에 Security Test Track 신규 구현 (현재 커맨드에 보안 기능 전무) |
| 2-4 | `harness/INDEX.md` | 수정 | Sentinel의 "Used By" 목록에 `/harness-review` 추가 |
| 2-5 | `codex-skills/harness-review/references/sentinel-prompt.md` | 유지 | Phase 2에서 정당화됨 (phantom 해소) |
| 2-6 | Codex mirror 신규 | 추가 | 5개 파이프라인에 security-triage-protocol.md mirror 복사 |
| 2-7 | Codex mirror 신규 | 추가 | harness, harness-team에 auditor-gate-protocol.md mirror 복사 |

**Phase 2 검증**:
- `/harness-review --dry-run`에서 Security Triage 출력 확인
- `/harness-docs`에서 API 키가 포함된 문서 생성 시 Secret Guard 경고 확인
- `/harness-qa`에서 로그인 관련 테스트 시 보안 시나리오 자동 포함 확인

### Phase 3 (선택적, 향후): /harness + /harness-team 병합 검토

**전제조건**:
- Phase 1, 2 완료 후 최소 2주간 사용
- 사용 패턴 데이터 수집: 사용자가 실제로 두 커맨드를 혼동하거나 잘못 선택하는 빈도
- 공유 프로토콜 추출 후 harness.md 크기가 ~666줄이므로, team 고유 콘텐츠 ~440줄을 더하면 ~1,106줄. 여전히 800줄 초과.

**결정 기준**:
- 혼동 빈도가 높고, 커맨드 크기 문제를 해결할 수 있는 방법(예: Phase 4를 별도 참조 파일로 추출)이 있으면 병합 진행
- 그렇지 않으면 현행 유지 (2 커맨드 분리가 더 명확)

**이 Phase는 강제가 아니라 데이터 기반 결정이다.**

### 파일 변경 매트릭스 (Phase 1 + Phase 2 합산)

| 파일 | Phase 1 | Phase 2 | 변경 유형 |
|------|---------|---------|----------|
| `references/security-triage-protocol.md` | 신규 | -- | 신규 |
| `references/auditor-gate-protocol.md` | 신규 | -- | 신규 |
| `commands/harness.md` | 수정 | -- | description + 참조 교체 |
| `commands/harness-team.md` | 수정 | -- | description + 참조 교체 |
| `commands/harness-review.md` | 수정 | 수정 | description → 보안 추가 |
| `commands/harness-docs.md` | 수정 | 수정 | description → 보안 추가 |
| `commands/harness-qa.md` | 수정 | 수정 | description → 보안 추가 |
| `.claude-plugin/plugin.json` | 수정 | -- | description |
| `harness/INDEX.md` | 수정 | 수정 | 참조 추가 → 에이전트 매핑 |
| `codex-skills/*/references/` | 삭제 5개 | 추가 7개 | phantom 제거 → mirror 추가 |
| **총 변경 파일** | **14** | **9** | |

---

## 8. 마이그레이션 가이드

### 8.1 기존 사용자 영향 분석

| 변경 | Breaking? | 사용자 영향 |
|------|-----------|-----------|
| Description 갱신 | No | Marketplace에서 더 정확한 설명 확인 가능 |
| 공유 프로토콜 추출 (Phase 1) | No | 내부 구조 변경. 사용자 호출 패턴 동일. 동작도 동일. |
| Phantom 파일 삭제 (Phase 1) | No | Codex 사용자에게도 영향 없음 (파일이 참조되지 않았으므로) |
| review/docs/qa에 Security Triage 추가 (Phase 2) | No (기능 강화) | 새로운 Phase 0.5가 추가되어 보안 민감도가 표시됨. 기존에 없던 기능이므로 비파괴적. LOW sensitivity에서는 추가 동작 없음. |
| review에 Sentinel 추가 (Phase 2) | Subtle change | Fixer가 수정한 코드에 보안 문제가 있으면 Sentinel이 BLOCK할 수 있음. 기존에는 무조건 통과했던 수정이 차단될 수 있음. **이는 의도된 동작이며 보안 강화임.** |
| docs에 Secret Guard 추가 (Phase 2) | Subtle change | Writer가 생성한 문서에 secret 패턴이 있으면 마스킹 요청이 추가됨. 기존에는 그대로 노출됐으므로 **보안 개선.** |
| qa에 Security Test Track 신규 추가 (Phase 2) | Subtle change | 보안 관련 테스트 대상에서 보안 시나리오가 자동 추가됨. 테스트 수 증가. **품질 향상.** 현재 harness-qa.md에는 보안 기능이 전혀 없으므로, 이는 기존 기능의 활성화가 아닌 완전한 신규 추가이다. |

### 8.2 하위 호환성 전략

**원칙**: "모든 기존 호출이 동일하게 작동하되, 보안이 강화된다."

1. **커맨드명 유지**: 5개 커맨드 이름이 모두 동일. `/harness`, `/harness-team`, `/harness-review`, `/harness-docs`, `/harness-qa`.

2. **인자 유지**: 모든 기존 인자(`--dry-run`, `--commit`, `--push`, `--pr`, `--agents N`, `--mode`)가 동일하게 작동.

3. **Artifact 경로 유지**: `.harness/build-*.md`, `.harness/team-*.md`, `.harness/review-*.md`, `.harness/docs-*.md`, `.harness/qa-*.md` 경로가 모두 동일. `security-triage.md`만 신규 추가.

4. **보안 추가의 투명성**: LOW sensitivity 작업(UI 수정, typo 수정, CSS 변경 등)에서는 Security Triage가 실행되지만 모든 보안 기능이 비활성화되므로, 기존 동작과 사실상 동일. MEDIUM/HIGH sensitivity 작업에서만 추가 보안 게이트가 작동.

### 8.3 버전 전략

| Phase | 버전 | Changelog |
|-------|------|-----------|
| Phase 1 | v3.6.0 | feat: extract shared security/auditor protocols to references. fix: correct agent counts in descriptions. chore: remove 5 phantom Codex files |
| Phase 2 | v4.0.0 | feat: uniform Security Triage across all 5 harness commands. feat: Sentinel Gate for harness-review. feat: Secret Exposure Guard for harness-docs. feat: Security Test Track (new) for harness-qa |

**Phase 2를 v4.0.0으로 하는 이유**: 보안 동작이 추가되어 기존 MEDIUM/HIGH sensitivity 작업의 실행 흐름이 변경된다. Semantic Versioning에서 새로운 동작의 도입은 minor로 볼 수 있지만, 보안 BLOCK이라는 사용자 경험 변화가 있으므로 major로 올리는 것이 보수적이고 안전하다. 사용자가 "v4.0.0부터 보안이 강화되었다"는 것을 명확히 인지할 수 있다.

### 8.4 롤백 계획

만약 Phase 2 적용 후 문제가 발생하면:

1. **Security Triage 비활성화**: `security-triage-protocol.md`에서 해당 파이프라인의 activation rules를 모두 false로 변경. 공유 프로토콜 덕분에 한 파일만 수정하면 5개 파이프라인 모두에 적용.

2. **Phase 1으로 롤백**: Phase 2 변경사항만 revert. Phase 1의 공유 프로토콜 추출과 description 갱신은 유지 (이들은 비파괴적).

3. **전체 롤백**: git revert로 v3.5.0으로 복원. 모든 변경 원복.

---

## 부록: 체크리스트

### 구현 전 확인

- [ ] `harness/references/` 디렉토리 존재 확인
- [ ] 기존 5개 참조 파일 무결성 확인
- [ ] INDEX.md 현재 상태 백업

### Phase 1 완료 확인

- [ ] `security-triage-protocol.md` 작성 완료
- [ ] `auditor-gate-protocol.md` 작성 완료
- [ ] `harness.md` 줄 수 < 700 (예상 ~666줄)
- [ ] `harness-team.md` 줄 수 < 520 (예상 ~507줄)
- [ ] 5개 description 갱신 완료
- [ ] `plugin.json` description 갱신 완료
- [ ] 5개 phantom 파일 삭제 완료
- [ ] INDEX.md 업데이트 완료
- [ ] `/harness` 실행 테스트 통과

### Phase 2 완료 확인

- [ ] 3개 커맨드에 Phase 0.5 Security Triage 추가 완료
- [ ] `/harness-review` Sentinel 조건부 호출 추가 완료
- [ ] `/harness-docs` Secret Exposure Guard 추가 완료
- [ ] `/harness-qa` Security Test Track 신규 추가 완료
- [ ] Codex mirror 7개 파일 추가 완료
- [ ] INDEX.md Sentinel "Used By" 업데이트 완료
- [ ] 5개 커맨드 모두 실행 테스트 통과
