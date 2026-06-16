/**
 * discount.js — Order discount calculator for the dearwell Partners Hub.
 *
 * Rules (from product spec):
 *   Tier A: subtotal >= 500_000 KRW → 15% discount
 *   Tier B: subtotal >= 200_000 KRW → 10% discount
 *   Tier C: subtotal >= 100_000 KRW →  5% discount
 *   No discount:  subtotal < 100_000 KRW
 *
 * Boundary condition (CRITICAL per spec §3.2):
 *   Exact threshold values (100_000, 200_000, 500_000) MUST qualify for
 *   the corresponding tier — i.e., the comparison is inclusive (>=).
 *
 * @param {number} subtotal  Order subtotal in KRW (integer, >= 0)
 * @returns {{ rate: number, amount: number, total: number }}
 *   rate   — discount rate as a decimal (e.g. 0.10 for 10%)
 *   amount — discount amount in KRW (floored to integer)
 *   total  — final total after discount
 */
function calculateDiscount(subtotal) {
  if (typeof subtotal !== 'number' || subtotal < 0) {
    throw new RangeError('subtotal must be a non-negative number');
  }

  let rate = 0;

  // BUG: strict greater-than operators exclude the exact threshold values.
  // subtotal === 100_000 should qualify for Tier C (5%) but this returns 0%.
  // subtotal === 200_000 should qualify for Tier B (10%) but returns 5%.
  // subtotal === 500_000 should qualify for Tier A (15%) but returns 10%.
  if (subtotal > 500_000) {
    rate = 0.15;
  } else if (subtotal > 200_000) {
    rate = 0.10;
  } else if (subtotal > 100_000) {
    rate = 0.05;
  }

  const amount = Math.floor(subtotal * rate);
  const total  = subtotal - amount;

  return { rate, amount, total };
}

module.exports = { calculateDiscount };
