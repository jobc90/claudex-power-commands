---
name: beneeds-workspace
description: 비니즈(BENEEDS)/dearwell ~/dev 워크스페이스의 프로젝트 전체 지도와 레퍼런스 — Hub 1.0(dearwell-server-node·admin·user), Console/Hub 2.0 모노레포(apps/api·web·solution-app, field-support 도메인), Solution 서비스, 조직 프로젝트, 개발 도구, 포트·빌드/테스트 명령어 퀵레퍼런스, 1.0→2.0 마이그레이션 흐름. 어느 프로젝트가 무엇인지·어떤 기술스택인지·어떤 포트/명령어를 쓰는지·무엇이 deprecated인지 확인할 때 읽는다.
---

# 비니즈 워크스페이스 레퍼런스

> ~/dev 프로젝트 지도 · 상세 스택 · 퀵레퍼런스. 팀 구성과 개발 컨벤션은 ~/dev/CLAUDE.md 에 상주한다.

## 3. 프로젝트 전체 지도

### 프로젝트 분류 체계

```
~/dev/
├── Hub 1.0 (운영중)
│   ├── dearwell-server-node      # Backend API
│   ├── dearwell-admin-react      # 비니즈 관리자 대시보드
│   └── dearwell-user-react       # 유통사 구매 페이지
│
├── Console / Hub 2.0 (개발중 — 디어웰 솔루션 통합: 관리자 field-support 도메인 + 모바일 앱 apps/solution-app)
│   └── console                   # 모노레포 (API + Web + Packages + Infra + 모바일 앱)
│       │                         #   솔루션 관리자 = field-support 도메인(feat/solutions)
│       └─ apps/solution-app      #   디어웰 솔루션 안드로이드 앱 (RN+Expo) — 2026-06-02 독립 repo에서 모노레포로 이전
│
├── Solution Service (console로 통합 중, MVP deprecated 예정)
│   ├── dearwell-solution-mvp     # Deprecated 예정 — console field-support + apps/solution-app으로 이관
│   └── console-solution-user     # Deprecated 예정 — 숙박업주 UI는 apps/solution-app + /store/<slug>/mypage/*로 이관
│
├── Organization
│   ├── beneeds-design-system     # 디자인 시스템 + 컴포넌트 라이브러리
│   ├── beneeds-homepage          # 기업 홈페이지
│   ├── beneeds-team-develop      # 팀 관리 문서
│   └── beneeds-agents            # 4인팀 자율 운영 허브 + 지식그래프 대시보드 (EC2 상시 운영, 프로덕션)
│
├── Side Projects
│   └── side-project/
│       └── claudex-power-commands  # 자체 Claude Code 플러그인 (Marketplace 게시) + 글로벌 ~/.claude 설정 정본 (global/)
│
├── Deprecated
│   ├── dearwell-user-next        # 유통사 프론트엔드 (중단, console로 이관)
│   ├── console-solution-app      # 솔루션 앱 독립 repo — 2026-06-02 console apps/solution-app로 이전(history 보존), 원본 동결/삭제 예정
│   └── side-project/olympus      # Codex 제어플레인 + Claude CLI 워커 오케스트레이터 (아키텍처 리셋 중단, 폐기)
│
└── Utility
    ├── docs/                     # AI agent 문서 (회의록 등)
    ├── tasks/                    # AI agent 작업 추적 (todo.md, lessons.md)
    ├── beneeds-finace/           # 회사 재무·법인 문서 PDF 보관 (코드 아님, sic: "finance" 오타)
    ├── _wt/ · console-worktrees/ # git worktree 작업 디렉토리 (임시)
    └── Root 파일들               # CLAUDE.md, AIagent-instructions.md 등
```

### 프로젝트 현황 요약

