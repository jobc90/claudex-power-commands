# /super — 기획 → 구현 → 리뷰 → 배포 전자동 파이프라인

`/cowork`(병렬 구현) + `/check`(리뷰+배포) + `/design`(디자인 품질)을 조합한 풀 파이프라인.
CRITICAL 보안 이슈에서만 중단. 그 외에는 끝까지.

## 인자
- 첫 번째 인자: 작업 설명 (필수)
- `--pr`: 푸시 후 PR 생성
- `--skip-discover`: PRD/기획서 있으면 Plan부터
- `--design <프리셋>`: 프론트엔드 디자인 규칙 활성화 (taste-skill 연동)
  - `--design`: taste-skill 기본값 (V8/M6/D4)
  - `--design soft` / `--design landing`: 에이전시급 프리미엄
  - `--design minimal` / `--design workspace`: 에디토리얼 미니멀리즘
  - `--design brutal` / `--design dashboard`: 스위스 타이포 + 터미널
  - `--design admin`: 관리자 패널 (V2/M3/D9)
  - `--design v3m8d2`: 커스텀 다이얼 (V/M/D 숫자 연결)

## 파이프라인

```
DISCOVER → PLAN → BUILD → CHECK → SHIP → DOCUMENT
```

### 디자인 시스템 파일 자동 감지

`--design` 플래그를 명시하지 않아도, 프로젝트에 디자인 시스템 파일이 존재하면 자동으로 디자인 모드를 활성화한다.

**탐색 패턴 (순서대로):**
1. `design.md`, `DESIGN.md`
2. `designsystem.md`, `DESIGNSYSTEM.md`, `design-system.md`, `DESIGN-SYSTEM.md`
3. `docs/design.md`, `docs/DESIGN.md`, `docs/design-system.md`
4. `*DESIGN*.md`, `*design_system*.md` (Glob 패턴 — 프로젝트별 커스텀 이름)

예: `BENEEDS_DESIGN_SYSTEM.md`, `MyApp_Design.md` 등 모두 감지.

**감지 우선순위:**
1. `--design <프리셋>` 명시 → 해당 프리셋 사용 (파일보다 우선)
2. `--design` 플래그 없음 + 디자인 시스템 파일 존재 → 파일 안의 `preset:` 및 다이얼 값 읽기
3. `--design` 플래그 없음 + 파일 없음 → 디자인 모드 비활성화

이로써 `/design init`으로 디자인 시스템 파일을 한 번 만들면, 이후 `/super`만으로 디자인 규칙이 자동 적용된다.

---

### [1] DISCOVER — 요구사항 구조화

사용자 입력을 분석하여 작업 규모를 자동 판단한다.

**판단 기준 → PM 커맨드 자동 라우팅:**

| 조건 | 커맨드 | 산출물 |
|------|--------|--------|
| 신규 기능, 3+ 파일 예상 | `/write-prd` | PRD 8섹션 (문제→목표→세그먼트→솔루션→릴리즈) |
| 기존 기능 개선, 1-2 파일 | `/write-stories` | INVEST 기준 유저 스토리 |
| 리스크 높은 작업 | `/pre-mortem` 병행 | Tiger/Paper Tiger/Elephant 분류 |
| 전략적 판단 필요 | `/strategy` | Product Strategy Canvas 9섹션 |
| 경쟁 분석 필요 | `/competitive-analysis` | 경쟁사 강약점 + 차별화 기회 |

산출물을 `prompt_plan.md`에 저장. **사용자 확인 없이** 다음 단계로 진행.

---

### [2] PLAN — 구현 계획 + 작업 분할

**정찰:**
1. Explore 에이전트 → 프로젝트 아키텍처, 디렉토리, 의존성 파악
2. `code-architect` (feature-dev) → 기존 코드 패턴, 컨벤션, 핵심 파일 분석
3. **디자인 시스템 파일 탐색** (design.md, DESIGN.md, designsystem.md, *DESIGN*.md 등) → 존재하면 디자인 모드 자동 활성화, 프리셋/다이얼 값 읽기

**분할:**
4. PRD/스토리를 구현 단위로 쪼갠다:
   - `/prioritize-features` → impact/effort/risk 기반 우선순위
   - `/test-scenarios` → 각 기능별 QA 시나리오 (happy/edge/error)
5. Wave 구조로 배치:
   - **Wave 1** (순차): 공유 타입, 인터페이스, 유틸리티
   - **Wave 2** (병렬): 데이터 레이어 / UI 컴포넌트 / 테스트
   - **Wave 3** (순차): import 정리, 미사용 코드 제거
6. 각 Wave에 에이전트별 **파일 경로 + 성공 기준** 명시
7. 디자인 모드 활성화 시: **프론트엔드 파일 담당 에이전트에 디자인 규칙을 지시서에 포함**

**사용자 확인 없이** 다음 단계로 진행.

---

### [3] BUILD — /cowork 패턴으로 병렬 구현

**`/cowork`의 지휘자 패턴을 그대로 실행한다.** (상세는 cowork.md 참조)

