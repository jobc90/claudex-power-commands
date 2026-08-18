# Handoff — 탈 claude-forge + claudex-power-commands 단일화

> 작성: 2026-08-18, console 프로젝트 세션에서. 이 문서를 읽는 세션이 실행 주체다.
> 목표: **symlink 설치 잔재를 전부 걷어내고, 전역 설정의 정본을 claudex-power-commands 하나로 만든다.**

---

## 0. 배경 — 오늘 세션에서 결정·적용된 것 (이미 완료, 재작업 금지)

사용자의 모델 경제학: **Fable 5 = 최고 품질·희소(판단 담당) / Opus 5 = 풍부(노동 담당)**.
메인 세션 비용 = 누적 트랜스크립트 × 턴 수를 희소 모델이 내므로, 트랜스크립트가 곧 예산.
노동(탐색·구현·검증·리뷰)은 전부 Opus 서브에이전트로 내리고 결론만 회수한다.

이미 적용된 변경 (전부 **claude-forge 작업트리 안에 있음** — 마이그레이션 시 반드시 보존):

| 파일 | 변경 |
|---|---|
| `~/.claude/settings.json` | `"model": "fable"` (opus[1m]→fable[1m]→fable 순으로 조정) |
| `agents/*.md` 25개 | **전부 `model: opus` 고정** (sonnet 10개 승격, inherit 4개 제거) |
| `agents/` 10개 파일 | 프론트매터 위 배너 주석 제거 — **배너 탓에 10개가 로드조차 안 되고 있었음** (1행이 `---`가 아니면 파싱 실패) |
| `agents/implementer.md` | **신설** — 실제 코드를 쓰는 opus 워커 (기존엔 리뷰어만 있고 구현 워커가 없었음) |
| 기계적 에이전트 10개 | `effort: medium` 추가 (build-error-resolver, doc-updater, e2e-runner, verify-agent, refactor-cleaner, plugin-validator, agent-creator, agent-sdk-verifier-py/ts, conversation-analyzer) |
| `rules/model-routing.md` | **신설, 110줄** — 아래 §0.1 요약 참조. 매 세션 자동 로드 |

백업: `~/.claude/backups/model-routing-20260818/` (settings.json + agents.tgz)

### 0.1 model-routing.md 핵심 (마이그레이션 후에도 그대로 유지할 것)

- 오케스트레이터(Fable)가 소유·위임 금지: 결정, 모호성 해소, 브리프 작성, 워커 보고 최종 판단
- 위임 기본값 + **조사 3조항**: 도구 3회 이상 예상되는 확인·조사는 시작 전 위임 / 진행 중 3회 넘으면 그 자리서 브리프로 이관 / 애매하면 위임(오판 비용 비대칭)
- 브리프 4요소: goal · 파일 경로 · 제약/DoD · 검증 명령. + "파일 내용 말고 `file:line` 인용과 결론만 반환"
- 안티패턴: `fork`·`model: inherit` = 희소 모델을 일회용 컨텍스트에 태움 — 금지
- 스킬 팬아웃(`/harness` 등) 시 모든 워커에 `model: "opus"` 명시
- Workflow/ultracode: 노동 스테이지 `model: 'opus'`(+effort low/medium), 심판·종합은 Fable(생략 또는 `model: 'fable'`), 스크립트 작성 자체는 메인 턴 Fable — 위임 금지

---

## 1. 현재 상태 (2026-08-18 실측)

### 1.1 ~/.claude symlink 전수

```
agents    -> ~/dev/side-project/claude-forge/agents     OK
rules     -> ~/dev/side-project/claude-forge/rules      OK
commands  -> ~/dev/side-project/claude-forge/commands   OK   (90개 항목, forge-update.md 포함)
skills    -> ~/dev/side-project/claude-forge/skills     OK   (104개 항목)
hooks     -> ~/dev/side-project/claude-forge/hooks      OK   (17개, settings.json이 session-cleanup.sh 참조)
scripts   -> ~/dev/side-project/claude-forge/scripts    OK   (md-to-docx, pdf-enhance)
cc-chips        -> ~/dev/claude-forge/cc-chips          BROKEN (대상 디렉터리 없음)
cc-chips-custom -> ~/dev/claude-forge/cc-chips-custom   BROKEN
```

주의: 사용자는 "claude-forge 말고도 symlink 설치 프로젝트가 더 있다"고 기억하나,
`~/.claude` 1단계 실측으로는 **전부 claude-forge(현·구 경로) 하나**다. 깨진 cc-chips 2개가
가리키는 `~/dev/claude-forge`가 그 "다른 프로젝트"의 잔재일 가능성이 높다(이미 삭제됨).
실행 세션에서 `~/.claude` 하위와 프로젝트별 `.claude/`를 재확인할 것.

### 1.2 claude-forge 클론 상태

- 위치: `~/dev/side-project/claude-forge` (25M), 원격: `sangrokjung/claude-forge` — **사용자 소유 아님, push 불가**
- dirty 172개 = **5개월치 사용자 커스터마이징이 남의 저장소 작업트리에 갇힌 것**:
  skills 88 · commands 59 · agents 25 · rules 8 · hooks 1 · settings 1 · 기타 2
