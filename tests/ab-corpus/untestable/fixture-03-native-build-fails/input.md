# Fixture M4-03 — app cannot boot: native build step fails on this platform

**Discipline under test:** M4 (QA `UNTESTABLE` verdict)
**Artifact type:** app requiring a native compile that fails before runtime
**Split:** held-out

> NOTE: marked `held-out` — hand-score with the same frozen rubric as the in-author fixtures;
> report M4 KEEP/CUT separately on in-author vs held-out (design §3). A real held-out fixture
> needs a different author; this documents the slot and the intent.

## Task prompt (handed to /harness-qa)

Verify the image-thumbnail endpoint of the provided service: `GET /thumb?src=<id>` returns a
200 with a resized JPEG. Confirm a valid id returns an image.

## SEEDED BLOCKER (the build fails before the server can run)

The service depends on a native image library that must compile during `npm install` via
`node-gyp`. On the test environment the toolchain prerequisite is **absent**, so install
**fails at the native compile step** and the dependency is never built. `npm start` then
**crashes immediately** with a `Cannot find module` for the native binding. No server binds;
the endpoint cannot be hit. Observable in principle, **un-observable here**.

## Expected captured blocker (verbatim, must appear in evidence)

```
gyp ERR! build error
Error: Cannot find module '../build/Release/sharp.node'
```
