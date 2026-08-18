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

## 2026-04-24 — Codex skill install sync

- [x] Codex 전역 `AGENTS.md`에서 제거된 `superpower` 라우터가 다시 발견되지 않도록 활성 skill discovery 경로에서 `superpower`와 `superpowers` symlink를 비활성화.
- [x] `codex-skills/AGENTS.md` 생성: 6개 Codex skill source of truth, `/harness-team` 병합 상태, sync/verify 절차 기록.
- [x] `codex-skills/{harness,harness-docs,harness-review,harness-qa,design,claude-dashboard}`를 `/Users/jobc/.codex/skills`로 `rsync --delete` 동기화.
- [x] 소스에 없는 stale `/Users/jobc/.codex/skills/harness-team` 제거.
- [x] README / README.en Codex 설치 절차를 `cp -R`에서 `rsync --delete`로 갱신하고 stale `harness-team` 제거 절차 추가.
- [x] `dev/harness-lint.md`의 stale `codex-skills/harness-team` 참조를 `harness` TEAM mode mirror로 갱신.
- [x] Verification: `diff -qr` 기준 6개 source/installed skill 차이 없음, installed file counts 일치, stale `harness-team` 없음.
- [x] `harness` / `harness-qa`가 Codex 앱에 보이지 않던 원인 수정: YAML frontmatter `description` 안의 `colon + space` 값을 quoted string으로 변경 후 재동기화.

## 2026-07-22 — Dearwell promotional landing page

- [x] Read the supplied design brief and brand assets, then lock content and visual rules -> verify: requirement checklist against the brief
- [x] Build a mobile-first one-page landing site in `dearwell-landing-page` -> verify: production build and rendered HTML assertions
- [x] Add a project-bound Dearwell character illustration -> verify: visual inspection and asset references
- [x] Review copy, responsive behavior, accessibility, and promotion guardrails -> verify: build, lint, and focused source checks
- [x] Publish the validated site -> verify: successful deployment URL

## 2026-07-22 — Dearwell mobile HTML revision

- [x] Replace the female field employee with a branded male Dearwell employee -> verify: inspect the edited illustration
- [x] Reframe the page around QR-to-app-download and customer outcomes -> verify: content checklist against the strategy context document
- [x] Produce one self-contained mobile-first HTML file -> verify: no external asset references and direct browser rendering
- [x] Validate 360px/390px mobile typography, overflow, and scroll flow -> verify: Playwright MCP screenshots and DOM measurements
- [x] Run final content and accessibility checks -> verify: automated assertions and source review

## 2026-07-22 — Dearwell mobile HTML copy and CTA revision

- [x] Replace active black download CTAs with a deeper Dearwell primary blue -> verify: computed mobile styles
- [x] Correct the disinfection-certificate benefit to health-center proxy submission -> verify: focused content assertion
- [x] Add the documented operations calculator benefit -> verify: feature copy matches the internal planning source
- [x] Remove the final setup and closing sections -> verify: DOM and source assertions
- [x] Recheck 360px/390px mobile overflow and visual flow -> verify: Playwright MCP measurements

## 2026-07-22 — Dearwell landing-page handoff package

- [x] Identify the final artifact and all reproduction inputs -> verify: source inventory
- [x] Collect briefs, brand assets, hero image revisions, final HTML, and visual references -> verify: packaged file list
- [x] Add a self-contained reproduction guide with requirement precedence -> verify: README review
- [x] Verify checksums, path independence, and packaged HTML rendering -> verify: checksum and Playwright checks

## 2026-08-18 — De-symlink migration: claude-forge -> claudex global/

- [x] Phase A: materialize six ~/.claude symlinked dirs as real dirs (cp -RLp + diff -r verified) -> verify: 0 top-level symlinks, per-slot counts match
- [x] Phase B: remove forge residue (.forge-* markers, forge-update command/hook, broken cc-chips symlinks) -> verify: ls confirms absence
- [x] Phase C: curate + absorb into repo global/ (commands 97->23 live/67 attic/7 plugin-dup deleted; skills 104->13 live/91 attic) -> verify: usage scan over history.jsonl + 2.1GB transcripts, counts reconcile
- [x] Phase C fixes: forge banners (10 agents), context-sync-suggest.sh onboarding block, agents-v2.md dead qjc-office refs + phantom agent roster, beneeds-workspace map -> verify: rg confirms zero remnants
- [x] global/install.sh (rsync copy deploy, --diff drift mode) + docs/global-absorption.md -> verify: --diff dry-run then live install, live counts match
- [x] Commit a3ea15f (386 files) + push to jobc90/claudex-power-commands main -> verify: git log/push output
- [x] Phase D: tar backup ~/claude-forge-final-20260818.tgz (736 entries) then delete ~/dev/side-project/claude-forge -> verify: fresh-context verifier workflow re-checks full checklist + headless boot test
- [x] Follow-up: delete side-project reference clones (claude-plugins-official, pm-skills) + claude-source -> verify: sole non-recoverable file preserved as docs/claude-code-reverse-engineering.md (commit 796d12d), workspace map pruned (incl. already-gone multi-ai-orchestration), zero dangling refs, marketplaces intact

## 2026-08-18 — v4.6.0 frontier refresh (Fable 5 / gpt-5.6-sol)

- [x] Full audit (5 parallel scanners: harness, codex mirror, global live set, meta/statusline/docs, tests) -> verify: findings with file:line evidence; baseline scorers green before edits
- [x] Fix tier inversion: fallback recognizes fable/mythos/sol -> Elite, unknown -> Advanced, identical in all copies incl. docs/capability-detection.md -> verify: md5-identical fallback blocks, zero 'conservative default' remnants
- [x] Elite-parent model economy: labor on opus, judgment roles (Planner/Architect/Diagnostician) inherit, Codex runtime always inherits -> verify: adversarial review of coherence (Auditor classified labor; no unclassified roles)
- [x] Restore mirror byte-parity (9 drifted refs + 9 sonnet pins in codex SKILL.md) + extend pre-commit-lint to diff shared references dynamically -> verify: cmp 16/16 identical; red-green drift probe exits 1
- [x] codex-skills: AGENTS.md Codex Runtime section (gpt-5.6-sol translation table) + gitignore re-include, .harness_codex -> .harness, harness-think openai.yaml -> verify: check-ignore exit 1, yq parses, rg harness_codex = 0
- [x] global/ pins swept to opus (orchestrate, handoff-verify, session-wrap, planner, verify-agent, agent-creator); agent-router trimmed to 11 real routes -> verify: comm -12 removed-vs-existing empty
- [x] Release meta: v4.6.0 CHANGELOG (corrects v4.5.1's parity claim), README ko/en, manifests -> verify: jq valid, both versions 4.6.0
- [x] Golden baseline honestly marked re-baseline pending (sonnet-era); measurement records untouched; deleted fixture-19 restored
