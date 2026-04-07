# Security Checklist

Shared reference for Analyzer, Refiner, Integrator, and Builder agents.
Read this when performing security checks on code changes.

## Secrets Detection

- [ ] No hardcoded API keys, passwords, tokens, or private keys in source code
- [ ] No secrets in logs, error messages, or API responses
- [ ] Environment variables used for all credentials (`process.env.*`)
- [ ] `.env` / `.env.local` / `*.pem` / `*.key` in `.gitignore`

**Mandatory grep** (run on ALL changed files):
```bash
grep -rn "api[_-]\?key\|password\|secret\|token\|private[_-]\?key" <files>
```

## Injection Prevention

- [ ] SQL queries use parameterized statements (no string concatenation with user input)
- [ ] No `innerHTML` / `dangerouslySetInnerHTML` with unsanitized data (XSS)
- [ ] No `eval()`, `new Function()`, or `child_process.exec()` with user input (command injection)
- [ ] URLs validated before redirect (prevent open redirect)
- [ ] File paths from user input sanitized (prevent path traversal)

## Authentication & Authorization

- [ ] Every protected endpoint checks authentication
- [ ] Every resource access checks ownership/role (prevents IDOR)
- [ ] Admin endpoints require admin role verification
- [ ] JWT tokens validated (signature, expiration, issuer)
- [ ] Session cookies set: `httpOnly`, `secure`, `sameSite`

## Input Validation

- [ ] All user input validated at system boundaries (API routes, form handlers)
- [ ] Validation uses allowlists (not denylists)
- [ ] String lengths constrained (min/max)
- [ ] Numeric ranges validated
- [ ] File uploads: type restricted, size limited, content verified

## Dependency Security

- [ ] New dependencies checked for known CVEs (`npm audit` / `pnpm audit`)
- [ ] No wildcard version ranges in package.json
- [ ] Lock file committed and up-to-date

## Severity Classification

| Severity | Criteria | Examples |
|----------|----------|---------|
| CRITICAL | Data loss, RCE, auth bypass | Hardcoded admin password, SQL injection, command injection |
| HIGH | Data exposure, privilege escalation | Secrets in logs, missing auth check, IDOR |
| MEDIUM | Limited exposure, requires conditions | XSS in admin-only page, verbose error messages |

**Security findings are never LOW.** If it's a real security issue, it's at minimum MEDIUM.

**Prioritization formula**: severity × exploitability × blast radius.
