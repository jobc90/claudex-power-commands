# Git Workflow

## Commit Message Format

```
<type>: <description>

<optional body>
```

Types: feat, fix, refactor, docs, test, chore, perf, ci

## Integration with /check and /super

- /check: after verification, runs `git add → git commit → git push`. With `--pr`: `gh pr create`
- /super SHIP: same flow. With `--pr`: auto-creates PR
- Commit messages follow the format above

## Pull Request Workflow

When creating PRs:
1. Analyze full commit history (not just latest commit)
2. Use `git diff [base-branch]...HEAD` to see all changes
3. Draft comprehensive PR summary
4. Include test plan with TODOs
5. Push with `-u` flag if new branch

## Feature Implementation Workflow

1. **Plan First**
   - Use **planner** agent to create implementation plan
   - Identify dependencies and risks
   - Break down into phases

2. **Tests That Pin Behavior**
   - 새 동작을 고정하는 테스트를 같은 커밋에
   - 회귀는 red-green 으로 증명 (수정을 되돌리면 실패해야 한다)
   - 커버리지는 저장소 CI 임계값을 따른다

3. **Code Review**
   - Use **code-reviewer** agent immediately after writing code
   - Address CRITICAL and HIGH issues
   - Fix MEDIUM issues when possible

4. **Commit & Push**
   - Detailed commit messages
   - Follow conventional commits format

## GitHub Organization

### New Repo

```bash
# From existing local project
cd ~/my-new-project
git init && git add . && git commit -m "init: system files"
gh repo create your-org/my-new-project --private --source=. --push

# Create empty repo first
gh repo create your-org/my-new-project --private --clone
```

### Clone All (New Machine)

```bash
gh repo list your-org --limit 50 --json sshUrl -q '.[].sshUrl' | xargs -n1 git clone
```
