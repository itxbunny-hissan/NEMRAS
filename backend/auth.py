"""
Firebase ID-token verification for the NEMRAS backend.

This module answers *authentication* only: it establishes who the caller is as
a verified Firebase UID. It makes no *authorization* decision. Deciding which
patient record a caller may read arrives with the UID -> CNIC binding in a
later increment, so nothing here should be read as granting record access.

Credentials never live in source. The Firebase Admin SDK is initialised from
Application Default Credentials, which honours GOOGLE_APPLICATION_CREDENTIALS
when it points at a service-account JSON file kept outside this repository.

The SDK is imported lazily inside the functions that need it. That keeps the
test suite runnable - and the failure mode explicit - on a machine with no
credentials and no firebase-admin installed, where every protected endpoint
returns 503 rather than silently admitting unauthenticated callers.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Optional
import logging
import os
import threading

from fastapi import Header, HTTPException

import supabase_auth

logger = logging.getLogger("nemras.auth")

# The Firebase project whose ID tokens this backend accepts. Tokens minted by
# any other project are rejected even if they are otherwise well formed.
DEFAULT_PROJECT_ID = "nemras-3230f"

# CallerIdentity.uid for a Supabase user is this prefix plus the user's UUID.
# Firebase UIDs and Supabase UUIDs are different identities and must never
# share a key, so Firebase tokens whose UID uses this prefix are rejected.
SUPABASE_UID_PREFIX = "supabase:"

UNAUTHENTICATED_DETAIL = "Invalid or missing access token."

_app = None
_app_lock = threading.Lock()


def expected_project_id() -> str:
    """Read at call time so tests can point the verifier at another project."""
    return os.environ.get("NEMRAS_FIREBASE_PROJECT_ID", DEFAULT_PROJECT_ID)


@dataclass(frozen=True)
class CallerIdentity:
    """A caller whose Firebase ID token verified successfully."""

    uid: str


class AuthError(Exception):
    """Base class for authentication failures raised inside this module."""


class TokenInvalid(AuthError):
    """The caller's token is missing, malformed or untrustworthy -> 401."""

    def __init__(self, reason_code: str) -> None:
        super().__init__(reason_code)
        self.reason_code = reason_code


class AdminUnavailable(AuthError):
    """The server cannot verify tokens at all -> 503, never a bypass."""


def _firebase_app():
    """Initialise the Admin SDK once, reusing an app if one already exists."""
    global _app
    if _app is not None:
        return _app

    with _app_lock:
        if _app is not None:
            return _app

        try:
            import firebase_admin
            from firebase_admin import credentials
        except ImportError as exc:
            raise AdminUnavailable("firebase_admin_not_installed") from exc

        try:
            _app = firebase_admin.get_app()
        except ValueError:
            try:
                _app = firebase_admin.initialize_app(
                    credentials.ApplicationDefault(),
                    {"projectId": expected_project_id()},
                )
            except Exception as exc:  # noqa: BLE001 - surfaced to the caller as 503
                # Only the exception type is logged: the message can carry the
                # credential path or contents.
                raise AdminUnavailable(type(exc).__name__) from exc
        return _app


def _verify_id_token(token: str) -> dict:
    """
    Verify signature, expiry, issuer, audience and revocation via the Admin SDK.

    `check_revoked=True` costs one user lookup per call but is what makes a
    signed-out or disabled account stop working immediately.
    """
    app = _firebase_app()

    try:
        from firebase_admin import auth as firebase_auth
    except ImportError as exc:
        raise AdminUnavailable("firebase_admin_not_installed") from exc

    try:
        return firebase_auth.verify_id_token(token, app=app, check_revoked=True)
    except firebase_auth.ExpiredIdTokenError as exc:
        raise TokenInvalid("token_expired") from exc
    except firebase_auth.RevokedIdTokenError as exc:
        raise TokenInvalid("token_revoked") from exc
    except firebase_auth.UserDisabledError as exc:
        raise TokenInvalid("user_disabled") from exc
    except firebase_auth.CertificateFetchError as exc:
        # Google's signing certificates were unreachable, so we cannot judge
        # the token either way. Failing closed with 503 beats guessing.
        raise AdminUnavailable("certificate_fetch_failed") from exc
    except (firebase_auth.InvalidIdTokenError, ValueError) as exc:
        raise TokenInvalid("token_invalid") from exc