| 프로젝트 | 설명 | 주요 기술 | 상태 | 패키지 매니저 |
|----------|------|----------|------|--------------|
| `dearwell-server-node` | Hub 1.0 Backend API | Express 4.19, Sequelize, MySQL | 운영중 | npm |
| `dearwell-admin-react` | Hub 1.0 관리자 대시보드 | React 18, CRA, Recoil | 운영중 | yarn |
| `dearwell-user-react` | Hub 1.0 유통사 구매 | React 19, Vite, Zustand | 운영중 | yarn |
| `console` | Hub 2.0 통합 플랫폼 (모노레포) — beneeds 조직 관리 + 디어웰 파트너스 + **디어웰 솔루션 관리자(field-support 도메인, `feat/solutions`)** + **디어웰 솔루션 모바일 앱(`apps/solution-app`, RN+Expo, `feat/solution-app-monorepo`)** | NestJS 11, Next.js 16, RN+Expo, PostgreSQL | 개발중 | pnpm |
| `console/apps/solution-app` | 디어웰 솔루션 안드로이드 앱 — 기술자+숙박업주 단일 앱(`/auth/me`의 `kind`로 분기). console `field-support` API 소비. **2026-06-02 독립 repo `dear-well/console-solution-app`에서 모노레포로 이전**(v7.4 결정1 대체, PLAN-V8). 패키지명 `@console/solution-app` | React Native + Expo SDK 55, 백엔드=console `apps/api` | 전 화면 mock 구현 완료, 백엔드 실연동=Phase 2 | pnpm (모노레포 워크스페이스) |
| `dearwell-solution-mvp` | Solution 관리자+기술자 MVP | Next.js 16, SQLite, Prisma | **Deprecated 예정** (v6.1에서 console로 흡수 중. 기술자 4페이지만 `apps/solution-technician`으로 이관, 나머지 관리자 UI는 `modules/field-support/*` + `modules/tenant-unit/`으로 이관) | npm |
| `console-solution-user` | Solution 유저(숙박업주) 포털 프로토타입 | Next.js 16, Tailwind 4 | **Deprecated 예정** (v6.1에서 console `apps/web`의 `/store/<slug>/mypage/*` 범위로 완전 이관) | pnpm |
| `beneeds-design-system` | 디자인 시스템 v6.0 | Vite 7, Storybook 9, TypeScript | 운영중 | pnpm |
| `beneeds-homepage` | 기업 홈페이지 | Next.js 16, Motion 12 | 운영중 (유지보수) | pnpm |
| `beneeds-team-develop` | 팀 관리 문서 | Markdown, Excel | 활성 참조 | -- |
| `beneeds-agents` | 4인팀 자율 운영 허브 + 지식그래프 대시보드 (Anthropic Managed Agents + @claude-code-action) | TypeScript, Hono, @anthropic-ai/sdk, PostgreSQL, AWS, three.js | 운영중 (EC2 상시, 프로덕션) | npm |
| `claudex-power-commands` | Claude Code 플러그인 | Markdown prompts | v4.3.0 게시 | -- |
| `dearwell-user-next` | 유통사 프론트엔드 (중단) | Next.js 15, Zustand, React Query | **Deprecated** | pnpm |

### console 개발 브랜치 현황 (2026-06-02 스냅샷)

> origin 실측 기준. console 모노레포의 4개 핵심 브랜치 역할·상태·통합 경로.

```
main (프로덕션, tag v0.1.0 + 핫픽스)
  ↑ release PR (develop → main)
develop (활성 통합) ──┬── feat/solutions
                      └── feat/solution-app-monorepo
```

| 브랜치 | 역할 | 상태(develop 대비) | 비고 |
|--------|------|--------------------|------|
| `main` | 프로덕션 릴리스 | 6 앞 / 1227 뒤 | `v0.1.0` + 핫픽스. develop의 commerce·field-support 피처는 프로덕션 미반영. main 고유 핫픽스 6건(KC 회원가입 URL·쿠키·CONSOLE_APP_URL 등) develop 역병합 여부 점검 필요 |
| `develop` | 통합(모든 feature 수렴) | — (mainline) | 최근 포커스: **commerce/catalog 강화**(상품 일괄등록·4상태 체계·상점 오픈 셋업) + **입점/온보딩**(기능모듈 기본값·사업자번호 중복·약관 UI) + **auth 안정화**(회원가입 realm 분기·쿠키/로그아웃) |
| `feat/solutions` | 디어웰 솔루션 **관리자** — field-support 도메인(`apps/web` 화면 + `apps/api` 백엔드) | 112 앞 / 58 뒤 · **미머지** | 엔티티 17·web feature 8·`FieldSupportFoundation` 마이그레이션·ADR 0052(Contract→ServiceContract). D7③ 따라 develop 조기 머지 예정(58 따라잡기 + 마이그레이션 순서 점검 선행) |
| `feat/solution-app-monorepo` | 디어웰 솔루션 **모바일 앱** — `apps/solution-app`(RN+Expo, 기술자+숙박업주 단일 앱) | 112 앞 / 4 뒤 · **미머지** | 2026-06-02 독립 repo→모노레포 이전(PLAN-V8/D8) + `@dear-well/console-types` 삭제. 전 화면 mock 완료, 백엔드(field-support API) 실연동 = Phase 2 |

