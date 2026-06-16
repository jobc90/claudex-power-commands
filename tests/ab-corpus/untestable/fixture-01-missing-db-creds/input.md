# Fixture M4-01 — app cannot boot: required DB credentials absent

**Discipline under test:** M4 (QA `UNTESTABLE` verdict)
**Artifact type:** web app that is observable in principle but **cannot be observed**
**Split:** in-author

## Task prompt (handed to /harness-qa, or /harness QA phase)

Verify the `/login` flow of the provided Express app: a user submits email + password, and on
success is redirected to `/dashboard`. Confirm the happy path renders the dashboard.

## SEEDED BLOCKER (the app genuinely cannot be brought up)

The app reads `DATABASE_URL` at startup and **throws + exits** if it is unset
(`throw new Error('DATABASE_URL not configured')`). The fixture ships **no** `.env`, no
running database, and no seeded user. `npm start` therefore **crashes on boot** with that
exact error before any HTTP server binds — Playwright cannot connect because nothing is
listening. The login flow is observable *in principle* but **un-observable in this
environment**: there is an objective, captured blocker.

## Expected captured blocker (verbatim, must appear in evidence)

```
Error: DATABASE_URL not configured
    at Object.<anonymous> (.../config.js:7:9)
npm ERR! code 1
```
