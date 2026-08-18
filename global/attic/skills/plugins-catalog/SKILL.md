---
name: plugins-catalog
description: 이 머신에 글로벌 설치된 외부 플러그인/커맨드/에이전트/스킬 전체 카탈로그와 라우팅 가이드. 어떤 슬래시 커맨드나 에이전트가 있는지, 어느 것을 써야 하는지, claudex-power-commands와 외부 플러그인 중 무엇이 우선인지 확인할 때 읽는다.
---


> 글로벌 설치된 외부 플러그인 전체 목록.
> 설치 경로: commands → `~/.claude/commands/`, agents → `~/.claude/agents/`, skills → `~/.claude/skills/`

---

## A. Commands (53개)

### Anthropic Official (17)

| 커맨드 | 플러그인 | 용도 |
|--------|---------|------|
| `/feature-dev` | feature-dev | 코드베이스 이해 기반 기능 개발 |
| `/code-review` | code-review | PR 코드 리뷰 |
| `/review-pr` | pr-review-toolkit | 6 에이전트 심층 PR 리뷰 |
| `/commit` | commit-commands | git 커밋 |
| `/commit-push-pr` | commit-commands | 커밋 + 푸시 + PR |
| `/clean_gone` | commit-commands | gone 브랜치 정리 |
| `/new-sdk-app` | agent-sdk-dev | Agent SDK 앱 스캐폴딩 |
| `/revise-claude-md` | claude-md-management | CLAUDE.md 감사/개선 |
| `/create-plugin` | plugin-dev | 플러그인 스캐폴딩 |
| `/hookify` | hookify | 대화분석 → 훅 자동생성 |
| `/configure` | hookify | hookify 규칙 설정 |
| `/list` | hookify | hookify 규칙 목록 |
| `/ralph-loop` | ralph-loop | 자율 반복 루프 시작 |
| `/cancel-ralph` | ralph-loop | 반복 루프 취소 |
| `/help` | hookify / ralph-loop | 도움말 |
| `/example-command` | example-plugin | 예시 커맨드 |

### PM Suite (36)

| 커맨드 | 플러그인 | 용도 |
|--------|---------|------|
| `/strategy` | pm-product-strategy | Product Strategy Canvas (9섹션) |
| `/business-model` | pm-product-strategy | Lean Canvas / BMC / Startup Canvas |
| `/market-scan` | pm-product-strategy | SWOT + PESTLE + Porter's 5 + Ansoff 통합 |
| `/pricing` | pm-product-strategy | 가격 전략 + WTP 추정 |
| `/value-proposition` | pm-product-strategy | 6파트 JTBD 가치 제안 |
| `/discover` | pm-product-discovery | 전체 디스커버리 사이클 |
| `/brainstorm` | pm-product-discovery | PM/Designer/Engineer 3관점 아이디어 |
| `/interview` | pm-product-discovery | 인터뷰 스크립트 / 요약 |
| `/triage-requests` | pm-product-discovery | 기능 요청 분류 + 우선순위 |
| `/setup-metrics` | pm-product-discovery | 메트릭스 대시보드 설계 |
| `/write-prd` | pm-execution | PRD 8섹션 템플릿 |
| `/write-stories` | pm-execution | 유저 스토리 / Job Story / WWA |
| `/sprint` | pm-execution | 스프린트 계획 + 레트로 + 릴리즈 노트 |
| `/plan-okrs` | pm-execution | OKR 수립 |
| `/stakeholder-map` | pm-execution | 이해관계자 맵핑 |
| `/pre-mortem` | pm-execution | 출시 전 리스크 분석 |
| `/test-scenarios` | pm-execution | QA 테스트 시나리오 |
| `/transform-roadmap` | pm-execution | 기능→성과 로드맵 전환 |
| `/meeting-notes` | pm-execution | 회의록 자동 요약 |
| `/generate-data` | pm-execution | 더미 데이터 생성 |
| `/plan-launch` | pm-go-to-market | GTM 전략 (beachhead+ICP+채널) |
| `/growth-strategy` | pm-go-to-market | 성장 루프 + GTM 모션 |
| `/battlecard` | pm-go-to-market | 경쟁사 세일즈 배틀카드 |
| `/competitive-analysis` | pm-market-research | 경쟁사 분석 |
| `/research-users` | pm-market-research | 페르소나 + 세그먼트 + 저니맵 |
| `/analyze-feedback` | pm-market-research | 피드백 감성 분석 |
| `/market-product` | pm-marketing-growth | 마케팅 아이디어 + 포지셔닝 + 제품명 |
| `/north-star` | pm-marketing-growth | North Star Metric 정의 |
| `/analyze-test` | pm-data-analytics | A/B 테스트 통계 분석 |
| `/analyze-cohorts` | pm-data-analytics | 코호트 리텐션 분석 |
| `/write-query` | pm-data-analytics | 자연어→SQL |
| `/proofread` | pm-toolkit | 문법/논리/흐름 교정 |
| `/review-resume` | pm-toolkit | PM 이력서 리뷰 |
| `/tailor-resume` | pm-toolkit | 직무별 이력서 맞춤화 |
| `/draft-nda` | pm-toolkit | NDA 초안 |
| `/privacy-policy` | pm-toolkit | 개인정보처리방침 초안 |

