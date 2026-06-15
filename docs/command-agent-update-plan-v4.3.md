# claudex Command & Agent Update Plan — "Soft-Entrance & Observation Grounding"

> Status: **IMPLEMENTED — v4.3.0** (2026-06-15). Full scope (Tier 0+1+2+3) shipped. Spine + Stop hook authored directly (verified); consumer wiring via a 6-group fan-out workflow (each group adversarially verified, all pass); Codex mirrors synced (0 drift); version bumped across all 4 sync points with honest "effect unmeasured" framing.
> Source: deep analysis of two reference harness plugins (`fivetaku/fablize`, `tmdgusya/prometheus`) mapped onto claudex's 6 commands + 27 agents + references.
> Method: 10 parallel read-only analysts → synthesis → 3-lens adversarial critique (completeness / anti-bloat fidelity / conflict-regression) → claims verified by direct grep against claudex source.
> Target version: **4.3.0** (Tier 1 only) — framed honestly as *transferred procedure, effect unmeasured on claudex's model mix*.

---

## 1. What the reference projects are (the "파악")

Both are Claude Code / agent **harness plugins — the same genre as claudex** — but radically *smaller and sharper*. prometheus is a fork of fablize; they share the same two "packs."

| | fivetaku/fablize | tmdgusya/prometheus |
|---|---|---|
| One line | "run Opus like Fable" | "steal the procedural fire for GLM-5.2" |
| Form | 1 skill + 2 packs + UserPromptSubmit **router** + **Stop hook** + goals.py | 1 skill + same 2 packs; **dropped goals.py**, delegates the gate to the runtime `/goal` |
| Size | R3+R4+R5 in **34 lines / 2 files**, router-gated (loads only on matching task) | even leaner |
| Core thesis | **A harness cannot raise a model's ceiling. It makes the model reach its *own* ceiling — by enforcing verification, completion, investigation as PROCEDURE.** | identical |
| Discipline | **Ship only what a controlled experiment verified. Unverified ideas stay out.** Honest about unmeasured effect. | "We have NOT measured whether this helps on GLM-5.2… until measured we do not claim validated." |

### The single most important idea they teach

> **"The most deterministic device (a hard gate) is useless if its *entrance* sits on the least deterministic layer (the agent voluntarily choosing to walk through it)."**

prometheus *lived* this: while demoing, its agent finished a decompose→verify task **without ever calling its own gate**. The fix was to move the gate's entrance to the **runtime** (`/goal`, evaluated every turn, no agent opt-in).

---

## 2. The core finding — claudex's gates have a SOFT ENTRANCE

The first-pass synthesis claimed claudex *"already has the hard-gate-with-hard-entrance design."* **That is false, and the adversarial critique caught it.** Verified against source:

- claudex's "orchestrator" **is the main agent executing its own prompt persona** (`meta-loop-protocol.md` §1/§4, `harness.md`: "The orchestrator runs the loop to completion"). There is no external runtime.
- Therefore **every gate claudex ships — Phase Verifier verdict, Completion Gate scan, retry cap — fires only if the agent voluntarily obeys its own instructions.** That is *exactly* prometheus's soft entrance, relocated one level up.
- claudex's **only** runtime-enforced hook today is `SessionStart → check-deps.sh` (`hooks/hooks.json`). It already ships a hooks layer (`hooks.json` + `check-deps.sh` + `pre-commit-lint.sh`) — so adding a real runtime entrance is **near-zero infrastructure cost**.

**Implication:** the highest-leverage transferable mechanism is not another prompt rule — it is giving claudex its **first runtime-enforced completion entrance** via a Stop hook (which fablize ships verbatim as `hooks/finish-the-work.sh`). The first synthesis cut this on the false premise "claudex has no hook layer."

---

## 3. The 10 transferable ideas (analysis lens)

