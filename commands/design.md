---
description: "3-다이얼(Variance/Motion/Density) + 프리셋(landing/dashboard/workspace)으로 프론트엔드 디자인 품질 제어. init으로 디자인 시스템 생성/업데이트, /super와 자동 연동."
---

# /design — 프론트엔드 디자인 품질 제어

3개 다이얼(Variance, Motion, Density)로 디자인 톤을 제어하고, 프리셋 또는 커스텀 조합으로 프론트엔드를 생성한다.
taste-skill 생태계를 통합 진입점 하나로 활용한다.

## 인자

### 서브커맨드
- `init`: 대화형 design.md 생성기 (새 프로젝트 / 리디자인 자동 판별)

### 프리셋 (스타일명)
- `--soft`: 에이전시급 프리미엄
- `--minimal`: 에디토리얼 미니멀리즘
- `--brutal`: 스위스 타이포 + 군용 터미널
- `--redesign`: 기존 사이트 분석 → 업그레이드

### 프리셋 (용도명) — 스타일명의 별칭
- `--landing`: = `--soft` (V7/M8/D3)
- `--dashboard`: = `--brutal` (V6/M2/D8)
- `--workspace`: = `--minimal` (V4/M3/D5)
- `--portfolio`: = `--soft` (V8/M7/D2)
- `--admin`: = taste-skill (V2/M3/D9)

### 커스텀 다이얼
- `--v N` / `--variance N`: 레이아웃 실험성 (1-10, 기본 8)
- `--m N` / `--motion N`: 애니메이션 강도 (1-10, 기본 6)
- `--d N` / `--density N`: 화면 채움도 (1-10, 기본 4)

### 옵션
- `--output-guard`: 코드 잘림/생략 방지 (어떤 프리셋과도 병용)

---

## /design init — 대화형 디자인 시스템 생성/업데이트

프로젝트 상태를 자동 감지하여 3가지 모드 중 하나로 진행한다.

### 디자인 시스템 파일 탐색

프로젝트에서 아래 패턴을 순서대로 탐색한다. 첫 번째로 발견된 파일을 디자인 시스템 파일로 사용한다.

```
1. design.md, DESIGN.md
2. designsystem.md, DESIGNSYSTEM.md, design-system.md, DESIGN-SYSTEM.md
3. docs/design.md, docs/DESIGN.md, docs/design-system.md
4. *DESIGN*.md, *design_system*.md (Glob 패턴 — 프로젝트별 커스텀 이름)
```

예시: `BENEEDS_DESIGN_SYSTEM.md`, `MyApp_Design.md`, `docs/design-tokens.md` 등 모두 감지.

### 실행 흐름

```
디자인 시스템 파일이 이미 있는가?
├── YES → 업데이트 모드
│   1. 기존 파일 읽기 (preset, 다이얼, 컬러, 폰트 등 현재 설정 파악)
│   2. 질문: "어떻게 바꾸고 싶으세요?"
│      → "더 화려하게" → VARIANCE↑ MOTION↑ 추천
│      → "더 깔끔하게" → VARIANCE↓ MOTION↓ DENSITY↓ 추천
│      → "대시보드로 전환" → brutal 프리셋 추천
│      → "프리셋 변경" → 새 프리셋 선택
│      → 커스텀 다이얼 직접 지정
│   3. 기존 파일을 diff 업데이트 (전체 덮어쓰기 아님)
│      → 변경된 항목만 갱신 (프리셋, 다이얼, 컬러, 모션 등)
│      → 기존 커스텀 컴포넌트 규칙은 유지
│
├── NO + 프론트엔드 코드 있음 → 리디자인 모드
│   1. Scan: 프레임워크, CSS 방식, 현재 폰트/색상/레이아웃 분석
│   2. Diagnose: 79항목 감사 → 주요 문제점 요약 보고
│   3. 질문: "어떤 방향으로 리디자인할까요?"
│      → 프리셋 선택 또는 참고 URL
│   4. 디자인 시스템 파일 생성 (현재 문제점 + 목표 프리셋 + 다이얼)
│
└── NO + 프론트엔드 코드 없음 → 새 프로젝트 모드
    1. 질문: "어떤 종류의 프로젝트인가요?"
       → SaaS 랜딩 / 대시보드 / 워크스페이스 / 포트폴리오 / 커머스 / 기타
    2. 질문: "참고할 사이트가 있나요?" (선택)
    3. 용도에 맞는 프리셋 자동 추천
    4. design.md 생성 (프리셋 + 다이얼 + 컬러 팔레트 + 폰트)
```

