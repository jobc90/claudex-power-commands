# jobc-power-commands

> [Claude Code](https://claude.ai/code)용 파워 커맨드 5종 플러그인

코드 리뷰, 팀 오케스트레이션, 대규모 자동화, 체계적 문서화, 프론트엔드 디자인을 슬래시 커맨드 하나로 실행합니다.

---

## 한눈에 보기

```
/check  — 코드 작성 끝 → 리뷰 → 수정 → 검증 → 커밋 → 푸시 (5분)
/cowork — 큰 작업 → 에이전트 팀 분배 → 병렬 구현 → 취합 → 검증 (15분)
/super  — 아이디어 → 기획 → 구현 → 리뷰 → 배포 → 문서화 (30분+)
/docs   — 문서 유형 자동 판별 → 리서치 → 구조화 → 작성 → 검수 (10분)
/design — 3-다이얼(V/M/D) + 프리셋으로 프론트엔드 디자인 품질 제어
```

### Codex 버전

이 저장소에는 `Claude Code`용 slash command 원본과, `Codex`용 skill 포트가 함께 들어 있습니다.

- Claude Code 원본: `commands/`
- Codex 포트: `codex-skills/`

Codex에서는 slash command 대신 아래처럼 스킬을 부릅니다:

```text
Use $check ...
Use $cowork ...
Use $super ...
Use $docs ...
```

### 언제 뭘 쓸까?

| 상황 | 커맨드 | 예시 |
|------|--------|------|
| 코드 다 짰고, 커밋하기 전 | `/check` | `/check --pr` |
| 파일 5개 이상 동시 수정 | `/cowork` | `/cowork 결제 환불 기능 추가` |
| 새 기능을 처음부터 끝까지 | `/super` | `/super 로그인에 2FA 추가` |
| 문서 작성/갱신/정리 | `/docs` | `/docs 프로젝트 전체 문서화` |
| 프론트엔드 UI 만들기 | `/design` | `/design --soft SaaS 랜딩페이지` |

---

## /check — 병렬 코드 리뷰 + 자동 수정 + 배포

변경 코드를 **5개 에이전트가 동시에** 리뷰합니다. CRITICAL/HIGH 이슈는 자동 수정하고, 빌드 검증 후 커밋+푸시합니다.

### 5개 에이전트

| 에이전트 | 검사 영역 |
|---------|---------|
| code-reviewer | 네이밍, DRY, 복잡도, 에러 핸들링 |
| code-simplifier | 불필요한 추상화, 중복 로직, 더 단순한 대안 |
| silent-failure-hunter | 빈 catch, 무시된 반환값, 미처리 Promise |
| type-design-analyzer | 불안전 `as`/`any`, 누락 제네릭, 약한 타입 |
| security-review | CWE Top 25 + STRIDE 위협 모델링 |

### 실행 흐름

```
변경 파일 수집 → 5 에이전트 동시 리뷰 → 자동 수정 → 빌드+린트+테스트 → 커밋 → 푸시
```

### 사용법

```bash
/check              # 리뷰 → 수정 → 검증 → 커밋 → 푸시
/check --dry-run    # 리뷰 결과만 보기 (수정/커밋 안 함)
/check --pr         # 푸시 후 GitHub PR도 생성
```

---

## /cowork — 지휘자 + Agent Teams 병렬 오케스트레이션

지휘자(Conductor)가 코드베이스를 파악하고, 작업을 에이전트 팀에 분배합니다.

**핵심 규칙:** 지휘자는 코드를 한 줄도 쓰지 않습니다. 정찰 → 계획 → 분배 → 취합 → 검증만.

### 5단계 실행

| Phase | 역할 | 활용 커맨드/도구 |
|-------|------|----------------|
| **1. 정찰** | 코드베이스 구조 파악 | Explore 에이전트 + code-architect |
| **2. 계획** | 작업을 독립 단위로 분할 | PM 커맨드 (/write-prd, /write-stories, /test-scenarios) |
| **3. 분배** | Wave별 에이전트 동시 호출 | Agent 도구 병렬 실행 |
| **4. 취합** | 충돌 확인 + 병합 | git diff + Edit |
| **5. 검증** | 빌드 + 린트 + 테스트 | 빌드 시스템 자동 감지 |

### Wave 구조

```
Wave 1 (순차): 공유 타입, 인터페이스, 유틸리티
Wave 2 (병렬): 데이터 레이어 / UI 컴포넌트 / 테스트
Wave 3 (순차): import 정리, 미사용 코드 제거
```

### 사용법

```bash
/cowork 결제 모듈에 환불 기능 추가
/cowork --agents 4 대규모 리팩토링
```

---

## /super — 기획 → 구현 → 리뷰 → 배포 전자동 파이프라인

아이디어 한 줄에서 배포까지. `/cowork`(병렬 구현) + `/check`(리뷰+배포) + `/design`(디자인 품질)을 조합한 풀 파이프라인.

**원칙:** CRITICAL 보안 이슈에서만 중단. 그 외에는 끝까지.

### 6단계 파이프라인

| 단계 | 역할 | 활용 커맨드/도구 |
|------|------|----------------|
| **DISCOVER** | 요구사항 구조화 | /write-prd, /write-stories, /pre-mortem, /strategy |
| **PLAN** | 구현 계획 + 작업 분할 + design.md 수집 | Explore, code-architect, /prioritize-features, /test-scenarios |
| **BUILD** | 병렬 구현 (/cowork + /design 연동) | Agent Teams, Wave 분배, 디자인 규칙 주입 |
| **CHECK** | 5-angle 리뷰 + 디자인 품질 체크 | 5+1 에이전트 리뷰, 빌드/린트/테스트 |
| **SHIP** | 커밋 + 푸시 + PR | git, gh CLI |
| **DOCUMENT** | 릴리즈 노트 + 문서 갱신 | /sprint, /revise-claude-md, /sync-docs |

### design.md 자동 감지

프로젝트에 디자인 시스템 파일(`design.md`, `designsystem.md`, `*DESIGN*.md` 등)이 있으면 `--design` 플래그 없이도 디자인 규칙이 자동 적용됩니다. `--design <프리셋>`으로 명시 지정하면 자동 감지보다 우선합니다.

### 사용법

```bash
# 기본 (디자인 없이)
/super 로그인에 2FA 추가
/super --pr 결제 모듈 리팩토링

# 디자인 명시 지정
/super --design landing 기획서 기반 서비스 구현
/super --design dashboard --pr 관리자 대시보드

# design.md 자동 감지 (가장 편한 방법)
/design init                    # 최초 1회 — design.md 생성
/super 서비스 전체 구현해줘      # design.md 자동 감지
/super 디자인 리팩토링해줘       # 리디자인도 동일
```

---

## /docs — 체계적 문서화 파이프라인

문서 유형을 **자동 판별**하고, 소스(코드/git/기존 문서)에서 사실을 추출하여 체계적으로 작성합니다.

**핵심 규칙:** 추측 금지. 확인 불가한 정보는 `[TODO]`로 표시. 최종 산출물은 문법 검수 통과.

### 10가지 문서 유형 자동 감지

| 유형 | 트리거 | 활용 커맨드 |
|------|--------|-----------|
| PRD | "기획", "요구사항" | /write-prd, /write-stories |
| 기술 문서 | "아키텍처", "설계" | Explore, code-architect |
| README | "시작하기", "설치" | Explore + 코드 분석 |
| 릴리즈 노트 | "배포", "changelog" | /sprint + git log |
| 회의록 | "회의", "미팅" | /meeting-notes |
| 인터뷰 요약 | "인터뷰", "고객 조사" | /interview |
| 전략 문서 | "전략", "GTM" | /strategy |
| 운영 문서 | "runbook", "배포 가이드" | Explore + 코드 분석 |
| 프로젝트 문서화 | "전체 문서화" | 전체 커맨드 조합 |
| 교정/개선 | "교정", "리뷰" | /proofread |

### 6단계 파이프라인

```
DETECT → RESEARCH → STRUCTURE → DRAFT → REVIEW → DELIVER
```

### 사용법

```bash
/docs 이 프로젝트 README 작성해줘
/docs --type prd 결제 모듈 기능 기획
/docs 지난 회의 트랜스크립트 정리해줘
/docs --dry-run 아키텍처 문서 구조만 잡아줘
/docs 프로젝트 전체 문서화
```

---

## /design — 프론트엔드 디자인 품질 제어

3개 다이얼로 디자인 톤을 제어합니다. [taste-skill](https://github.com/Leonxlnx/taste-skill) 생태계를 통합 진입점 하나로 활용합니다.

### /design init — 디자인 시스템 생성/업데이트

```bash
/design init
# → 디자인 시스템 파일 있으면: 업데이트 모드 ("더 화려하게", "프리셋 변경" 등)
# → 파일 없음 + 코드 있으면: 리디자인 모드 (스캔 → 감사 → 목표)
# → 파일 없음 + 코드 없음: 새 프로젝트 모드 (용도 질문 → 생성)
```

`design.md`, `designsystem.md`, `BENEEDS_DESIGN_SYSTEM.md` 등 커스텀 이름도 자동 감지합니다.

### 3-다이얼 시스템

| 다이얼 | 1-3 | 4-7 | 8-10 |
|--------|-----|-----|------|
| **VARIANCE** (레이아웃) | 정돈된 그리드 | 오프셋, 겹침 | 비대칭, 넓은 여백 |
| **MOTION** (애니메이션) | hover 정도 | 페이드인, 스크롤링 | 마그네틱, 스프링 물리 |
| **DENSITY** (채움도) | 럭셔리, 여유 | 일반 앱 수준 | 대시보드, 빽빽함 |

### 프리셋 — 스타일명 또는 용도명

| 스타일명 | 용도명 | V | M | D | 용도 |
|---------|--------|---|---|---|------|
| (기본) | — | 8 | 6 | 4 | 범용 프론트엔드 |
| `--soft` | `--landing` | 7 | 8 | 3 | 랜딩, SaaS |
| `--soft` | `--portfolio` | 8 | 7 | 2 | 포트폴리오 |
| `--minimal` | `--workspace` | 4 | 3 | 5 | 워크스페이스, 에디토리얼 |
| `--brutal` | `--dashboard` | 6 | 2 | 8 | 대시보드, 데이터 헤비 |
| — | `--admin` | 2 | 3 | 9 | 관리자 패널 |
| `--redesign` | `--redesign` | (분석) | (분석) | (분석) | 기존 사이트 업그레이드 |

### 사용법

```bash
# design.md 생성 (최초 1회)
/design init

# 용도명으로 바로 사용 (직관적)
/design --landing SaaS 랜딩페이지
/design --dashboard 실시간 모니터링
/design --workspace 팀 협업 도구
/design --admin 관리자 패널

# 커스텀 다이얼
/design --v 8 --m 7 --d 2 럭셔리 브랜드 랜딩

# 리디자인
/design --redesign 디자인 업그레이드
```

---

## 설치

```bash
# 1. Clone
git clone https://github.com/jobc90/jobc-power-commands.git

# 2. 커맨드 복사
cp jobc-power-commands/commands/*.md ~/.claude/commands/

# 3. (선택) 플러그인 카탈로그 규칙 복사
cp jobc-power-commands/rules/*.md ~/.claude/rules/

# 4. 확인 — 새 세션에서
#    /check, /cowork, /super, /docs, /design 이 슬래시 커맨드로 보이면 성공
```

### Codex 설치

```bash
# 1. Clone
git clone https://github.com/jobc90/jobc-power-commands.git

# 2. Codex skill 디렉토리 생성
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills"

# 3. Codex skill 복사
cp -R jobc-power-commands/codex-skills/check "${CODEX_HOME:-$HOME/.codex}/skills/"
cp -R jobc-power-commands/codex-skills/cowork "${CODEX_HOME:-$HOME/.codex}/skills/"
cp -R jobc-power-commands/codex-skills/super "${CODEX_HOME:-$HOME/.codex}/skills/"
cp -R jobc-power-commands/codex-skills/docs "${CODEX_HOME:-$HOME/.codex}/skills/"

# 4. 확인 — 새 Codex 세션에서
#    $check, $cowork, $super, $docs 를 명시하거나 관련 작업을 요청
```

### Codex 사용 예시

```text
Use $check on the current diff.
Use $check --pr after verification passes.
Use $cowork --agents 4 for this refactor.
Use $super --skip-discover because the PRD already exists.
Use $docs to create a README for this project.
Use $docs --type prd for the payment module feature.
Use $docs --dry-run to outline architecture documentation.
```

### Codex 포트 차이점

- slash command가 아니라 skill 기반이다.
- commit/push/PR은 기본 자동 실행이 아니라, 명시적으로 요청했을 때만 수행한다.
- `cowork`, `super`는 병렬 에이전트가 유효한 경우에만 delegation을 사용하고, 아니면 같은 파이프라인을 단일 세션으로 축소 실행한다.
- 검증 없는 완료 선언을 막기 위해 "검증 증거 없이 완료 선언 금지" 규칙을 기본 반영했다.
- `docs`는 문서 작업에서 shell 사용을 최소화하고, 실제 설치된 Codex 스킬 이름(`create-prd`, `user-stories`, `release-notes` 등)에 맞춰 라우팅한다.

### 삭제

```bash
# Claude Code
rm ~/.claude/commands/{check,cowork,super,docs,design}.md
rm ~/.claude/rules/plugins-catalog.md

# Codex
rm -rf "${CODEX_HOME:-$HOME/.codex}"/skills/{check,cowork,super,docs}
```

### 업데이트

```bash
cd jobc-power-commands && git pull

# Claude Code
cp commands/*.md ~/.claude/commands/
cp rules/*.md ~/.claude/rules/

# Codex
cp -R codex-skills/check "${CODEX_HOME:-$HOME/.codex}/skills/"
cp -R codex-skills/cowork "${CODEX_HOME:-$HOME/.codex}/skills/"
cp -R codex-skills/super "${CODEX_HOME:-$HOME/.codex}/skills/"
cp -R codex-skills/docs "${CODEX_HOME:-$HOME/.codex}/skills/"
```

---

## 의존성 (선택)

이 플러그인은 **단독으로도 동작**합니다. 아래 플러그인이 있으면 더 강력합니다:

| 플러그인 | 필수 여부 | 역할 | 없으면? |
|---------|---------|------|--------|
| [Claude Forge](https://github.com/sangrokjung/claude-forge) | 권장 | verification-engine, /plan, /tdd, /sync-docs | 기본 빌드/테스트로 대체 |
| [claude-plugins-official](https://github.com/anthropics/claude-plugins-official) | 권장 | pr-review-toolkit (6 에이전트), feature-dev, code-simplifier | 에이전트 수 감소 (5→1) |
| [pm-skills](https://github.com/phuryn/pm-skills) | 선택 | write-prd, write-stories, pre-mortem, test-scenarios, release-notes | PM 단계 생략, 바로 구현 |
| [taste-skill](https://github.com/Leonxlnx/taste-skill) | /design 권장 | taste-skill, soft-skill, minimalist-skill, brutalist-skill, redesign-skill, output-skill | 공통 금지 패턴만 적용, 프리셋 상세 규칙 축소 |

---

## 파일 구조

```
jobc-power-commands/
├── .claude-plugin/
│   └── plugin.json          # 플러그인 매니페스트
├── commands/
│   ├── check.md             # /check (42줄)
│   ├── cowork.md            # /cowork (52줄)
│   ├── design.md            # /design (330줄)
│   ├── docs.md              # /docs (202줄)
│   └── super.md             # /super (188줄)
├── codex-skills/
│   ├── check/
│   │   ├── SKILL.md            # Codex 스킬 정의
│   │   └── agents/openai.yaml  # Codex 에이전트 설정
│   ├── cowork/
│   │   ├── SKILL.md
│   │   └── agents/openai.yaml
│   ├── docs/
│   │   ├── SKILL.md
│   │   └── agents/openai.yaml
│   └── super/
│       ├── SKILL.md
│       └── agents/openai.yaml
├── hooks/
│   └── check-design-deps.sh # SessionStart: taste-skill 설치 여부 감지
├── rules/
│   └── plugins-catalog.md   # 설치된 플러그인 카탈로그 (참조용)
├── README.md
└── LICENSE
```

## 라이선스

MIT
