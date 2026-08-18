# Model Routing — Scarce Judgment, Abundant Labor

## The budget shape (the reason for every rule below)

- **Fable 5 — highest quality, scarce.** It runs the main session. Spend it on judgment.
- **Opus 5 — abundant.** It runs every subagent. Spend it freely on labor.

Main-session cost is the accumulated transcript re-sent every turn. The scarce model
pays that bill, so **the transcript is the budget**. Anything that inflates it — full-file
reads, test logs, long diffs, exploratory greps — belongs inside a subagent, not here.

## Orchestrator (main session)

Owns, and never delegates:

- the decision — architecture, security posture, data shape, public contracts, trade-offs,
  what "done" means, what to tell the user
- reading the user, resolving ambiguity, choosing the approach, writing the brief
- the final judgment on a worker's report

Does sparingly: a targeted read of the exact lines it must judge.

Does **not**: broad exploration, whole-file reads, build/test loops, bulk edits, or
pasting large tool output into the transcript.

## Workers (subagents — all pinned to Opus)

| Need | Agent |
| --- | --- |
| explore / locate / map | `code-explorer`, or `Explore` **with `model: "opus"` passed explicitly** |
| write code | `implementer` |
| build · type · lint · test | `verify-agent` |
| adversarial review | `code-reviewer`, `silent-failure-hunter`, `security-reviewer`, `pr-test-analyzer` |
| plan a large change | `planner`, `architect` |

Run independent workers in parallel in one message. Breadth is cheap on the abundant
model, and it keeps the scarce transcript small.

## Delegate by default

Do it inline only when the edit is 1–2 lines with a known target and the file is already
in context, or the answer is already in the transcript. Otherwise delegate.

Investigation counts as work. It is the most common way the scarce budget leaks, because
tool output lands in this transcript and is re-sent every turn afterwards:

- If a check or investigation looks like **3 or more tool calls**, do not start it — delegate it.
- If you started inline and cross 3 tool calls, **stop there** and hand the rest over as a
  brief; fold what you already learned into that brief instead of continuing to accumulate.
- When the size is unclear, lean toward delegating. Delegating wrongly costs one round trip;
  doing it inline wrongly costs the scarce budget, and that cost is already paid by the time
  you notice.

## Brief contract

**goal · exact file paths · constraints and definition of done · the verification command.**
Always add: *return conclusions with `file:line` citations, not file contents.*
A vague brief is not cheap — it comes back as a wrong answer you must re-read.

## Anti-patterns — these burn the scarce budget

- Reading a long file in the main session to answer one question → delegate it
- Re-running a failing test loop in the main session → `verify-agent`
- `subagent_type: "fork"` — it inherits the scarce model into a throwaway context.
  Never use it for labor
- An agent with `model: inherit` — same failure. Every local agent is pinned to `opus`.
  Keep it pinned; never add `inherit` back

## Session-level escape hatch

A session with no judgment in it — a mechanical fix, getting a build green, a doc sweep —
should not run on the scarce model at all. Switch the session down: `/model opus[1m]`.
Conversely, when the session is about deciding, stay on Fable and push every read down.

## Verification

A worker's self-report is not evidence. Require the actual command and its output in the
worker's report, or re-run through `verify-agent`. See `verification.md`.

## Context hygiene

Compact at boundaries — after exploration and before implementation, after a milestone,
before a topic change. Never paste a full diff or log into the main transcript; summarize
it or cite `file:line`.

## Skills that spawn their own subagents

A skill's own agent specs override nothing here — they simply bypass it. When a skill
says "spawn a subagent" **without** naming a model, that subagent inherits the scarce
main model and does labor with it. When it pins `sonnet`, it skips the abundant model
entirely.

So: when running a skill that fans out (`/harness`, `/harness-qa`, `/harness-review`,
`/orchestrate`, and similar), pass `model: "opus"` on every spawned worker — builder,
scout, QA, sentinel, refiner, auditor, diagnostician. Keep the scarce model on the
orchestrating turn only.

## Workflow / ultracode model mix

When authoring a Workflow script, the same split applies inside the script:

- `agent()` **inherits the main-loop model when `model` is omitted.** On a Fable session
  every unlabeled agent burns the scarce model. Never leave a labor stage unlabeled.
- Labor stages — explore, implement, verify, mechanical transforms, bulk sweeps —
  pass `model: 'opus'`; add `effort: 'low'` or `'medium'` for mechanical ones.
- Judgment stages — the final judge panel, synthesis, the verdict that gates shipping —
  run on Fable: omit `model` on a Fable session, or pin `model: 'fable'` to be explicit.
  Keep these stages few and their inputs small (verdicts and citations, not raw dumps).
- The script itself is judgment: decomposition, stage prompts, and acceptance criteria
  are written by the orchestrator in the main turn. Do not delegate script authoring.
