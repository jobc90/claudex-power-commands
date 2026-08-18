---
name: agent-router
description: "전문 에이전트 자동 라우팅. 구현 계획, 코드리뷰, 아키텍처, TDD, 빌드 에러, 보안, DB, 리팩토링, 문서, E2E, 검증 등 11 도메인"
---

<SUBAGENT-STOP>
서브에이전트로 실행 중이면 이 스킬을 건너뛴다. 재귀 스폰 방지.
</SUBAGENT-STOP>

# Agent Router

> 비유: 병원 접수 데스크. 환자가 "배가 아파요"라고 하면 내과로, "뼈가 부러졌어요"라면 정형외과로 배정한다. 접수 데스크가 직접 진료하지 않는다.

## 규칙 (CRITICAL)

1. 아래 라우팅 테이블에서 매칭되는 에이전트가 있으면 → **반드시 Agent tool로 스폰**
2. 매칭이 없으면 → 이 스킬을 무시하고 직접 처리
3. 사용자가 "직접 해" 또는 "에이전트 없이"라고 하면 → 라우팅 스킵
4. 여러 에이전트가 매칭되면 → 가장 구체적인 것 선택
5. 에이전트 스폰 시 사용자의 원본 요청을 그대로 전달 (요약/변형 금지)

## 라우팅 테이블

| 키워드 (하나라도 포함 시) | 에이전트 |
|------------------------|---------|
| 구현 계획, 복잡한 기능, 설계, implementation plan | planner |
| 코드 리뷰, 코드 검토, code review, 리뷰해줘 | code-reviewer |
| 아키텍처, 설계 판단, 기술 부채, architecture | architect |
| TDD, 테스트 먼저, 테스트 작성, test first | tdd-guide |
| 빌드 에러, 빌드 실패, 타입 에러, build error | build-error-resolver |
| 보안 검토, 보안 리뷰, 취약점, security review | security-reviewer |
| DB 리뷰, SQL 쿼리, 마이그레이션, 인덱스 | database-reviewer |
| 데드 코드, 리팩토링, 미사용 코드, cleanup | refactor-cleaner |
| 문서 업데이트, 코드맵, 문서 동기화 | doc-updater |
| E2E 테스트, Playwright, 유저 여정 | e2e-runner |
| 검증, 빌드 확인, 테스트 확인, verify | verify-agent |

테이블에는 `global/agents/`에 실제로 존재하는 에이전트만 올린다. 없는 에이전트로 라우팅하면 스폰이 실패한다.

## 예외 (라우팅 스킵)

- 단순 질문/정보 요청 → 직접 답변
- 한 줄 수정/오타 → 직접 처리
- 이미 에이전트가 실행 중 → 중복 스폰 방지
- 사용자가 명시적으로 "에이전트 없이" 요청 → 직접 처리
- 서브에이전트 내부에서 실행 중 → 스킵 (재귀 방지)
