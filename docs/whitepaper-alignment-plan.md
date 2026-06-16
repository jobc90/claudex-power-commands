# claudex-power-commands × "The New SDLC With Vibe Coding" 정렬 계획서

> 근거: Google 화이트페이퍼 「The New SDLC With Vibe Coding」(Osmani·Saboo·Kartakis, 2026.5, 51p) 전문 정독 + 10개 원칙을 프로젝트 실제 파일에 대조한 11-에이전트 감사(파일 증거 기반).
> 작성 2026-06-16. 상태: **DRAFT — 승인 대기**. 이 계획의 어떤 항목도 아직 구현하지 않았습니다.

---

## 0. 한 장 결론

**이 프로젝트는 화이트페이퍼가 정의하는 "하니스(harness)" 그 자체다.** `Agent = Model + Harness`에서 claudex는 정확히 "Harness" 쪽 — 프롬프트·도구·컨텍스트 정책·훅·서브에이전트·관측성의 집합 — 을 만든다. 따라서 정렬 작업은 "새 패러다임으로의 전환"이 아니라 **"이미 하고 있는 하니스 규율을 화이트페이퍼 기준으로 끝까지 채우는 것"**이다.

감사 결과 핵심 한 줄: **갭의 대부분은 "없는 능력"이 아니라 "설계됐으나 미실행" 또는 "이미 계산된 신호의 last-mile 누락"이다.** 가장 큰 단일 발견 — 자체 A/B eval 프로그램이 `docs/v4.3.0-ab-measurement-design.md`에 완전히 설계돼 있으나 `tests/` 디렉터리는 git 이력상 한 번도 존재한 적이 없다(검증됨). 비전이 아니라 실행이 빠졌다.

**P0 5개(병렬 가능)**: ① 설계된 §7 최소 eval 실행 ② Trajectory Reporter + latency 계측 ③ Residual-Risk(잔여 20%) 요약 섹션 ④ PreToolUse/commit 결정론적 가드 훅 ⑤ Builder/Refiner에 DoD 주입.

---

## 1. 핵심 통찰 — 왜 이 화이트페이퍼가 이 프로젝트에 특별히 잘 맞는가

화이트페이퍼의 중심 명제와 claudex의 설계가 **구조적으로 동형(isomorphic)**이다:

| 화이트페이퍼 개념 | claudex에서의 대응물 |
|---|---|
| `Agent = Model + Harness` (모델 ~10%, 하니스 ~90%) | 프로젝트 전체가 하니스. 6 커맨드 + 27 에이전트 프롬프트 + references + hooks |
| "하니스를 코드처럼 다뤄라 — 리뷰·버전·소유" | `harness/INDEX.md` 앵커 + `/harness-lint` 일관성 검사 + Codex 미러 동기화 |
| Context Engineering(정적/동적·progressive disclosure) | `references/`를 온디맨드 로드, 에이전트별 fresh context, Selective Context Protocol |
| Intelligent Model Routing | `references/tier-matrix.md`의 tier×scale 모델 선택 |
| Output + Trajectory eval, "configuration failure" 진단 | QA(anti-leniency 루브릭) + Auditor(claim↔diff 대조) + Diagnostician(근인) |
| "Generation is solved; verification is the new craft" | 파이프라인 전체가 build보다 verify에 무게 |

**결론: claudex는 화이트페이퍼의 모범 사례를 이미 상당 부분 구현 중이다.** 따라서 이 계획의 1원칙은 **"새 표면적을 늘리기보다 이미 잘 작동하는 것을 끝까지 채운다"** — 프로젝트 자체의 anti-accretion 원칙과도 일치.

---

## 2. 정직한 정렬 현황 (과장 금지)

감사가 파일 증거로 확인한 "이미 강한 것"과 "실제 갭". 갭을 부풀리지 않는 것이 이 계획의 신뢰성이다.

