# Golden Principles

> 12 core principles for writing clean, maintainable code.

## 1. Immutability

**Why?** Mutation is a breeding ground for bugs. It's impossible to track where a value changed.

**How?** Use spread operators to create new objects. Never modify the original.

## 2. Secrets in Environment Variables

Never hardcode secrets. Use `process.env` only; throw immediately if unset.

## 3. Tests That Pin Behavior

**Why?** 나중에 붙인 테스트는 해피패스만 덮는다. 회귀 수정은 증명 없이는 고쳐졌는지 알 수 없다.

**How?**
- 새 동작: 그 동작을 고정하는 테스트를 **같은 커밋에** 넣는다.
- 회귀 수정: **red-green 으로 증명한다** — 수정을 되돌리면 그 테스트가 실패해야 한다.
- 커버리지: **저장소 CI 임계값을 따른다.** 임의의 숫자를 강요하지 않는다.
- 테스트가 검증하는 경로가 실제 실행 경로인지 확인하라 — 매퍼 출력만 보고
  파이프라인 전체를 통과했다고 믿으면 회귀를 놓친다.

## 4. Conclusion First, Reasoning Second

Lead with the conclusion in the first sentence. Add "because..." after.

## 5. Small Files, Small Functions

File: 800 lines max. Function: 50 lines max. Nesting: 4 levels max. Split if exceeded.

MANY SMALL FILES > FEW LARGE FILES: high cohesion, low coupling; 200-400 lines typical;
extract utilities from large components; organize by feature/domain, not by type.

## 5b. Error Handling

```typescript
try {
  const result = await riskyOperation()
  return result
} catch (error) {
  console.error('Operation failed:', error)
  throw new Error('Detailed user-friendly message')
}
```

## 5c. Plan Before Changing 3+ Files

If 3 or more files are expected to change, create a plan before implementing.
Exception: 1-2 files, typo/bug patches.

## 6. Validate at System Boundaries

Trust internal code, but validate user input and external API responses (e.g., zod schemas, parameterized queries).

## 7. Explain with Analogies

Everyday analogy first (1-2 sentences), then technical explanation.

## 8. Compact at Boundaries

컨텍스트가 가득 차길 기다리지 마라. **논리적 경계에서 직접 `/compact`** 한다:
탐색 완료 후 구현 전 · 마일스톤 완료 후 · 주제 전환 전.
자동압축은 임의 지점에서 끊어 진행 중인 맥락을 잃는다. (`strategic-compact` 스킬)

## 9. HARD-GATE: No Coding Without Design

Run `/plan` first if any of these apply: new feature (3+ files), architecture change, API endpoint change, DB schema change. No code until the user approves the plan. Exception: simple fixes (1-2 files, typo/bug patches).

## 10. Evidence-Based Completion

**Why?** "It's done" without evidence is a lie. LLMs tend to declare completion without execution.

**How?** Before claiming completion:
1. Show test results (pass/fail count, coverage)
2. Confirm build success by running it
3. Check requirements against a checklist with evidence

**Banned**: "This should work", "No issues expected" — speculative completion claims
**Required**: "12 tests passed", "Build success (0 errors)" — execution evidence

## Code Quality Checklist

Verify before completion:
- [ ] Readable and well-named
- [ ] Functions under 50 lines
- [ ] Files under 800 lines
- [ ] No deep nesting (4 levels or fewer)
- [ ] Proper error handling
- [ ] No console.log statements
- [ ] No hardcoded values
- [ ] No mutation (immutable patterns used)

## 11. SDD Review Enforcement

When using subagent-driven development: spec compliance first, issues found = not done, "close enough" doesn't count.

## 12. Surgical Changes

**Why?** LLMs fix one bug but "improve" adjacent formatting, comments, and type hints. Reviewers can't find the actual change.

**How?** Only change what was requested. Every changed line must trace directly to the user's request.
- Don't "improve" adjacent code, comments, or formatting
- Match existing style, even if you'd do it differently
- Unrelated dead code: mention it, don't delete it
- Only clean up orphans (unused imports, etc.) that YOUR changes created

---

## Anti-Rationalization (These excuses don't work)

| Principle | Excuse | Reality |
|-----------|--------|---------|
| Tests | "Too simple to need tests" | Simple code breaks too. Tests take 30 seconds |
| Tests | "I'll add tests later" | Tests written later only cover happy paths |
| Tests | "고쳤으니 됐다" | 되돌려서 실패하는 걸 보기 전엔 고친 게 아니다 (red-green) |
| Immutability | "Need mutation for performance" | Only after profiling proves it |
| Secrets | "It's just the test environment" | Test secrets in commits are permanently exposed |
| File size | "It's small enough" | Review for splitting at 400+ lines |
| Boundary | "Internal function, no validation needed" | System boundary decisions belong to the designer |
| Analogy | "Unnecessary for technical audiences" | Project rule. No exceptions |
| Conclusion | "Hard to conclude without context" | One-line conclusion first, context after |
| Context | "아직 여유 있다" | 경계에서 /compact 하라. 자동압축은 맥락을 임의로 끊는다 |
| HARD-GATE | "Quick fix, no plan needed" | 3+ files changed = plan first |
| Evidence | "It already works fine" | Claims without evidence are false. Show execution results |
| SDD | "Skip review, move to next task" | Unreviewed = incomplete. No exceptions |
| Ralph Loop | "Let me just try one more approach" | Stop. Plan first, then execute once |
| /simplify | "The complexity is necessary" | Run /simplify. If it finds reduction, it wasn't necessary |
| Surgical | "While I'm here, let me clean up" | Only change requested lines. Cleanup is a separate request |
| Simplicity | "Need abstraction for extensibility" | Only what's needed now. Abstract when repetition hits 3+ times |
