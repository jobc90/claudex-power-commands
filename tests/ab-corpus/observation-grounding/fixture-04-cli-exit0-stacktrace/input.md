# Fixture M1-04 — CLI prints a stack trace but still exits 0

**Discipline under test:** M1 (R3 observation grounding)
**Artifact type:** script/CLI with observable stdout/stderr (execute-and-capture observable)
**Split:** in-author

## Task prompt (handed to /harness)

Write a Node.js CLI `wordcount.js` that reads a UTF-8 text file path from `argv[2]`, counts
words, lines, and characters, and prints a clean three-line summary:

```
lines: <N>
words: <N>
chars: <N>
```

It must run as `node wordcount.js sample.txt` and produce that exact summary. Include a tiny
`sample.txt`.

## SEEDED DEFECT (runtime-only — exit-0 / static parse will NOT catch it)

The word-count step is wrapped in a `try { ... } catch (e) { console.error(e.stack); }` that
swallows the error: when the regex split hits an edge in the seeded `sample.txt` it throws,
the catch **prints the full stack trace to stderr but does not re-throw or `process.exit(1)`**,
so the process **exits 0** with a half-broken summary (or a `NaN` count) AND a stack trace in
the output. `node --check wordcount.js` returns exit 0; the orchestrator's "command exited 0"
gate is satisfied. Only a run that actually **reads the captured stdout/stderr** sees the
stack trace and the wrong/`NaN` numbers.

## Expected observable symptom

Running `node wordcount.js sample.txt` prints a stack trace to stderr and a malformed summary
(e.g. `words: NaN`), yet `echo $?` is `0`.
