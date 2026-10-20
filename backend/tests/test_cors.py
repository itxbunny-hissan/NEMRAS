"""CORS policy tests. Clients authenticate with Bearer headers, not cookies."""

PREFLIGHT_HEADERS = {
    "Origin": "https://untrusted.example",
    "Access-Control-Request-Method": "POST",
    "Access-Control-Request-Headers": "authorization",
}


def test_preflight_does_not_allow_credentials(client):
    response = client.options("/api/v1/me/patient-id", headers=PREFLIGHT_HEADERS)

    assert response.status_code == 200
    assert "access-control-allow-credentials" not in response.headers
    assert response.headers["access-control-allow-origin"] == "*"


def test_requesting_origin_is_not_echoed_as_trusted(client):
    response = client.get("/health", headers={"Origin": "https://untrusted.example"})

    assert response.headers.get("access-control-allow-origin") == "*"
    assert "access-control-allow-credentials" not in response.headers


def test_bearer_authorization_header_is_still_allowed(client):
    response = client.options("/api/v1/me/patient-id", headers=PREFLIGHT_HEADERS)

    allowed = response.headers["access-control-allow-headers"].lower()
    assert "authorization" in allowed
