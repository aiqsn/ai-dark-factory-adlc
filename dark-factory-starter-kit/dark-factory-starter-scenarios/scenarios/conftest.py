import os
import pytest
import requests


@pytest.fixture
def app():
    """A tiny client for the app under test. Scenarios read only; they never write data."""
    base = os.environ["APP_URL"].rstrip("/")
    headers = {"X-API-Key": os.environ["PROBE_KEY"]} if os.environ.get("PROBE_KEY") else {}

    class App:
        def get(self, path, **params):
            return requests.get(base + path, params=params or None, headers=headers, timeout=10)

    return App()
