# Agent Orchestration

> 에이전트 카탈로그: `~/.claude/agents/` (25개, 전부 `model: opus` 고정)

## Built-in Skills

| Skill | When to Use |
|-------|-------------|
| /simplify | 기능 구현 후 코드 정리 (3 병렬 에이전트) |
| /batch | 동일 패턴 반복 변경 (5+ 파일) |
| /rc | 외출 시 원격 세션 접속 |
| /ralph-loop | 다중 턴 자율 반복 (`--max-iterations` 필수) |
| /email-action | 2-Phase 이메일 처리: 빈 입력→목록, 번호→매칭, 검색어→4-Opus 팀 (Phase 2만 에이전트 사용) |

## 에이전트 자동 라우팅 (CRITICAL)

`/agent-router` 스킬이 전문 도메인의 실질적 작업 요청을 자동 라우팅한다.
using-superpowers의 "1% 규칙"에 의해 매 턴 agent-router 체크가 강제된다.
단순 질문/정보 요청은 라우팅하지 않고 직접 답변한다.

주요 라우팅 대상 (25 에이전트, `~/.claude/agents/`):
- 구현/계획: planner, architect, code-architect, implementer, build-error-resolver, refactor-cleaner
- 탐색: code-explorer
- 리뷰/검증: code-reviewer, code-simplifier, security-reviewer, database-reviewer, silent-failure-hunter, pr-test-analyzer, comment-analyzer, type-design-analyzer, verify-agent
- 테스트: tdd-guide, e2e-runner
- 문서/플러그인: doc-updater, plugin-validator, skill-reviewer, agent-creator, agent-sdk-verifier-py, agent-sdk-verifier-ts, conversation-analyzer

상세 라우팅 테이블: `/agent-router` 스킬 참조.

## Parallel Task Execution

독립 작업은 항상 병렬 실행. 순차 실행이 필요한 경우만 예외.

## Subagents vs Agent Teams

| | Subagents | Agent Teams |
|---|---|---|
| 통신 | 메인에게만 보고 | 리더 경유 (hub-and-spoke) |
| 최적 용도 | 결과만 중요한 집중 작업 | 논의/협업이 필요한 복잡한 작업 |
| 토큰 비용 | 낮음 | 높음 |

모델 배분과 위임 기준은 model-routing.md를 따른다.
