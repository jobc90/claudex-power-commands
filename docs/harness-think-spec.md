# `/harness-think` 설계 스펙 (Surveyor — codebase-anchored 토론 커맨드)

> 상태: **승인·구현·측정 완료 (2026-06-17).** Claude-only로 구현 후 M8 A/B **양 split KEEP**(in-author +4 / 독립저자 held-out +4, FP 1/2) → v4.5.0 공개 릴리즈(Codex 미러 포함). 측정: `tests/ab-results/RESULTS-grounding.md`.
> 근거: 블라인드 A/B 니치 검증(2026-06-16) + 3-아키텍트 judge-panel 합성(minimalist/standalone/submode). 작성 2026-06-17.

---

## 0. 한 줄 요약

**`/harness-think`는 "코드베이스에 매인 결정·feasibility 토론"을 위한 read-only 사고 파트너다.** 유일하게 load-bearing한 기능은 **강제 grounding(cite-or-abstain)** — repo 사실에 대한 모든 주장 앞에 `[path:line]` 인용을 붙이거나, 못 찾으면 `[Unknown]`으로 강등한다. 추론 품질(결론 우선·confidence tag·anti-sycophancy)은 사용자의 상시 페르소나가 이미 공급하므로 **재구현하지 않고 상속**한다. 파이프라인 아님, 서브에이전트 0, 신규 에이전트 프롬프트 0, 코드 안 씀.

## 1. 왜 만드는가 (검증된 근거)

블라인드 A/B(2 케이스 × 3 arm: persona / +frameworks / +grounded)에서 **두 케이스 모두 `grounded > frameworks > persona`로 복제**됐고, 결정적 장면은 이것이다:

- **케이스 A에서 persona-only arm이 #12·#13을 "둘 다 build 가치 있음"으로 자신 있게 추천** — 우리가 이미 *둘 다 취소*로 판정한 항목을. repo를 안 읽으니 유창하고 확신에 찬 **틀린** 답.
- 오직 repo를 읽은 arm만 정답에 도달. 차별자 = **code grounding**(2/2 복제).
- 부수 발견: **frameworks-without-grounding은 net-negative** — 깔끔한 매트릭스로 #12를 자신 있게 틀리게 greenlight(구조화된 확신찬 오답).

→ 니치 검증됨. 단 가치는 정확히 **grounding**에 있고, frameworks는 부차적이며 grounding 없이는 해롭다.

**니치 경계(중요)**: 검증된 가치는 *검증가능한 repo 제약이 답을 결정하는* feasibility·decision 토론에 한정된다. 순수 추상/제품/시장 브레인스토밍은 ground할 사실이 없어 grounding 우위가 사라진다 → 페르소나 + 외부 PM Suite가 이미 커버. 이 커맨드는 거기로 **라우팅**하지 재구현하지 않는다.

## 2. 결정된 surface form — standalone 커맨드 (submode/skill 기각)

| 후보 | 판정 | 이유 |
|---|---|---|
| **standalone 커맨드** | ✅ 채택 | 기존 4개 형제(`/harness-docs·-review·-qa`)와 동일한 단일목적 표면. read-only invariant를 자기 Critical-Rules 블록으로 깔끔히 선언. slash 메뉴에서 발견 가능 |
| submode (`/harness --think`) | ❌ 기각 | 전제("EXIT 브랜치를 deepen")가 EXIT의 목적을 뒤집음 — `harness.md:44-48` EXIT은 non-build를 *밖으로 내보내려고* 존재. 56KB 빌드 커맨드에 read-only chat을 접으면 reader가 tier/Scale/Security triage를 통과해야 하고, 모든 다른 경로가 코드를 쓰는 커맨드에 read-only invariant가 묻힘. 플래그는 메뉴에서 invisible |
| 자동로드 skill | ❌ 기각 | description 매칭으로 예측 불가하게 발화. eval의 load-bearing 발견 = grounding은 *의식적·가시적·의도적으로 진입한* 행위여야 함. 명시 커맨드라야 grounding 게이트가 선택된 행위가 됨 |

