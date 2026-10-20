"""
Supabase access-token verification for the NEMRAS backend.

Like ``auth``, this module answers *authentication* only: it establishes that a
caller holds a valid Supabase session and returns the user's UUID. It grants no
access to any patient record, and it does not bind a Supabase user to a CNIC.

Only asymmetric signing keys are accepted. Public keys are fetched from the
project's JWKS endpoint, so the backend holds no Supabase secret. Tokens signed
with the legacy shared HS256 secret are rejected, as are anon, service-role and
anonymous-sign-in tokens.

``SUPABASE_URL`` is the only setting, and it is not a secret. When it is unset,
Supabase verification is disabled and nothing here runs.

Tokens, claims and e-mail addresses are never logged. Failures carry a short
reason code that the caller logs instead.
"""

from __future__ import annotations

from dataclasses import dataclass
import os
import threading
from typing import Callable, Dict, Final, Optional
from urllib.parse import urlsplit
import uuid

import jwt


SUPABASE_URL_ENV: Final = "SUPABASE_URL"
ALLOWED_ALGORITHMS: Final = ("ES256", "RS256")
AUDIENCE: Final = "authenticated"
REQUIRED_ROLE: Final = "authenticated"
LEEWAY_SECONDS: Final = 10
JWKS_TIMEOUT_SECONDS: Final = 5
JWKS_CACHE_SECONDS: Final = 600
_LOCAL_HOSTS: Final = frozenset({"localhost", "127.0.0.1"})


class SupabaseAuthError(Exception):
    """Base class. ``reason_code`` is safe to log; the message carries no token."""

    def __init__(self, reason_code: str) -> None:
        super().__init__(reason_code)
        self.reason_code = reason_code


class SupabaseTokenInvalid(SupabaseAuthError):
    """The token is malformed, unsigned, expired or not for this project -> 401."""


class SupabaseUnavailable(SupabaseAuthError):
    """The server cannot verify Supabase tokens right now -> 503, never a bypass."""


@dataclass(frozen=True)
class SupabaseIdentity:
    """A Supabase user whose access token verified successfully."""

    user_id: str


SigningKeyResolver = Callable[[str], object]


def configured_project_url() -> Optional[str]:
    """
    Return the normalised project URL, or None when Supabase is not configured.

    The URL must be https, or http on localhost for the Supabase CLI. A set but
    unusable value raises SupabaseUnavailable so misconfiguration fails closed.
    """
    raw = os.environ.get(SUPABASE_URL_ENV, "").strip()
    if not raw:
        return None
    parts = urlsplit(raw)
    secure = parts.scheme == "https"
    local = parts.scheme == "http" and parts.hostname in _LOCAL_HOSTS
    if (
        not (secure or local)
        or not parts.hostname
        or parts.path not in ("", "/")
        or parts.query
        or parts.fragment
        or parts.username
        or parts.password
    ):
        raise SupabaseUnavailable("supabase_url_invalid")
    return f"{parts.scheme}://{parts.netloc}"


def expected_issuer(project_url: str) -> str:
    return f"{project_url}/auth/v1"


def jwks_url(project_url: str) -> str:
    return f"{project_url}/auth/v1/.well-known/jwks.json"


def is_supabase_token(token: str, project_url: str) -> bool:
    """
    Report whether an *unverified* token names this project as its issuer.

    Used only to choose a verifier. The chosen verifier then checks the token
    in full, so a forged issuer gains nothing.
    """
    try:
        claims = jwt.decode(token, options={"verify_signature": False})
    except jwt.PyJWTError:
        return False
    return isinstance(claims, dict) and claims.get("iss") == expected_issuer(
        project_url
    )


_resolvers: Dict[str, SigningKeyResolver] = {}
_resolvers_lock = threading.Lock()


def _jwks_resolver(project_url: str) -> SigningKeyResolver:
    """One cached JWKS client per project URL."""
    with _resolvers_lock:
        resolver = _resolvers.get(project_url)
        if resolver is not None:
            return resolver

        client = jwt.PyJWKClient(
            jwks_url(project_url),
            cache_keys=True,
            cache_jwk_set=True,
            lifespan=JWKS_CACHE_SECONDS,
            timeout=JWKS_TIMEOUT_SECONDS,
        )

        def _resolve(token: str) -> object:
            try:
                return client.get_signing_key_from_jwt(token).key
            except jwt.PyJWKClientConnectionError as exc:
                raise SupabaseUnavailable("jwks_unreachable") from exc
            except jwt.PyJWKClientError as exc:
                # Includes "no key matches this kid", which a rotated-out or
                # foreign key produces.
                raise SupabaseTokenInvalid("signing_key_not_found") from exc
            except jwt.PyJWTError as exc:
                raise SupabaseTokenInvalid("token_malformed") from exc

        _resolvers[project_url] = _resolve
        return _resolve


def reset_key_cache() -> None:
    """Drop cached JWKS clients. Used by tests; not called in production."""
    with _resolvers_lock:
        _resolvers.clear()


def verify_access_token(
    token: str,
    project_url: str,
    *,
    key_resolver: Optional[SigningKeyResolver] = None,
) -> SupabaseIdentity:
    """
    Verify a Supabase access token and return the signed-in user's UUID.

    Checks, in order: header algorithm and key id, signature against the
    project's published key, expiry, issuer, audience, then the role,
    anonymous-user and subject claims.
    """
    try:
        header = jwt.get_unverified_header(token)
    except jwt.PyJWTError as exc:
        raise SupabaseTokenInvalid("token_malformed") from exc
    if header.get("alg") not in ALLOWED_ALGORITHMS:
        raise SupabaseTokenInvalid("algorithm_not_allowed")
    if not header.get("kid"):
        raise SupabaseTokenInvalid("missing_key_id")

    resolver = key_resolver or _jwks_resolver(project_url)
    key = resolver(token)

    try:
        claims = jwt.decode(
            token,
            key=key,
            algorithms=list(ALLOWED_ALGORITHMS),
            audience=AUDIENCE,
            issuer=expected_issuer(project_url),
            leeway=LEEWAY_SECONDS,
            options={"require": ["exp", "iat", "iss", "aud", "sub"]},
        )
    except jwt.ExpiredSignatureError as exc:
        raise SupabaseTokenInvalid("token_expired") from exc
    except jwt.InvalidAudienceError as exc:
        raise SupabaseTokenInvalid("audience_mismatch") from exc
    except jwt.InvalidIssuerError as exc:
        raise SupabaseTokenInvalid("issuer_mismatch") from exc
    except jwt.InvalidSignatureError as exc:
        raise SupabaseTokenInvalid("signature_invalid") from exc
    except jwt.PyJWTError as exc:
        raise SupabaseTokenInvalid("token_invalid") from exc

    if claims.get("role") != REQUIRED_ROLE:
        raise SupabaseTokenInvalid("role_not_authenticated")
    if claims.get("is_anonymous") is True:
        raise SupabaseTokenInvalid("anonymous_user")

    subject = claims.get("sub")
    try:
        user_id = uuid.UUID(subject) if isinstance(subject, str) else None
    except ValueError:
        user_id = None
    if user_id is None:
        raise SupabaseTokenInvalid("missing_subject")
    return SupabaseIdentity(user_id=str(user_id))
