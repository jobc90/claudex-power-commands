---
description: "5-angle 병렬 코드 리뷰(품질/간결화/무음실패/타입/보안) → CRITICAL/HIGH 자동 수정 → 빌드+린트+테스트 검증 → 커밋+푸시. --dry-run, --pr 지원."
---

# /check — 병렬 코드 리뷰 + 수정 + 검증 + 배포

변경된 코드를 5개 관점에서 동시 리뷰하고, 이슈를 자동 수정한 뒤, 검증하고 배포한다.

## 인자
- `--dry-run`: 리뷰만 실행, 수정/커밋 안 함
- `--pr`: 푸시 후 PR도 생성
- (기본): 리뷰 → 수정 → 검증 → 커밋 → 푸시

## 실행

### 1. 변경 파일 수집
`git diff --name-only HEAD` + `git diff --staged --name-only` → 0개면 종료.

### 2. 병렬 리뷰 (5 에이전트 동시 호출)

한 메시지에 Agent 5개를 동시에 호출한다:

| Agent | 역할 | 출력 |
|-------|------|------|
| **code-reviewer** (pr-review-toolkit) | 품질: 네이밍, DRY, 복잡도, 에러핸들링 | `{file, line, severity, fix}[]` |
| **code-simplifier** (pr-review-toolkit) | 간결화: 불필요 추상화, 중복, 더 단순한 대안 | `{file, before, after}[]` |
| **silent-failure-hunter** (pr-review-toolkit) | 무음 실패: 빈 catch, 무시된 반환값, 미처리 에러 | `{file, line, risk}[]` |
| **type-design-analyzer** (pr-review-toolkit) | 타입: 불안전 as/any, 누락 제네릭, 약한 타입 | `{file, line, fix}[]` |
| **security-review** (Forge) | 보안: CWE Top 25 + STRIDE 위협 | `{file, cwe, severity, fix}[]` |

### 3. 자동 수정
CRITICAL/HIGH → Edit 도구로 수정. MEDIUM → 보고만. LOW → 무시.
수정 범위: 해당 줄만. 주변 코드 건드리지 않음 (golden-principles: surgical changes).

### 4. 검증
`pnpm build` → `pnpm lint` → `pnpm test` (없으면 skip).
실패 시 자동 수정 → 재검증 (최대 3회). 3회 실패 → 중단.

### 5. 배포
`git add` → `git commit -m "<type>: <desc>"` → `git push`.
`--pr` 시 `gh pr create`.
`--dry-run` 시 리뷰 결과만 출력.

## 중단 조건
- 하드코딩된 시크릿/SQL 인젝션 발견 → 즉시 중단
- 빌드 3회 실패 → 중단
