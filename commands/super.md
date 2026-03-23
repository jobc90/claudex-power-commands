# /super — 기획 → 구현 → 리뷰 → 배포 전자동 파이프라인

`/cowork`(병렬 구현) + `/check`(리뷰+배포)를 조합한 풀 파이프라인.
CRITICAL 보안 이슈에서만 중단. 그 외에는 끝까지.

## 인자
- 첫 번째 인자: 작업 설명 (필수)
- `--pr`: 푸시 후 PR 생성
- `--skip-discover`: PRD 있으면 Plan부터

## 파이프라인

```
DISCOVER → PLAN → BUILD → CHECK → SHIP → DOCUMENT
```

---

### [1] DISCOVER — 요구사항 구조화

사용자 입력을 분석하여 작업 규모를 자동 판단한다.

**판단 기준 → PM 스킬 자동 선택:**

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

**분할:**
3. PRD/스토리를 구현 단위로 쪼갠다:
   - `/prioritize-features` → impact/effort/risk 기반 우선순위
   - `/test-scenarios` → 각 기능별 QA 시나리오 (happy/edge/error)
4. Wave 구조로 배치:
   - **Wave 1** (순차): 공유 타입, 인터페이스, 유틸리티
   - **Wave 2** (병렬): 데이터 레이어 / UI 컴포넌트 / 테스트
   - **Wave 3** (순차): import 정리, 미사용 코드 제거
5. 각 Wave에 에이전트별 **파일 경로 + 성공 기준** 명시

**사용자 확인 없이** 다음 단계로 진행.

---

### [3] BUILD — /cowork 패턴으로 병렬 구현

**`/cowork`의 지휘자 패턴을 그대로 실행한다.** (상세는 cowork.md 참조)

핵심:
- 지휘자는 코드를 쓰지 않는다. 에이전트에게 **파일 경로 + 성공 기준 + 금지사항**을 전달
- Wave 1 순차 완료 → Wave 2 에이전트 **한 메시지에 동시 호출** → Wave 3 마무리
- 충돌 시 지휘자가 Edit으로 병합
- 실패 시 SendMessage로 해당 에이전트 재지시 (최대 3회)

---

### [4] CHECK — /check 패턴으로 리뷰 + 검증

**`/check`의 5-에이전트 병렬 리뷰를 그대로 실행한다.** (상세는 check.md 참조)

핵심:
- 5개 에이전트 동시 리뷰 (품질/간결화/무음실패/타입/보안)
- CRITICAL/HIGH 자동 수정 → 빌드/린트/테스트 검증
- 3회 실패 시 중단 + 상세 보고

---

### [5] SHIP — 커밋 + 푸시

```
git add <변경 파일> → git commit -m "<type>: <desc>" → git push origin <branch>
```
`--pr` 시 `gh pr create --title "<title>" --body "## Summary\n<변경 요약>"`.

---

### [6] DOCUMENT — 문서 자동 갱신

| 작업 | 스킬 | 산출물 |
|------|------|--------|
| 릴리즈 노트 | `release-notes` | 커밋 기반 카테고리별 변경 요약 |
| CLAUDE.md 갱신 | `/revise-claude-md` | 세션 학습 사항 반영 |
| 문서 동기화 | `/sync-docs` | prompt_plan.md, spec.md 갱신 |

---

## 중단 조건
- CRITICAL 보안 이슈 → 즉시 중단
- 빌드 3회 실패 → 중단 + 상세 보고

## 사용 예시
```bash
/super 로그인에 2FA 추가
/super --pr 결제 모듈 리팩토링
/super --skip-discover PRD가 이미 있으니 Plan부터
```
