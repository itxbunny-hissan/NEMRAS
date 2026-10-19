"""NEMRAS Patient ID generator and local registry.

A NEMRAS Patient ID locates a record slot. It does not authenticate a person,
and it does not grant access to a medical record. Access still requires a
separate authenticated, authorized caller.

The revised proposal (section 5.1) gives the shape as an example and marks the
identifier design PROPOSED, not supervisor-approved: a random non-sequential
number with one check digit, illustrated as 12 digits plus a check digit,
shown in groups. This module follows that example. Luhn is the check-digit
algorithm selected for this implementation because the proposal asks for one
numeric check digit and does not name an algorithm.

Canonical storage format
    Thirteen ASCII digits, no separators, leading zeros preserved.
    Characters 1-12 are the random body. Character 13 is the Luhn check digit.
    Example: ``0000000000018``

Display format
    The body in groups of four digits, then the check digit.
    Example: ``0000 0000 0001 8``
    Display text is not accepted as a registry key.

The registry primary key is the canonical ID. ``active`` and ``retired`` are
the only statuses. A retired ID stays in the table and is never issued again.

``PatientIdStore`` is the storage protocol for those three operations.
``PatientIdRegistry`` is the SQLite implementation and remains the default
store. ``PostgresPatientIdRegistry`` is used only when
``NEMRAS_PATIENT_ID_BACKEND`` is ``postgresql``. Importing this module does
not connect to PostgreSQL, and the application does not create the PostgreSQL
table. Cryptographic generation and Luhn validation stay in this module, not
in the database. ``backend/sql/oracle11g/001_nemras_id_registry.sql`` is an
unapplied Oracle 11g script. This module does not connect to Oracle.

This module does not read a patient dataset and does not derive an ID from a
national identifier, name, phone number, date of birth, or any other patient
attribute.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
import os
from pathlib import Path
import secrets
import sqlite3
from typing import Final, Protocol, runtime_checkable


PATIENT_ID_DB_PATH_ENV: Final = "NEMRAS_PATIENT_ID_DB_PATH"
PATIENT_ID_BACKEND_ENV: Final = "NEMRAS_PATIENT_ID_BACKEND"
PATIENT_ID_DATABASE_URL_ENV: Final = "NEMRAS_PATIENT_ID_DATABASE_URL"
POSTGRESQL_REGISTRY_SCRIPT: Final = "sql/postgresql/001_nemras_id_registry.sql"
POSTGRESQL_UNIQUE_VIOLATION: Final = "23505"
POSTGRESQL_UNDEFINED_TABLE: Final = "42P01"
# libpq connect_timeout is in seconds. Psycopg 3 treats values below 2 as 2.
POSTGRESQL_CONNECT_TIMEOUT_SECONDS: Final = 5
# PostgreSQL statement_timeout and lock_timeout are in milliseconds.
POSTGRESQL_STATEMENT_TIMEOUT_MS: Final = 5_000
POSTGRESQL_LOCK_TIMEOUT_MS: Final = 2_000
REGISTRY_FILENAME: Final = "patient_id_registry.sqlite3"
ID_BODY_LENGTH: Final = 12
ID_LENGTH: Final = 13
BODY_SPACE: Final = 10**ID_BODY_LENGTH
STATUS_ACTIVE: Final = "active"
STATUS_RETIRED: Final = "retired"
DEFAULT_ALLOCATION_ATTEMPTS: Final = 8
BUSY_TIMEOUT_MS: Final = 5_000

_STATUSES: Final = frozenset({STATUS_ACTIVE, STATUS_RETIRED})


class PatientIdError(Exception):
    """Base error. Messages stay generic and never include an identifier."""


class PatientIdConfigurationError(PatientIdError):
    """The registry backend or database location is not usable."""


class PatientIdRegistryUnavailableError(PatientIdError):
    """The registry could not initialize or complete an operation."""


class InvalidPatientIdError(PatientIdError):
    """The value is not a canonical 13-digit ID with a valid check digit."""


class PatientIdNotFoundError(PatientIdError):
    """No registry row exists for the requested canonical ID."""


class PatientIdAllocationError(PatientIdError):
    """A unique ID could not be reserved within the attempt limit."""


@dataclass(frozen=True)
class PatientIdRecord:
    """Registry metadata for one ID. This is not a patient record."""

    nemras_id: str
    status: str
    created_at: str

    @property
    def display(self) -> str:
        return format_patient_id(self.nemras_id)


def default_database_path() -> Path:
    """Return the local runtime path. This does not create the file."""
    return Path(__file__).resolve().parent / "runtime" / REGISTRY_FILENAME


def configured_database_path() -> Path:
    """Return the absolute registry path.

    ``NEMRAS_PATIENT_ID_DB_PATH`` overrides the default when it is set. A
    relative override is rejected so the process working directory cannot
    choose where identifiers are written.
    """
    raw_path = os.environ.get(PATIENT_ID_DB_PATH_ENV, "").strip()
    if not raw_path:
        return default_database_path()

    path = Path(raw_path).expanduser()
    if not path.is_absolute():
        raise PatientIdConfigurationError(
            "Patient ID database path must be an absolute path."
        )
    if path.exists() and path.is_dir():
        raise PatientIdConfigurationError(
            "Patient ID database path must identify a file."
        )
    return path


def generate_body() -> str:
    """Return 12 cryptographically random digits, including leading zeros."""
    return f"{secrets.randbelow(BODY_SPACE):0{ID_BODY_LENGTH}d}"


def luhn_check_digit(body: str) -> str:
    """Return the Luhn check digit for a 12-digit body.

    The check digit is appended on the right. Validation therefore doubles
    every second digit of the body, starting with its rightmost digit.
    """
    if not _is_ascii_digits(body, ID_BODY_LENGTH):
        raise InvalidPatientIdError("NEMRAS Patient ID body must be 12 digits.")

    total = 0
    for index, character in enumerate(reversed(body)):
        digit = ord(character) - 48
        if index % 2 == 0:
            digit *= 2
            if digit > 9:
                digit -= 9
        total += digit
    return str((10 - (total % 10)) % 10)


def generate_patient_id() -> str:
    """Return a new canonical 13-digit ID. This does not reserve it."""
    body = generate_body()
    return body + luhn_check_digit(body)


def is_valid_patient_id(value: object) -> bool:
    """Return whether ``value`` is a canonical ID with a valid Luhn digit.

    A true result means only that the check digit matches. It does not mean
    the ID is registered, and it does not authenticate anyone.
    """
    if not _is_ascii_digits(value, ID_LENGTH):
        return False
    return _luhn_valid(value)


def format_patient_id(nemras_id: str) -> str:
    """Format a canonical ID as ``XXXX XXXX XXXX C``.

    ``C`` is the check digit. The returned text is for display. Callers store
    and look up the 13-digit canonical string.
    """
    canonical = require_patient_id(nemras_id)
    body = canonical[:ID_BODY_LENGTH]
    check_digit = canonical[ID_BODY_LENGTH:]
    return f"{body[0:4]} {body[4:8]} {body[8:12]} {check_digit}"


def require_patient_id(value: object) -> str:
    """Return ``value`` when it is a valid canonical ID."""
    if not is_valid_patient_id(value):
        raise InvalidPatientIdError(
            "NEMRAS Patient ID must be 13 digits with a valid Luhn check digit."
        )
    return str(value)


@runtime_checkable
class PatientIdStore(Protocol):
    """Storage operations already supported by the SQLite registry.

    Generation and check-digit validation are not part of this protocol.
    ``register`` reserves an ID that the implementation obtains from
    ``generate_patient_id``. A future database adapter must keep that split:
    Python creates the candidate, and the database only enforces uniqueness
    and permanent reservation.

    The Python status values are ``active`` and ``retired``. The unapplied
    Oracle script stores ``ACTIVE`` and ``RETIRED``. Mapping those spellings
    belongs to a future adapter. This protocol does not connect to Oracle.
    """

    def register(
        self, *, max_attempts: int = DEFAULT_ALLOCATION_ATTEMPTS
    ) -> PatientIdRecord:
        """Reserve a new active ID, retrying when the value is already reserved."""

    def get(self, nemras_id: str) -> PatientIdRecord:
        """Return the registry row for one canonical ID."""

    def retire(self, nemras_id: str) -> PatientIdRecord:
        """Keep the ID reserved and mark it retired."""


class PatientIdRegistry:
    """SQLite registry of issued NEMRAS Patient IDs.

    This class satisfies ``PatientIdStore``. The canonical ID is the primary
    key, so an ``active`` or ``retired`` row permanently occupies that value.
    ``register`` generates an ID itself; callers cannot submit one.
    """

    def __init__(self, database_path: Path | str | None = None) -> None:
        self._path = _database_file(database_path)

    @property
    def database_path(self) -> Path:
        return self._path

    @classmethod
    def create(
        cls, database_path: Path | str | None = None
    ) -> "PatientIdRegistry":
        """Open the registry and create its parent directory and schema."""
        registry = cls(database_path)
        registry.initialize_schema(create_parent=True)
        return registry

    def initialize_schema(self, *, create_parent: bool = False) -> None:
        """Create the table when it is absent. Existing rows are kept."""
        parent = self._path.parent
        if not parent.exists():
            if not create_parent:
                raise PatientIdConfigurationError(
                    "Patient ID database directory does not exist."
                )
            try:
                parent.mkdir(parents=True, exist_ok=True)
            except OSError as exc:
                raise PatientIdRegistryUnavailableError(
                    "Patient ID database directory could not be created."
                ) from exc

        connection: sqlite3.Connection | None = None
        try:
            connection = self._connect()
            connection.execute("PRAGMA journal_mode = WAL")
            connection.execute("BEGIN IMMEDIATE")
            connection.execute(
                """
                CREATE TABLE IF NOT EXISTS patient_id (
                    nemras_id TEXT NOT NULL PRIMARY KEY,
                    status TEXT NOT NULL CHECK (status IN ('active', 'retired')),
                    created_at TEXT NOT NULL
                )
                """
            )
            connection.execute("COMMIT")
        except PatientIdRegistryUnavailableError:
            raise
        except (OSError, sqlite3.Error) as exc:
            if connection is not None and connection.in_transaction:
                connection.execute("ROLLBACK")
            raise PatientIdRegistryUnavailableError(
                "Patient ID registry schema could not be initialized."
            ) from exc
        finally:
            if connection is not None:
                connection.close()

    def register(
        self, *, max_attempts: int = DEFAULT_ALLOCATION_ATTEMPTS
    ) -> PatientIdRecord:
        """Reserve a new active ID, retrying if the value is already reserved."""
        if isinstance(max_attempts, bool) or not isinstance(max_attempts, int):
            raise ValueError("max_attempts must be a positive integer.")
        if max_attempts < 1:
            raise ValueError("max_attempts must be at least 1.")

        for _ in range(max_attempts):
            candidate = generate_patient_id()
            if not is_valid_patient_id(candidate):
                raise InvalidPatientIdError(
                    "Generated NEMRAS Patient ID failed check-digit validation."
                )
            timestamp = _utc_now()
            connection: sqlite3.Connection | None = None
            try:
                connection = self._connect()
                connection.execute("BEGIN IMMEDIATE")
                connection.execute(
                    """
                    INSERT INTO patient_id (nemras_id, status, created_at)
                    VALUES (?, ?, ?)
                    """,
                    (candidate, STATUS_ACTIVE, timestamp),
                )
                connection.execute("COMMIT")
            except sqlite3.IntegrityError:
                if connection is not None and connection.in_transaction:
                    connection.execute("ROLLBACK")
                continue
            except PatientIdRegistryUnavailableError:
                if connection is not None and connection.in_transaction:
                    connection.execute("ROLLBACK")
                raise
            except sqlite3.Error as exc:
                if connection is not None and connection.in_transaction:
                    connection.execute("ROLLBACK")
                raise PatientIdRegistryUnavailableError(
                    "NEMRAS Patient ID could not be reserved."
                ) from exc
            finally:
                if connection is not None:
                    connection.close()
            return PatientIdRecord(
                nemras_id=candidate,
                status=STATUS_ACTIVE,
                created_at=timestamp,
            )

        raise PatientIdAllocationError("A NEMRAS Patient ID could not be allocated.")

    def get(self, nemras_id: str) -> PatientIdRecord:
        """Look up one canonical ID. Display text is rejected."""
        canonical = require_patient_id(nemras_id)
        connection: sqlite3.Connection | None = None
        try:
            connection = self._connect()
            row = connection.execute(
                """
                SELECT nemras_id, status, created_at
                FROM patient_id
                WHERE nemras_id = ?
                """,
                (canonical,),
            ).fetchone()
        except PatientIdRegistryUnavailableError:
            raise
        except sqlite3.Error as exc:
            raise PatientIdRegistryUnavailableError(
                "Patient ID registry lookup failed."
            ) from exc
        finally:
            if connection is not None:
                connection.close()
        if row is None:
            raise PatientIdNotFoundError("NEMRAS Patient ID was not found.")
        return _record_from_row(row)

    def retire(self, nemras_id: str) -> PatientIdRecord:
        """Mark an ID retired and keep it reserved.

        Retiring an ID that is already retired does not change its creation
        timestamp and does not free the value.
        """
        canonical = require_patient_id(nemras_id)
        connection: sqlite3.Connection | None = None
        try:
            connection = self._connect()
            connection.execute("BEGIN IMMEDIATE")
            row = connection.execute(
                """
                SELECT nemras_id, status, created_at
                FROM patient_id
                WHERE nemras_id = ?
                """,
                (canonical,),
            ).fetchone()
            if row is None:
                connection.execute("ROLLBACK")
                raise PatientIdNotFoundError("NEMRAS Patient ID was not found.")
            if row["status"] != STATUS_RETIRED:
                cursor = connection.execute(
                    """
                    UPDATE patient_id
                    SET status = ?
                    WHERE nemras_id = ? AND status = ?
                    """,
                    (STATUS_RETIRED, canonical, STATUS_ACTIVE),
                )
                if cursor.rowcount != 1:
                    connection.execute("ROLLBACK")
                    raise PatientIdRegistryUnavailableError(
                        "NEMRAS Patient ID could not be retired."
                    )
            connection.execute("COMMIT")
            return PatientIdRecord(
                nemras_id=row["nemras_id"],
                status=STATUS_RETIRED,
                created_at=row["created_at"],
            )
        except PatientIdError:
            if connection is not None and connection.in_transaction:
                connection.execute("ROLLBACK")
            raise
        except sqlite3.Error as exc:
            if connection is not None and connection.in_transaction:
                connection.execute("ROLLBACK")
            raise PatientIdRegistryUnavailableError(
                "NEMRAS Patient ID could not be retired."
            ) from exc
        finally:
            if connection is not None:
                connection.close()

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
            raise PatientIdRegistryUnavailableError(
                "Patient ID registry is unavailable."
            ) from exc


def _database_file(database_path: Path | str | None) -> Path:
    if database_path is None:
        return configured_database_path()
    path = Path(database_path).expanduser()
    if not path.is_absolute():
        raise PatientIdConfigurationError(
            "Patient ID database path must be an absolute path."
        )
    if path.exists() and path.is_dir():
        raise PatientIdConfigurationError(
            "Patient ID database path must identify a file."
        )
    return path


def _is_ascii_digits(value: object, length: int) -> bool:
    return (
        isinstance(value, str)
        and len(value) == length
        and value.isascii()
        and value.isdigit()
    )


def _luhn_valid(number: str) -> bool:
    total = 0
    for index, character in enumerate(reversed(number)):
        digit = ord(character) - 48
        if index % 2 == 1:
            digit *= 2
            if digit > 9:
                digit -= 9
        total += digit
    return total % 10 == 0


def _record_from_row(row: sqlite3.Row) -> PatientIdRecord:
    status = row["status"]
    if status not in _STATUSES:
        raise PatientIdRegistryUnavailableError(
            "Patient ID registry contains an unsupported status."
        )
    return PatientIdRecord(
        nemras_id=row["nemras_id"],
        status=status,
        created_at=row["created_at"],
    )


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="microseconds").replace(
        "+00:00", "Z"
    )


def open_patient_id_registry() -> PatientIdStore:
    """Return the one registry selected for this process.

    Unset ``NEMRAS_PATIENT_ID_BACKEND``, or the value ``sqlite``, selects
    SQLite. ``postgresql`` requires ``NEMRAS_PATIENT_ID_DATABASE_URL`` and
    does not fall back to SQLite. This function does not open a connection.
    """
    backend = os.environ.get(PATIENT_ID_BACKEND_ENV, "sqlite").strip().casefold()
    if backend in ("", "sqlite"):
        return PatientIdRegistry()
    if backend == "postgresql":
        database_url = os.environ.get(PATIENT_ID_DATABASE_URL_ENV, "").strip()
        if not database_url:
            raise PatientIdConfigurationError(
                "Set NEMRAS_PATIENT_ID_DATABASE_URL when "
                "NEMRAS_PATIENT_ID_BACKEND is postgresql. "
                "SQLite is not used as a fallback."
            )
        return PostgresPatientIdRegistry(database_url)
    raise PatientIdConfigurationError(
        "NEMRAS_PATIENT_ID_BACKEND must be sqlite or postgresql."
    )


class PostgresPatientIdRegistry:
    """PostgreSQL registry of issued NEMRAS Patient IDs.

    This class satisfies ``PatientIdStore``. Python generates every ID.
    The table ``nemras_id_registry`` must already exist. Applying
    ``sql/postgresql/001_nemras_id_registry.sql`` is a separate, manual step.

    Each connection uses a finite libpq ``connect_timeout`` and session
    ``statement_timeout`` and ``lock_timeout`` values. Those limits stop a
    stalled connect, query, or row lock from waiting forever. They do not
    guarantee recovery from every network or operating-system failure: a
    process blocked in uninterruptible I/O, or a failure after the server
    has finished the statement but before the client reads the result, can
    still outlive the timeout.
    """

    def __init__(self, database_url: str, *, connect=None) -> None:
        if not isinstance(database_url, str) or not database_url.strip():
            raise PatientIdConfigurationError(
                "Set NEMRAS_PATIENT_ID_DATABASE_URL when "
                "NEMRAS_PATIENT_ID_BACKEND is postgresql. "
                "SQLite is not used as a fallback."
            )
        self._database_url = database_url.strip()
        self._connect = connect

    def register(
        self, *, max_attempts: int = DEFAULT_ALLOCATION_ATTEMPTS
    ) -> PatientIdRecord:
        """Reserve a new active ID, retrying only a unique-value collision."""
        _require_attempts(max_attempts)
        for _ in range(max_attempts):
            candidate = generate_patient_id()
            if not is_valid_patient_id(candidate):
                raise InvalidPatientIdError(
                    "Generated NEMRAS Patient ID failed check-digit validation."
                )
            timestamp = _utc_now()
            connection = None
            collision = False
            failure: PatientIdError | None = None
            try:
                connection = self._open()
                with connection.transaction():
                    connection.execute(
                        """
                        INSERT INTO nemras_id_registry (
                            nemras_id, status, created_at
                        )
                        VALUES (%s, %s, %s)
                        """,
                        (candidate, STATUS_ACTIVE, timestamp),
                    )
            except Exception as exc:
                if _sqlstate(exc) == POSTGRESQL_UNIQUE_VIOLATION:
                    collision = True
                else:
                    failure = _driver_failure(
                        exc, "NEMRAS Patient ID could not be reserved."
                    )
            finally:
                _close_quietly(connection)
            if collision:
                continue
            if failure is not None:
                raise failure
            return PatientIdRecord(
                nemras_id=candidate,
                status=STATUS_ACTIVE,
                created_at=timestamp,
            )
        raise PatientIdAllocationError("A NEMRAS Patient ID could not be allocated.")

    def get(self, nemras_id: str) -> PatientIdRecord:
        """Look up one canonical ID. Display text is rejected."""
        canonical = require_patient_id(nemras_id)
        connection = None
        failure: PatientIdError | None = None
        row = None
        try:
            connection = self._open()
            with connection.transaction():
                row = connection.execute(
                    """
                    SELECT nemras_id, status, created_at
                    FROM nemras_id_registry
                    WHERE nemras_id = %s
                    """,
                    (canonical,),
                ).fetchone()
        except Exception as exc:
            failure = _driver_failure(exc, "Patient ID registry lookup failed.")
        finally:
            _close_quietly(connection)
        if failure is not None:
            raise failure
        if row is None:
            raise PatientIdNotFoundError("NEMRAS Patient ID was not found.")
        return _record_from_postgres_row(row)

    def retire(self, nemras_id: str) -> PatientIdRecord:
        """Mark an ID retired and keep it reserved.

        Retiring an ID that is already retired does not change its creation
        timestamp and does not free the value.
        """
        canonical = require_patient_id(nemras_id)
        connection = None
        failure: PatientIdError | None = None
        record: PatientIdRecord | None = None
        try:
            connection = self._open()
            with connection.transaction():
                row = connection.execute(
                    """
                    SELECT nemras_id, status, created_at
                    FROM nemras_id_registry
                    WHERE nemras_id = %s
                    FOR UPDATE
                    """,
                    (canonical,),
                ).fetchone()
                if row is None:
                    raise PatientIdNotFoundError("NEMRAS Patient ID was not found.")
                record = _record_from_postgres_row(row)
                if record.status != STATUS_RETIRED:
                    cursor = connection.execute(
                        """
                        UPDATE nemras_id_registry
                        SET status = %s
                        WHERE nemras_id = %s AND status = %s
                        """,
                        (STATUS_RETIRED, canonical, STATUS_ACTIVE),
                    )
                    if cursor.rowcount != 1:
                        raise PatientIdRegistryUnavailableError(
                            "NEMRAS Patient ID could not be retired."
                        )
                    record = PatientIdRecord(
                        nemras_id=record.nemras_id,
                        status=STATUS_RETIRED,
                        created_at=record.created_at,
                    )
        except Exception as exc:
            failure = _driver_failure(
                exc, "NEMRAS Patient ID could not be retired."
            )
        finally:
            _close_quietly(connection)
        if failure is not None:
            raise failure
        if record is None:
            raise PatientIdRegistryUnavailableError(
                "NEMRAS Patient ID could not be retired."
            )
        return record

    def _open(self):
        if self._connect is not None:
            connection = self._connect(
                self._database_url,
                connect_timeout=POSTGRESQL_CONNECT_TIMEOUT_SECONDS,
            )
        else:
            psycopg = _load_psycopg()
            connection = psycopg.connect(
                self._database_url,
                connect_timeout=POSTGRESQL_CONNECT_TIMEOUT_SECONDS,
            )
        try:
            _apply_postgres_timeouts(connection)
        except Exception:
            _close_quietly(connection)
            raise
        return connection


def _require_attempts(max_attempts: int) -> None:
    if isinstance(max_attempts, bool) or not isinstance(max_attempts, int):
        raise ValueError("max_attempts must be a positive integer.")
    if max_attempts < 1:
        raise ValueError("max_attempts must be at least 1.")


def _load_psycopg():
    """Import Psycopg only when a PostgreSQL operation opens a connection."""
    try:
        import psycopg
    except ImportError as exc:
        raise PatientIdRegistryUnavailableError(
            "Psycopg is not installed in this Python environment."
        ) from exc
    return psycopg


def _apply_postgres_timeouts(connection) -> None:
    """Set session timeouts with bound parameters, then end that transaction.

    ``set_config`` is a normal function, so the values are parameters rather
    than SQL text. ``is_local`` is false, so the settings survive the commit
    and apply to later statements on this short-lived connection. The commit
    leaves the connection idle for the caller's own transaction.
    """
    for name, milliseconds in (
        ("statement_timeout", POSTGRESQL_STATEMENT_TIMEOUT_MS),
        ("lock_timeout", POSTGRESQL_LOCK_TIMEOUT_MS),
    ):
        if isinstance(milliseconds, bool) or not isinstance(milliseconds, int):
            raise PatientIdRegistryUnavailableError(
                "PostgreSQL timeout configuration is invalid."
            )
        if milliseconds < 1:
            raise PatientIdRegistryUnavailableError(
                "PostgreSQL timeout configuration is invalid."
            )
        connection.execute(
            "SELECT set_config(%s, %s, %s)",
            (name, str(milliseconds), False),
        )
    connection.commit()


def _sqlstate(exc: BaseException) -> str | None:
    state = getattr(exc, "sqlstate", None)
    if isinstance(state, str):
        return state
    return None


def _postgres_failure(exc: BaseException, fallback: str) -> PatientIdError:
    if isinstance(exc, PatientIdError):
        return exc
    if _sqlstate(exc) == POSTGRESQL_UNDEFINED_TABLE:
        return PatientIdRegistryUnavailableError(
            "The nemras_id_registry table does not exist. Review "
            f"{POSTGRESQL_REGISTRY_SCRIPT} and apply it manually after "
            "approval. This process does not create the table."
        )
    return PatientIdRegistryUnavailableError(fallback)


class _DriverFailure(Exception):
    """Diagnostic cause with a SQLSTATE and exception type.

    The original driver message is omitted. It can contain a host, database
    name, role, or identifier.
    """

    def __init__(self, error_type: str, sqlstate: str | None) -> None:
        self.sqlstate = sqlstate
        state = sqlstate if sqlstate else "no SQLSTATE"
        super().__init__(f"{error_type} ({state})")


def _driver_failure(exc: BaseException, fallback: str) -> PatientIdError:
    """Return a public registry error for ``exc``.

    A registry error raised by this module is returned unchanged. A driver
    error becomes an actionable public error whose cause keeps only the
    driver type and SQLSTATE. The public error is meant to be raised after
    the ``except`` block, so the driver exception is not chained.
    """
    if isinstance(exc, PatientIdError):
        return exc
    public = _postgres_failure(exc, fallback)
    public.__cause__ = _DriverFailure(type(exc).__name__, _sqlstate(exc))
    return public


def _close_quietly(connection) -> None:
    """Close ``connection`` without changing the operation result.

    A close failure is discarded. Raising it would replace a successful
    reservation, stop a unique-collision retry, or hide the database error
    from the operation. That discarded failure is not logged, because driver
    text can include a host, database name, or role. If ``close`` fails, the
    underlying socket can remain open until garbage collection; it cannot be
    reported without hiding the operation result. ``KeyboardInterrupt`` and
    ``SystemExit`` are not discarded.
    """
    if connection is None:
        return
    try:
        connection.close()
    except Exception:
        return


def _record_from_postgres_row(row) -> PatientIdRecord:
    nemras_id, status, created_at = row
    if status not in _STATUSES:
        raise PatientIdRegistryUnavailableError(
            "Patient ID registry contains an unsupported status."
        )
    return PatientIdRecord(
        nemras_id=str(nemras_id),
        status=status,
        created_at=_created_at_text(created_at),
    )


def _created_at_text(value) -> str:
    if isinstance(value, datetime):
        if value.tzinfo is None:
            value = value.replace(tzinfo=timezone.utc)
        return value.astimezone(timezone.utc).isoformat(
            timespec="microseconds"
        ).replace("+00:00", "Z")
    return str(value)
