"""Shared pytest fixtures for the NEMRAS backend tests."""

import os
import sys

import pytest
from fastapi.testclient import TestClient

# Allow "import main" when pytest is invoked from the repository root.
BACKEND_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if BACKEND_DIR not in sys.path:
    sys.path.insert(0, BACKEND_DIR)

import main  # noqa: E402


@pytest.fixture(scope="session")
def client():
    """
    TestClient used as a context manager so the FastAPI lifespan handler runs
    and the dataset is loaded, exactly as it is in production.

    Reads NEMRAS_Dataset.csv read-only; nothing is written back.
    """
    with TestClient(main.app) as c:
        yield c


@pytest.fixture(scope="session")
def known_cnic(client):
    """A real CNIC from the dataset, taken from the public sample endpoint."""
    response = client.get("/api/patients/sample", params={"n": 1})
    assert response.status_code == 200
    rows = response.json()
    if not rows:
        pytest.skip("Dataset returned no sample rows")
    return rows[0]["CNIC"]