def _assert_claims(decoded: dict) -> str:
    """
    Re-check the project-scoped claims after the SDK has verified the token.

    The SDK validates `aud` against the project it was initialised with, which
    is derived from ambient credentials. Comparing against the expected project
    again means a misconfigured deployment cannot start accepting another
    project's tokens.
    """
    project = expected_project_id()

    if decoded.get("aud") != project:
        raise TokenInvalid("audience_mismatch")
    if decoded.get("iss") != f"https://securetoken.google.com/{project}":
        raise TokenInvalid("issuer_mismatch")

    uid = decoded.get("uid") or decoded.get("sub")
    if not uid or not isinstance(uid, str):
        raise TokenInvalid("missing_subject")
    if uid.startswith(SUPABASE_UID_PREFIX):
        # Reserved for Supabase identities, so a Firebase UID can never be
        # mistaken for a Supabase user in stores keyed by CallerIdentity.uid.
        raise TokenInvalid("reserved_uid_namespace")
    return uid


def _parse_bearer(header: Optional[str]) -> str:
    if not header:
        raise TokenInvalid("missing_authorization_header")

    parts = header.split()
    if len(parts) != 2 or parts[0].lower() != "bearer" or not parts[1]:
        raise TokenInvalid("malformed_authorization_header")
    return parts[1]


def verify_firebase_token(
    authorization: Optional[str] = Header(default=None),
) -> CallerIdentity:
    """
    FastAPI dependency yielding the verified caller.

    The 401 detail is deliberately identical for every rejection reason; the
    specific reason code goes to the server log only, so the response cannot
    be used to probe which tokens or accounts exist. Raw tokens are never
    logged.
    """
    try:
        token = _parse_bearer(authorization)
        decoded = _verify_id_token(token)
        uid = _assert_claims(decoded)
    except TokenInvalid as exc:
        logger.info("[NEMRAS] auth deny: %s", exc.reason_code)
        raise HTTPException(
            status_code=401,
            detail="Invalid or missing Firebase ID token.",
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc
    except AdminUnavailable as exc:
        logger.error("[NEMRAS] auth unavailable: %s", exc)
        raise HTTPException(
            status_code=503,
            detail="Authentication is not configured on this server.",
        ) from exc

    return CallerIdentity(uid=uid)


def _unauthenticated(reason_code: str) -> HTTPException:
    logger.info("[NEMRAS] auth deny: %s", reason_code)
    return HTTPException(
        status_code=401,
        detail=UNAUTHENTICATED_DETAIL,
        headers={"WWW-Authenticate": "Bearer"},
    )


def verify_caller(
    authorization: Optional[str] = Header(default=None),
) -> CallerIdentity:
    """
    FastAPI dependency accepting a Firebase ID token or a Supabase access token.

    Supabase is considered only when SUPABASE_URL is configured, and only for
    a token whose unverified issuer is that project. The issuer is used to
    choose a verifier and nothing else; the chosen verifier checks the token in
    full. Every other token goes through the Firebase path unchanged.

    A Supabase caller's uid is ``supabase:<uuid>``. Authentication grants no
    access to any patient record.
    """
    try:
        token = _parse_bearer(authorization)
    except TokenInvalid as exc:
        raise _unauthenticated(exc.reason_code) from exc

    try:
        project_url = supabase_auth.configured_project_url()
    except supabase_auth.SupabaseUnavailable as exc:
        logger.error("[NEMRAS] auth unavailable: %s", exc.reason_code)
        raise HTTPException(
            status_code=503,
            detail="Authentication is not configured on this server.",
        ) from exc

    if project_url is not None and supabase_auth.is_supabase_token(
        token, project_url
    ):
        try:
            identity = supabase_auth.verify_access_token(token, project_url)
        except supabase_auth.SupabaseTokenInvalid as exc:
            raise _unauthenticated(f"supabase_{exc.reason_code}") from exc
        except supabase_auth.SupabaseUnavailable as exc:
            logger.error("[NEMRAS] auth unavailable: supabase_%s", exc.reason_code)
            raise HTTPException(
                status_code=503,
                detail="Authentication is temporarily unavailable.",
            ) from exc
        return CallerIdentity(uid=SUPABASE_UID_PREFIX + identity.user_id)

    try:
        decoded = _verify_id_token(token)
        uid = _assert_claims(decoded)
    except TokenInvalid as exc:
        raise _unauthenticated(exc.reason_code) from exc
    except AdminUnavailable as exc:
        logger.error("[NEMRAS] auth unavailable: %s", exc)
        raise HTTPException(
            status_code=503,
            detail="Authentication is not configured on this server.",
        ) from exc
    return CallerIdentity(uid=uid)


def reset_admin_app_cache() -> None:
    """Drop the memoised Admin app. Used by tests; not called in production."""
    global _app
    with _app_lock:
        _app = None