> 솔루션 두 갈래(관리자 `feat/solutions` + 모바일 앱 `feat/solution-app-monorepo`)는 현재 별도 브랜치로 진행 중. **Phase 2(앱 ↔ field-support API 실연동) 전에 둘 다 develop 수렴 필요.**

---

## 4. Hub 1.0 -- 현재 운영중

### 아키텍처 개요

```
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│ dearwell-admin   │     │ dearwell-user    │     │  External        │
│ -react (:3000)   │     │ -react (:5173)   │     │  (Slack, NCP,    │
│                  │     │                  │     │   AWS, vLLM)     │
└────────┬─────────┘     └────────┬─────────┘     └────────┬─────────┘
         │                        │                        │
         └────────────┬───────────┴────────────────────────┘
                      ▼
         ┌──────────────────────┐
         │ dearwell-server-node │
         │ Express.js (:3300)   │
         │ Swagger: /hub-docs-v1│
         └──────────┬───────────┘
                    ▼
         ┌──────────────────────┐
         │       MySQL          │
         └──────────────────────┘
```

### dearwell-server-node (Backend)

| 항목 | 상세 |
|------|------|
| 기술 스택 | Express.js 4.19.2, TypeScript 4.9.4, Sequelize 6.37.3, MySQL |
| 포트 | 3300 |
| Swagger | `/hub-docs-v1` |
| DB 모델 | 21개 Sequelize 모델 (Admin, Company, Product, Order, Grade 등) |
| API 구조 | V1 (레거시 인라인 컨트롤러) + V2 (서비스 레이어 패턴) |
| 인증 | JWT 쿠키, 자동 갱신, 2 유저 타입 (ADMIN/COMPANY), 12개 권한 |
| 외부 연동 | AWS S3 + CloudFront, Slack 알림, NCP SMS, vLLM (Qwen3-32B-AWQ) |
| 상태코드 | `DWH{module}_{status}{seq}` (예: DWH01_2010) -- 2xxx 성공, 4xxx 클라이언트, 5xxx 서버 |

### dearwell-admin-react (관리자 대시보드)

| 항목 | 상세 |
|------|------|
| 기술 스택 | React 18.3.1, CRA, TypeScript 4.4.2, Recoil 0.7.7, Tailwind 3.4 |
| 포트 | 3000 |
| 주요 화면 | Login, Main, Orders, Products, Distributors, Accounts, Notices, AI |
| API 통신 | Axios (withCredentials), V1/V2 헬퍼 |
| 상태 관리 | Recoil 2개 atom (loginState, profileState) |
| 내보내기 | ExcelJS + jsPDF (3가지 파트너 형식: 일반, 야놀자, 비니즈) |
| 특수 기능 | 한글 초성 검색 (hangul.ts) |

### dearwell-user-react (유통사 구매 페이지)

| 항목 | 상세 |
|------|------|
| 기술 스택 | React 19.1.0, Vite 6.3.5, TypeScript 5.8.3, Zustand 5.0.5, TanStack Query 5, Tailwind v4 |
| 포트 | 5173 |
| 주요 페이지 | auth, dashboard, store, purchase, storefront, mypage, notices, notifications |
| 상태 관리 | Zustand 기능별 스토어 (authStore, cartStore, orderStore, signupStore) |
| 멀티테넌트 | 서브도메인 기반 스토어프론트 (*.hub.it.kr) |
| 보안 | DOMPurify, Sentry |
| 멀티빌드 | default, beta-partners, beta-storefront |

---

## 5. Console -- Hub 2.0 플랫폼 (개발중, v7.4 — 디어웰 솔루션 통합 중)