| 원칙(쪽) | 이미 강한 것 (증거) | 실제 갭 |
|---|---|---|
| **Eval over demo** (p14,44) | QA 1–10 루브릭·anti-leniency·few-shot 보정 (`qa-prompt.md`) | 자체 에이전트 행동 eval **0%**. `tests/` git 이력상 부재. 설계만 존재(`v4.3.0-ab-measurement-design.md`) |
| **Context Engineering** (p15–18) | references 온디맨드, fresh context, Selective Context | `commands/harness.md` 1007줄. Banned Expressions 8중복·Rationalizations 8중복·Elite 블록 7중복(검증) |
| **Trajectory eval + 관측성** (p22,28,30) | Auditor claim↔diff, Diagnostician 인과, execution-log/traces | latency 미계산(타임스탬프 델타만 있으면 됨), 단일 run 종합 리포트 부재, `statusline.js`에 `.harness` 인지 **0** |
| **Guardrails/Hooks** (p28–30) | `agent-containment.md` CRITICAL 목록, Sentinel, Stop 훅 | **PreToolUse 훅 부재** — 화이트페이퍼의 "커밋 비밀번호 차단" 예시가 에이전트 사후검사로만 존재. 등록된 훅은 SessionStart/Stop뿐 |
| **Conductor vs Orchestrator** (p31–33) | Scale S 경량 경로, Non-Build EXIT | 전부 orchestrator. 1줄 수정도 ~5에이전트·2승인 파이프라인을 지불(conductor 언급 0) |
| **Agent Skills/progressive disclosure** (p17–18) | references 온디맨드, Codex SKILL.md 6개 작성 능력 입증 | references가 산문 참조일 뿐 — 트리거 메타데이터(frontmatter) 없음 |
| **AGENTS.md "where to start"** (p15,43–45) | Scout 매 run 컨텍스트 수집 | 학습 규칙을 타깃 repo에 **누적하지 않음** — 매 run 재-scout, CLAUDE.md/AGENTS.md 기록 에이전트 0 |
| **Factory / 성공기준>단계지시** (p24,31) | Planner/Worker/phase-book DoD, Worker PASS/FAIL 표 | Builder/Refiner에 "success criteria"·"DoD" 히트 **0** — 단계지시+합리화 산문 누적 |
| **Economics/Model Routing** (p40–42) | tier-matrix 모델 라우팅(frontier/cheap 분기) | context/token budget 규율 부재. routing은 이미 강함 → 보강만 |
| **80% 문제** (p34,47–48) | Diagnostician CONFIRMED/LIKELY/HYPOTHESIS, QA UNTESTABLE, confidence-calibration | 인간 판단 신호를 **BUILD Summary에서 평탄화** — `/harness-review` Reporter는 surface하나 `/harness`는 안 함 |

---

## 3. 6대 교차 테마 (여러 감사가 수렴한 패턴)

1. **측정은 설계됐으나 미구축.** `v4.3.0-ab-measurement-design.md`가 golden fixture·oracle·null fixture·사전등록 KEEP/CUT 임계·결과 CSV를 완전 명세하지만 `tests/`는 git 이력상 부재. 감사 1·3·8이 독립적으로 "§7 최소 first pass 실행"을 최우선으로 수렴. **이 테마가 다른 모든 프롬프트 수정의 신뢰성을 게이트한다** — 없으면 회귀가 보이지 않게 출하된다.
2. **관측 데이터는 있으나 종합·피드백되지 않음.** session-events 타임라인·execution-log·qa-evidence·statusline.js 비용 계측이 모두 존재하지만, (a) 단일 run으로 종합하는 것이 없고, (b) latency는 미계산, (c) statusline과 `.harness`가 만나지 않음. **build-from-scratch가 아니라 last-mile 종합 문제.**
3. **인간 판단 채널이 인간 도달 전에 끊긴다.** 파이프라인은 등급화된 불확실성(Diagnostician LIKELY/HYPOTHESIS, <70 confidence deferral, QA UNTESTABLE, Integrator RISKY)을 실제로 생성하지만 `/harness` BUILD Summary가 이진 PASS로 평탄화. **80% 문제 해결과 cross-run 학습은 같은 아키텍처 동작 — 이미 계산된 신호를 버리지 않는 것.**
4. **결정론적 강제가 에이전트 자율감시에 비해 과소사용.** containment CRITICAL 전체(커밋 비밀번호 차단 포함)가 Sentinel 에이전트의 사후 로그 검사로만, 그것도 Sentinel 활성 시에만 강제됨. 순수 regex 검사는 결정론적 훅으로, 판단은 에이전트로.
5. **정적 텍스트 중복(프롬프트 + Claude↔Codex 미러).** Banned Expressions·Common Rationalizations·Elite 블록이 손으로 N중 동기화 — context-rot + drift 표면. 공유 reference / 단일 진실원천으로 추출.
6. **프로젝트는 이미 잘 정렬됨 — 과장 금지.** 컨텍스트 엔지니어링·모델 라우팅·성공기준 계획·in-pipeline 검증이 모두 진짜 강하다. 대부분 갭은 last-mile 배관 또는 미실행 설계이지 빠진 능력이 아니다.

