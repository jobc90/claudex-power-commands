# /design — 프론트엔드 디자인 품질 제어

3개 다이얼(Variance, Motion, Density)로 디자인 톤을 제어하고, 프리셋 또는 커스텀 조합으로 프론트엔드를 생성한다.
taste-skill 생태계를 통합 진입점 하나로 활용한다.

## 인자

- `--v N` / `--variance N`: 레이아웃 실험성 (1-10, 기본 8)
- `--m N` / `--motion N`: 애니메이션 강도 (1-10, 기본 6)
- `--d N` / `--density N`: 화면 채움도 (1-10, 기본 4)
- `--soft`: 에이전시급 프리미엄 프리셋
- `--minimal`: 에디토리얼 미니멀리즘 프리셋
- `--brutal`: 스위스 타이포 + 군용 터미널 프리셋
- `--redesign`: 기존 사이트 분석 → 업그레이드 모드
- `--output-guard`: 코드 잘림/생략 방지 (어떤 프리셋과도 병용)

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

| 프리셋 | V | M | D | 스킬 | 용도 |
|--------|---|---|---|------|------|
| (기본) | 8 | 6 | 4 | taste-skill | 범용 프론트엔드 |
| `--soft` | 7 | 8 | 3 | soft-skill | 랜딩, 포트폴리오, SaaS |
| `--minimal` | 4 | 3 | 5 | minimalist-skill | 워크스페이스, 에디토리얼 |
| `--brutal` | 6 | 2 | 8 | brutalist-skill | 대시보드, 데이터 헤비 |
| `--redesign` | (분석) | (분석) | (분석) | redesign-skill | 기존 사이트 업그레이드 |

커스텀 예시: `/design --v 2 --m 3 --d 9` → 관리자 대시보드 (정돈된 그리드, 최소 모션, 빽빽한 밀도)

---

## 실행

### 1. 모드 결정

프리셋 플래그 → 해당 스킬 활성화.
커스텀 다이얼(`--v`, `--m`, `--d`) → taste-skill을 다이얼 값 오버라이드로 활성화.
플래그 없음 → taste-skill 기본값 (V8/M6/D4).

### 2. 스킬 라우팅

| 모드 | 활성화 스킬 |
|------|------------|
| 기본 / 커스텀 다이얼 | taste-skill (DESIGN_VARIANCE={V}, MOTION_INTENSITY={M}, VISUAL_DENSITY={D}) |
| `--soft` | soft-skill |
| `--minimal` | minimalist-skill |
| `--brutal` | brutalist-skill |
| `--redesign` | redesign-skill (Scan → Diagnose → Fix 순서) |

`--output-guard` 지정 시 output-skill을 **병행 활성화** — 코드 생략/placeholder 패턴 차단.

### 3. 공통 금지 패턴 (모든 모드)

어떤 프리셋을 쓰든 아래는 절대 금지:

**시각/CSS:**
- 네온/외부 글로우, 순수 `#000000`, 과채도 악센트, 그라디언트 텍스트 남용, 커스텀 마우스 커서
- "AI 퍼플/블루" 미학 — 보라 버튼 글로우, 네온 그라디언트 금지

**타이포그래피:**
- Inter 폰트 (프리미엄/크리에이티브 맥락), 과대 H1, 대시보드에 세리프

**레이아웃:**
- 3-column 균등 카드, `h-screen` (→ `min-h-[100dvh]`), 복잡한 flexbox calc (→ CSS Grid)
- VARIANCE > 4일 때 중앙 정렬 Hero 금지

**콘텐츠:**
- "John Doe", "Acme", "Nexus" 등 제네릭 이름
- `99.99%`, `50%` 등 가짜 라운드 숫자 (→ `47.2%`, `+1 (312) 847-1928`)
- "Elevate", "Seamless", "Unleash" 등 AI 클리셰

**기술:**
- `transform`과 `opacity`만 애니메이션. `top`, `left`, `width`, `height` 절대 금지
- 깨진 Unsplash 링크 금지 → `picsum.photos/seed/{id}/800/600` 또는 SVG 아바타
- shadcn/ui 기본 상태 그대로 사용 금지 — 반드시 커스터마이즈

**필수:**
- 인터랙티브 상태 4종: Loading(스켈레톤), Empty, Error, Tactile Feedback
- 768px 미만 단일 컬럼 붕괴, 가로 스크롤 금지
- 이모지 전면 금지 — Phosphor/Radix 아이콘 또는 SVG

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
/design 결제 페이지 UI 만들어줘
/design --soft SaaS 랜딩페이지
/design --minimal 노션 스타일 워크스페이스
/design --brutal 실시간 모니터링 대시보드
/design --v 2 --m 3 --d 9 관리자 대시보드
/design --v 8 --m 7 --d 2 럭셔리 브랜드 랜딩
/design --redesign 이 프로젝트 디자인 업그레이드
/design --soft --output-guard 랜딩페이지 (코드 완전 출력)
```

## 의존성

[taste-skill](https://github.com/Leonxlnx/taste-skill) 플러그인이 설치되어 있어야 전체 기능이 작동한다.
없으면 공통 금지 패턴과 3-다이얼 시스템은 적용되지만, 프리셋별 상세 규칙은 축소된다.
