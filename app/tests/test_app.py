"""Unit tests that run without a database.

The real database layer is replaced by a small in-memory fake, so these tests
are safe to run in CI and never open a network connection.
"""
import os

# main.py reads DATABASE_URL at import time; this dummy value is never connected to.
os.environ.setdefault("DATABASE_URL", "postgresql://localhost/unit_test_db")

from fastapi.testclient import TestClient  # noqa: E402

from main import app  # noqa: E402
from routers.journal_router import get_entry_service  # noqa: E402


class FakeEntryService:
    def __init__(self, entries=None):
        self.entries = entries or []

    async def create_entry(self, entry_data):
        return entry_data

    async def get_all_entries(self):
        return self.entries

    async def get_entry(self, entry_id):
        for entry in self.entries:
            if entry["id"] == entry_id:
                return entry
        return None


def make_client(entries=None):
    app.dependency_overrides[get_entry_service] = lambda: FakeEntryService(entries)
    return TestClient(app)


def teardown_function():
    app.dependency_overrides.clear()


def test_health_returns_healthy():
    response = make_client().get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}


def test_metrics_exposes_request_counter():
    client = make_client()
    client.get("/health")
    response = client.get("/metrics")
    assert response.status_code == 200
    assert "http_requests_total" in response.text


def test_openapi_lists_entry_routes():
    paths = make_client().get("/openapi.json").json()["paths"]
    assert "/entries" in paths
    assert "/entries/{entry_id}" in paths


def test_create_entry_success():
    payload = {"work": "Wrote tests", "struggle": "Mocking", "intention": "Ship it"}
    response = make_client().post("/entries", json=payload)
    assert response.status_code == 200
    body = response.json()
    assert body["detail"] == "Entry created successfully"
    assert body["entry"]["work"] == "Wrote tests"


def test_create_entry_rejects_blank_field():
    payload = {"work": "   ", "struggle": "Mocking", "intention": "Ship it"}
    response = make_client().post("/entries", json=payload)
    assert response.status_code == 422


def test_list_entries_returns_count():
    entries = [{"id": "1", "work": "a", "struggle": "b", "intention": "c"}]
    response = make_client(entries).get("/entries")
    assert response.status_code == 200
    assert response.json()["count"] == 1


def test_missing_entry_returns_404():
    response = make_client().get("/entries/does-not-exist")
    assert response.status_code == 404
