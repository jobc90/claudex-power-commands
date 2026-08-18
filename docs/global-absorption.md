# Global Config Absorption — 탈 claude-forge 단일화 (2026-08-18)

> 실행 기록. 계획 원문: `docs/HANDOFF-desymlink-migration.md`

## 결과 요약

`~/.claude`의 symlink 설치(→ `~/dev/side-project/claude-forge` 작업트리)를 전부 걷어내고,
전역 설정의 정본을 이 저장소의 `global/`로 옮겼다. claude-forge 클론은 삭제
(최종 백업: `~/claude-forge-final-20260818.tgz`, 원격 `sangrokjung/claude-forge`는 사용자 소유 아님).

```
global/                  # 정본. install.sh가 ~/.claude로 복사 배포 (symlink 아님)
├── agents/    (25)      # 전원 model: opus 고정, forge 배너 제거
├── rules/     (9)       # 플러그인으로 배포 불가 → install.sh가 유일한 배포 경로
├── commands/  (23)      # 사용 실적·규칙 참조 기준 선별
├── skills/    (13)      # 〃
├── hooks/     (16)      # hooks.json + 15 스크립트 (settings.json은 session-cleanup.sh 참조)
├── scripts/   (2)       # md-to-docx, pdf-enhance
├── attic/               # 강등 보관 (설치 안 됨) — commands 67, skills 91
└── install.sh           # 배포: ./global/install.sh, 드리프트 확인: --diff
```

## 절대 규칙 — 레이아웃 함정

**`global/` 내용물을 저장소 최상위 `commands/ skills/ agents/ hooks/`로 옮기지 말 것.**
`plugin.json`이 컴포넌트를 명시하지 않으므로 플러그인 로더가 최상위 디렉터리를 자동
발견한다. 최상위로 옮기는 순간 커맨드·스킬·에이전트 전부가 `claudex:*`로 모든 세션에
배포된다. 최상위 `commands/` `hooks/` `rules/`는 **플러그인(harness 계열) 전용**이다.

복원(승격)은 `mv global/attic/skills/X global/skills/X && ./global/install.sh` 한 줄.

## 선별 기준과 결과

기준: (a) 사용 실적 — `~/.claude/history.jsonl` 7,661줄 + 프로젝트 트랜스크립트 2.1GB/7,503파일
전수 스캔, (b) rules/CLAUDE.md 참조, (c) 구조적 의존(훅이 참조하는 스킬 등). 셋 다 0이면 attic.

| slot | 이전 | keep | attic | 삭제 |
|---|---|---|---|---|
| commands | 97 | 23 | 67 | 7 (플러그인과 바이트 동일 중복: harness×5, design, claude-dashboard) |
| skills | 104 | 13 | 91 | 0 |
| agents | 25 | 25 | 0 | 0 |
| rules | 9 | 9 | 0 | 0 |
| hooks | 16 | 16 | 0 | 0 |
| scripts | 2 | 2 | 0 | 0 |

- keep commands (23): agent-router, auto, commit, commit-push-pr, discover, explore,
  handoff-verify, hookify, interview, list, market-scan, orchestrate, plan, pricing,
  privacy-policy, ralph-loop, refactor-clean, revise-claude-md, sprint, summarize, sync,
  sync-docs, tdd
- keep skills (13): beneeds-workspace, brutalist-skill, frontend-design, manage-skills,
  minimalist-skill, output-skill, redesign-skill, session-wrap(훅 의존), soft-skill,
  strategic-compact, taste-skill, team-orchestrator, using-superpowers
- attic 대량 강등의 실체: PM/전략 스킬팩(~60개)과 스킬 저작 팩 등 사용 증거 0인 벤치마킹
  잔재 (104개 중 91개가 3개 신호 모두 0). guide·show-setup은 사용 실적이 있으나 내용이
  forge 설치·튜토리얼 그 자체라 attic.
- 사용 실적 판정의 한계: 스킬은 모델이 호출하므로 history의 `/이름` 매칭은 약한 신호.
  트랜스크립트 신호와 교차해 판정했다. 오판이면 attic에서 승격하면 된다.

## 적용한 수정 (forge 잔재 정리)

- agents 10개: 프론트매터 내 `# Part of Claude Forge` 배너 제거
- `hooks/context-sync-suggest.sh`: `.forge-onboarded` 마커 검사 + `/guide` 안내 블록 제거
  (마커 파일은 Phase B에서 삭제됨 — 방치 시 매 세션 깨진 안내 출력)
- `rules/agents-v2.md`: 실존하지 않는 `~/qjc-office/dotclaude/reference/*` 참조 5곳,
  `~/.claude/agent-memory` 섹션 제거. 라우팅 대상을 실재하는 25개 에이전트로 정정
  (구 목록은 존재하지 않는 에이전트 ~20개를 포함했음)
- `skills/beneeds-workspace/SKILL.md`: 워크스페이스 지도에서 claude-forge 항목 제거,
  정본 위치를 이 저장소로 정정
- 삭제된 forge 인프라: `~/.claude/.forge-{meta.json,onboarded,update-last-check}`,
  `commands/forge-update.md`, `hooks/forge-update-check.sh`, 깨진 `cc-chips*` symlink 2개

## 주의사항

- statusline은 `~/.claude/plugins/marketplaces/claudex-power-commands/dashboard/statusline.js`
  (마켓플레이스 체크아웃)를 절대경로로 참조한다 — 그 체크아웃을 옮기거나 지우지 말 것.
- `rules/verification.md`는 최상위(플러그인용)와 `global/rules/`(전역 배포용)에 각각 존재한다.
  소비자가 다르므로 의도된 중복이다. 내용 수정 시 양쪽을 같이 고칠 것.
- 전역 수정 워크플로: `global/`에서 고치고 `./global/install.sh` → 커밋. `~/.claude`를 직접
  고쳤다면 `--diff`로 드리프트를 확인해 `global/`로 역이식 후 커밋.
