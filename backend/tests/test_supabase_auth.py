"""
Supabase access-token verification tests.

No test contacts Supabase or Firebase. Tokens are signed in-process with a
P-256 key generated per test session; the verifier receives that key through
the same resolver seam the JWKS client uses. One test drives the real
PyJWKClient with its key-set download replaced, so key-id matching runs for
real.

Nothing here is a real credential.
"""

import json
import logging
import sqlite3
import time
import uuid

from cryptography.hazmat.primitives.asymmetric import ec
import jwt
import pytest

import auth
import main
import patient_id
import patient_id_issuance
import supabase_auth


PROJECT_URL = "https://nemras-test-project.supabase.co"
ISSUER = f"{PROJECT_URL}/auth/v1"
KID = "test-signing-key"
USER_ID = "8f14e45f-ceea-467a-9575-6a2f1c2b9e0d"


@pytest.fixture(scope="module")
def signing_key():
    return ec.generate_private_key(ec.SECP256R1())


@pytest.fixture(scope="module")
def other_key():
    return ec.generate_private_key(ec.SECP256R1())


def claims(**overrides):
    now = int(time.time())
    base = {
        "iss": ISSUER,
        "aud": "authenticated",
        "sub": USER_ID,
        "role": "authenticated",
        "is_anonymous": False,
        "email": "demo-user@example.test",
        "iat": now,
        "exp": now + 3600,
        "session_id": str(uuid.uuid4()),
    }
    base.update(overrides)
    return {k: v for k, v in base.items() if v is not _DROP}


_DROP = object()


def sign(key, payload, *, algorithm="ES256", kid=KID):
    headers = {"kid": kid} if kid is not None else {}
    return jwt.encode(payload, key, algorithm=algorithm, headers=headers)


def resolver_for(key):
    calls = []

    def _resolve(token):
        calls.append(token)
        return key.public_key()

    _resolve.calls = calls
    return _resolve


def verify(token, key):
    return supabase_auth.verify_access_token(
        token, PROJECT_URL, key_resolver=resolver_for(key)
    )


def reason(excinfo):
    return excinfo.value.reason_code


# ------------------------------------------------------------------
# verify_access_token
# ------------------------------------------------------------------
def test_valid_token_returns_the_user_uuid(signing_key):
    identity = verify(sign(signing_key, claims()), signing_key)

    assert identity == supabase_auth.SupabaseIdentity(user_id=USER_ID)


def test_audience_list_containing_authenticated_is_accepted(signing_key):
    token = sign(signing_key, claims(aud=["authenticated", "other"]))

    assert verify(token, signing_key).user_id == USER_ID


@pytest.mark.parametrize("token", ["", "not-a-jwt", "a.b.c", "Bearer x.y.z"])
def test_malformed_token_is_rejected(signing_key, token):
    with pytest.raises(supabase_auth.SupabaseTokenInvalid) as excinfo:
        verify(token, signing_key)

    assert reason(excinfo) == "token_malformed"


def test_signature_from_another_key_is_rejected(signing_key, other_key):
    token = sign(other_key, claims())

    with pytest.raises(supabase_auth.SupabaseTokenInvalid) as excinfo:
        verify(token, signing_key)

    assert reason(excinfo) == "signature_invalid"


def test_tampered_payload_is_rejected(signing_key):
    header, _, signature = sign(signing_key, claims()).split(".")
    forged_payload = jwt.utils.base64url_encode(
        json.dumps(claims(sub=str(uuid.uuid4()))).encode()
    ).decode()

    with pytest.raises(supabase_auth.SupabaseTokenInvalid) as excinfo:
        verify(f"{header}.{forged_payload}.{signature}", signing_key)

    assert reason(excinfo) == "signature_invalid"


def test_expired_token_is_rejected(signing_key):
    past = int(time.time()) - 7200
    token = sign(signing_key, claims(iat=past, exp=past + 3600))

    with pytest.raises(supabase_auth.SupabaseTokenInvalid) as excinfo:
        verify(token, signing_key)

    assert reason(excinfo) == "token_expired"


