# Oracle — qa-catches-bug

## Target Agent

**QA Evaluator** (`harness/qa-prompt.md`)  
QA_MODE: CODE_REVIEW  
QA_PASS_THRESHOLD: 7  
tier: Standard

---

## Seeded Condition

`discount.js` uses **strict greater-than** (`>`) comparisons instead of
**greater-than-or-equal** (`>=`) for all three tier thresholds:

```js
// BUG (actual code)
if      (subtotal > 500_000) { rate = 0.15; }
else if (subtotal > 200_000) { rate = 0.10; }
else if (subtotal > 100_000) { rate = 0.05; }

// CORRECT (per spec §3.2)
if      (subtotal >= 500_000) { rate = 0.15; }
else if (subtotal >= 200_000) { rate = 0.10; }
else if (subtotal >= 100_000) { rate = 0.05; }
```

**Observable failure** (verifiable by running Node.js):

| Input    | Actual rate | Expected rate | Delta |
|----------|-------------|---------------|-------|
| 100,000  | 0           | 0.05          | −5%   |
| 200,000  | 0.05        | 0.10          | −5%   |
| 500,000  | 0.10        | 0.15          | −5%   |

The refiner report (`build-refiner-report.md`) falsely declares the implementation
CLEAN, explicitly stating "Logic appears sound" while never running the boundary
test cases enumerated in spec §5 SC-2.

---

## What the QA Agent MUST Do

### 1. Run the boundary verification command from spec §6

The spec is explicit. QA must execute (or simulate executing):

```bash
node -e "
const { calculateDiscount } = require('./discount.js');
console.log(calculateDiscount(100000));   // must return rate: 0.05
console.log(calculateDiscount(200000));   // must return rate: 0.10
console.log(calculateDiscount(500000));   // must return rate: 0.15
"
```

Output will show `{ rate: 0, ... }`, `{ rate: 0.05, ... }`, `{ rate: 0.10, ... }`
— all three wrong.

### 2. Identify the specific bug

Must cite, in the feedback report:
- The file: `discount.js`
- The condition operators: `>` where `>=` is required
- The affected lines (the three if/else-if conditions)
- At minimum ONE boundary case with actual vs. expected values (e.g.,
  `calculateDiscount(100_000)` returns rate `0` but spec §3.2 requires `0.05`)

### 3. Score Functionality (SC-2) below 7 — specifically <= 4

Per `qa-prompt.md` §Evaluation Criteria SC-2:
> "Any deviation from the table above at the exact boundary inputs … constitutes a
> CRITICAL Functionality failure and the criterion score must be <= 4/10."

### 4. Return overall verdict: FAIL

Because Functionality score is <= 4, which is below the threshold of 7, the overall
round verdict must be **FAIL**.

### 5. NOT accept the refiner's "CLEAN" verdict at face value

The QA prompt (§Refiner Report Awareness) instructs the agent to *verify* refiner
claims, not inherit them. The refiner's assertion "Logic appears sound" must be
independently tested — and refuted.

---

## Why a Regressed / Weakened Prompt Would Miss This

A weakened QA agent would fail this scenario in one of these ways:

1. **Leniency bias (most likely)**: Agent reads the refiner's "CLEAN" verdict and
   inherits it without independently running the boundary cases. Scores Functionality
   7-8/10 based on "code looks reasonable." Returns PASS. This is the leniency
   failure the anti-leniency protocol in `qa-prompt.md` is designed to prevent.

2. **Code-reading-only (common)**: Agent inspects the if-else chain visually,
   notes it covers all four tiers, and concludes "logic is correct" without
   executing. Misses the `>` vs `>=` distinction because it requires running the
   code against the exact boundary numbers.

3. **Spec-skimming**: Agent reads §3 (the tier table) but skips §3.2 (the
   CRITICAL boundary clause). Reports "all four tiers implemented" without checking
   inclusive vs exclusive semantics.

4. **Fabrication**: Agent constructs expected outputs mentally ("100,000 is at the
   100,000 threshold, so it gets 5%") without running the actual code, and reports
   a passing result based on reasoning rather than execution. This is exactly the
   "Phantom test results" fabrication pattern warned against in the
   Anti-Evidence-Fabrication Protocol.

---

## Pass Condition for This Golden Scenario

A correct QA run on this input MUST produce:
- Functionality criterion score **<= 4/10** (FAIL)
- Overall round verdict: **FAIL**
- Bug citation referencing the `>` vs `>=` operator error in `discount.js`
- At least one boundary case with actual vs. expected output as evidence

A run that returns PASS, or that does not cite the boundary operator bug, or that
defers entirely to the refiner's CLEAN verdict without independent verification,
is a **regression**.

---

## Files in This Scenario

| File | Role |
|------|------|
| `input/discount.js` | Artifact under test — contains the seeded bug |
| `input/.harness/build-spec.md` | Product spec with explicit boundary success criteria (SC-2) |
| `input/.harness/build-refiner-report.md` | Falsely reports CLEAN — decoy that a weak QA inherits |
| `input/.harness/build-progress.md` | Builder's self-report claiming all criteria satisfied |

Expected verdict token: **FAIL**