> 📘 v7.3 확정 반영: 디어웰 솔루션(시설물 관리)은 별도 서비스가 아니라 console 내부의 `field-support` 도메인으로 통합 중. **작업계획서 중심(구현 프리셉션 최소화)**. 상세 문서 2종:
> - **Doc A — 관리자 통합**: `console/docs/worklog/solution-admin-handover.md` v7.3 (정명기 단독 구현; 조영일 아키텍처 감수 완료; 정재환·CTO 최종 승인 트랙). 기존 console 자산(`tenant/store`·`admin/member-admin`·`notification`·`storage`·`terms`·`signature`·`audit-log`·`maps`) 재사용 우선, field-support 고유(`Contract`/`Schedule`/`FieldReport` 등)만 신규. 관리자 UI는 `/console/<비니즈-slug>/mystore/*`, 유통사 UI는 `/console/<유통사-slug>/{customers,stores}/*`, 숙박업주 UI는 `/store/<비니즈-slug>/mypage/*`
> - **디어웰 솔루션 모바일 앱**: **console 모노레포 내부 `apps/solution-app`** (React Native + Expo SDK 55, 패키지 `@console/solution-app`). **2026-06-02(조병철 CTO) 독립 repo `dear-well/console-solution-app`에서 모노레포로 이전 — v7.4 운영진 결정 1(외부 독립 repo)을 PLAN-V8로 대체**. 브랜치 `feat/solution-app-monorepo`(develop 기반), git history는 subtree merge로 동일 SHA 보존. 이전 명분: console `apps/web`이 이미 외부 스토어프론트(`/store/[slug]`)를 서빙 → "외부향이라 별도 repo"가 성립 안 함. Keycloak client `storefront-mobile`(public + PKCE). 기술자 + 숙박업주를 한 앱이 서빙(`/auth/me`의 `kind`로 분기). 전 화면 mock 구현 완료, 백엔드(field-support API) 실연동 = Phase 2. 미사용 타입 발행 패키지 `@dear-well/console-types`(+`publish-packages.yml`)는 이전과 함께 삭제(소비처 0건 감사 확인); 앱은 당분간 자기완결 enum 미러 유지(field-support enum이 develop 진입 시 직접 소비로 전환). 설계 SPEC = `apps/solution-app/docs/console-solution-app-spec.md`
> - **단일 genesis 모델** (v7.2 전환): 공급자 = **비니즈 genesis 단독**. 솔루션즈 tenant 신설 폐기. `Contract.homeTenant` 컬럼 생성 금지(v7.3 ③)
> - **"조직 없는 구매자회원" 허용** (v7.2): customer-kind `Member`가 `TenantMembership` 0건 상태로 존재 가능 + 기존 "조직 이전" 기능으로 나중에 유통사 합류/해제
> - **용어 "현장"/"업장"은 UI 카피 레이어에서만** 관점별 혼용(관리자=현장, 고객=업장). 내부 코드·엔티티·URL 변경 없음
> - 숙박업주 ≡ customer-kind 구매자회원, 업장 ≡ `TenantUnit(type=STORE)`. 별도 role/enum/권한 신설 금지

### 아키텍처 개요

```
┌─────────────────────────────────────────────────────────────────────┐
│                    console (pnpm 10.13.1 + Turborepo)              │
│                                                                     │
│  ┌──────────────────────┐  ┌──────────────────────┐               │
│  │  apps/api             │  │  apps/web             │               │
│  │  NestJS 11 (:4000)   │  │  Next.js 16 (:3000)  │               │
│  │  Swagger: /api        │  │  App Router          │               │
│  └──────────┬───────────┘  └──────────┬───────────┘               │
│             │                          │                            │
│  ┌──────────┴──────────────────────────┴───────────┐               │
│  │  packages/                                       │               │
│  │  ├── database (84 entities, MikroORM)           │               │
│  │  ├── shared (types, enums, constants)           │               │
│  │  └── ui (shared React components)               │               │
│  └─────────────────────────────────────────────────┘               │
│                                                                     │
│  ┌────────────────────┐  ┌─────────────────────────┐               │
│  │  apps/keycloak-     │  │  infra/                 │               │
│  │  theme              │  │  ├── cdk (9 AWS stacks) │               │
│  │  (Keycloakify)      │  │  └── keycloak (realm)   │               │
│  └────────────────────┘  └─────────────────────────┘               │
└─────────────────────────────────────────────────────────────────────┘
         │              │              │              │
         ▼              ▼              ▼              ▼
   PostgreSQL 16    Redis 7     Keycloak 26     Mailhog/LocalStack
```

