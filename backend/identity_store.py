"""Persistent Firebase UID -> CNIC identity bindings.

This module is storage infrastructure only. It does not authenticate callers,
bind accounts through an API, or expose patient records.

The database location and HMAC key must be supplied explicitly through the
environment. Identifiers, secrets, SQL parameters, and credentials are never
logged.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
import hashlib
import hmac
import os
from pathlib import Path
import sqlite3
from typing import Final


IDENTITY_DB_PATH_ENV: Final = "NEMRAS_IDENTITY_DB_PATH"
HMAC_KEY_ENV: Final = "NEMRAS_HMAC_KEY"
MIN_HMAC_KEY_BYTES: Final = 32
BUSY_TIMEOUT_MS: Final = 5_000


class IdentityStoreError(Exception):
    """Base class for failures safe to surface without identifiers."""


class StoreConfigurationError(IdentityStoreError):
    """Required environment or path configuration is absent or invalid."""


class StoreUnavailableError(IdentityStoreError):
    """SQLite could not initialize or complete an operation."""


class DuplicateUidError(IdentityStoreError):
    """The Firebase UID already has a binding."""


class DuplicateCnicError(IdentityStoreError):
    """The CNIC already has a binding."""


class BindingNotFoundError(IdentityStoreError):
    """No binding exists for the requested verified UID."""


class InvalidHmacKeyError(IdentityStoreError):
    """The pseudonymization key is missing or too weak."""


@dataclass(frozen=True)
class BindingMetadata:
    """Binding metadata only; this is not a patient record."""

    uid: str
    cnic: str
    created_at: str
    updated_at: str


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="microseconds").replace(
        "+00:00", "Z"
    )


def configured_database_path() -> Path:
    """Return the explicitly configured absolute database path."""
    raw_path = os.environ.get(IDENTITY_DB_PATH_ENV, "").strip()
    if not raw_path:
        raise StoreConfigurationError("Identity database path is not configured.")

    path = Path(raw_path).expanduser()
    if not path.is_absolute():
        raise StoreConfigurationError(
            "Identity database path must be an absolute path."
        )
    if path.exists() and path.is_dir():
        raise StoreConfigurationError(
            "Identity database path must identify a file."
        )
    return path


def _hmac_key(explicit_key: str | bytes | None = None) -> bytes:
    value = explicit_key
    if value is None:
        value = os.environ.get(HMAC_KEY_ENV)

    if isinstance(value, str):
        key = value.encode("utf-8")
    elif isinstance(value, bytes):
        key = value
    else:
        raise InvalidHmacKeyError("HMAC key is not configured.")

    if len(key) < MIN_HMAC_KEY_BYTES:
        raise InvalidHmacKeyError("HMAC key does not meet the minimum strength.")
    return key


def pseudonymous_reference(
    identifier: str,
    *,
    purpose: str,
    key: str | bytes | None = None,
) -> str:
    """Return a deterministic, domain-separated HMAC-SHA-256 reference.

    ``purpose`` separates future audit-subject and phone-reference namespaces,
    so the same identifier does not receive the same reference in both uses.
    """
    if not isinstance(identifier, str) or not identifier:
        raise ValueError("Identifier must be a non-empty string.")
    if not isinstance(purpose, str) or not purpose:
        raise ValueError("HMAC purpose must be a non-empty string.")

    secret = _hmac_key(key)
    message = f"nemras:{purpose}:{identifier}".encode("utf-8")
    return hmac.new(secret, message, hashlib.sha256).hexdigest()


class IdentityStore:
    """Small SQLite API for one-to-one Firebase UID <-> CNIC bindings."""

    def __init__(self, database_path: Path | str | None = None) -> None:
        if database_path is None:
            self._path = configured_database_path()
        else:
            path = Path(database_path).expanduser()
            if not path.is_absolute():
                raise StoreConfigurationError(
                    "Identity database path must be an absolute path."
                )
            if path.exists() and path.is_dir():
                raise StoreConfigurationError(
                    "Identity database path must identify a file."
                )
            self._path = path

    @classmethod
    def from_environment(cls) -> "IdentityStore":
        return cls(configured_database_path())

    def _connect(self) -> sqlite3.Connection:
        try:
            connection = sqlite3.connect(
                self._path,
                timeout=BUSY_TIMEOUT_MS / 1000,
                isolation_level=None,
            )
            connection.row_factory = sqlite3.Row
            connection.execute("PRAGMA foreign_keys = ON")
            connection.execute(f"PRAGMA busy_timeout = {BUSY_TIMEOUT_MS}")
            return connection
        except (OSError, sqlite3.Error) as exc:
            raise StoreUnavailableError(
                "Identity database is unavailable."
            ) from exc

    def initialize_schema(self, *, create_parent: bool = False) -> None:
        """Initialize the schema, optionally creating the configured directory."""
        parent = self._path.parent
        if not parent.exists():
            if not create_parent:
                raise StoreConfigurationError(
                    "Identity database directory does not exist."
                )
            try:
                parent.mkdir(parents=True, exist_ok=True)
            except OSError as exc:
                raise StoreUnavailableError(
                    "Identity database directory could not be created."
                ) from exc

        connection: sqlite3.Connection | None = None
        try:
            connection = self._connect()
            # journal_mode cannot be changed while a transaction is active.
            connection.execute("PRAGMA journal_mode = WAL")
            connection.execute("BEGIN IMMEDIATE")
            connection.execute(
                """
                CREATE TABLE IF NOT EXISTS identity_binding (
                    uid TEXT NOT NULL PRIMARY KEY,
                    cnic TEXT NOT NULL UNIQUE,
                    created_at TEXT NOT NULL,
                    updated_at TEXT NOT NULL
                )
                """
            )
            connection.execute("COMMIT")
        except StoreUnavailableError:
            raise
        except (OSError, sqlite3.Error) as exc:
            if connection is not None and connection.in_transaction:
                connection.execute("ROLLBACK")
            raise StoreUnavailableError(
                "Identity database schema could not be initialized."
            ) from exc
        finally:
            if connection is not None:
                connection.close()

    def is_uid_bound(self, uid: str) -> bool:
        return self._exists("uid", uid)

    def is_cnic_bound(self, cnic: str) -> bool:
        return self._exists("cnic", cnic)

    def _exists(self, column: str, value: str) -> bool:
        # Keep both SQL statements static. Only values are ever supplied at
        # runtime, and every value is a bound parameter.
        if column == "uid":
            query = "SELECT 1 FROM identity_binding WHERE uid = ? LIMIT 1"
        elif column == "cnic":
            query = "SELECT 1 FROM identity_binding WHERE cnic = ? LIMIT 1"
        else:
            raise ValueError("Unsupported identity lookup.")
        try:
            with self._connect() as connection:
                row = connection.execute(query, (value,)).fetchone()
            return row is not None
        except StoreUnavailableError:
            raise
        except sqlite3.Error as exc:
            raise StoreUnavailableError(
                "Identity database lookup failed."
            ) from exc

    def create_binding(self, uid: str, cnic: str) -> BindingMetadata:
        """Atomically create a one-to-one binding."""
        if not isinstance(uid, str) or not uid.strip():
            raise ValueError("UID must be a non-empty string.")
        if not isinstance(cnic, str) or not cnic.strip():
            raise ValueError("CNIC must be a non-empty string.")

        timestamp = _utc_now()
        connection: sqlite3.Connection | None = None
        try:
            connection = self._connect()
            connection.execute("BEGIN IMMEDIATE")
            connection.execute(
                """
                INSERT INTO identity_binding (uid, cnic, created_at, updated_at)
                VALUES (?, ?, ?, ?)
                """,
                (uid, cnic, timestamp, timestamp),
            )
            connection.execute("COMMIT")
        except sqlite3.IntegrityError as exc:
            if connection is not None and connection.in_transaction:
                connection.execute("ROLLBACK")
            # Determine the conflicting side without parsing SQLite's message,
            # which can vary between SQLite versions.
            if self.is_uid_bound(uid):
                raise DuplicateUidError("Firebase UID is already bound.") from exc
            if self.is_cnic_bound(cnic):
                raise DuplicateCnicError("CNIC is already bound.") from exc
            raise StoreUnavailableError("Identity binding could not be created.") from exc
        except StoreUnavailableError:
            if connection is not None and connection.in_transaction:
                connection.execute("ROLLBACK")
            raise
        except sqlite3.Error as exc:
            if connection is not None and connection.in_transaction:
                connection.execute("ROLLBACK")
            raise StoreUnavailableError("Identity binding could not be created.") from exc
        finally:
            if connection is not None:
                connection.close()

        return BindingMetadata(
            uid=uid,
            cnic=cnic,
            created_at=timestamp,
            updated_at=timestamp,
        )

    def get_binding_by_uid(self, uid: str) -> BindingMetadata:
        try:
            with self._connect() as connection:
                row = connection.execute(
                    """
                    SELECT uid, cnic, created_at, updated_at
                    FROM identity_binding
                    WHERE uid = ?
                    """,
                    (uid,),
                ).fetchone()
        except StoreUnavailableError:
            raise
        except sqlite3.Error as exc:
            raise StoreUnavailableError(
                "Identity database lookup failed."
            ) from exc

        if row is None:
            raise BindingNotFoundError("Identity binding was not found.")
        return BindingMetadata(
            uid=row["uid"],
            cnic=row["cnic"],
            created_at=row["created_at"],
            updated_at=row["updated_at"],
        )
