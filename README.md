# jobc-power-commands

> [Claude Code](https://claude.ai/code)용 파워 커맨드 3종 플러그인

코드 리뷰, 팀 오케스트레이션, 대규모 자동화를 슬래시 커맨드 하나로 실행합니다.

---

## 한눈에 보기

```
/check  — 코드 작성 끝 → 리뷰 → 수정 → 검증 → 커밋 → 푸시 (5분)
/cowork — 큰 작업 → 에이전트 팀 분배 → 병렬 구현 → 취합 → 검증 (15분)
/super  — 아이디어 → 기획 → 구현 → 리뷰 → 배포 → 문서화 (30분+)
```

### 언제 뭘 쓸까?

| 상황 | 커맨드 | 예시 |
|------|--------|------|
| 코드 다 짰고, 커밋하기 전 | `/check` | `/check --pr` |
| 파일 5개 이상 동시 수정 | `/cowork` | `/cowork 결제 환불 기능 추가` |
| 새 기능을 처음부터 끝까지 | `/super` | `/super 로그인에 2FA 추가` |

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

| Phase | 역할 | 활용 도구 |
|-------|------|---------|
| **1. 정찰** | 코드베이스 구조 파악 | Explore 에이전트 + code-architect |
| **2. 계획** | 작업을 독립 단위로 분할 | PM 스킬 (write-prd, write-stories, test-scenarios) |
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

아이디어 한 줄에서 배포까지. `/cowork`(병렬 구현) + `/check`(리뷰+배포)를 조합한 풀 파이프라인.

**원칙:** CRITICAL 보안 이슈에서만 중단. 그 외에는 끝까지.

### 6단계 파이프라인

| 단계 | 역할 | 활용 스킬 |
|------|------|---------|
| **DISCOVER** | 요구사항 구조화 | write-prd, write-stories, pre-mortem, strategy |
| **PLAN** | 구현 계획 + 작업 분할 | Explore, code-architect, prioritize-features, test-scenarios |
| **BUILD** | 병렬 구현 (/cowork 패턴) | Agent Teams, Wave 분배 |
| **CHECK** | 병렬 리뷰 + 검증 (/check 패턴) | 5 에이전트 리뷰, 빌드/린트/테스트 |
| **SHIP** | 커밋 + 푸시 + PR | git, gh CLI |
| **DOCUMENT** | 릴리즈 노트 + 문서 갱신 | release-notes, revise-claude-md, sync-docs |

### 사용법

```bash
/super 로그인에 2FA 추가
/super --pr 결제 모듈 리팩토링
/super --skip-discover PRD가 이미 있으니 Plan부터
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
#    /check, /cowork, /super 가 슬래시 커맨드로 보이면 성공
```

### 삭제

```bash
rm ~/.claude/commands/{check,cowork,super}.md
rm ~/.claude/rules/plugins-catalog.md
```

### 업데이트

```bash
cd jobc-power-commands && git pull
cp commands/*.md ~/.claude/commands/
cp rules/*.md ~/.claude/rules/
```

---

## 의존성 (선택)

이 플러그인은 **단독으로도 동작**합니다. 아래 플러그인이 있으면 더 강력합니다:

| 플러그인 | 필수 여부 | 역할 | 없으면? |
|---------|---------|------|--------|
| [Claude Forge](https://github.com/sangrokjung/claude-forge) | 권장 | verification-engine, /plan, /tdd, /sync-docs | 기본 빌드/테스트로 대체 |
| [claude-plugins-official](https://github.com/anthropics/claude-plugins-official) | 권장 | pr-review-toolkit (6 에이전트), feature-dev, code-simplifier | 에이전트 수 감소 (5→1) |
| [pm-skills](https://github.com/phuryn/pm-skills) | 선택 | write-prd, write-stories, pre-mortem, test-scenarios, release-notes | PM 단계 생략, 바로 구현 |

---

## 파일 구조

```
jobc-power-commands/
├── .claude-plugin/
│   └── plugin.json          # 플러그인 매니페스트
├── commands/
│   ├── check.md             # /check (42줄)
│   ├── cowork.md            # /cowork (52줄)
│   └── super.md             # /super (108줄)
├── rules/
│   └── plugins-catalog.md   # 설치된 플러그인 카탈로그 (참조용)
├── README.md
└── LICENSE
```

## 라이선스

MIT