---

## 4. 권고 마스터 리스트 (deduped, 15개)

| # | 권고 | 유형 | 우선 | 노력 | 화이트페이퍼 근거 |
|---|------|------|------|------|------|
| 1 | 설계된 §7 최소 A/B eval 실행(M1 render-leak + M4 UNTESTABLE), fixture+결과 커밋 | new-ref | **P0** | M | Eval over demo p14 |
| 2 | Trajectory Reporter(`.harness/trajectory-report.md`) + session-events에 `dur=` latency 컬럼 | new-agent | **P0** | M | Trajectory eval+관측성 p22/28/30 |
| 3 | `/harness` S/M/L Summary에 "Residual Risk / 인간 확인 필요" 섹션 | mod-cmd | **P0** | M | 80% 문제 p34,47–48 |
| 4 | PreToolUse(Bash) deny-list 훅 + before-commit 시크릿 스캔 훅 | new-hook | **P0** | M | Guardrails/Hooks p28–30 |
| 5 | Builder/Refiner에 라운드별 DoD 주입 + DoD-Check 표 요구 | mod-cmd | **P0** | M | Factory/성공기준 p24–25 |
| 6 | conductor/`--quick` 모드: Phase-0 모드선택 fork(trivial 수정은 Meta-Loop 우회) | mod-cmd | P1 | M | Conductor vs Orchestrator p31–33 |
| 7 | Curator 단계(승인 게이트): 학습 규칙을 타깃 AGENTS.md에 dedup 누적 | new-agent | P1 | M | AGENTS.md "add a rule" p15,43–45 |
| 8 | Release-gate: 프롬프트 수정은 fixture 점수 통과 없이 출하 불가 | process | P1 | M | Eval gate p14 |
| 9 | ~~중복 가드레일 블록 추출~~ — **취소(전제 반박)**: 8개 블록이 전부 agent-specific(고유 해시 8) | — | ~~P1~~ | — | 검증으로 반박 |
| 10 | 범용 체크리스트 4종을 portable Claude Code Skill로 패키징 + Codex 미러 단일화 | new-ref | P1 | M | Agent Skills p17–18 |
| 11 | golden-task trajectory-eval 하니스(`dev/harness-eval.md` + `tests/golden/`) | new-ref | P1 | L | Trajectory eval p44 |
| 12 | `references/context-budget.md` + 에이전트별 token/cost 로깅 | new-ref | P2 | M | Context=financial lever p40–42 |
| 13 | Auditor "Trajectory Efficiency" 판정 + cross-run drift 원장 | mod-agent | P2 | M | 효율 trajectory eval p28/30 |
| 14 | 기계적 Sentinel 검사를 새 훅으로 이관(판단 검사는 에이전트 유지) | mod-agent | P2 | S | 결정론적>기억 p28–30 |
| 15 | (옵션) spec-as-eval 게이트 — opt-in/flag 전용, conductor fork에 종속 | mod-cmd | P2 | M | 코드 전 테스트/eval p43 |

---

## 5. P0 상세 (기반 — 더 많은 프롬프트를 건드리기 전에 하니스를 측정·관측·안전·정직하게)