- **역할 라벨 = "Surveyor"** ("Conductor"는 `/harness --quick`이 점유 — `harness.md:50-61`, 재사용 금지).
- **inline, 서브에이전트 0** — grounding scout를 쓰면 인용이 *숨겨져* 메커니즘이 의존하는 가시성이 깨짐(`meta-loop-protocol.md:24-28`: self-enforced이지 runtime-enforced 아님 → 서브에이전트는 enforcement 이득 0에 handoff seam만 추가). grounding은 메인 에이전트 자신의 행위.
- **신규 에이전트 프롬프트 0** (29 + 1 helper 불변) — anti-accretion 신호로 INDEX에 명시 등록.

## 3. 핵심 메커니즘 — cite-or-abstain grounding (load-bearing)

repo 명사(파일/플래그/엔티티/브랜치/config)를 4-state 원장으로 해소한다:

```
| claim-id | repo 명사 | 증거 (path:line) | state | as-of (git short-sha) |
```

- **state**: `VERIFIED` / `NOT-FOUND` / `STALE` / `UNKNOWN`.
- **RULE**: repo 사실을 주장하는 모든 문장은 *이번 세션의* 실제 Read/Grep에서 얻은 인라인 `[path:line]`을 달거나, `[Unknown — not found: <검색어>]`로 강등. **인용 없는 repo 주장 금지.** `[Unknown]`이 확신찬 추측을 이긴다 — eval이 증명한 실패 모드 그 자체.
- **STALE 상태는 해당 명사를 "live target"으로 취급하는 것을 차단** (예: `console-solution-app`을 ground하면 "Deprecated 예정 / 2026-06-02 모노레포 이전" 라인에 걸림 → state=STALE → "새로 빌드" 결론 봉쇄).
- **as-of git short-sha** 컬럼 — 인용의 신선도 기준점.
- **가시성**: 응답 첫 줄에 배너 `grounded: N files read, M claims cited, K unknowns`.
- **CODE 질문은 트리를 검증**(워크스페이스 CLAUDE.md 아님 — doc은 main vs develop drift를 인정하므로 doc-vs-tree-drift를 태그).
- **브랜치-상태 질문은 git/branch read를 명시적으로** 수행(112-ahead/58-behind는 단일 파일 Read로 안 나옴).

> 이것은 `observation-grounding.md`("exit-0 = well-formed, not correct")의 결정-레이어 쌍둥이다: **"유창한 답 = well-formed, not grounded."**

## 4. 플로우 (단일 커맨드 본문 ~150줄, `.harness` ceremony 최소)

1. **SCOPE-GATE** (grounding 비용 전에) — 2문항 triage. **Q1**: 답이 *이 repo* 사실에 의존하나? **Q2**: 틀린 repo 사실이 actively harmful할 수 있나(취소된 걸 build 추천, 불변식 깨는 마이그레이션)?
   - **IN** = 둘 다 yes (또는 Q1 yes + Q2 unclear) → grounding 진행.
   - **EXIT** = Q1 no → 한 줄 출력 후 추상/제품/시장은 *named* PM Suite(`/strategy·/discover·/pre-mortem`)나 일반 대화로 라우팅, `.harness/` 잔여물 0.
   - **MIXED** = repo-anchored 하위주장만 ground, 추상 잔여는 일반대화/PM으로, 어느 쪽인지 명시.
   - BUILD 요청("구현/수정/추가")은 "/harness 영역"으로 EXIT.