| | Idea | claudex status (verified) |
|---|---|---|
| R1 | Capability vs Procedure; honest **escalation** at the ceiling | Tier system *detects* capability but **never escalates** — 3-retry exhaustion jumps straight to a user pause |
| R2 | **Evidence-based / anti-bloat** shipping; honest about unmeasured effect | **Absent** — claudex accretes (v3.2→4.0→4.1→4.2); no "ship only what's measured" posture |
| R3 | Verification **grounding** (run+observe render/exec artifacts) | **Already present at the two points that matter** (Builder step 9 "open the running app… mandatory"; QA Playwright "non-negotiable"). Gap is only the **intermediate** verifiers that stop at exit-0 |
| R4 | **Anti-over-verification** ("one clean observation; don't re-verify unchanged") | Absent — and it's *not a separate idea*, it's the last paragraph of the R3 pack |
| R5 | Investigation: 3+ competing hypotheses; **surface all, filter separately** | Partial — Diagnostician has a (single-threaded) Hypothesis Protocol; review has a Deferred sink (`confidence-calibration.md:34`) but no *mandate to capture* the 60-79 band |
| R6 | **Context-first decomposition** (+ Explore-when-unsure) | Absent at the decomposition points; the **bad-vs-good worked example** is the most copyable artifact in either repo |
| R7 | **Runtime-gate** over self-invoked gate | The soft-entrance gap of §2 |
| R8 | **Early-stop prevention** (deterministic Stop hook) | Absent; fablize ships it; claudex's hook layer makes it cheap |
| R9 | **Smallest-matching discipline** | claudex has Scale S/M/L + tier detection (good); the *plan itself* must honor this |
| R10 | Working-style invariants | Already covered by global CLAUDE.md + Phase Verifier "claims are not evidence" |

---

## 4. The reconciled plan (anti-bloat–faithful)

The first synthesis proposed ~40 always-on edits across every pipeline + a version bump — **the exact accretion fablize exists to prevent, wearing an anti-bloat label.** The anti-bloat critic rejected it; the conflict critic flagged 4 collisions; the completeness critic flagged the inverted core thesis. The reconciliation below is **deliberately small** and models fablize's own restraint: *one router-gated reference per discipline, cited by the 2-3 highest-leverage consumers only — not re-inlined into 15 prompts.*

### Tier 0 — Honesty corrections (philosophy; ~3 small edits)

