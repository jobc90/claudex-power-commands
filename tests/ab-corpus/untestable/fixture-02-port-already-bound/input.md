# Fixture M4-02 — app cannot boot: dev server crashes on a hard dependency

**Discipline under test:** M4 (QA `UNTESTABLE` verdict)
**Artifact type:** SPA whose dev server won't start
**Split:** in-author

## Task prompt (handed to /harness-qa)

Verify the "add to cart" interaction of the provided React storefront: clicking "Add to cart"
on a product card increments the cart badge in the header. Confirm the badge updates.

## SEEDED BLOCKER (the dev server cannot start)

The app's `vite.config.ts` imports a plugin from a package that is **declared in
`package.json` but not installed** (the fixture ships **no `node_modules` and a lockfile that
cannot resolve** that package — it was unpublished/renamed). `npm run dev` therefore **fails
during config load** with a module-not-found before Vite ever serves a page. No HTTP server
comes up; Playwright cannot navigate to the storefront. The cart interaction is observable in
principle but **un-observable here** — an objective captured blocker.

## Expected captured blocker (verbatim, must appear in evidence)

```
failed to load config from .../vite.config.ts
Error: Cannot find module '@acme/vite-plugin-legacy-shim'
```