### P0-1. 설계된 §7 최소 A/B eval 실행 — **단일 최고 레버리지**
- **무엇**: `docs/v4.3.0-ab-measurement-design.md`의 §7 "minimal first pass"만 구현. 가장 oracle이 선명한 2개 분야:
  - `tests/ab-corpus/observation-grounding/` — 런타임에서만 드러나는 결함을 심은 render fixture 10–15개 + oracle, 순수로직 null fixture 5개
  - `tests/ab-corpus/untestable/` — 도달 불가 앱 fixture 10개 + 도달 가능 null 5개
- **실행**: `/harness`를 fixture에 대해 ON/OFF 30–40회 페어 실행 → oracle 대조 수동 채점 → `tests/ab-results/*.csv`(설계의 필수 스키마: model·effort·condition·fixture·in-author|held-out·primary-metric·fp-metric·evidence-pointer)
- **왜**: CHANGELOG의 반복되는 "effect unmeasured" 면책을 **측정된 KEEP/CUT/INCONCLUSIVE 판정**으로 전환. 다른 모든 항목(특히 #8 release-gate)을 잠금 해제. 설계 스스로 이것을 "the whole commitment"로 한정.
- **대상**: `tests/ab-corpus/{observation-grounding,untestable}/`, `tests/ab-results/*.csv`, `docs/v4.3.0-ab-measurement-design.md`
- **검증**: CSV에 점수가 기록되고 KEEP/CUT 판정이 사전등록 임계와 비교되면 done. [높음 — 설계가 이미 명세돼 있어 실행 리스크 낮음]

### P0-2. Trajectory Reporter + per-agent latency
- **무엇**: `harness/trajectory-reporter-prompt.md` 신설 — 매 run 종료 시 session-events 타임라인·execution-log·QA 점수추이·Auditor 판정을 `.harness/trajectory-report.md` 한 장으로 종합. 동시에 `session-events.md` append 라인에 `dur=NNs` 컬럼 추가(ISO 타임스탬프가 이미 있으므로 델타 한 줄).
- **왜**: 화이트페이퍼의 "관측성 = 로그·트레이스·평가 + 비용/지연 계측, 없으면 조용한 드리프트를 못 본다"의 latency 갭을 거의 0 비용으로 메움. 이미 캡처된 데이터의 종합일 뿐.
- **대상**: `harness/trajectory-reporter-prompt.md`, `harness/INDEX.md`, `commands/harness.md`, `references/session-protocol.md`, Codex 미러
- **검증**: 한 run 후 trajectory-report.md에 단계별 dur·점수추이·판정이 채워지면 done.

### P0-3. Residual-Risk("잔여 20%") Summary 섹션
- **무엇**: `/harness` S/M/L Summary 템플릿에 "Residual Risk / 인간 확인 필요" 섹션 추가 — Diagnostician LIKELY/HYPOTHESIS, Refiner/Integrator <70 deferral, QA UNTESTABLE, Integrator RISKY 병합을 "손으로 확인할 상위 N 지점" 랭크 리스트로 통합.
- **왜**: 파이프라인이 **이미 계산하는** 인간 판단 신호를 BUILD Summary가 버리고 있다(`/harness-review` Reporter는 surface). 화이트페이퍼 "잔여 20%(엣지·통합 seam·미묘한 정확성)에 인간 주의를 집중"의 직접 구현. 새 분석 0 — 신호 재사용.
- **대상**: `commands/harness.md`, `harness/qa-reporter-prompt.md`, `codex-skills/harness/SKILL.md`
- **검증**: PASS run에서도 잔여 위험 항목이 비어있지 않게 출력되거나 "없음"이 명시되면 done.

### P0-4. PreToolUse deny-list + before-commit 시크릿 스캔 훅
- **무엇**: `hooks/guard-bash.sh`(PreToolUse Bash deny-list) + `hooks/guard-commit.sh`(커밋 전 시크릿/하드코딩 비밀번호 regex) 추가, `hooks/hooks.json` 등록. `agent-containment.md` CRITICAL 목록의 순수 regex 패턴을 결정론적으로 강제.
- **왜**: 화이트페이퍼의 문자 그대로의 예시("하드코딩 비밀번호 커밋 차단")가 현재 결정론적 구현이 없다 — 조건부 Sentinel 에이전트의 사후 검사뿐. "탐지"가 아니라 "예방", Sentinel 비활성 구간에서도 무조건 작동.
- **주의(충돌)**: Codex에는 PreToolUse 런타임이 없음 → Claude 전용으로 만들고 Codex 측은 기존 Stop 훅처럼 "문서화된 수동 등가물"로 미러.
- **대상**: `hooks/guard-bash.sh`, `hooks/guard-commit.sh`, `hooks/hooks.json`, `references/agent-containment.md`
- **검증**: 하드코딩 시크릿을 포함한 커밋 시도가 차단되는 red-green 테스트.

### P0-5. Builder/Refiner에 DoD 주입
- **무엇**: phase-book/build-spec에 이미 존재하는 DoD(경로 + 관측가능 증거 + verify 커맨드)를 Builder/Refiner 태스크에 명시 전달하고, Worker처럼 PASS/FAIL DoD-Check 표를 출력하도록 요구.
- **왜**: 가장 비싼 station(Builder/Refiner)이 파이프라인의 나머지가 따르는 성공기준 철학과 어긋나 있다 — 두 프롬프트에 "success criteria"/"DoD" 히트 0, 대신 단계지시+합리화 산문이 누적(검증). 화이트페이퍼 "단계지시가 아니라 성공기준을 주고 반복하게 하라". artifact가 이미 존재하므로 배선만 신설 — 저위험.
- **대상**: `commands/harness.md`, `harness/builder-prompt.md`, `harness/refiner-prompt.md`
- **검증**: Builder 출력에 DoD-Check 표가 등장하고 QA 점수 회귀가 없으면 done(P0-1 eval로 측정).

---

## 6. P1·P2 요약

**P1 — 심화·통합 (측정·관측 기반 위에 build)**
- **#6 conductor/`--quick`**: `/harness` 내부의 얇은 Phase-0 fork(플래그 + 분기, 기본 OFF, 새 파이프라인/에이전트 0). 1줄 수정에 ~5에이전트를 지불하는 문제 해소. 기존 Non-Build EXIT 절을 확장. **dual-mode 정체성을 완성**(현재 orchestrator 절반만 구현).
- **#7 Curator(승인 게이트)**: Diagnostician이 이미 검출하는 Cumulative Patterns를 타깃 repo의 AGENTS.md에 dedup 누적(show-then-append 승인 필수 — containment 준수). Scout가 다음 run에 fast-path prior로 읽음. stateless → 누적 학습.
- **#8 Release-gate**: `harness/*-prompt.md`/`commands/*.md` 변경 시 §7 fixture 실행, 사전등록 임계 이하 회귀면 버전 bump 차단. **P0-1에 하드 의존.**
- **#9 가드레일 중복 추출 — 취소(전제 반박, 2026-06-16)**: 실행 전 검증으로 확인 — "Banned Expressions"(8 프롬프트)·"Common Rationalizations"(10 프롬프트)는 **헤딩/포맷만 공유하고 내용은 전부 에이전트별 고유**(8개 distinct 해시; scout=증거 규율 `"seems to use"→"uses (file:line)"`, planner=명세 규율 `"should work"→정확한 테스트가능 동작`). 단일 출처로 추출하면 에이전트별 가드레일을 파괴함. 감사(synthesis)가 "포맷 공유"를 "내용 중복"으로 오판. **실행하지 않음.** (교훈: refactor 전 중복 실측 필수.)
- **#10 범용 체크리스트 4종 Skill화**: `.harness` 결합이 없는 4개(security·error-handling·confidence-calibration·observation-grounding)만 `skills/*/SKILL.md` + plugin.json `skills` 키로. **7개 파이프라인 결합 reference는 절대 건드리지 않음**(충돌). Codex 미러 단일화.
- **#11 golden-task trajectory-eval(L)**: §7 fixture를 재사용 가능한 시나리오로 일반화(known-good build, 심은 persistence 버그를 QA가 FAIL해야, 조작된 claim을 Auditor가 잡아야, 도달 불가 앱을 UNTESTABLE로). release-gate가 강제하는 영속 회귀 스위트. P0-1이 방법을 입증한 뒤 진행.

**P2 — 거버넌스·다듬기**
- **#12 context-budget.md**: Selective Context Protocol을 전 에이전트 per-role 읽기 예산으로 일반화 + statusline 비용을 파이프라인에 연결. routing은 이미 강하니 거버넌스 폴리시. **budget→routing 결합이 Elite tier 불변식을 덮어쓰지 않게**(충돌).
- **#13 Auditor Trajectory-Efficiency**: 동일 exit-code 반복·중복 재렌더·baseline 초과 라운드 → EFFICIENT/ACCEPTABLE/WASTEFUL + cross-run 원장(retry율 상승·1라운드 점수 하락 = 조용한 드리프트 탐지). P0-2 뒤.
- **#14 Sentinel 기계검사 훅 이관**: 순수 regex는 훅(예방), Sentinel은 scope·부정직 진척주장·prompt-injection 의미검사(판단) 유지. P0-4에 의존, 순수 cleanup.
- **#15 (옵션) spec-as-eval 게이트**: 코드 전 verify 커맨드를 실패 테스트로 — **opt-in/flag 전용**, conductor fork에 종속(기본화하면 ceremony 역전).

---

## 7. 하지 말 것 — 충돌·가드레일 (감사가 명시한 안티패턴)

1. **11개 reference 전체를 Skill화하지 말 것.** 7개(meta-loop·tier-matrix·team-build·session-protocol·phase-verification·completion-gate·agent-containment)는 `.harness/` 경로와 내부 에이전트명을 하드코딩 — orchestration 배선 자체다. SKILL.md로 강제하면 file-handoff 척추가 파편화. **범용 4개만.**
2. **spec-as-eval를 기본값으로 만들지 말 것.** 커밋된 테스트 스위트를 모든 코드 전에 강제하면 greenfield/throwaway build와 conductor 모드(#6)와 충돌. opt-in 전용.
3. **Curator를 무승인 write-back으로 만들지 말 것.** 에이전트가 사용자 repo의 build 범위 밖 파일을 편집 — containment의 external-write 규율 위반. show-then-append + dedup + 승인 필수.
4. **token budget을 model routing 위에 두지 말 것.** context 70% 초과 시 자동 모델 다운그레이드는 Elite-tier "Builder(L) 다운그레이드 금지" 불변식과 충돌 — 측정 불가한 품질 회귀 유발. tier 불변식이 budget 압력을 이긴다. P2로 미룸.

---

## 8. 실행 순서

**Phase P0 — 기반 (서로 독립, 병렬 가능)**
(1) §7 eval 실행 → 이후 모든 프롬프트 수정과 release-gate 잠금 해제 · (2) Trajectory Reporter + latency · (3) Residual-Risk 섹션 · (4) PreToolUse/commit 훅(Claude 전용, Codex 수동 등가물) · (5) Builder/Refiner DoD 주입. + S-노력 quick-win 동승.

**Phase P1 — 심화·통합** (측정/관측 기반 위에)
(6) conductor fork → (7) Curator → (8) Release-gate[P0-1 의존] → (9) 가드레일 추출 → (10) Skill 패키징[frontmatter quick-win 의존] → (11) golden-task eval(L)[P0-1이 방법 입증 후].

**Phase P2 — 거버넌스·폴리시**
(12) context-budget → (13) Auditor efficiency[P0-2 의존] → (14) Sentinel 훅 이관[P0-4 의존] → (15) 옵션 spec-as-eval.

**전 단계 공통**: 행동 변경 편집은 Codex skill 트리에 미러하고 `/harness-lint`로 4-place 동기화 검증(프로젝트 기존 규율).

---

## 9. 빠른 성과 (S-노력, P0와 동승 가능)

- `session-events.md` append 라인에 `dur=NNs` 컬럼(1줄 스키마 변경, P0-2 잠금 해제)
- `commands/harness.md`의 중복 session-state/event-log bash 블록 ~6개를 `session-protocol.md` 포인터로 추출(~40–60줄 절감)
- 범용 체크리스트 4종에 YAML frontmatter(name + load 트리거) 추가(가산적, 기존 16 소비처 무영향)
- Refiner에 Worker식 "Success Criteria Check" PASS/FAIL 표 추가
- `commands/harness.md` Cost Awareness 표에 tier별 token/cost 밴드 추가(CapEx/OpEx 가시화)

---

## 10. 메타 원칙 — 이 계획 자체를 eval로 게이트하라

화이트페이퍼의 "set the bar at the eval, not the demo"는 **이 계획에도 적용된다.** P0-1(eval)을 먼저 세우는 이유: 이후 P0-3·P0-5 같은 프롬프트 변경이 QA/Auditor의 결함 검출력을 떨어뜨렸는지 fixture로 측정할 수 있어야 한다. **"개선했다"는 demo가 아니라 KEEP/CUT 판정으로 증명한다.** 이 계획의 성공 기준 자체가 `tests/ab-results/*.csv`의 회귀 없는 점수다.

> 다음 단계: 이 계획서를 검토 후, P0 항목을 `/harness`(또는 직접)로 실행할지 결정. P0-1(eval 실행)을 먼저 세우는 것을 권장 — 나머지의 신뢰성을 게이트하기 때문. [높음]

---

## 11. 실행 후 검증 결과 (2026-06-16)

이 계획을 실제로 실행한 결과. **각 항목은 실행 전 전제를 검증**했고(=#9의 교훈), 그 결과 P2 tail의 여러 항목이 "감사(synthesis)의 과대 진단"으로 판명됐다.

### 완료 (커밋됨, 6커밋 — 브랜치 `feat/whitepaper-alignment-p0-p1`)
- **P0 전부**(1–5): eval 스캐폴딩·Trajectory Reporter·Residual-Risk·결정론적 가드 훅(guard-bash/commit)·Builder/Refiner DoD.
- **P1 #6 Conductor `--quick`**, **#7 Curator**(승인 게이트 학습 → 타깃 AGENTS.md).
- **eval 캠페인 (3라운드)**: observation-grounding이 **in-author KEEP(+6)·독립저자 held-out KEEP(+4)·M4 strict-OFF KEEP(+6)**, FP 0. caveat: mechanism-level(full-pipeline 아님)·render-geometry/execution-output 집중·sonnet/xhigh 한정. CHANGELOG·`observation-grounding.md`·`tests/ab-results/` 기록.
- **#11 golden 회귀 그물**: `tests/golden/` 4 시나리오 + `golden-score.py`(regression→exit 1), baseline 4/4. = #8 게이트의 실체.

### 취소 — 검증으로 전제 반박
- **#9 가드레일 중복 추출**: 8개 "Banned Expressions" 블록이 전부 **고유**(distinct 해시 8). 에이전트별 고유 규율이지 중복 아님. 추출하면 가드레일 파괴.
- **#14 Sentinel 기계검사 훅 이관**: Sentinel의 CRITICAL 검사는 **Codex의 유일 enforcement**(Codex엔 PreToolUse 없음) + Claude defense-in-depth → 제거 불가. 계층 분담 노트는 **이미 P0-4에서 agent-containment.md에 추가됨**. → 실질 완료, 별도 행동 불필요.
- **#10 "Codex 미러 단일화"**: 4종 체크리스트를 단일 스킬 출처로 모으면 내용 복제 또는 16개 path 소비처 재배선(위험) 필요. 안전한 부분(frontmatter)만으론 가치 미미. → 보류.

### 보류 — 저가치 polish/governance (코어 아님)
- **#8 release-gate**: golden-score.py + dev/harness-eval.md로 **수동 게이트는 이미 제공**. "매 커밋 자동" 버전은 에이전트 재생 비용상 git pre-commit엔 부적합 → 수동 게이트가 올바른 형태.
- **#12 context-budget**, **#13 Auditor efficiency**: governance polish. 라우팅은 이미 강함.

### 바텀라인
**고가치 코어(P0 + 측정 + 회귀 그물)는 완료·검증됨.** P2 tail은 감사 과대 진단으로 대부분 불필요/부적절. 권장 다음 단계는 **새 항목 추가가 아니라 브랜치 검토·push/병합**(consolidation).
