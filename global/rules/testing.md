---
paths:
  - "**/*.test.*"
  - "**/*.spec.*"
  - "**/tests/**"
  - "**/__tests__/**"
  - "**/playwright/**"
---

# Testing Requirements

## Coverage: 저장소 CI 임계값을 따른다

임의의 목표치를 강요하지 마라. 임계값은 저장소의 테스트 설정에 있다
(예: `apps/api/vitest.config.ts`). 커버리지 숫자를 올리려고 의미 없는
테스트를 쓰지 말고, **커버되지 않은 실패 경로**를 덮어라.

Test Types:
1. **Unit** — 함수·유틸·컴포넌트
2. **Integration** — API 엔드포인트, DB 동작
3. **E2E** — 핵심 사용자 흐름 (Playwright)

## 회귀는 red-green 으로 증명한다

1. 실패를 재현하는 테스트를 쓴다 → 실행 → **FAIL** (테스트가 버그를 잡는지 확인)
2. 수정한다 → 실행 → **PASS**
3. 수정을 되돌린다 → 실행 → **FAIL** (테스트가 정말 그 수정을 검증하는지 확인)
4. 수정을 복원한다 → 실행 → **PASS**

2번 단계가 실패하지 않으면 그 테스트는 아무것도 검증하지 않는다.

**테스트가 실제 실행 경로를 타는지 확인하라.** 매퍼·직렬화 출력만 단언하고
디스패치 파이프라인을 건너뛰면, 파이프라인 단계에서 생긴 회귀를 통과시킨다.

## 새 동작에는 같은 커밋에 테스트를 넣는다

나중에 붙인 테스트는 해피패스만 덮는다.

## Troubleshooting Test Failures

1. Use **tdd-guide** agent
2. Check test isolation
3. Verify mocks are correct
4. Fix implementation, not tests (unless tests are wrong)

## Agent Support

- **tdd-guide** - Use PROACTIVELY for new features, enforces write-tests-first
- **e2e-runner** - Playwright E2E testing specialist