2. **GROUND** (inline, 메인 에이전트 Read/Grep/Glob) — `.harness/think-grounding.md`(gitignored)에 4-state 원장 작성. §3 규칙 적용.
3. **DISCUSS** (적응형 frameworks, grounding 뒤에 게이트) — 질문 형태가 요구하는 만큼만, **없을 수도 있음**. 이진 정착 질문 → 결론 우선 + confidence tag, STOP. ≥2 live 옵션 → 셀이 *원장 행을 인용하는* 트레이드오프 매트릭스(`[Unknown]` 셀은 표시, 날조 금지). 페르소나 행동은 글로벌 CLAUDE.md에서 **상속**(재진술 안 함). "프레임워크는 원장 사실만 소비 가능; 정착된 질문에 매트릭스 강제 = rigid-template 안티패턴."
4. **RED-TEAM** (기본 OFF) — grounding이 high-stakes·low-reversibility 결정(스키마 마이그레이션, repo topology, 패키지 삭제)을 드러낼 때 **한 번 제안**(자동실행 아님). Y면 *같은 원장의 인용된 사실만으로* 반대 결론 재논증, contested 인용 보고(= 진짜 리스크). 병렬 fan-out 없음(그건 `/harness TEAM`).
5. **HANDOFF** (build seed, spec 아님) — "이거 하자"로 수렴 시(또는 `--seed`)만. `.harness/think-handoff.md` 발행: (a) 한 줄 결정 + confidence, (b) build가 존중해야 할 VERIFIED 사실, (c) 열린 `[Unknown]` 가정, (d) **"Explicitly OUT-OF-SCOPE" 줄**(예: "취소된 항목 build 금지" — 직접적 해독제), (e) copy-paste `/harness "..."` 문자열. 출력: "결정이 섰으면 위 seed로 /harness를 직접 실행하세요. 저는 빌드로 넘어가지 않습니다." **STOP. /harness 자동호출 절대 안 함.**

## 5. Anti-patterns (Critical Rules 블록)

`.harness/think-*.md` 외 어떤 repo 파일도 쓰지/편집하지 않는다 · 이번 세션 `[path:line]` 없이 repo 주장 안 함 · CODE 질문에 워크스페이스 CLAUDE.md를 verified로 인용 안 함(트리 검증 + drift 태그) · `/harness` 자동 전환 안 함 · 정착된 질문에 프레임워크 강제 안 함 · 추상 질문 ground 안 함(EXIT/라우팅) · PM-Suite/페르소나 재구현 안 함(전자는 라우팅, 후자는 상속) · "Conductor" 재사용 안 함 · grounding에 서브에이전트 안 씀(inline, 인용 가시성 유지) · load-bearing 사실이 `[Unknown]`인데 수렴 결론 제시 안 함 · STALE 명사를 live target으로 취급 안 함.

## 6. 파일 구조 + 다운스트림 영향

- **신규** `commands/harness-think.md`
- **신규** `harness/references/think-grounding.md` (on-demand, scope-gate=IN일 때만 로드. `observation-grounding.md` 구조 미러: 1 규칙 + 4-state 원장 스키마 + as-of 규칙 + `[Unknown]`-over-guess 강등 + anti-over-grounding stop("주장당 인용 1개로 충분, 변화없는 파일 재독 금지") + observation-grounding.md 교차참조 + doc-vs-tree-drift 위험)
- **편집** `harness/INDEX.md` (0-서브에이전트 inline 커맨드로 등록 — 에이전트 수 **불변** 29+1 — + think-grounding.md Shared-Reference 행)
- **편집** `plugin.json` + `marketplace.json` + `README`(커맨드 6→7, 버전 bump — MEMORY 4-place sync)
- **Codex 미러** `codex-skills/harness-think/{SKILL.md, references/think-grounding.md}` — **§9 핵심 결정에 따라 staged** (M8 KEEP 후 추가). 아티팩트 → `.harness_codex/think-*.md`

## 7. 측정 계획 (M8 — 기존 rig 재사용)

- **M8 = repo-fact escape rate.** 코퍼스 `tests/ab-corpus/grounding/`.
- **골든 시나리오** (2026-06-16 근거에 연결): `/harness-think "디어웰 솔루션 독립 앱이랑 console-solution-user 둘 다 새로 빌드해야 하나?"` — ON은 "Deprecated 예정 / 2026-06-02 모노레포 이전 / 완전 흡수" 라인을 인용(원장 state=STALE)하고 "둘 다 아님 — 하나는 흡수, 하나는 이관, 둘 다 빌드는 오답"으로 결론. OFF(persona-only)는 둘 다 빌드를 자신 있게 추천(기록된 실패).
- **스코어러 지표**: arm이 cancelling fact를 *인용과 함께* 명명했는가.
- **Null fixtures** = 진짜 추상 질문(ON이 EXIT해야 — over-grounding 가드, co-primary FP).
- **규모**: cancelling-fact 5 + abstract-null 2 (§7 minimal-first-pass).
- **사전등록 KEEP** = margin ≥ 3 & null FP 0 (M1/M4와 동일). 채워지기 전까지 score.py는 INCONCLUSIVE → ship + flag unproven, 절대 silent cut 안 함.