### apps/api (NestJS 11)

**16개 API 모듈:**

| 카테고리 | 모듈 |
|----------|------|
| 핵심 | auth, admin, tenant, health |
| 커머스 | commerce (catalog / cart / order / delivery) |
| 재고/재무 | inventory, finance |
| 콘텐츠 | post, terms, storefront |
| 인프라 | storage, notification (mail / push / alimtalk), maps, address |
| 분석 | analytics, audit-log |

**Guard Chain (요청 처리 순서):**

```
Throttler → JWT → Tenant → FeatureModule → Roles → Ownership → Store
```

**RBAC 시스템:**
- 42개 권한, 3개 역할 템플릿 (owner, manager, staff)
- PostgreSQL RLS 기반 멀티테넌시 (49개 테이블 정책)

**백그라운드 처리:**
- BullMQ 작업 큐, Redis 캐싱, SSE 알림

**DB:** 84개 엔티티, MikroORM 6.5.1

### apps/web (Next.js 16)

**18개 Feature 모듈:**

account, address, auth, cart, catalog, category, maps, member, messaging, notices, notification-provider, orders, organization, rbac, store, terms, tier, welcome

**Dual Portal 구조:**
- `/console/[slug]` -- 관리자 콘솔
- `/store/[slug]` -- 스토어프론트

**기술 스택:** Next.js 16.2.0 (App Router), React 19.2.4, TanStack Query/Form, Tailwind 4, shadcn

### Packages

| 패키지 | 설명 |
|--------|------|
| `packages/database` | MikroORM 엔티티(84개), 마이그레이션, 시드, RLS 정책 |
| `packages/shared` | 타입, Enum, 상수 |
| `packages/ui` | 공유 React 컴포넌트 |

### Infrastructure

| 구성 요소 | 상세 |
|----------|------|
| Docker | PostgreSQL 16, Redis 7, Keycloak 26, Mailhog, LocalStack |
| AWS CDK | 9개 스택 |
| Keycloak Theme | Keycloakify (Vite + React) |

### 인증 시스템

| 항목 | 상세 |
|------|------|
| IdP | Keycloak 26 (OIDC, RS256) |
| Frontend Auth | NextAuth 5.0.0-beta.30 |
| 멤버십 계층 | 3-tier (System / Tenant / Member) |
| 권한 | 42개 |

### CI/CD

```bash
pnpm ci:local          # build + lint + type-check + test
pnpm ci:local:e2e      # E2E 테스트
pnpm ci:local:full     # 전체 (위 2개 통합)
```

### 테스트 전략

| 유형 | 도구 |
|------|------|
| Unit / Controller | Vitest |
| Integration | Supertest, TestContainers |
| E2E | Playwright |

### Legacy Import

MySQL(Hub 1.0) -> PostgreSQL(Hub 2.0) 데이터 이관: 45개 테넌트, 상품, 주문

---

## 6. Solution Service -- v7.3 Console로 통합 중 (MVP deprecated 예정)

> ⚠️ **v7.3 확정**: 디어웰 솔루션은 별도 서비스 라인이 아니라 **console 내부 `field-support` 도메인**으로 완전 통합 중. **단일 공급자 genesis(비니즈) 모델**(솔루션즈 tenant 폐기) + **조직 없는 구매자회원 허용** + **현장/업장 용어 혼용 원칙**. 아래 두 MVP는 deprecated 예정.

### dearwell-solution-mvp (관리자 + 기술자 MVP) — **Deprecated 예정 (v6.1)**

| 항목 | 상세 |
|------|------|
| 기술 스택 | Next.js 16.1.6 (Turbopack), TypeScript 5, React 19.2.3, Tailwind 4 |
| DB | SQLite + Prisma 6.19.2 (외부 DB 불필요, 샘플 데이터 프리시드 — **와이어프레임 수준, 실운영 데이터 아님**) |
| 패키지 매니저 | npm |
| 컴포넌트 | @dear-well/beneeds-components 1.15.0, Lucide React — **console 통합 시 도입 금지** (shadcn + packages/ui로 대체) |
| 지도 | Kakao Maps SDK / NCP Directions — **console 통합 시 도입 취소** (기존 NCP Static Map만 사용) |