- **0.1** Add an **"Enforcement Boundary"** note to `meta-loop-protocol.md`: the Meta-Loop / Completion Gate are **agent-self-enforced (soft entrance)** — they raise compliance probability but are *not* runtime-guaranteed; the agent must NOT treat "I ran the Phase Verifier" as proof the gate fired. (Mirrors prometheus's central lesson; the rest of the plan flows from this.)
- **0.2** Ship every new discipline under prometheus's **Status posture**: *"transferred procedure; effect on claudex's model mix is not yet A/B-measured."* No "validated" marketing headline in the CHANGELOG.

### Tier 1 — Ship now (genuine, high-leverage, low-footprint)

| # | Change | Files | Why it's not bloat |
|---|---|---|---|
| **T1.1** | **Stop hook** — port `fablize/hooks/finish-the-work.sh` → `hooks/finish-the-work.sh` + add a `Stop` entry to `hooks/hooks.json`. Deterministic regex; `stop_hook_active` loop-guard; excludes turns ending in a user question. | `hooks/finish-the-work.sh` (new), `hooks/hooks.json` | claudex's **first runtime-enforced entrance** — the one thing the self-enforced Meta-Loop structurally cannot provide. ~1 file. **This is the headline.** |
| **T1.2** | **`observation-grounding.md`** — ONE ≤40-line reference co-locating **R3 + R4** (exactly as fablize co-locates them in one pack): observable-output definition; the **exclusion trigger** ("could this look/behave wrong only when it runs?"); the optional `runtime-observation-required` flag (absent = current exit-0 behavior); the **anti-over-verification close** (pack's exact wording — "one clean observation… re-render only after a change"); degrade path ("observation-blocked never PASS/CLEAN"). | `harness/references/observation-grounding.md` (new) + Codex mirrors | Single source, DRY (the `completion-gate-protocol.md §8` "why a reference not each prompt" argument — **verified to exist**, valid citation). |
| **T1.3** | Wire R3 to the **~3 agents that genuinely stop at exit-0** only: `phase-verifier`, review `verifier`, (optionally Refiner/Integrator smoke). **NOT** Builder/QA — they already run+observe (promoting = rename). Reframe `verifier-prompt.md:9` from "Exit code 0 IS verification" → flag-conditional ("exit 0 = well-formed for non-observable; observation proves correct for flagged artifacts"). | `phase-verifier-prompt.md`, `verifier-prompt.md`, `phase-verification-protocol.md` | ~3 edits, not 15. Flag is OPTIONAL/backward-compatible. |
| **T1.4** | **R1 escalation rung** — ONE rung in `meta-loop-protocol.md §5` only: same phase fails 3× with unchanged root cause → **rung 1: recommend the user raise effort/thinking** (agent cannot self-set it) → **rung 2: hand off to a higher TIER with an evidence package** (symptoms/attempts/failure/repro; TIER LABEL only, never a model id) → **rung 3: human**. Update the **5 places** asserting the 3-retry terminal to route to the rung (no drift). Keep retry cap **flat** (don't make it tier-variant). | `meta-loop-protocol.md`, `tier-matrix.md` (params only, cross-ref), `harness.md` | The genuine gap; centralized once. |
| **T1.5** | **QA `UNTESTABLE` state** — tightly gated against the documented leniency bias: permitted ONLY with a **captured blocker error** (app won't boot / Playwright can't connect / creds absent); **does NOT count toward the grade**; routes into the T1.4 ladder, never a silent PASS. Add as "Fabrication Pattern 7: UNTESTABLE without a captured blocker is a disguised skip." | `qa-prompt.md` | Today an unreachable app forces a *fabricated* PASS or FAIL — a real honesty gap. |
| **T1.6** | **Decomposition worked example (R6)** — import prometheus's bad-vs-good example **verbatim** (adapted to claudex phase/DoD vocab): every phase DoD carries a *specific-path + observable-evidence* pair ("fix X:line → command Y produces Z"); ban unobservable goals ("analyze", "clean up"). Plus the 4-question **context-sufficiency check** routing to **Scout** (agents are contained — cannot self-spawn Explore) with *return-conclusion-only* + *iterate-until-sufficient* loop. | `phase-book-planner-prompt.md`, `meta-loop-protocol.md §3`, `scout-prompt.md` | The single most copyable artifact; the first synthesis dropped it. |

### Tier 2 — Gate behind evidence (do NOT ship until a real failure is reproduced)

Per R2: no always-on discipline ships until a concrete claudex failure is observed.

- **R5 review discover-then-filter** — formalize the *existing* Deferred sink (`confidence-calibration.md:34`) into a mandatory two-pass, **REVIEW-mode only**, reconciled with the line-28 Key Principle (governs FIX, not REPORT). *Med consolidation, not a "keystone."* Ship when a dropped true-positive is observed.
- **Diagnostician competing-hypotheses** — **restructure** the existing Hypothesis Protocol (`diagnostician-prompt.md:62-70`) from "for each cause, test" → "enumerate 2-3 competing causes first, test, report rejected." One edit, not a parallel Step 0.
- **qa-reporter verbatim gate output (R7)** — embed the gate's **raw** exit code + literal output in the Appendix so the Auditor can diff it. Spans `completion-gate-protocol.md §6` (attestation format). **Honest limit:** claudex has no runtime Stop-gate, so this is the *best available proxy*, not parity.

### Tier 3 — One tiny justified one-off

- **`claude-dashboard.md` Step 2b** — after editing the user's global `settings.json`, validate it's still well-formed JSON (`node -e`/`jq`) before declaring ready. A botched merge bricks the user's config. No tiers/gates/agents. (The *only* config-one-shot addition that survives R2/R9.)

---

## 5. What we CUT, and why (the anti-bloat ledger)

Modeling fablize: these were proposed and **rejected** to keep claudex from accreting.

| Cut | Reason |
|---|---|
| Re-inlining R3 into Builder/Worker/QA/qa-reporter | Already run+observe (verified). Promoting = rename, not capability. |
| Standalone R4 sections across 12 prompts | R4 is one paragraph of the R3 pack; it ships **only** inside `observation-grounding.md`. |
| ~10 per-agent "third-state" variants (Scout BLOCKED, Planner INSUFFICIENT-CONTEXT, Worker ceiling-row, …) | Interface bloat — 12 new vocabulary tokens the orchestrator must interpret. Keep only **QA UNTESTABLE** until each silent-fake is observed. |
| R8 force-fit into harness/meta-loop prompt text | R8 belongs at the **hook** layer (T1.1), not in agent prompts. |
| R10 working-style rule in `harness.md` | Already covered by global CLAUDE.md + Phase Verifier. |
| Tier-variant retry caps (2/1) | Contradicts two tables that declare the cap tier-invariant. Keep flat. |
| Auditor pulled into R3 observation | Off-charter ("forensic accountant — judge whether NUMBERS are real"). |
| Codex-mirror every new discipline into 4 skill dirs pre-emptively | Quadruples maintenance for unmeasured benefit; mirror only what Tier 1 ships. |

> **Correction to the synthesis (verified):** its `completion-gate-protocol §8` citation is **valid** — §8 ("Why this is in a reference, not in each prompt") exists. The anti-bloat critic's claim that it was fabricated is itself wrong. Keep the citation.

---

## 6. Conflicts & resolutions (must land as reframings, not appended opposites)

1. **R3 vs `verifier-prompt.md:9` "Exit code 0 IS verification"** → reframe line 9 as flag-conditional; make CLEAN-verdict definition conditional on the flag. Do **not** append a contradicting Step 3.5.
2. **R1 rung blast radius** → the 3-retry terminal is asserted in **5 places** (`meta-loop §4d/§5/§6-table`, `phase-verification-protocol` Retry Protocol, `harness.md:818`). All must route to the rung or they contradict §5. DoD greps for this.
3. **R5 vs `confidence-calibration.md:28` Key Principle** → scope new rule REVIEW-mode-only; frame as *formalizing the existing Deferred sink*, not inventing a surface; downgrade high→med.
4. **`.harness` flag = contract change** → 4.3.0 minor is safe ONLY if the flag is strictly OPTIONAL and **absent = today's exit-0 behavior**. Add a backward-read-compat DoD (old artifact still passes new Phase Verifier).
5. **QA UNTESTABLE vs anti-sycophancy** → gate tightly (captured blocker, no grade credit, routes to escalation).
6. **Sentinel unknown→WARN** → constrain to Sentinel's *existing* security categories, don't broaden the CLEAR contract.

---

## 7. Version & sequencing

**Version: 4.3.0 (minor)** — Tier 1 is genuinely net-new user-visible capability (first runtime entrance, observation discipline, escalation rung), additive, no breaking change *if the flag is optional*. Framed in the CHANGELOG in **prometheus's voice**: "transferred procedures; effect on claudex's model mix unmeasured." Headline: *v4.2.0 stopped stale-artifact leaks at finalization; v4.3.0 adds claudex's first runtime completion entrance and stops exit-0-is-not-correctness leaks at the intermediate verifiers.*

**Sequence (2 real phases, not 5):**
1. **Phase 1 — Tier 0 + Tier 1.** Shared references first (`observation-grounding.md`, `meta-loop §5` rung, decomposition example), then wire the ≤3 R3 consumers + QA UNTESTABLE + the Stop hook. Update `INDEX.md` (count + mirror map) and the 4-place version sync. **Then stop and observe.**
2. **Phase 2 — Tier 2, only if Phase 1 surfaces a real failure** the discipline would have caught.

---

## 8. Definition of Done (verifiable)

- [ ] `observation-grounding.md` ≤40 lines, listed in `INDEX.md` reference table with consuming agents; every agent given an R3 change cites it by exact path (`rg` the citation).
- [ ] R3 flag is **optional**: an old-format `.harness` artifact (no flag) still passes the new Phase Verifier unchanged (prove with a run, not assertion).
- [ ] R1 ladder mechanism appears in **exactly one** file (`meta-loop §5`); `grep` for duplicate "raise effort / stronger tier" bodies returns one. Every escalation phrasing uses a TIER LABEL — `rg -i 'sonnet|opus|haiku|claude-'` across edited files returns only pre-existing allowed mentions.
- [ ] All 5 "retry ≥ 3" assertions route to the rung (grep-verified).
- [ ] QA UNTESTABLE never credits a grade; carries a captured blocker; routes to escalation.
- [ ] Stop hook: `hooks.json` has a `Stop` entry; `finish-the-work.sh` is executable; loop-guarded; excludes user-question endings (smoke-test: a turn ending "next I'll run QA" with no tool call is re-engaged; a turn ending in a question is not).
- [ ] Cut-list honored — none of §5's cuts were added (grep).
- [ ] Run the **Completion Gate scan** + `/harness-lint` over all edited files: 0 stale artifacts, 0 Codex-mirror drift, agent count in `INDEX.md` still consistent.
- [ ] Version synced in all 4 places (plugin.json, marketplace.json, README.md/README.en.md, INDEX/CHANGELOG) to 4.3.0; the 4-step plugin sync run afterward.

---

## 9. Decisions (resolved 2026-06-15)

1. **Stop hook (T1.1): INCLUDE.** It is the centerpiece — claudex's first runtime-enforced completion entrance. Accepted that it is a hook, slightly outside the literal "commands and agents" scope.
2. **Aggressiveness: ship Tier 1 as 4.3.0** with honest "effect unmeasured on claudex's model mix" framing (prometheus's Status voice). Not an unversioned experiment.
3. **Tier 2 timing: INCLUDE in this pass** (R5 review two-pass, Diagnostician competing-hypotheses, qa-reporter verbatim gate). Scope therefore = T0 + T1 + T2 + T3, all in 4.3.0.

→ Net: the anti-bloat *discipline* still governs HOW each change lands (one shared reference per discipline, no per-prompt re-inlining, conflicts resolved as reframings) — but the *breadth* is the full plan, shipped and versioned.