---

## B. Agents (14개)

### feature-dev (3)

| 에이전트 | 용도 |
|---------|------|
| `code-architect` | 기존 코드베이스 분석 → 기능 아키텍처 설계 |
| `code-explorer` | 실행 흐름 추적 → 코드 깊이 분석 |
| `code-reviewer` | 버그, 로직 오류, 보안 취약점 리뷰 |

### pr-review-toolkit (6)

| 에이전트 | 용도 |
|---------|------|
| `code-reviewer` | 코딩 표준 준수 리뷰 |
| `code-simplifier` | 코드 간결화/정리 |
| `comment-analyzer` | 코드 코멘트 품질 분석 |
| `pr-test-analyzer` | PR 테스트 커버리지 분석 |
| `silent-failure-hunter` | 무음 실패 패턴 탐지 |
| `type-design-analyzer` | 타입 설계 품질 분석 |

### plugin-dev (3)

| 에이전트 | 용도 |
|---------|------|
| `agent-creator` | 에이전트 생성 가이드 |
| `plugin-validator` | 플러그인 구조 검증 |
| `skill-reviewer` | 스킬 품질 리뷰 |

### 기타 (2)

| 에이전트 | 플러그인 | 용도 |
|---------|---------|------|
| `agent-sdk-verifier-py` | agent-sdk-dev | Python SDK 앱 검증 |
| `agent-sdk-verifier-ts` | agent-sdk-dev | TypeScript SDK 앱 검증 |
| `conversation-analyzer` | hookify | 대화 분석 → 훅 규칙 추출 |

---

## C. Skills (80개)

### Anthropic Official (15)

| 스킬 | 플러그인 | 용도 |
|------|---------|------|
| `claude-automation-recommender` | claude-code-setup | 코드베이스 분석 → 자동화 추천 |
| `claude-md-improver` | claude-md-management | CLAUDE.md 감사/개선 |
| `frontend-design` | frontend-design | 고품질 프론트엔드 인터페이스 생성 |
| `playground` | playground | 인터랙티브 HTML 플레이그라운드 생성 |
| `skill-creator` | skill-creator | 스킬 생성/수정/성능 측정 |
| `agent-development` | plugin-dev | 에이전트 구조/시스템 프롬프트 가이드 |
| `command-development` | plugin-dev | 슬래시 커맨드 개발 가이드 |
| `hook-development` | plugin-dev | 훅 이벤트/프롬프트 훅 개발 가이드 |
| `mcp-integration` | plugin-dev | MCP 서버 통합 가이드 |
| `plugin-settings` | plugin-dev | 플러그인 설정 파일 패턴 |
| `plugin-structure` | plugin-dev | 플러그인 디렉토리/매니페스트 가이드 |
| `skill-development` | plugin-dev | 스킬 구조/프로그레시브 디스클로저 |
| `writing-rules` | hookify | hookify 규칙 문법/패턴 |
| `example-command` | example-plugin | 예시 커맨드 템플릿 |
| `example-skill` | example-plugin | 예시 스킬 템플릿 |

### PM - Product Strategy (12)

| 스킬 | 용도 |
|------|------|
| `product-strategy` | Product Strategy Canvas 9섹션 |
| `product-vision` | 영감적 제품 비전 수립 |
| `business-model` | Business Model Canvas 9블록 |
| `lean-canvas` | Lean Canvas (문제→솔루션→메트릭) |
| `startup-canvas` | Strategy + Business Model 통합 |
| `value-proposition` | 6파트 JTBD 가치 제안 |
| `ansoff-matrix` | Ansoff 성장 전략 매트릭스 |
| `pestle-analysis` | 거시환경 PESTLE 분석 |
| `porters-five-forces` | Porter 5 Forces 산업 분석 |
| `swot-analysis` | SWOT 전략 평가 |
| `monetization-strategy` | 수익 모델 3-5개 도출 |
| `pricing-strategy` | 가격 모델 + 경쟁 + WTP |

### PM - Product Discovery (13)

| 스킬 | 용도 |
|------|------|
| `brainstorm-ideas-new` | 신제품 아이디어 발산 |
| `brainstorm-ideas-existing` | 기존 제품 아이디어 발산 |
| `brainstorm-experiments-new` | 신제품 실험(pretotype) 설계 |
| `brainstorm-experiments-existing` | 기존 제품 실험 설계 |
| `identify-assumptions-new` | 신제품 8카테고리 리스크 가정 |
| `identify-assumptions-existing` | 기존 제품 Value/Usability/Viability/Feasibility 가정 |
| `prioritize-assumptions` | Impact×Risk 매트릭스 가정 우선순위 |
| `prioritize-features` | 기능 백로그 우선순위 (impact/effort/risk) |
| `analyze-feature-requests` | 기능 요청 테마별 분류/우선순위 |
| `opportunity-solution-tree` | OST (Teresa Torres 방법론) |
| `interview-script` | JTBD 인터뷰 스크립트 (The Mom Test) |
| `summarize-interview` | 인터뷰 트랜스크립트 → 구조화 요약 |
| `metrics-dashboard` | 메트릭스 대시보드 KPI/시각화 설계 |