@pytest.mark.parametrize(
    "overrides, expected",
    [
        ({"iss": "https://other-project.supabase.co/auth/v1"}, "issuer_mismatch"),
        ({"iss": "supabase"}, "issuer_mismatch"),
        ({"aud": "anon"}, "audience_mismatch"),
        ({"role": "anon"}, "role_not_authenticated"),
        ({"role": "service_role"}, "role_not_authenticated"),
        ({"role": _DROP}, "role_not_authenticated"),
        ({"is_anonymous": True}, "anonymous_user"),
        ({"sub": "not-a-uuid"}, "missing_subject"),
        ({"exp": _DROP}, "token_invalid"),
        ({"sub": _DROP}, "token_invalid"),
    ],
)
def test_claims_that_are_not_a_signed_in_user_are_rejected(
    signing_key, overrides, expected
):
    token = sign(signing_key, claims(**overrides))

    with pytest.raises(supabase_auth.SupabaseTokenInvalid) as excinfo:
        verify(token, signing_key)

    assert reason(excinfo) == expected


def test_hs256_token_is_rejected_before_any_key_lookup(signing_key):
    """Legacy anon/service-role keys are HS256 JWTs signed with the project secret."""
    token = sign("a-shared-secret-of-at-least-32-bytes!!", claims(), algorithm="HS256")
    resolver = resolver_for(signing_key)

    with pytest.raises(supabase_auth.SupabaseTokenInvalid) as excinfo:
        supabase_auth.verify_access_token(token, PROJECT_URL, key_resolver=resolver)

    assert reason(excinfo) == "algorithm_not_allowed"
    assert resolver.calls == []


def test_unsigned_alg_none_token_is_rejected(signing_key):
    token = jwt.encode(claims(), None, algorithm="none", headers={"kid": KID})

    with pytest.raises(supabase_auth.SupabaseTokenInvalid) as excinfo:
        verify(token, signing_key)

    assert reason(excinfo) == "algorithm_not_allowed"


def test_token_without_key_id_is_rejected(signing_key):
    token = sign(signing_key, claims(), kid=None)

    with pytest.raises(supabase_auth.SupabaseTokenInvalid) as excinfo:
        verify(token, signing_key)

    assert reason(excinfo) == "missing_key_id"


# ------------------------------------------------------------------
# Real JWKS client, with only the network download replaced
# ------------------------------------------------------------------
@pytest.fixture
def published_keys(monkeypatch, signing_key):
    jwk = jwt.algorithms.ECAlgorithm.to_jwk(signing_key.public_key(), as_dict=True)
    jwk.update({"kid": KID, "alg": "ES256", "use": "sig"})
    fetched_urls = []

    def _fetch(client):
        fetched_urls.append(client.uri)
        return {"keys": [jwk]}

    monkeypatch.setattr(jwt.PyJWKClient, "fetch_data", _fetch)
    supabase_auth.reset_key_cache()
    yield fetched_urls
    supabase_auth.reset_key_cache()


def test_jwks_client_verifies_a_token_with_a_published_key(
    signing_key, published_keys
):
    identity = supabase_auth.verify_access_token(
        sign(signing_key, claims()), PROJECT_URL
    )

    assert identity.user_id == USER_ID
    assert published_keys[0] == f"{PROJECT_URL}/auth/v1/.well-known/jwks.json"


def test_jwks_client_rejects_an_unpublished_key_id(signing_key, published_keys):
    token = sign(signing_key, claims(), kid="rotated-out-key")

    with pytest.raises(supabase_auth.SupabaseTokenInvalid) as excinfo:
        supabase_auth.verify_access_token(token, PROJECT_URL)

    assert reason(excinfo) == "signing_key_not_found"


def test_unreachable_jwks_endpoint_fails_closed(signing_key):
    """Port 1 on loopback refuses the connection; nothing leaves this machine."""
    supabase_auth.reset_key_cache()
    try:
        with pytest.raises(supabase_auth.SupabaseUnavailable) as excinfo:
            supabase_auth.verify_access_token(
                sign(signing_key, claims(iss="http://127.0.0.1:1/auth/v1")),
                "http://127.0.0.1:1",
            )
    finally:
        supabase_auth.reset_key_cache()

    assert reason(excinfo) == "jwks_unreachable"


# ------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------
def test_unset_project_url_disables_supabase(monkeypatch):
    monkeypatch.delenv(supabase_auth.SUPABASE_URL_ENV, raising=False)

    assert supabase_auth.configured_project_url() is None


