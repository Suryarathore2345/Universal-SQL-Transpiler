"""
Phase 6 — Golden-file snapshot tests.

For every (source_dialect, target_dialect, object_type) triple the transpiler
output is compared against a stored .sql file in tests/golden/.

Run normally:
    pytest tests/test_phase6_golden.py

Regenerate all snapshots after an intentional generator change:
    pytest tests/test_phase6_golden.py --regen-golden

Golden files live at:
    tests/golden/{src}_to_{tgt}/{object_type}.sql

Total: 8 × 8 × 5 = 320 snapshot files.
"""
from __future__ import annotations

import pathlib

import pytest

from app.transpiler import Transpiler
from tests.golden_samples import ALL_DIALECTS, GOLDEN_SAMPLES, OBJECT_TYPES

GOLDEN_DIR = pathlib.Path(__file__).parent / "golden"


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _golden_path(src: str, tgt: str, obj_type: str) -> pathlib.Path:
    return GOLDEN_DIR / f"{src}_to_{tgt}" / f"{obj_type}.sql"


def _run(src: str, tgt: str, obj_type: str) -> str:
    sql_input = GOLDEN_SAMPLES[src][obj_type]
    result = Transpiler.convert(sql_input, src, tgt)
    return result.converted_sql


# ---------------------------------------------------------------------------
# Parametrized golden test
# ---------------------------------------------------------------------------

_PARAMS = [
    (src, tgt, obj_type)
    for src in ALL_DIALECTS
    for tgt in ALL_DIALECTS
    for obj_type in OBJECT_TYPES
]


@pytest.mark.parametrize("src,tgt,obj_type", _PARAMS, ids=[
    f"{s}_to_{t}__{o}" for s, t, o in _PARAMS
])
def test_golden(src: str, tgt: str, obj_type: str, regen_golden: bool) -> None:
    actual = _run(src, tgt, obj_type)
    path = _golden_path(src, tgt, obj_type)

    if regen_golden:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(actual, encoding="utf-8")
        return

    assert path.exists(), (
        f"Golden file missing: {path}\n"
        f"Run: pytest --regen-golden  to create all snapshots."
    )
    expected = path.read_text(encoding="utf-8")
    assert actual == expected, (
        f"Output changed for {src} → {tgt} ({obj_type}).\n"
        f"Run: pytest --regen-golden  to accept the new output.\n\n"
        f"--- expected ---\n{expected}\n"
        f"--- actual ---\n{actual}"
    )


# ---------------------------------------------------------------------------
# Sanity: every golden file must contain non-empty SQL
# ---------------------------------------------------------------------------

@pytest.mark.parametrize("src,tgt,obj_type", _PARAMS, ids=[
    f"nonempty_{s}_to_{t}__{o}" for s, t, o in _PARAMS
])
def test_output_nonempty(src: str, tgt: str, obj_type: str) -> None:
    actual = _run(src, tgt, obj_type)
    assert actual.strip(), (
        f"Transpiler returned empty string for {src} → {tgt} ({obj_type})"
    )
