# Spec: paginate utility — Scale S / CODE_REVIEW mode

## Scale: S
## QA_MODE: CODE_REVIEW
## QA_PASS_THRESHOLD: 7
## Round: 1

## Task

Implement a pure-Python list paginator utility (`paginate.py`) with a comprehensive test suite
(`test_paginate.py`).  No external services, no database, no web server.  The function must be
importable as `from paginate import paginate`.

## Function Signature

```python
def paginate(items: list, page: int, page_size: int) -> dict:
    ...
```

## Return Shape

The return value is always a `dict` with exactly these five keys:

| Key          | Type | Description                                        |
|--------------|------|----------------------------------------------------|
| `page`       | int  | The requested page number (echoed back)            |
| `page_size`  | int  | Items per page (echoed back)                       |
| `total`      | int  | Total number of items in the full collection       |
| `total_pages`| int  | Ceiling division of total by page_size; minimum 1  |
| `items`      | list | The slice of items for this page (may be empty)    |

## Error Contract

| Condition                | Exception   | Message pattern                          |
|--------------------------|-------------|------------------------------------------|
| `items` not a `list`     | `TypeError` | mentions received type                   |
| `page` not an `int`      | `TypeError` | mentions received type                   |
| `page_size` not an `int` | `TypeError` | mentions received type                   |
| `bool` passed for page/page_size | `TypeError` | `bool` is a subclass of `int` and must be explicitly rejected |
| `page < 1`               | `ValueError`| mentions the received value              |
| `page_size < 1`          | `ValueError`| mentions the received value              |

## Test Coverage Required

The test suite must cover:

1. Return-value shape — all five keys present, page/page_size echoed
2. Empty list — `items == []`, `total == 0`, `total_pages == 1`
3. Empty list with page > 1 — `items == []` (no crash)
4. Single-item list — correct slice, correct counts
5. Exact-fit scenario (items divide evenly) — first, middle, last pages correct
6. Partial last page — ceiling-division gives correct `total_pages`
7. Page beyond `total_pages` — returns `items == []`, totals unchanged
8. Mutation safety — original list not mutated; returned slice is independent
9. `TypeError` for tuple, dict, float page, string page, bool page, float page_size, bool page_size
10. `ValueError` for `page=0`, `page=-1`, `page_size=0`, `page_size=-5`

## Success Criteria

All of the following must be met for QA to pass (threshold 7/10 on all criteria):

### SC-1 — Completeness
All ten test coverage categories above have at least one test case each.
The test file is importable without error.

### SC-2 — Functionality
`python3 -m pytest test_paginate.py` exits 0 with **all tests passing (0 failures, 0 errors)**.
No skipped tests that skip a required category.

### SC-3 — Code Quality
- `paginate.py` contains no `print()` statements, no `TODO`/`FIXME` comments,
  no commented-out code blocks, no hardcoded secrets.
- The function is under 50 lines of implementation code (docstring excluded).
- Error messages for `TypeError` and `ValueError` mention the bad value or type received.
- No mutation of the input `items` list.

## Out of Scope

- Visual design (not applicable — no UI)
- Playwright / browser testing (not applicable — no web server)
- Performance benchmarks
