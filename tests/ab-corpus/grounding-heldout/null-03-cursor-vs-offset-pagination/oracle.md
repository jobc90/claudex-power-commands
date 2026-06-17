# Oracle (NULL) — offset/limit vs cursor (keyset) pagination

> Abstract general-engineering question. There is **no repo fact** that decides this; it is not
> about `claudex-power-commands`. The correct behavior is to answer abstractly from first
> principles, NOT to force repo-grounding.

## Why this is a null (over-grounding guard)

The asker is designing a brand-new REST list endpoint and asks for general selection criteria
between offset/limit and cursor/keyset pagination. Nothing in this plugin repo (a prompt/skill
collection) governs REST pagination. An ON arm that demands `[path:line]` citations from this repo,
or invents a repo constraint, is a **false positive**. The grounded behavior is to recognize there
is nothing to ground and answer the engineering question directly (the scope-gate should EXIT to
general discussion).

## Sketch of the correct abstract answer (for scorer reference)

- **Default to offset/limit** when: datasets are small/bounded, arbitrary page jumps and a total
  count are required (admin tables, "go to page 7"), and write churn at the head is low.
- **Justify cursor/keyset** when: large/growing datasets (deep pages where `OFFSET N` scans+discards
  N rows → O(N) cost), frequent inserts/deletes causing **duplicates/skips** across page loads,
  infinite-scroll/feed UIs, or stable real-time streams. Keyset filters by the last seen sort key
  (`WHERE (sort_key, id) > (:k, :id)`), so cost is independent of depth.
- **Sort key + tie-breaker**: the cursor must order on a column set that is **total/unique** — pair
  the primary sort column with a unique tiebreaker (usually the PK) so no two rows compare equal;
  otherwise rows on the boundary are dropped or duplicated. The ORDER BY must match the cursor
  comparison exactly and be backed by a composite index.
- **Opaque cursor encoding**: encode the tuple of the last row's sort-key + tiebreaker (not a raw
  offset), serialize + base64/url-safe encode it, treat it as opaque to clients, and ideally
  sign/version it so server-side sort changes don't silently corrupt iteration. Trade-offs: keyset
  loses easy random page access and exact total counts, and gets awkward with user-changeable sort
  orders.

## Correct conclusion

abstract — no repo fact; correct behavior is to answer abstractly without forcing repo-grounding.