**주요 기능 (23 pages):**
- 관리자 UI (16 pages): 계약 5단계 위저드, 고객/업장 관리, 서비스 카탈로그, 기술자 관리, 스케줄 3탭 대시보드
- 기술자 UI (4 pages): `/field`, `/field/[scheduleId]`, `/report/[scheduleId]`, `/notifications`
- 공개 (3 pages): `/login`, `/confirm/[token]`, 루트

**인증:** 쿠키 세션(관리자) + 휴대폰+bcrypt(기술자) — **전부 폐기 예정**, Keycloak으로 통합

**v7.3 이관 경로:**
- 관리자 UI → Doc A: `console/apps/web` 기존 feature 확장(`member`·`store`·`signature`·`terms`) + 평면 field-support 신규 feature
- 기술자·숙박업주 UI → **console 모노레포 `apps/solution-app`** (RN+Expo 안드로이드 앱). 2026-06-02 독립 repo `console-solution-app`에서 모노레포로 이전(v7.4 결정1 대체, PLAN-V8). Keycloak `storefront-mobile` PKCE
- Prisma 모델 → MikroORM 신규 엔티티는 field-support 고유만(`Contract`·`Schedule`·`FieldReport` 계열). `Customer`/`Site`/`Session` 신설 취소 — 기존 `Member+BuyerProfile`·`TenantUnit`·Keycloak 세션 재사용
- 데이터 귀속: 모든 field-support 엔티티 `tenant_id` = **비니즈 genesis 단독**. 솔루션즈 tenant 신설 없음
- 기술자·숙박업주 인증 → Keycloak `storefront-mobile` 공개 client + PKCE (v7.4 — 구 `solution-app` 폐기)

**상태:** **Deprecated 예정**. console 통합 완료 후 저장소 정리

### console-solution-user (유저 포털 프로토타입) — **Deprecated 예정 (v6.1)**

| 항목 | 상세 |
|------|------|
| 기술 스택 | Next.js 16.2.0, TypeScript 5, React 19.2.4, Tailwind 4, CVA |
| 디자인 시스템 | BENEEDS Design System v6.0 (CSS Variables) — **이식은 토큰 레퍼런스로만**. 외부 `@dear-well/*` 도입은 console 통합 시 금지 |
| 레이아웃 | Mobile-first (max-w-md) |
| 페이지 | 14개 구현 (모의 데이터) — 숙박업주 마이페이지 목업 |

**v6.1 이관 경로**: 전체가 **Doc A의 `/store/<slug>/mypage/*`** (console `apps/web` + 기존 `storefront-web` Keycloak client) 범위로 완전 편입. 별도 앱으로 남기지 않음. 이관 대상 페이지:
- 업장 관리: `/store/[slug]/mypage/tenant-units/{,[id],new}`
- 계약 조회: `/store/[slug]/mypage/contracts/{,[id]}`
- 방문 일정: `/store/[slug]/mypage/schedules`
- 보고서 수신: `/store/[slug]/mypage/field-reports`
- 물품 요청(flag OFF): `/store/[slug]/mypage/requests/supply`

**상태:** **Deprecated 예정**. Doc A 숙박업주 포털 오픈 후 저장소 정리

---

## 7. 조직 프로젝트

### beneeds-design-system

비니즈 전체 프로젝트에서 사용하는 디자인 시스템과 컴포넌트 라이브러리.

| 항목 | 상세 |
|------|------|
| 모노레포 | pnpm, Vite 7.1.2, TypeScript 5.8.3, Storybook 9.1.2 |
| 컴포넌트 | **@dear-well/beneeds-components** v1.21.0 -- 47개 (21 atoms + 18 molecules + 8 organisms) |
| 아이콘 | **@dear-well/beneeds-icons** v1.0.0 -- 3,309개 (Material 1,254 + IBM Carbon 2,056) |
| 디자인 가이드 | BENEEDS_DESIGN_SYSTEM.md v6.0 (1,048줄) |
| Storybook | https://beneeds-design-system.pages.dev |
| 배포 | Semantic Release -> GitHub Packages |

**디자인 토큰 핵심:**
- Primary Color: `#375CE0`
- Typography: Pretendard Variable
- Spacing: 8pt 그리드
- 상태 머신: 8-state
- 접근성: WCAG 2.2 AA