### PM - Execution (15)

| 스킬 | 용도 |
|------|------|
| `create-prd` | PRD 8섹션 (문제→목표→세그먼트→솔루션→릴리즈) |
| `user-stories` | 3C + INVEST 유저 스토리 |
| `job-stories` | When/Want/So 형식 Job Story |
| `wwas` | Why-What-Acceptance 백로그 아이템 |
| `sprint-plan` | 용량 추정 + 스토리 선택 + 의존성 |
| `retro` | 스프린트 레트로 (잘한점/아쉬운점/액션) |
| `release-notes` | 유저향 릴리즈 노트 생성 |
| `brainstorm-okrs` | 회사 목표 → 팀 OKR 도출 |
| `stakeholder-map` | Power×Interest 그리드 + 커뮤니케이션 계획 |
| `pre-mortem` | Tiger/Paper Tiger/Elephant 리스크 분류 |
| `test-scenarios` | QA 시나리오 (happy/edge/error) |
| `outcome-roadmap` | 기능→성과 로드맵 전환 |
| `summarize-meeting` | 회의록 → 결정/액션아이템 구조화 |
| `dummy-dataset` | CSV/JSON/SQL 더미 데이터 |
| `prioritization-frameworks` | RICE/ICE/Kano/MoSCoW 등 9개 프레임워크 참조 |

### PM - Go-to-Market (6)

| 스킬 | 용도 |
|------|------|
| `beachhead-segment` | 첫 번째 시장 세그먼트 선정 |
| `ideal-customer-profile` | ICP 정의 (JTBD/pains/gains) |
| `competitive-battlecard` | 경쟁사별 세일즈 배틀카드 |
| `growth-loops` | 5가지 성장 루프 (Viral/Usage/Collab/UGC/Referral) |
| `gtm-motions` | 7가지 GTM 모션 (Inbound/Outbound/PLG/ABM 등) |
| `gtm-strategy` | GTM 전략 (채널/메시징/메트릭/타임라인) |

### PM - Market Research (7)

| 스킬 | 용도 |
|------|------|
| `competitor-analysis` | 경쟁사 강약점 + 차별화 기회 |
| `market-segments` | 3-5개 고객 세그먼트 (JTBD/인구통계/제품적합) |
| `market-sizing` | TAM/SAM/SOM (top-down + bottom-up) |
| `user-personas` | 리서치 기반 3 페르소나 |
| `user-segmentation` | 행동/JTBD 기반 유저 세그먼트 |
| `customer-journey-map` | 터치포인트/감정/페인포인트 저니맵 |
| `sentiment-analysis` | 감성 분석 + 세그먼트별 만족도 |

### PM - Marketing & Growth (5)

| 스킬 | 용도 |
|------|------|
| `marketing-ideas` | 5개 저비용 마케팅 아이디어 |
| `positioning-ideas` | 경쟁 차별화 포지셔닝 |
| `product-name` | 5개 제품명 + 브랜드 근거 |
| `north-star-metric` | NSM + Input Metrics 정의 |
| `value-prop-statements` | 마케팅/세일즈/온보딩용 가치 제안 문구 |

### PM - Data Analytics (3)

| 스킬 | 용도 |
|------|------|
| `ab-test-analysis` | A/B 테스트 통계 유의성 + ship/extend/stop |
| `cohort-analysis` | 코호트 리텐션 + 기능 채택 트렌드 |
| `sql-queries` | 자연어→SQL (BigQuery/PG/MySQL) |

### PM - Toolkit (4)

| 스킬 | 용도 |
|------|------|
| `grammar-check` | 문법/논리/흐름 교정 |
| `review-resume` | PM 이력서 10항목 리뷰 |
| `privacy-policy` | 개인정보처리방침 초안 |
| `draft-nda` | NDA 초안 |

---

## D. 라우팅 가이드

### claudex-power-commands vs 외부 플러그인 우선순위

| 도메인 | claudex-power-commands | 외부 플러그인 | 규칙 |
|--------|-------------------|-------------|------|
| 코드 리뷰 + 배포 | `/check` | `/review-pr` (Official) | /check 우선 (검증+배포 포함) |
| 병렬 오케스트레이션 | `/cowork` | — | 자체 전용 |
| 풀 파이프라인 | `/super` | `/feature-dev` (Official) | /super 우선 (디자인 연동) |
| 문서화 | `/docs` | — | 자체 전용 |
| 디자인 | `/design` | taste-skill 직접 사용 | /design 우선 (통합 진입점) |
| PM/전략 | PM 커맨드 라우팅 | PM Suite 전체 | 외부 PM Suite 활용 |

### 중복 커맨드 충돌

같은 이름 커맨드가 있으면 `~/.claude/commands/`의 마지막 복사본이 우선.
