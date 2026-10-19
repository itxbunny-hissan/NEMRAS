"""
Firebase authentication tests for GET /api/v1/me/identity.

No test here contacts Firebase. Each one patches a seam inside `auth`:

  * `auth._verify_id_token`  - stands in for the Admin SDK call, so header
    parsing, claim checking and status mapping are exercised for real.
  * `auth._firebase_app`     - stands in for SDK initialisation, so the
    unconfigured-server path is exercised without the SDK installed.

Tokens in this file are opaque placeholder strings. They are never real
credentials and are never verified by anything.
"""

import time

import pytest

import auth

ENDPOINT = "/api/v1/me/identity"
FAKE_TOKEN = "placeholder-not-a-real-token"
AUTH_HEADER = {"Authorization": f"Bearer {FAKE_TOKEN}"}


def decoded_claims(uid: str = "firebase-uid-under-test", project: str = None) -> dict:
    """A well-formed decoded ID token, shaped like Firebase's own output."""
    project = project or auth.expected_project_id()
    now = int(time.time())
    return {
        "uid": uid,
        "sub": uid,
        "aud": project,
        "iss": f"https://securetoken.google.com/{project}",
        "auth_time": now,
        "iat": now,
        "exp": now + 3600,
        "firebase": {"sign_in_provider": "phone"},
    }


@pytest.fixture
def accepts_token(monkeypatch):
    """Make verification succeed, returning claims the test can choose."""

    def _install(claims: dict):
        monkeypatch.setattr(auth, "_verify_id_token", lambda token: claims)
        return claims

    return _install


@pytest.fixture
def rejects_token(monkeypatch):
    """Make verification fail the way the Admin SDK would for a given reason."""

    def _install(reason_code: str):
        def _raise(token):
            raise auth.TokenInvalid(reason_code)

        monkeypatch.setattr(auth, "_verify_id_token", _raise)

    return _install


# ------------------------------------------------------------------
# Success
# ------------------------------------------------------------------
def test_valid_token_returns_identity(client, accepts_token):
    accepts_token(decoded_claims(uid="uid-abc-123"))

    response = client.get(ENDPOINT, headers=AUTH_HEADER)

    assert response.status_code == 200
    body = response.json()
    assert body == {
        "uid": "uid-abc-123",
        "binding_status": "not_implemented",
        "bound": False,
        "detail": body["detail"],
    }
    assert "not implemented" in body["detail"].lower()


def test_response_carries_no_patient_or_personal_data(client, accepts_token):
    accepts_token(decoded_claims())

    body = client.get(ENDPOINT, headers=AUTH_HEADER).json()

    assert set(body) == {"uid", "binding_status", "bound", "detail"}
    assert body["bound"] is False


# ------------------------------------------------------------------
# The UID must come from the token, never from the client
# ------------------------------------------------------------------
def test_uid_comes_from_the_verified_token_not_from_query_parameters(
    client, accepts_token
):
    accepts_token(decoded_claims(uid="uid-from-verified-token"))

    response = client.get(
        ENDPOINT,
        headers=AUTH_HEADER,
        params={"uid": "uid-forged-by-client", "cnic": "00000-0000000-0"},
    )

    assert response.status_code == 200
    assert response.json()["uid"] == "uid-from-verified-token"


def test_endpoint_ignores_a_request_body_claiming_another_uid(client, accepts_token):
    accepts_token(decoded_claims(uid="uid-from-verified-token"))

    response = client.request(
        "GET",
        ENDPOINT,
        headers=AUTH_HEADER,
        json={"uid": "uid-forged-by-client"},
    )

    assert response.status_code == 200
    assert response.json()["uid"] == "uid-from-verified-token"


# ------------------------------------------------------------------
# 401 - missing and malformed credentials
# ------------------------------------------------------------------
def test_missing_authorization_header_returns_401(client):
    response = client.get(ENDPOINT)

    assert response.status_code == 401
    assert response.headers["WWW-Authenticate"] == "Bearer"


@pytest.mark.parametrize(
    "header",
    [
        "",
        FAKE_TOKEN,                      # no scheme
        f"Basic {FAKE_TOKEN}",           # wrong scheme
        "Bearer",                        # scheme with no token
        "Bearer ",                       # scheme with blank token
        f"Bearer {FAKE_TOKEN} extra",    # too many parts
    ],
)
def test_malformed_bearer_header_returns_401(client, header):
    response = client.get(ENDPOINT, headers={"Authorization": header})

    assert response.status_code == 401