핵심:
- 지휘자는 코드를 쓰지 않는다. 에이전트에게 **파일 경로 + 성공 기준 + 금지사항**을 전달
- Wave 1 순차 완료 → Wave 2 에이전트 **한 메시지에 동시 호출** → Wave 3 마무리
- 충돌 시 지휘자가 Edit으로 병합
- 실패 시 SendMessage로 해당 에이전트 재지시 (최대 3회)

#### 디자인 모드 활성화 시 BUILD 추가 규칙

디자인 모드가 활성화되면(`--design` 명시 또는 design.md 자동 감지), 프론트엔드를 담당하는 모든 에이전트 지시서에 아래를 추가한다:

**1. 디자인 스킬 활성화:**
- `--design soft` → soft-skill 규칙 적용
- `--design minimal` → minimalist-skill 규칙 적용
- `--design brutal` → brutalist-skill 규칙 적용
- `--design` 또는 `--design v{N}m{N}d{N}` → taste-skill (다이얼 값 전달)

**2. 에이전트 지시서에 포함할 디자인 컨텍스트:**
```
디자인 규칙: {프리셋명} 모드 활성화.
참조 파일: {감지된 디자인 시스템 파일 경로}
다이얼: VARIANCE={V}, MOTION={M}, DENSITY={D}
필수 준수:
- design.md에 정의된 컬러, 타이포, 컴포넌트 규칙 따를 것
- /design 커맨드의 공통 금지 패턴 (AI Tells) 위반 금지
- Inter 폰트 금지 → Geist, Outfit, Cabinet Grotesk, Satoshi
- 악센트 1개, 채도 < 80%, 베이스 Zinc/Slate
- 768px 미만 단일 컬럼 붕괴
- Loading/Empty/Error/Tactile 상태 필수
```

**3. 백엔드 전용 에이전트는 디자인 규칙 불필요** — 프론트엔드 파일(.tsx, .jsx, .css, .html)을 담당하는 에이전트에만 적용.

---

### [4] CHECK — /check 패턴으로 리뷰 + 검증

**`/check`의 5-에이전트 병렬 리뷰를 그대로 실행한다.** (상세는 check.md 참조)

핵심:
- 5개 에이전트 동시 리뷰 (품질/간결화/무음실패/타입/보안)
- CRITICAL/HIGH 자동 수정 → 빌드/린트/테스트 검증
- 3회 실패 시 중단 + 상세 보고

#### 디자인 모드 활성화 시 CHECK 추가 규칙

5-angle 코드 리뷰에 **6번째 앵글: 디자인 품질**을 추가한다:

| 체크 항목 | 확인 내용 |
|-----------|----------|
| AI Tells | Inter 폰트, 순수 #000000, 네온 글로우, 3-column 균등 카드, 제네릭 이름 |
| 디자인 시스템 준수 | 컬러 팔레트, 타이포 스케일, 컴포넌트 규칙이 디자인 시스템 파일과 일치하는지 |
| 다이얼 일관성 | VARIANCE/MOTION/DENSITY 값에 맞는 레이아웃/애니메이션/밀도인지 |
| 반응형 | 768px 미만 단일 컬럼 붕괴, 가로 스크롤 없음 |
| 인터랙티브 상태 | Loading/Empty/Error/Tactile 4종 존재 여부 |
| 접근성 | 포커스 링, 시맨틱 HTML, 터치 타겟 44px+ |

CRITICAL/HIGH 디자인 이슈도 자동 수정 대상에 포함.

---

### [5] SHIP — 커밋 + 푸시

```
git add <변경 파일> → git commit -m "<type>: <desc>" → git push origin <branch>
```
`--pr` 시 `gh pr create --title "<title>" --body "## Summary\n<변경 요약>"`.

---

### [6] DOCUMENT — 문서 자동 갱신

| 작업 | 커맨드 | 산출물 |
|------|--------|--------|
| 릴리즈 노트 | `/sprint` (release-notes) | 커밋 기반 카테고리별 변경 요약 |
| CLAUDE.md 갱신 | `/revise-claude-md` | 세션 학습 사항 반영 |
| 문서 동기화 | `/sync-docs` | prompt_plan.md, spec.md 갱신 |

---

## 중단 조건
- CRITICAL 보안 이슈 → 즉시 중단
- 빌드 3회 실패 → 중단 + 상세 보고

## 사용 예시
```bash
# 기본 (디자인 없이)
/super 로그인에 2FA 추가
/super --pr 결제 모듈 리팩토링
/super --skip-discover PRD가 이미 있으니 Plan부터

# 디자인 명시 지정
/super --design soft 기획서와 design.md를 읽고 서비스 전체 구현
/super --design dashboard --pr 관리자 대시보드 구현 후 PR까지

# design.md 자동 감지 (가장 편한 방법)
# 1. /design init 으로 design.md 생성 (최초 1회)
# 2. 이후 /super만 쓰면 design.md를 자동 감지
/super 서비스 전체 구현해줘
/super 디자인 리팩토링해줘
```
