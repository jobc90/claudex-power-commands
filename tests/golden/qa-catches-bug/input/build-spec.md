# Build Spec — Order Discount Calculator

**Feature**: Discount rate calculation for dearwell Partners Hub orders  
**Module**: `discount.js`  
**Scope**: Pure JS utility function; no UI, no persistence  
**QA_MODE**: CODE_REVIEW  
**QA_PASS_THRESHOLD**: 7  
**tier**: Standard

---

## §1 Background

The Partners Hub applies volume-based discounts to distributor orders. The discount
calculator is a shared utility called by the order creation endpoint and the cart
subtotal component.

---

## §2 Function Signature

```js
calculateDiscount(subtotal: number): { rate: number, amount: number, total: number }
```

- `subtotal` — order subtotal in KRW, integer, >= 0
- Returns an object with:
  - `rate`   — discount rate as a decimal (0, 0.05, 0.10, 0.15)
  - `amount` — KRW amount discounted (Math.floor applied)
  - `total`  — final payable amount = subtotal − amount

---

## §3 Discount Tier Rules

| Tier | Condition              | Discount Rate |
|------|------------------------|---------------|
| A    | subtotal >= 500,000    | 15%           |
| B    | subtotal >= 200,000    | 10%           |
| C    | subtotal >= 100,000    | 5%            |
| None | subtotal < 100,000     | 0%            |

---

## §3.2 Boundary Condition (CRITICAL)

Exact threshold values **must qualify** for the corresponding tier. The comparison
is **inclusive** (`>=`). Specifically:

- `calculateDiscount(100_000)` → rate **0.05** (Tier C, NOT 0%)
- `calculateDiscount(200_000)` → rate **0.10** (Tier B, NOT 5%)
- `calculateDiscount(500_000)` → rate **0.15** (Tier A, NOT 10%)

Failure to meet this requirement means distributors placing orders at exact tier
thresholds receive the wrong (lower) discount — a direct revenue/trust bug.

---

## §4 Error Handling

- `subtotal < 0` or non-number input → throw `RangeError`

---

## §5 Success Criteria (each must score >= 7/10 to pass)

**SC-1 Completeness**  
All four discount tiers are implemented. The function signature matches §2 exactly.

**SC-2 Functionality — Boundary Correctness (CRITICAL)**  
Running `node discount.js` or a test script against the following inputs must
return the exact rates below:

| Input (subtotal) | Expected rate | Expected amount | Expected total |
|-----------------|---------------|-----------------|----------------|
| 50,000          | 0             | 0               | 50,000         |
| 100,000         | 0.05          | 5,000           | 95,000         |
| 150,000         | 0.05          | 7,500           | 142,500        |
| 200,000         | 0.10          | 20,000          | 180,000        |
| 350,000         | 0.10          | 35,000          | 315,000        |
| 500,000         | 0.15          | 75,000          | 425,000        |
| 750,000         | 0.15          | 112,500         | 637,500        |

Any deviation from the table above at the exact boundary inputs (100,000 / 200,000 /
500,000) constitutes a **CRITICAL** Functionality failure and the criterion score
must be <= 4/10.

**SC-3 Error Handling**  
`calculateDiscount(-1)` and `calculateDiscount('abc')` must throw `RangeError`.

**SC-4 Code Quality**  
No magic numbers without comments, no mutation of input, no debug `console.log`.

---

## §6 Testing Instructions

No build step required. Verify by running:

```bash
node -e "
const { calculateDiscount } = require('./discount.js');
// boundary cases
console.log(calculateDiscount(100000));   // expect rate: 0.05
console.log(calculateDiscount(200000));   // expect rate: 0.10
console.log(calculateDiscount(500000));   // expect rate: 0.15
"
```
