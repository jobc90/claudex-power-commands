# Oracle (NULL) — idempotency keys for duplicate-payment prevention

> Abstract general-engineering question. There is **no repo fact** that decides this; it is not
> about `claudex-power-commands`. The correct behavior is to answer abstractly from first
> principles, NOT to force repo-grounding.

## Why this is a null (over-grounding guard)

The asker is designing a payment API's idempotency-key scheme. This plugin repo has no payment code,
no idempotency layer, and nothing to cite. An ON arm that demands `[path:line]` repo citations or
fabricates a repo constraint is a **false positive**. The grounded behavior is to EXIT to general
discussion and answer the engineering question directly.

## Sketch of the correct abstract answer (for scorer reference)

- **Key generation**: the **client** generates the idempotency key (a UUID/random token) per logical
  operation and resends the *same* key on retries. The key identifies the intent, not the transport.
- **Storage + TTL**: persist `key → {status, response snapshot, request fingerprint}` in a durable,
  atomically-conditional store (DB unique constraint, or Redis `SET NX`). Scope the key per
  merchant/account to avoid cross-tenant collisions. Apply a TTL long enough to cover realistic
  retry windows (commonly ~24h) but bounded so the table doesn't grow unbounded; a returned cached
  result must outlive the client's retry budget.
- **Concurrency / race on simultaneous retries**: make the first-writer-wins step atomic — insert the
  key row in a `PENDING`/in-progress state under a unique constraint (or `SET NX`) **before** calling
  the payment processor. Concurrent duplicates that lose the insert either block on the in-flight
  result or get a "request in progress / retry later" (409/425-style) response; they must **not**
  each call the processor. Finalize the row to `COMPLETED` with the stored response.
- **Body-mismatch conflict**: store a fingerprint (hash) of the request body with the key. If a
  later request reuses the key with a **different** body, reject with `409 Conflict` rather than
  silently returning the old result or processing a new charge — same key must mean same operation.
- **Pitfalls to avoid**: calling the processor before persisting the key (a crash leaves a charge
  with no record → the retry double-charges); caching only success and not failures (a retried
  failure re-attempts); non-atomic check-then-act (TOCTOU double charge); unbounded TTL; keying on
  the wrong granularity (per-request transport id instead of per-intent); and returning a stale
  cached response for a genuinely different request.

## Correct conclusion

abstract — no repo fact; correct behavior is to answer abstractly without forcing repo-grounding.
