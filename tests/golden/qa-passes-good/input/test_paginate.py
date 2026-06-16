"""
test_paginate.py — Test suite for paginate.py

Covers:
  - empty list
  - single-item list
  - exact fit (items divide evenly into pages)
  - partial last page
  - page beyond total_pages returns empty items slice
  - page_size larger than total
  - first page, middle page, last page
  - total_pages calculation correctness
  - TypeError on wrong argument types
  - ValueError on out-of-range arguments
  - return-value shape (all five keys present)
  - items list is not mutated by paginate()
"""

import copy
import pytest
from paginate import paginate


# ---------------------------------------------------------------------------
# Shape / contract
# ---------------------------------------------------------------------------

class TestReturnShape:
    def test_all_keys_present(self):
        result = paginate([1, 2, 3], page=1, page_size=2)
        assert set(result.keys()) == {"page", "page_size", "total", "total_pages", "items"}

    def test_page_echoed(self):
        result = paginate([1], page=1, page_size=10)
        assert result["page"] == 1

    def test_page_size_echoed(self):
        result = paginate([1, 2], page=1, page_size=5)
        assert result["page_size"] == 5


# ---------------------------------------------------------------------------
# Empty list
# ---------------------------------------------------------------------------

class TestEmptyList:
    def test_empty_items(self):
        result = paginate([], page=1, page_size=10)
        assert result["items"] == []

    def test_empty_total_zero(self):
        result = paginate([], page=1, page_size=10)
        assert result["total"] == 0

    def test_empty_total_pages_is_one(self):
        # A paginator with no data still has at least 1 page (the empty page)
        result = paginate([], page=1, page_size=10)
        assert result["total_pages"] == 1

    def test_empty_page_beyond_returns_empty(self):
        result = paginate([], page=5, page_size=10)
        assert result["items"] == []


# ---------------------------------------------------------------------------
# Single item
# ---------------------------------------------------------------------------

class TestSingleItem:
    def test_single_item_page1(self):
        result = paginate(["only"], page=1, page_size=1)
        assert result["items"] == ["only"]
        assert result["total"] == 1
        assert result["total_pages"] == 1

    def test_single_item_page_size_larger_than_total(self):
        result = paginate(["only"], page=1, page_size=100)
        assert result["items"] == ["only"]
        assert result["total_pages"] == 1


# ---------------------------------------------------------------------------
# Exact fit (evenly divisible)
# ---------------------------------------------------------------------------

class TestExactFit:
    def setup_method(self):
        self.items = list(range(1, 7))  # [1, 2, 3, 4, 5, 6]

    def test_total_pages(self):
        result = paginate(self.items, page=1, page_size=2)
        assert result["total_pages"] == 3

    def test_first_page(self):
        result = paginate(self.items, page=1, page_size=2)
        assert result["items"] == [1, 2]

    def test_middle_page(self):
        result = paginate(self.items, page=2, page_size=2)
        assert result["items"] == [3, 4]

    def test_last_page(self):
        result = paginate(self.items, page=3, page_size=2)
        assert result["items"] == [5, 6]


# ---------------------------------------------------------------------------
# Partial last page
# ---------------------------------------------------------------------------

class TestPartialLastPage:
    def setup_method(self):
        self.items = list(range(1, 8))  # 7 items, page_size=3 → pages 1,2,3 (last has 1 item)

    def test_total_pages_rounds_up(self):
        result = paginate(self.items, page=1, page_size=3)
        assert result["total_pages"] == 3

    def test_last_page_partial(self):
        result = paginate(self.items, page=3, page_size=3)
        assert result["items"] == [7]

    def test_total_correct(self):
        result = paginate(self.items, page=1, page_size=3)
        assert result["total"] == 7


# ---------------------------------------------------------------------------
# Page beyond total_pages
# ---------------------------------------------------------------------------

class TestPageBeyondTotalPages:
    def test_over_page_returns_empty(self):
        items = list(range(1, 6))  # 5 items, page_size=5 → 1 page
        result = paginate(items, page=2, page_size=5)
        assert result["items"] == []

    def test_over_page_total_unchanged(self):
        items = list(range(1, 6))
        result = paginate(items, page=99, page_size=5)
        assert result["total"] == 5

    def test_over_page_total_pages_unchanged(self):
        items = list(range(1, 6))
        result = paginate(items, page=99, page_size=5)
        assert result["total_pages"] == 1


# ---------------------------------------------------------------------------
# Mutation safety
# ---------------------------------------------------------------------------

class TestMutationSafety:
    def test_original_list_not_mutated(self):
        original = [10, 20, 30, 40, 50]
        snapshot = copy.copy(original)
        paginate(original, page=1, page_size=3)
        assert original == snapshot

    def test_returned_items_is_a_slice_not_original(self):
        original = [1, 2, 3]
        result = paginate(original, page=1, page_size=2)
        result["items"].append(99)
        assert original == [1, 2, 3]


# ---------------------------------------------------------------------------
# TypeError
# ---------------------------------------------------------------------------

class TestTypeErrors:
    def test_items_not_list(self):
        with pytest.raises(TypeError):
            paginate((1, 2, 3), page=1, page_size=2)

    def test_items_dict(self):
        with pytest.raises(TypeError):
            paginate({"a": 1}, page=1, page_size=2)

    def test_page_float(self):
        with pytest.raises(TypeError):
            paginate([1, 2], page=1.0, page_size=2)

    def test_page_string(self):
        with pytest.raises(TypeError):
            paginate([1, 2], page="1", page_size=2)

    def test_page_bool_rejected(self):
        # bool is a subclass of int in Python; we explicitly reject it
        with pytest.raises(TypeError):
            paginate([1, 2], page=True, page_size=2)

    def test_page_size_float(self):
        with pytest.raises(TypeError):
            paginate([1, 2], page=1, page_size=2.0)

    def test_page_size_bool_rejected(self):
        with pytest.raises(TypeError):
            paginate([1, 2], page=1, page_size=True)


# ---------------------------------------------------------------------------
# ValueError
# ---------------------------------------------------------------------------

class TestValueErrors:
    def test_page_zero(self):
        with pytest.raises(ValueError):
            paginate([1, 2], page=0, page_size=2)

    def test_page_negative(self):
        with pytest.raises(ValueError):
            paginate([1, 2], page=-1, page_size=2)

    def test_page_size_zero(self):
        with pytest.raises(ValueError):
            paginate([1, 2], page=1, page_size=0)

    def test_page_size_negative(self):
        with pytest.raises(ValueError):
            paginate([1, 2], page=1, page_size=-5)