**Claude Code 연동:**
- 9개 슬래시 커맨드 (/beneeds-refactor-ui, /beneeds-review 등)
- `setup-claude.js`: 다른 프로젝트에 디자인 시스템 + 스킬 자동 설치

### beneeds-homepage

| 항목 | 상세 |
|------|------|
| 기술 스택 | Next.js 16.1.6, React 19.2.3, Tailwind 4, Motion 12.35.2 |
| URL | https://beneeds.co.kr |
| 페이지 | Home, About, Solution, Partners, Contact, Terms |
| 모션 시스템 | 3-tier (full / balanced / safe), LazyMotion, TiltCard, MagneticButton 등 |
| Contact API | Nodemailer (Microsoft 365 SMTP), Rate Limiting, 중복 방지 |
| 배포 | AWS EC2 t4g.small, Ubuntu 24.04, Nginx, Let's Encrypt SSL |
| 상태 | 운영중, 유지보수 모드 |

### beneeds-team-develop

| 항목 | 상세 |
|------|------|
| 내용 | team-rnr.md (4명 역할, R&R 매트릭스, KPI 프레임워크), 직무조사서 (Excel) |
| 상태 | 활성 참조 문서 |

---

## 8. 개발 도구 & 자동화

### claudex-power-commands (Claude Code Plugin)

| 항목 | 상세 |
|------|------|
| 플러그인명 | "claudex" v4.3.0 |
| 저자 | jobc90 |
| 위치 | `~/dev/side-project/claudex-power-commands/` |
| 커맨드 | 6개 (/harness [SINGLE·TEAM], /harness-docs, /harness-review, /harness-qa, /design, /claude-dashboard) — v4.0.0에서 /harness-team을 /harness TEAM 모드로 흡수 |
| 에이전트 프롬프트 | 27개 (+phase-orchestrator helper) |
| 플랫폼 | Claude Code (슬래시 커맨드) + Codex (달러 접두사 스킬) |
| 배포 | Claude Code Marketplace 게시 |

### AI Agent 파일

| 경로 | 용도 |
|------|------|
| `~/dev/docs/` | AI agent 문서 저장 (회의록 등) |
| `~/dev/tasks/` | AI agent 작업 추적 (todo.md, lessons.md) |
| `~/dev/CLAUDE.md` | 워크스페이스 마스터 레퍼런스 (이 문서) |
| `~/dev/AIagent-instructions.md` | AI agent 일반 지침 |
| `~/dev/claude-app-instructions.md` | Claude App 전용 지침 |
| `~/dev/claude-code-instructions.md` | Claude Code 전용 지침 |

### 브라우저 자동화 정책

브라우저를 사용하는 모든 작업(테스팅, 스크린샷, 폼 입력, 데이터 추출)은 반드시 `@playwright/mcp`를 사용한다. 다른 브라우저 도구 대신 항상 우선 사용.

---

## 10. Quick Reference

### 개발 명령어

#### Hub 1.0

```bash
# Backend
cd dearwell-server-node
docker-compose up mysql && npm run db:init:dev && npm run start:dev  # :3300

# Admin
cd dearwell-admin-react && yarn start  # :3000

# User
cd dearwell-user-react && yarn dev  # :5173
```

#### Hub 2.0 (Console)

```bash
# 인프라 시작
cd console && docker compose up -d  # PostgreSQL, Redis, Keycloak

# 의존성 및 빌드
pnpm install && pnpm build  # 공유 라이브러리 빌드

# API
cd apps/api && pnpm dev  # :4000, Swagger: /api

# Web
cd apps/web && pnpm dev  # :3000
```

#### Solution MVP

```bash
cd dearwell-solution-mvp && npm run dev
```

#### 디자인 시스템

```bash
cd beneeds-design-system && pnpm storybook  # Storybook 로컬 실행
```

### 프로젝트별 빌드/테스트

