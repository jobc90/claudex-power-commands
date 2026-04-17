## 2026-03-30

- [x] Claude 기준 7개 commands와 Codex skills 차이 확인
- [x] Codex legacy skills (`check`, `cowork`, `docs`, `super`) 제거
- [x] Codex skills를 `harness`, `harness-docs`, `harness-review`, `harness-team`, `harness-qa`, `design`, `claude-dashboard` 7개로 재편
- [x] Codex skill references에 harness prompt 번들 반영
- [x] README / README.en 의 Codex 관련 설명을 새 구조로 갱신

## 2026-04-17 — v4.1.0 (Meta-Loop + Capability Detection)

Reference plan: `tasks/plan-opus-47-upgrade.md`.

- [x] Phase 1 — Tier 재정립 + 명명 중립화: `session-protocol.md` §9/§9.5, `tier-matrix.md`, agent prompts 9개, `agent-containment.md`, commands/harness.md. 전 live source Mythos/opus-4.x 잔존 0건.
- [x] Phase 2 — Elite tier 효과 활성화: tier-aware round limits, QA threshold, Sentinel/Auditor activation, Scale thresholds. qa/auditor/scout prompts + harness-docs/qa/review commands.
- [x] Phase 3 — Meta-Loop Architecture 기본 내장: `meta-loop-protocol.md`, `phase-verification-protocol.md`, `phase-book-planner-prompt.md`, `phase-verifier-prompt.md`, `phase-orchestrator-prompt.md` 신규. commands/harness.md Phase 0.7 + Phase 4-verify 삽입. planner / diagnostician prompt 업데이트. INDEX.md 반영.
- [x] Phase 4 — Agent 프롬프트 Elite-tier 대응 강화: sentinel (scope creep, evidence backdating, hook bypass 확장), auditor (quantitative claim verification, phase boundary integrity), qa (anti-sycophancy), builder (SHA-256 audit, subagent spawn log), worker (containment + Elite HIGH gating), refiner (hook bypass self-check).
- [x] Phase 5 — Codex Mirror 동기화: 6 SKILL.md에 Meta-Loop + tier-aware 반영. 모든 references mirror cp 동기화.
- [x] Phase 6 — 문서 + 버전 범프 v4.1.0: plugin.json version + description, README.md / README.en.md What's New v4.1.0, CHANGELOG.md, docs/meta-loop-design.md, docs/capability-detection.md 신규. docs/mythos-harness-improvement-plan.md → docs/harness-hardening-plan-v3.md (git mv). .gitignore 신규 (.harness/, .playwright-mcp/).
