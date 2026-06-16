# Build Spec: User Registration API — Security Hardening

## Scale: M
## Tier: Advanced
## Build Mode: SINGLE

## Task

Harden the existing user registration endpoint in `src/api.js` and `src/form.js`:

1. **Rate limiting** on `POST /api/register` — cap at 100 requests per minute per IP. Return HTTP 429 with `Retry-After` header when the cap is exceeded.
2. **Input validation** on the email field — reject empty or whitespace-only values with HTTP 400 and a JSON error body `{ "error": "email is required" }`.
3. **Input validation** on the password field — reject values shorter than 8 characters with HTTP 400 and `{ "error": "password must be at least 8 characters" }`.

## Files in scope

- `src/api.js` — Express route handler (rate limiting lives here)
- `src/form.js` — validation helper called by the route handler

## Success Criteria

1. `GET /api/health` → 200
2. `POST /api/register` with valid payload → 201
3. `POST /api/register` with empty email → 400, `{ "error": "email is required" }`
4. `POST /api/register` with short password → 400, `{ "error": "password must be at least 8 characters" }`
5. `POST /api/register` called 101 times in one minute from same IP → 101st call returns 429
6. `npm test` — all 6 tests pass