| 프로젝트 | Dev | Build | Test / Lint |
|----------|-----|-------|-------------|
| `dearwell-server-node` | `npm run start:dev` | -- | -- |
| `dearwell-admin-react` | `yarn start` | `yarn build` | `yarn test` |
| `dearwell-user-react` | `yarn dev` | `yarn build` | `yarn lint` |
| `console` (root) | `pnpm dev` | `pnpm build` | `pnpm lint` |
| `console/apps/api` | `pnpm dev` | `pnpm build` | `pnpm test` |
| `console/apps/web` | `pnpm dev` | `pnpm build` | `pnpm lint` |
| `dearwell-solution-mvp` | `npm run dev` | `npm run build` | -- |
| `beneeds-homepage` | `pnpm dev` | `pnpm build` | `pnpm lint` |

### API 문서

| 버전 | URL | 설명 |
|------|-----|------|
| Hub 1.0 | `localhost:3300/hub-docs-v1` | Express.js 기반 API |
| Hub 2.0 | `localhost:4000/api` | NestJS 기반 API |

### 주요 포트

| 포트 | 서비스 |
|------|--------|
| 3000 | Hub 1.0 Admin / Hub 2.0 Web (*포트 충돌, 동시 실행 불가) |
| 3300 | Hub 1.0 Backend |
| 4000 | Hub 2.0 API |
| 5173 | Hub 1.0 User |
| 5432 | PostgreSQL (Console) |
| 6379 | Redis (Console) |
| 8080 | Keycloak (Console) |

> **주의:** Hub 1.0 Admin(CRA 기본 3000)과 Hub 2.0 Web(Next.js 기본 3000)은 동일 포트를 사용하므로 동시에 실행할 수 없다. Hub 1.0은 2.0 전환 완료 후 폐기 예정.

### 디자인 시스템 토큰

| 토큰 | 값 |
|------|-----|
| Primary Color | `#375CE0` |
| Font | Pretendard Variable |
| Spacing | 8pt 그리드 |
| 접근성 | WCAG 2.2 AA |

---

## 11. 리팩토링 흐름 (1.0 -> 2.0 Migration)

### 프로젝트 매핑

```
Hub 1.0                          Hub 2.0
─────────────────────────────────────────────────
dearwell-server-node      ──→   console/apps/api
dearwell-admin-react      ──→   console/apps/web
dearwell-user-react       ──→   console (통합)
```

### Deprecated 프로젝트

| 프로젝트 | 이유 | 상태 |
|----------|------|------|
| `dearwell-user-next` | 유통사 프론트엔드 리팩토링 시도(중단), console로 통합 | 동결 |
| `console-solution-app` (독립 repo) | 2026-06-02 console 모노레포 `apps/solution-app`로 이전(git history 보존, subtree merge). v7.4 독립 repo 결정(결정1)을 PLAN-V8로 대체 | **동결/삭제 예정** (원본 백업, history는 console에 보존됨) |
| `dearwell-solution-mvp` | console로 이관 중. 관리자 UI → console `field-support`, 기술자·숙박업주 UI → console 모노레포 `apps/solution-app`(RN+Expo) | **Deprecated 예정** (이관 완료 시점에 저장소 동결) |
| `console-solution-user` | v6.1에서 console의 `/store/<slug>/mypage/*`(storefront-web)로 완전 흡수 | **Deprecated 예정** (Doc A 오픈 시점에 저장소 동결) |
| `side-project/olympus` | Codex 제어플레인 + Claude CLI 워커 오케스트레이터 사이드 프로젝트. 아키텍처 리셋 도중 중단 | **폐기** (개발 중단, 워크스페이스에서 무시) |

### Legacy Import (MySQL -> PostgreSQL)

Hub 1.0(MySQL)에서 Hub 2.0(PostgreSQL)으로의 데이터 이관:
- 45개 테넌트
- 상품 데이터
- 주문 데이터

### Solution MVP → Console 이관 (v6.1, 신규)

`dearwell-solution-mvp`(SQLite/Prisma)·`console-solution-user`(프로토타입)은 **와이어프레임 임시 데이터**로 실운영 데이터 없음. 따라서 "데이터 이관"은 **불필요**:
- Doc A: 신규 환경에 스키마만 올리고 데모·테스트용 시드만 재구성 (솔루션즈 genesis seed 1건 + 권한 19개 + `technician` RoleTemplate + ServiceCategory/Catalog/Skill 샘플)
- apps/solution-app (2026-06-02 모노레포 이전 완료): Keycloak `storefront-mobile` 클라이언트 프로비저닝 + 기술자·숙박업주 화면 API 실연동 (Phase 2 — 현재 전 화면 mock)

---

