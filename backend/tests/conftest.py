"""
Pytest configuration for the Universal SQL Transpiler test suite.

Provides the --regen-golden flag used by test_phase6_golden.py to
regenerate snapshot files instead of asserting against them.
"""
import pytest


def pytest_addoption(parser: pytest.Parser) -> None:
    parser.addoption(
        "--regen-golden",
        action="store_true",
        default=False,
        help="Regenerate golden SQL snapshot files instead of asserting.",
    )


@pytest.fixture(scope="session")
def regen_golden(request: pytest.FixtureRequest) -> bool:
    return request.config.getoption("--regen-golden")