### 업데이트 모드 상세

기존 디자인 시스템 파일의 다이얼 값을 기준으로 방향을 추천한다:

| 사용자 의도 | 현재 V5/M4/D5 기준 추천 |
|------------|----------------------|
| "더 화려하게" | V→8, M→7 (레이아웃 비대칭 + 모션 강화) |
| "더 차분하게" | V→3, M→2 (그리드 정돈 + 모션 최소화) |
| "더 여유롭게" | D→2 (갤러리 모드, 넓은 여백) |
| "더 빽빽하게" | D→8 (콕핏 모드, 카드 대신 구분선) |
| "럭셔리 느낌" | V→8, M→7, D→2 |
| "실용적으로" | V→3, M→3, D→7 |

프리셋 변경 시, 연관된 컬러/폰트/모션 규칙도 함께 갱신한다.

### 생성되는 design.md 구조

```markdown
# Design System: {프로젝트명}

## 현재 상태 (리디자인 모드에서만)
- 폰트: {현재 폰트} (→ 교체 필요)
- 색상: {현재 문제점}
- 레이아웃: {현재 문제점}
- 모션: {현재 상태}
- 상태: {Loading/Empty/Error 존재 여부}

## 목표
preset: {프리셋명}
variance: {N}
motion: {N}
density: {N}

## 컬러 팔레트
- Canvas: {hex}
- Surface: {hex}
- Text: {hex}
- Accent: {hex} (1개만)
- Base: {Zinc 또는 Slate}

## 타이포그래피
- Display: {폰트}, {스케일}
- Body: {폰트}, {스케일}
- Mono: {폰트}
- Banned: Inter, Roboto, Arial, Open Sans

## 컴포넌트 규칙
(프리셋에 맞는 카드, 버튼, 인풋, 네비게이션 스타일)

## 모션
(다이얼 값에 맞는 전환, 애니메이션, 인터랙션 규칙)

## 반응형
- Mobile collapse: 768px 미만 단일 컬럼
- Touch targets: 44px+
- Typography scaling: clamp()
```

`/design init` 완료 후, 사용자에게 다음 단계를 안내한다:
```
{파일명} 생성/업데이트 완료.
다음 단계: /super 서비스 구현해줘
(디자인 시스템 파일을 자동으로 감지하여 디자인 규칙이 적용됩니다)
```

업데이트 모드에서는 기존 파일명을 그대로 유지한다 (예: `BENEEDS_DESIGN_SYSTEM.md` → 같은 파일 갱신).

---

## 3-다이얼 시스템

### DESIGN_VARIANCE — 레이아웃 실험성

| 범위 | 스타일 | 특징 |
|------|--------|------|
| 1-3 | 정돈된 그리드 | 12-column, 대칭, 균일 패딩 |
| 4-7 | 오프셋 | margin 겹침, 다양한 비율, 좌측 정렬 헤더 |
| 8-10 | 비대칭 | Masonry, fractional Grid, broken-grid, 넓은 여백 |

모바일 오버라이드: 4-10은 768px 미만에서 단일 컬럼 (`w-full`, `px-4`)으로 붕괴.

### MOTION_INTENSITY — 애니메이션 강도

| 범위 | 스타일 | 특징 |
|------|--------|------|
| 1-3 | 정적 | hover/active 상태만. 자동 애니메이션 없음 |
| 4-7 | 유려한 CSS | `cubic-bezier(0.16,1,0.3,1)`, 딜레이 캐스케이드, transform+opacity |
| 8-10 | 고급 안무 | 스크롤 트리거, Framer Motion, 패럴랙스, 영구 마이크로 애니메이션 |