def test_bearer_scheme_is_case_insensitive(client, accepts_token):
    accepts_token(decoded_claims())

    response = client.get(
        ENDPOINT, headers={"Authorization": f"bearer {FAKE_TOKEN}"}
    )

    assert response.status_code == 200


# ------------------------------------------------------------------
# 401 - tokens the SDK rejects
# ------------------------------------------------------------------
@pytest.mark.parametrize(
    "reason_code",
    ["token_invalid", "token_expired", "token_revoked", "user_disabled"],
)
def test_rejected_tokens_return_401(client, rejects_token, reason_code):
    rejects_token(reason_code)

    response = client.get(ENDPOINT, headers=AUTH_HEADER)

    assert response.status_code == 401


def test_rejection_detail_does_not_disclose_the_reason(client, rejects_token):
    """A caller must not be able to tell 'expired' from 'no such user'."""
    rejects_token("token_expired")
    expired = client.get(ENDPOINT, headers=AUTH_HEADER).json()["detail"]

    rejects_token("token_invalid")
    invalid = client.get(ENDPOINT, headers=AUTH_HEADER).json()["detail"]

    assert expired == invalid


# ------------------------------------------------------------------
# 401 - tokens from the wrong Firebase project
# ------------------------------------------------------------------
def test_token_from_another_project_returns_401(client, accepts_token):
    accepts_token(decoded_claims(project="some-other-project"))

    response = client.get(ENDPOINT, headers=AUTH_HEADER)

    assert response.status_code == 401


def test_audience_mismatch_returns_401(client, accepts_token):
    claims = decoded_claims()
    claims["aud"] = "some-other-project"
    accepts_token(claims)

    assert client.get(ENDPOINT, headers=AUTH_HEADER).status_code == 401


def test_issuer_mismatch_returns_401(client, accepts_token):
    claims = decoded_claims()
    claims["iss"] = "https://securetoken.google.com/some-other-project"
    accepts_token(claims)

    assert client.get(ENDPOINT, headers=AUTH_HEADER).status_code == 401


def test_token_without_a_subject_returns_401(client, accepts_token):
    claims = decoded_claims()
    claims.pop("uid")
    claims.pop("sub")
    accepts_token(claims)

    assert client.get(ENDPOINT, headers=AUTH_HEADER).status_code == 401


def test_expected_project_defaults_to_the_confirmed_nemras_project():
    assert auth.DEFAULT_PROJECT_ID == "nemras-3230f"


# ------------------------------------------------------------------
# 503 - server cannot verify, and must not fall back to allowing access
# ------------------------------------------------------------------
def test_unconfigured_firebase_admin_returns_503(client, monkeypatch):
    def _unavailable():
        raise auth.AdminUnavailable("firebase_admin_not_installed")

    monkeypatch.setattr(auth, "_firebase_app", _unavailable)
    auth.reset_admin_app_cache()

    response = client.get(ENDPOINT, headers=AUTH_HEADER)

    assert response.status_code == 503


def test_certificate_fetch_failure_returns_503_not_200(client, monkeypatch):
    """If Google's certificates are unreachable we fail closed, never open."""

    def _raise(token):
        raise auth.AdminUnavailable("certificate_fetch_failed")

    monkeypatch.setattr(auth, "_verify_id_token", _raise)

    response = client.get(ENDPOINT, headers=AUTH_HEADER)

    assert response.status_code == 503


def test_unconfigured_server_still_rejects_a_missing_token_with_401(
    client, monkeypatch
):
    """Malformed requests are refused before server configuration matters."""

    def _unavailable():
        raise auth.AdminUnavailable("firebase_admin_not_installed")

    monkeypatch.setattr(auth, "_firebase_app", _unavailable)

    assert client.get(ENDPOINT).status_code == 401


# ------------------------------------------------------------------
# A1 must not change the existing surface
# ------------------------------------------------------------------
def test_existing_unversioned_routes_remain_unauthenticated(client):
    """
    Pins current behaviour so a later increment cannot change it silently.
    These routes are NOT secure; they are addressed in a later increment.
    """
    assert client.get("/health").status_code == 200
    assert client.get("/").status_code == 200
    assert client.get("/api/stats").status_code == 200