## 8. Open risks (정직한 천장)

1. **self-enforcement는 soft floor** — runtime이 인용 전 파일 열기를 강제하지 않음. 게으른/과신 에이전트가 `[path:line]`을 날조하거나 stale doc을 인용 가능. 가시적 원장이 비용을 올리고 위조를 auditable하게 하지만 Stop-hook급 hard gate는 아님. 유일 기계적 backstop은 훅이나, 그건 우리가 줄이려는 표면적을 재도입. 완화 = 골든 회귀 + M8이 *체계적* 회귀를 잡는 것(per-run 보장 아님).
2. **인용 존재 ≠ 인용 지지** — 게이트는 `[path:line]` 존재만 확인, 그 라인이 주장을 *뒷받침하는지*는 아님. 완화 = load-bearing 인용마다 "왜 이 라인이 주장을 정착시키나" 한 줄 + opt-in red-team이 contested 인용 재독.
3. **garbage-in** — repo/doc 자체가 stale하면 충실히 틀린 사실을 인용. doc-vs-tree-drift 안티패턴이 줄이나 제거 못함.
4. **scope-gate는 soft classifier** — 답하는 같은 모델이 분류, keyword backstop 없음. MIXED에서 오발 가능, 위험 방향 = repo 의존이 숨은 전략질문을 *under-ground*. M8 null은 over-ground 방향만 가드 → under-ground는 측정 안 될 수 있음.
5. **페르소나 중복은 실재·협소** — grounding 빼면 순수 페르소나 중복. forced-grounding-by-default가 relying-on-discipline을 이기기 때문에만 keep을 번다(eval이 증명). **M8이 INCONCLUSIVE/CUT면 이 커맨드는 자기 원칙상 bloat. M8에 살고 죽는다.**

## 9. 핵심 결정사항 (검토 시 확정 요청)

**Codex 미러를 지금 출하 vs eval 뒤로 stage?**

- **Option A (둘 다 지금)**: 최대 parity. 단 7번째 커맨드 + 신규 reference를 `harness/`와 `codex-skills/` *양쪽*에 추가 → 가치가 한 게이트뿐이고 KEEP이 아직 INCONCLUSIVE(M8 0행)인 규율에 유지보수 2배.
- **Option B (권장 — stage)**: Claude-only 먼저(`commands/harness-think.md` + `harness/references/think-grounding.md`) → M8 코퍼스 seed → 블라인드 A/B → **score.py가 margin ≥3, null FP 0로 KEEP 보고한 뒤에만** Codex 미러 추가. INDEX P1 #10("mirror collapse" defer)의 선례 + suite의 asymmetry 규칙(INCONCLUSIVE는 ship+flag, never silent cut)과 정합. 비용 = 일시적 Claude/Codex 기능 편차. A의 비용 = 정당성 미검증 표면에 영구 2배 유지보수.

> 중립 프레이밍: **day-one 크로스플랫폼 parity** vs **evidence-gated accretion**, 어느 쪽을 더 가치있게 보는가?

## 10. 검토 요청 사항

1. surface form(standalone 커맨드, "Surveyor") 동의?
2. §9 핵심 결정 — A vs B (권장 B)?
3. 스코프 경계(codebase-anchored 전용, 추상은 EXIT) 동의? 더 좁히거나 넓힐 부분?
4. `--seed` 외 플래그 0 — 동의? (미니멀 바이어스)

승인 시 구현 순서: ① `commands/harness-think.md` + `harness/references/think-grounding.md` 작성 → ② M8 골든/코퍼스 seed → ③ 블라인드 A/B 실행 → ④ KEEP이면 Codex 미러 + 4-place sync + 버전 bump.