### VISUAL_DENSITY — 화면 채움도

| 범위 | 스타일 | 특징 |
|------|--------|------|
| 1-3 | 갤러리 | 넓은 여백, 큰 섹션 간격, 럭셔리 |
| 4-7 | 일반 앱 | 표준 웹/앱 수준 |
| 8-10 | 콕핏 | 작은 패딩, 카드 대신 구분선, 모노스페이스 숫자, 대시보드 |

---

## 프리셋 매핑

| 프리셋 (스타일) | 프리셋 (용도) | V | M | D | 스킬 | 용도 |
|----------------|-------------|---|---|---|------|------|
| (기본) | — | 8 | 6 | 4 | taste-skill | 범용 프론트엔드 |
| `--soft` | `--landing` | 7 | 8 | 3 | soft-skill | 랜딩, SaaS |
| `--soft` | `--portfolio` | 8 | 7 | 2 | soft-skill | 포트폴리오 |
| `--minimal` | `--workspace` | 4 | 3 | 5 | minimalist-skill | 워크스페이스 |
| `--brutal` | `--dashboard` | 6 | 2 | 8 | brutalist-skill | 대시보드 |
| — | `--admin` | 2 | 3 | 9 | taste-skill | 관리자 패널 |
| `--redesign` | `--redesign` | (분석) | (분석) | (분석) | redesign-skill | 기존 사이트 업그레이드 |

---

## 실행

### 1. 모드 결정

1. `init` 서브커맨드 → design.md 생성기 실행
2. 프리셋 플래그 (스타일명 또는 용도명) → 해당 스킬 활성화
3. 커스텀 다이얼(`--v`, `--m`, `--d`) → taste-skill 다이얼 오버라이드
4. 플래그 없음 → taste-skill 기본값 (V8/M6/D4)

### 2. 스킬 라우팅

| 모드 | 활성화 스킬 |
|------|------------|
| 기본 / 커스텀 다이얼 / `--admin` | taste-skill (DESIGN_VARIANCE={V}, MOTION_INTENSITY={M}, VISUAL_DENSITY={D}) |
| `--soft` / `--landing` / `--portfolio` | soft-skill |
| `--minimal` / `--workspace` | minimalist-skill |
| `--brutal` / `--dashboard` | brutalist-skill |
| `--redesign` | redesign-skill (Scan → Diagnose → Fix 순서) |

`--output-guard` 지정 시 output-skill을 **병행 활성화** — 코드 생략/placeholder 패턴 차단.

### 3. 기본 디자인 규칙 (모든 모드)

taste-skill이 설치되면 상세 규칙은 해당 스킬이 제공한다.
아래는 taste-skill 유무와 관계없이 항상 적용되는 기본 규칙이다.

#### 타이포그래피

**권장 폰트** (Inter, Roboto, Arial, Open Sans 금지):
- Display/Headlines: `Geist`, `Outfit`, `Cabinet Grotesk`, `Satoshi`
- Body: 기존 프로젝트 폰트 또는 위 목록에서 선택
- Monospace: `Geist Mono`, `JetBrains Mono`
- 세리프: 크리에이티브/에디토리얼 전용. 대시보드/소프트웨어 UI에서는 금지

**타이포 스케일:**
- Display: `text-4xl md:text-6xl tracking-tighter leading-none`
- Body: `text-base text-gray-600 leading-relaxed max-w-[65ch]`
- 순수 `#000000` 금지 → off-black (`#111111`, `zinc-950`)

#### 컬러

- 악센트 컬러 **최대 1개**, 채도 80% 미만
- 베이스: Zinc 또는 Slate 계열 중성색
- "AI 퍼플/블루" 금지 — 보라 버튼 글로우, 네온 그라디언트 금지
- 프로젝트 내 warm/cool gray 혼용 금지 — 하나로 통일

#### 레이아웃