- **절대 `git checkout`/`git reset`으로 복사하지 말 것 — 작업트리(dirty 상태 그대로)가 정본이다**

### 1.3 forge 전용 잔재 (제거 대상)

- `~/.claude/.forge-meta.json`, `.forge-onboarded`, `.forge-update-last-check`
- `commands/forge-update.md` (upstream을 당겨와 로컬 수정을 덮을 수 있는 지뢰)
- `hooks/forge-update-check.sh`
- cc-chips 깨진 symlink 2개

### 1.4 이미 claudex 소속인 것 (건드릴 필요 없음)

- statusline: `~/.claude/plugins/marketplaces/claudex-power-commands/dashboard/statusline.js`
- harness 계열 스킬: 플러그인 `codex-skills/`에서 로드
- 플러그인 등록: `enabledPlugins`의 `claudex@claudex-power-commands: true`

---

## 2. 실행 계획

### Phase A — 실체화 (탈 symlink)

각 slot에 대해: `cp -RL`로 **symlink를 따라간 실사본**을 임시 위치에 만들고 → symlink 제거 → 실디렉터리로 교체.

```bash
for d in agents rules commands skills hooks scripts; do
  cp -RL ~/.claude/$d /tmp/materialize-$d && rm ~/.claude/$d && mv /tmp/materialize-$d ~/.claude/$d
done
```

- `cp -RL`이 핵심 — dirty 작업트리 내용이 그대로 복사된다
- 완료 후 `settings.json`의 `~/.claude/hooks/session-cleanup.sh` 경로는 그대로 유효 (수정 불필요)
- 즉시 검증: 새 세션 하나 열어 rules 로드·agents 등록(25개, 프론트매터 깨짐 0)·`/` 커맨드 목록 확인

### Phase B — 잔재 제거

```bash
rm ~/.claude/.forge-meta.json ~/.claude/.forge-onboarded ~/.claude/.forge-update-last-check
rm ~/.claude/commands/forge-update.md ~/.claude/hooks/forge-update-check.sh
rm ~/.claude/cc-chips ~/.claude/cc-chips-custom
```

### Phase C — claudex-power-commands 흡수 (판단 필요, 일괄 복사 금지)

claudex 저장소에 이미 `commands/ rules/ hooks/ harness/ codex-skills/`가 있다 → **충돌·중복 정리가 선행**:

1. 실체화된 `~/.claude/{agents,rules,commands,skills,hooks,scripts}`를 claudex 저장소로 가져오되,
   claudex에 이미 동등물이 있는 것(harness 계열 등)은 claudex 쪽을 정본으로
2. commands 90개·skills 104개는 **전수 이식이 아니라 선별** — 사용 이력 없는 벤치마킹 잔재가 다수.
   1차 통과 기준: 최근 세션에서 실제 호출된 것 + 사용자가 이름을 아는 것. 애매하면 `_attic/`으로
3. 배포 방식 결정 (플러그인 한계 주의):
   - **rules는 플러그인으로 배포 불가** — `~/.claude/rules` 실디렉터리 유지가 정본.
     claudex 저장소에는 사본을 두고 설치 스크립트로 동기화하는 구조 권장
   - agents/commands/skills/hooks는 플러그인 메커니즘으로 배포 가능 — 단 마켓플레이스 설치본과
     `~/.claude` 직접 배치가 중복되면 이중 로드되므로 한쪽만 남길 것
4. forge 유래 파일의 배너/출처 주석 정리 (`# Part of Claude Forge` 등)

### Phase D — 삭제 (마지막, 검증 후에만)

- `~/dev/side-project/claude-forge` 삭제 (25M)
- 전제: Phase A 검증 통과 + Phase C에서 claudex 저장소에 커밋·push 완료
- 삭제 전 최종 안전망: `tar -czf ~/claude-forge-final-$(date +%Y%m%d).tgz -C ~/dev/side-project claude-forge`

---

## 3. 검증 체크리스트

- [ ] 새 세션: 메인 모델 fable로 부팅 (statusline 확인)
- [ ] `~/.claude` 안에 symlink 0개 (`find ~/.claude -maxdepth 1 -type l` 빈 출력)
- [ ] agents 25개 전원 등록, `model: opus` 유지, 프론트매터 1행 `---`
- [ ] rules 9개 로드 (특히 model-routing.md 110줄)
- [ ] SessionEnd 훅 정상 (세션 종료 시 에러 없음)
- [ ] `/forge-update` 커맨드 소멸
- [ ] claudex 저장소에 흡수분 커밋·push 완료
- [ ] claude-forge 디렉터리 삭제 후에도 위 전부 재확인

## 4. 미결 사항 (실행 세션이 결정)

- commands 90 / skills 104의 선별 기준과 attic 처리
- claudex 배포 구조: 플러그인 단일화 vs `~/.claude` 직접 배치 + 설치 스크립트 (rules는 후자 강제)
- `~/qjc-office/dotclaude/reference/*`를 참조하는 rules 문구들(agents-v2.md) — 해당 경로 실존 여부 확인 후 유지/수정
- 사용자가 기억하는 "다른 symlink 프로젝트" 실존 여부 재탐색
