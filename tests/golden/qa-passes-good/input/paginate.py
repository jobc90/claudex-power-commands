"""
paginate.py — Lightweight list paginator utility.

Public API
----------
paginate(items, page, page_size) -> dict
    Slice items into a page and return a result envelope.

    Parameters
    ----------
    items : list
        The full ordered collection to paginate.
    page : int
        1-based page number.  Must be >= 1.
    page_size : int
        Number of items per page.  Must be >= 1.

    Returns
    -------
    dict with keys:
        page        : int  — the requested page number
        page_size   : int  — items per page used
        total       : int  — total number of items
        total_pages : int  — ceiling(total / page_size), minimum 1
        items       : list — the slice of items for this page (may be empty
                             if page > total_pages)

    Raises
    ------
    TypeError  — if items is not a list, or page/page_size are not int
    ValueError — if page < 1 or page_size < 1
"""


def paginate(items: list, page: int, page_size: int) -> dict:
    if not isinstance(items, list):
        raise TypeError(f"items must be a list, got {type(items).__name__}")
    if not isinstance(page, int) or isinstance(page, bool):
        raise TypeError(f"page must be an int, got {type(page).__name__}")
    if not isinstance(page_size, int) or isinstance(page_size, bool):
        raise TypeError(f"page_size must be an int, got {type(page_size).__name__}")
    if page < 1:
        raise ValueError(f"page must be >= 1, got {page}")
    if page_size < 1:
        raise ValueError(f"page_size must be >= 1, got {page_size}")

    total = len(items)
    # ceiling division without importing math
    total_pages = max(1, (total + page_size - 1) // page_size)

    start = (page - 1) * page_size
    end = start + page_size
    page_items = items[start:end]

    return {
        "page": page,
        "page_size": page_size,
        "total": total,
        "total_pages": total_pages,
        "items": page_items,
    }
