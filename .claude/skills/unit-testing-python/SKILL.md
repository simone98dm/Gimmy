---
name: unit-testing-python
description: Patterns and suite structure for unit testing Python code with pytest (and unittest interop). Use when writing or reviewing tests for Python functions, classes, services, or API handlers — triggers on pytest, unittest, test_, fixture, monkeypatch, mock, parametrize, unit test.
---

# Unit Testing in Python (pytest)

pytest is the default. If the repo already uses `unittest.TestCase`, keep that style — pytest runs unittest suites natively, so the runner stays `pytest` either way.

## Suite Structure

```
tests/
  unit/
    test_services.py      ← mirrors src/services.py
    test_models.py
    conftest.py           ← shared fixtures for this directory tree
```

File naming: `test_{module}.py`; test functions `test_{behavior}`; test classes (optional grouping) `TestClassName` with no `__init__`. Mirror the source structure.

## Testing Types

| Type | Target | Tooling |
| ---- | ------ | ------- |
| Pure-function testing | Input/output tables, edge cases | `@pytest.mark.parametrize` |
| State testing | Classes: construction, transitions, invariants | plain asserts + fixtures |
| Contract testing | Service boundaries: calls out, error propagation | `unittest.mock` / `mocker` |
| Exception testing | Failure modes | `pytest.raises` |
| Property-style checks | Invariants over ranges of inputs | parametrize (or `hypothesis` if installed) |

## Pattern: Pure Functions (parametrize)

```python
import pytest
from src.pricing import apply_discount

@pytest.mark.parametrize(
    ("price", "pct", "expected"),
    [
        (100.0, 10, 90.0),
        (100.0, 0, 100.0),
        (100.0, 100, 0.0),
        (0.0, 50, 0.0),
    ],
)
def test_apply_discount(price, pct, expected):
    assert apply_discount(price, pct) == expected

def test_apply_discount_rejects_negative_pct():
    with pytest.raises(ValueError, match="percentage"):
        apply_discount(100.0, -1)
```

## Pattern: Fixtures and State

```python
import pytest
from src.cart import Cart

@pytest.fixture
def cart():
    return Cart(currency="EUR")

def test_new_cart_is_empty(cart):
    assert cart.items == []
    assert cart.total == 0

def test_add_item_updates_total(cart):
    cart.add("sku-1", price=10.0, qty=2)
    assert cart.total == 20.0
```

Fixture scopes: `function` (default, isolated), `module`/`session` only for expensive read-only setup. Shared fixtures live in `conftest.py`, never imported explicitly.

## Pattern: Mocking Dependencies

Mock at the architectural seam (HTTP client, repository, gateway) — patch where the name is *used*, not where it is defined:

```python
from unittest.mock import Mock, patch
import pytest
from src.payment_service import charge

@patch("src.payment_service.gateway")  # patch where it's looked up
def test_charge_calls_gateway_and_returns_receipt(mock_gateway):
    mock_gateway.charge.return_value = {"id": "tx_1", "status": "ok"}

    receipt = charge(user_id="u1", amount=42.0)

    mock_gateway.charge.assert_called_once_with(amount=42.0, user="u1")
    assert receipt.status == "ok"

@patch("src.payment_service.gateway")
def test_charge_propagates_gateway_error(mock_gateway):
    mock_gateway.charge.side_effect = TimeoutError
    with pytest.raises(TimeoutError):
        charge(user_id="u1", amount=42.0)
```

Other mocking methods:

- `monkeypatch` fixture — env vars (`monkeypatch.setenv`), attributes, `sys.path`; auto-undone per test
- `tmp_path` fixture — real filesystem work in an isolated temp dir; never touch the repo tree
- `freezegun` / `time-machine` (if installed) — freeze time; otherwise inject a clock
- `capsys` — assert on stdout/stderr
- async code: `pytest.mark.asyncio` (pytest-asyncio) with `AsyncMock`

## What to Cover

- [ ] Happy path with realistic inputs
- [ ] Every raised/propagated exception (`pytest.raises`, assert on `match=`)
- [ ] Edge cases: empty, `None`, zero, negative, boundary values (parametrize them)
- [ ] State transitions and invariants for stateful classes
- [ ] Public API only — no reaching into private attributes

## Rules

- Plain `assert` — pytest rewrites it for rich failure output; no `assertEquals` in new pytest code
- One behavior per test; the function name states the expectation
- No test interdependence — each test builds its own state via fixtures
- Deterministic: seed randomness, freeze/inject time, no real network/DB
- Prefer parametrize over copy-pasted near-identical tests
- Run `pytest` after writing tests and report actual results (`-q` for summary)