@pytest.mark.parametrize(
    "value, expected",
    [
        ("https://abc.supabase.co", "https://abc.supabase.co"),
        ("https://abc.supabase.co/", "https://abc.supabase.co"),
        ("  https://abc.supabase.co  ", "https://abc.supabase.co"),
        ("http://127.0.0.1:54321", "http://127.0.0.1:54321"),
        ("http://localhost:54321", "http://localhost:54321"),
    ],
)
def test_valid_project_urls_are_normalised(monkeypatch, value, expected):
    monkeypatch.setenv(supabase_auth.SUPABASE_URL_ENV, value)

    assert supabase_auth.configured_project_url() == expected


@pytest.mark.parametrize(
    "value",
    [
        "http://abc.supabase.co",
        "abc.supabase.co",
        "https://abc.supabase.co/auth/v1",
        "https://abc.supabase.co?x=1",
        "https://user:pass@abc.supabase.co",
        "ftp://abc.supabase.co",
    ],
)
def test_unusable_project_urls_fail_closed(monkeypatch, value):
    monkeypatch.setenv(supabase_auth.SUPABASE_URL_ENV, value)

    with pytest.raises(supabase_auth.SupabaseUnavailable):
        supabase_auth.configured_project_url()


def test_issuer_routing_ignores_other_tokens(signing_key):
    assert supabase_auth.is_supabase_token(sign(signing_key, claims()), PROJECT_URL)
    assert not supabase_auth.is_supabase_token(
        sign(signing_key, claims(iss="https://securetoken.google.com/x")),
        PROJECT_URL,
    )
    assert not supabase_auth.is_supabase_token("garbage", PROJECT_URL)


# ------------------------------------------------------------------
# Protected routes
# ------------------------------------------------------------------
@pytest.fixture
def supabase_configured(monkeypatch, signing_key):
    monkeypatch.setenv(supabase_auth.SUPABASE_URL_ENV, PROJECT_URL)
    monkeypatch.setattr(
        supabase_auth, "_jwks_resolver", lambda url: resolver_for(signing_key)
    )


@pytest.fixture
def firebase_rejects(monkeypatch):
    """Any token reaching the Firebase verifier is rejected, as a real one would be."""
    calls = []

    def _reject(token):
        calls.append(token)
        raise auth.TokenInvalid("token_invalid")

    monkeypatch.setattr(auth, "_verify_id_token", _reject)
    return calls


@pytest.fixture
def issuance(monkeypatch, tmp_path):
    ledger = patient_id_issuance.PatientIdIssuanceLedger.create(
        tmp_path / "issuance.sqlite3"
    )
    registry = patient_id.PatientIdRegistry.create(tmp_path / "registry.sqlite3")
    monkeypatch.setattr(main, "patient_id_issuance_backends", lambda: (ledger, registry))
    return ledger


def bearer(token):
    return {"Authorization": f"Bearer {token}"}


def mapped_uids(ledger):
    connection = sqlite3.connect(ledger.database_path)
    try:
        return [row[0] for row in connection.execute("SELECT uid FROM patient_id_issuance")]
    finally:
        connection.close()


def test_identity_route_accepts_a_valid_supabase_token(
    client, supabase_configured, firebase_rejects, signing_key
):
    response = client.get("/api/v1/me/identity", headers=bearer(sign(signing_key, claims())))

    assert response.status_code == 200
    body = response.json()
    assert body["uid"] == f"supabase:{USER_ID}"
    assert body["bound"] is False
    assert body["binding_status"] == "not_implemented"
    assert firebase_rejects == []


def test_supabase_user_is_issued_a_patient_id_in_its_own_namespace(
    client, supabase_configured, firebase_rejects, signing_key, issuance
):
    token = sign(signing_key, claims())

    first = client.post("/api/v1/me/patient-id", headers=bearer(token))
    again = client.post("/api/v1/me/patient-id", headers=bearer(token))

    assert first.status_code == 201
    assert again.status_code == 200
    assert again.json()["nemras_id"] == first.json()["nemras_id"]
    assert first.json()["binding_status"] == "not_bound"
    assert mapped_uids(issuance) == [f"supabase:{USER_ID}"]


def test_same_identifier_from_both_providers_gets_different_ids(
    client, supabase_configured, signing_key, issuance, monkeypatch
):
    project = auth.expected_project_id()
    monkeypatch.setattr(
        auth,
        "_verify_id_token",
        lambda token: {
            "uid": USER_ID,
            "sub": USER_ID,
            "aud": project,
            "iss": f"https://securetoken.google.com/{project}",
        },
    )

    supabase_id = client.post(
        "/api/v1/me/patient-id", headers=bearer(sign(signing_key, claims()))
    ).json()["nemras_id"]
    firebase_id = client.post(
        "/api/v1/me/patient-id", headers=bearer("placeholder-firebase-token")
    ).json()["nemras_id"]

    assert supabase_id != firebase_id
    assert sorted(mapped_uids(issuance)) == sorted([USER_ID, f"supabase:{USER_ID}"])