- 3-column 균등 카드 금지 → 2-column 지그재그, 비대칭 그리드, 수평 스크롤
- `h-screen` 금지 → `min-h-[100dvh]` (iOS Safari 뷰포트 점프 방지)
- 복잡한 flexbox calc 금지 → CSS Grid
- VARIANCE > 4일 때 중앙 정렬 Hero 금지
- DENSITY > 7일 때 카드 컨테이너 금지 → `border-t`, `divide-y`, 네거티브 스페이스로 그룹핑

#### 모션 기본값

- 전환: `transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1)`
- Spring physics: `stiffness: 100, damping: 20`
- Tactile feedback: `:active` 시 `-translate-y-[1px]` 또는 `scale-[0.98]`
- `transform`과 `opacity`만 애니메이션. `top`, `left`, `width`, `height` 절대 금지
- MOTION > 5일 때 Framer Motion 사용 시 `useMotionValue`/`useTransform` (React useState 금지)

#### 콘텐츠

- "John Doe", "Acme", "Nexus" 등 제네릭 이름 금지
- `99.99%`, `50%` 등 가짜 라운드 숫자 금지 → `47.2%`, `+1 (312) 847-1928`
- "Elevate", "Seamless", "Unleash" 등 AI 클리셰 금지
- 깨진 Unsplash 링크 금지 → `picsum.photos/seed/{id}/800/600` 또는 SVG 아바타

#### 기술

- shadcn/ui 기본 상태 금지 — radius, color, shadow 반드시 커스터마이즈
- React/Next.js: Server Components 기본. 글로벌 상태는 `"use client"` 래퍼 안에서만
- Tailwind: v3/v4 문법 차이 주의. 프로젝트 버전 확인 후 작성
- 의존성 import 전 package.json 확인 — 미설치 패키지 import 금지
- 이모지 전면 금지 — `@phosphor-icons/react` 또는 `@radix-ui/react-icons`

#### 필수 상태

- Loading: 레이아웃 크기에 맞춘 스켈레톤 로더 (원형 스피너 금지)
- Empty: 구성된 빈 상태 화면
- Error: 인라인 에러 리포팅
- Tactile: `:active` 시 `-translate-y-[1px]` 또는 `scale-[0.98]`
- 768px 미만 단일 컬럼 붕괴, 가로 스크롤 금지

### 4. redesign 모드 실행 순서

`--redesign` 지정 시:
1. **Scan** — 코드베이스 읽기, 프레임워크/스타일링 방식 식별
2. **Diagnose** — 79항목 체크리스트 감사 (타이포, 색상, 레이아웃, 인터랙션, 콘텐츠, 컴포넌트, 아이콘, 코드 품질)
3. **Fix** — 우선순위별 수정:
   1. 폰트 교체 (최대 임팩트, 최저 리스크)
   2. 색상 팔레트 정리
   3. hover/active 상태 추가
   4. 레이아웃/간격 조정
   5. 제네릭 컴포넌트 교체
   6. Loading/Empty/Error 상태 추가
   7. 타이포그래피/간격 폴리시

기능은 유지. 디자인만 개선.

---

## 사용 예시

```bash
# design.md 생성 (최초 1회)
/design init

# 프리셋 (스타일명)
/design --soft SaaS 랜딩페이지
/design --minimal 노션 스타일 워크스페이스
/design --brutal 실시간 모니터링 대시보드

# 프리셋 (용도명) — 더 직관적
/design --landing SaaS 랜딩페이지
/design --dashboard 실시간 모니터링
/design --workspace 팀 협업 도구
/design --portfolio 디자이너 포트폴리오
/design --admin 관리자 패널

# 커스텀 다이얼
/design --v 2 --m 3 --d 9 관리자 대시보드
/design --v 8 --m 7 --d 2 럭셔리 브랜드 랜딩

# 리디자인
/design --redesign 이 프로젝트 디자인 업그레이드

# 조합
/design --landing --output-guard 랜딩페이지 (코드 완전 출력)
```

## 의존성

[taste-skill](https://github.com/Leonxlnx/taste-skill) 플러그인이 설치되어 있어야 전체 기능이 작동한다.
없으면 기본 디자인 규칙과 3-다이얼 시스템은 적용되지만, 프리셋별 상세 규칙은 축소된다.