@pytest.mark.parametrize(
    "make_token",
    [
        lambda key, other: sign(other, claims()),
        lambda key, other: sign(
            key, claims(iat=int(time.time()) - 7200, exp=int(time.time()) - 3600)
        ),
        lambda key, other: sign(key, claims(role="anon")),
        lambda key, other: sign(key, claims(is_anonymous=True)),
        lambda key, other: sign(
            "a-shared-secret-of-at-least-32-bytes!!", claims(), algorithm="HS256"
        ),
    ],
    ids=["bad-signature", "expired", "anon-role", "anonymous-user", "hs256"],
)
def test_rejected_supabase_tokens_get_401_and_issue_nothing(
    client, supabase_configured, firebase_rejects, signing_key, other_key,
    issuance, make_token,
):
    response = client.post(
        "/api/v1/me/patient-id", headers=bearer(make_token(signing_key, other_key))
    )

    assert response.status_code == 401
    assert response.json() == {"detail": auth.UNAUTHENTICATED_DETAIL}
    assert response.headers["WWW-Authenticate"] == "Bearer"
    assert mapped_uids(issuance) == []
    assert firebase_rejects == []


def test_missing_token_is_401_with_supabase_configured(
    client, supabase_configured, issuance
):
    response = client.post("/api/v1/me/patient-id")

    assert response.status_code == 401
    assert mapped_uids(issuance) == []


def test_supabase_tokens_are_not_accepted_when_supabase_is_not_configured(
    client, monkeypatch, firebase_rejects, signing_key, issuance
):
    monkeypatch.delenv(supabase_auth.SUPABASE_URL_ENV, raising=False)
    token = sign(signing_key, claims())

    response = client.post("/api/v1/me/patient-id", headers=bearer(token))

    assert response.status_code == 401
    assert firebase_rejects == [token]
    assert mapped_uids(issuance) == []


def test_firebase_uid_in_the_supabase_namespace_is_rejected(
    client, monkeypatch, issuance
):
    project = auth.expected_project_id()
    forged = f"supabase:{USER_ID}"
    monkeypatch.setattr(
        auth,
        "_verify_id_token",
        lambda token: {
            "uid": forged,
            "sub": forged,
            "aud": project,
            "iss": f"https://securetoken.google.com/{project}",
        },
    )

    response = client.post("/api/v1/me/patient-id", headers=bearer("placeholder"))

    assert response.status_code == 401
    assert mapped_uids(issuance) == []


def test_unusable_supabase_url_fails_closed_with_503(client, monkeypatch, issuance):
    monkeypatch.setenv(supabase_auth.SUPABASE_URL_ENV, "http://not-https.example")

    response = client.post("/api/v1/me/patient-id", headers=bearer("placeholder"))

    assert response.status_code == 503
    assert mapped_uids(issuance) == []


def test_unreachable_key_server_returns_503_and_issues_nothing(
    client, monkeypatch, signing_key, issuance
):
    def _unreachable(url):
        def _resolve(token):
            raise supabase_auth.SupabaseUnavailable("jwks_unreachable")

        return _resolve

    monkeypatch.setenv(supabase_auth.SUPABASE_URL_ENV, PROJECT_URL)
    monkeypatch.setattr(supabase_auth, "_jwks_resolver", _unreachable)

    response = client.post(
        "/api/v1/me/patient-id", headers=bearer(sign(signing_key, claims()))
    )

    assert response.status_code == 503
    assert mapped_uids(issuance) == []


def test_tokens_and_emails_are_never_logged(
    client, supabase_configured, firebase_rejects, signing_key, other_key, caplog
):
    caplog.set_level(logging.DEBUG)
    good = sign(signing_key, claims())
    bad = sign(other_key, claims())

    client.get("/api/v1/me/identity", headers=bearer(good))
    client.get("/api/v1/me/identity", headers=bearer(bad))

    assert good not in caplog.text
    assert bad not in caplog.text
    assert "demo-user@example.test" not in caplog.text
    assert "auth deny: supabase_signature_invalid" in caplog.text
