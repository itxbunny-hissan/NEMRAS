"""Issuance ledger: one NEMRAS Patient ID per verified Firebase UID.

This module records which verified Firebase UID was issued which NEMRAS
Patient ID. It does not bind a UID to a CNIC, does not read a patient record,
and does not grant access to one. An issued ID locates a future record slot
only.

It is deliberately separate from both neighbours:

* ``patient_id`` generates IDs and keeps the registry of reserved values. Its
  schema is not changed here. The ledger reserves IDs only through the
  ``PatientIdStore`` protocol.
* ``identity_store`` holds UID -> CNIC bindings. Its CNIC column is never used
  for Patient IDs.

Concurrency
    ``issue`` holds a ``BEGIN IMMEDIATE`` write lock on the ledger while it
    checks the UID, reserves an ID through the registry, and writes the
    mapping. Concurrent requests for the same UID therefore wait and then
    replay the first issuance instead of reserving a second ID. The ``uid``
    primary key and the ``nemras_id`` unique constraint enforce the same rule
    in the database as a backstop.

Two-store failure
    The registry and the ledger are separate databases, so reserving an ID and
    recording its owner cannot be one atomic transaction. When the registry
    reserves an ID and the ledger does not record it, the ledger connection is
    rolled back and closed, and then:

    * A uniqueness conflict leaves the ID untouched. The value may already
      belong to another UID.
    * A failure raised by ``COMMIT`` leaves the ID untouched. The commit
      outcome is unknown: a fresh read cannot prove that the mapping will not
      become durable, for example when WAL frames reached disk before the
      error was reported and are replayed by the next recovery.
    * A failure before ``COMMIT`` was sent cannot have committed anything. The
      ID is retired only if a fresh read confirms it is absent from the
      ledger. If the read fails, or finds the ID, it is left untouched.

    A retired ID stays reserved and is never issued again. An ID left
    untouched stays ``active`` with no confirmed owner. It grants nothing.
    Every such outcome logs a non-identifying ``event=`` code for manual
    review. No identifier, UID, or database location is logged.

    A process that stops between the registry commit and the ledger commit
    logs nothing and leaves the ID active. Absence from this ledger alone does
    not prove an ID is an orphan, because other issuers may use the same
    registry. Nothing here retires IDs on that basis.

Audit
    Every issuance and every replay appends a row to
    ``patient_id_issuance_audit`` in the same transaction as the decision it
    records. Triggers reject UPDATE and DELETE on both tables, and every
    connection this module opens enables ``recursive_triggers`` so that
    ``INSERT OR REPLACE`` cannot delete a row around them.

    These triggers only constrain SQL sent through ordinary connections. They
    are not tamper protection: a connection with recursive triggers disabled
    can still replace rows, and anyone who can change the schema or the file
    can drop the triggers, edit rows, or replace the database. The audit is
    append-only for this application, not tamper-evident.

Identifiers, tokens, and database locations are never included in error
messages or logs.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
import logging
import os
from pathlib import Path
import sqlite3
from typing import Final

import patient_id


logger = logging.getLogger("nemras.patient_id_issuance")

ISSUANCE_DB_PATH_ENV: Final = "NEMRAS_PATIENT_ID_ISSUANCE_DB_PATH"
ISSUANCE_FILENAME: Final = "patient_id_issuance.sqlite3"
BUSY_TIMEOUT_MS: Final = 5_000
MAX_UID_LENGTH: Final = 128

ACTION_ISSUED: Final = "issued"
ACTION_REPLAYED: Final = "replayed"
ACTION_REPLAY_REJECTED: Final = "replay_rejected"

# Diagnostic event codes for a reserved ID the ledger did not record.
EVENT_RESERVED_ID_RETIRED: Final = "reserved_id_retired"
EVENT_LEDGER_CONFLICT: Final = "reserved_id_ledger_conflict"
EVENT_COMMIT_OUTCOME_UNKNOWN: Final = "commit_outcome_unknown"
EVENT_RESERVED_ID_IN_LEDGER: Final = "reserved_id_found_in_ledger"
EVENT_LEDGER_STATE_UNVERIFIED: Final = "ledger_state_unverified"
EVENT_RETIRE_FAILED: Final = "reserved_id_retire_failed"

LEDGER_PRESENT: Final = "present"
LEDGER_ABSENT: Final = "absent"
LEDGER_UNKNOWN: Final = "unknown"


class IssuanceError(Exception):
    """Base error. Messages stay generic and never include an identifier."""


class IssuanceConfigurationError(IssuanceError):
    """The ledger location or its relation to the registry is not usable."""


class IssuanceUnavailableError(IssuanceError):
    """The ledger could not initialize or complete an operation."""


class IssuedIdInactiveError(IssuanceError):
    """The UID's issued ID is no longer active in the registry."""


@dataclass(frozen=True)
class IssuanceResult:
    """The ID issued to one verified UID. This is not a patient record."""

    nemras_id: str
    status: str
    created_at: str
    issued_at: str
    newly_issued: bool

    @property
    def display(self) -> str:
        return patient_id.format_patient_id(self.nemras_id)


@dataclass(frozen=True)
class AuditEvent:
    uid: str
    action: str
    nemras_id: str
    occurred_at: str


def default_database_path() -> Path:
    """Return the local runtime path. This does not create the file."""
    return Path(__file__).resolve().parent / "runtime" / ISSUANCE_FILENAME


def configured_database_path() -> Path:
    """Return the absolute ledger path.

    ``NEMRAS_PATIENT_ID_ISSUANCE_DB_PATH`` overrides the default when it is
    set. A relative override is rejected.
    """
    raw_path = os.environ.get(ISSUANCE_DB_PATH_ENV, "").strip()
    if not raw_path:
        return default_database_path()
    return _database_file(raw_path)


class PatientIdIssuanceLedger:
    """SQLite ledger of UID -> NEMRAS Patient ID issuance."""

    def __init__(self, database_path: Path | str | None = None) -> None:
        if database_path is None:
            self._path = configured_database_path()
        else:
            self._path = _database_file(database_path)

    @property
    def database_path(self) -> Path:
        return self._path

    @classmethod
    def create(
        cls, database_path: Path | str | None = None
    ) -> "PatientIdIssuanceLedger":
        """Open the ledger and create its parent directory and schema."""
        ledger = cls(database_path)
        ledger.initialize_schema(create_parent=True)
        return ledger

    def initialize_schema(self, *, create_parent: bool = False) -> None:
        """Create the tables and triggers when absent. Existing rows are kept."""
        parent = self._path.parent
        if not parent.exists():
            if not create_parent:
                raise IssuanceConfigurationError(
                    "Issuance database directory does not exist."
                )
            try:
                parent.mkdir(parents=True, exist_ok=True)
            except OSError as exc:
                raise IssuanceUnavailableError(
                    "Issuance database directory could not be created."
                ) from exc

        connection: sqlite3.Connection | None = None
        try:
            connection = self._connect()
            # journal_mode cannot be changed while a transaction is active.
            connection.execute("PRAGMA journal_mode = WAL")
            connection.execute("BEGIN IMMEDIATE")
            for statement in _SCHEMA:
                connection.execute(statement)
            connection.execute("COMMIT")
        except IssuanceUnavailableError:
            raise
        except (OSError, sqlite3.Error) as exc:
            _rollback(connection)
            raise IssuanceUnavailableError(
                "Issuance database schema could not be initialized."
            ) from exc
        finally:
            _close_quietly(connection)

    def issue(
        self, uid: str, registry: patient_id.PatientIdStore
    ) -> IssuanceResult:
        """Return the UID's ID, reserving one through ``registry`` if needed.

        ``uid`` must come from a verified token. The first call reserves an ID
        and records the mapping. Later calls return the same ID and original
        timestamps.
        """
        _require_uid(uid)
        self._reject_shared_file(registry)

        connection: sqlite3.Connection | None = None
        reserved: patient_id.PatientIdRecord | None = None
        commit_sent = False
        try:
            connection = self._connect()
            connection.execute("BEGIN IMMEDIATE")
            row = connection.execute(
                """
                SELECT nemras_id, id_created_at, issued_at
                FROM patient_id_issuance
                WHERE uid = ?
                """,
                (uid,),
            ).fetchone()

            if row is not None:
                return self._replay(connection, uid, row, registry)

            reserved = registry.register()
            issued_at = _utc_now()
            connection.execute(
                """
                INSERT INTO patient_id_issuance (
                    uid, nemras_id, id_created_at, issued_at
                )
                VALUES (?, ?, ?, ?)
                """,
                (uid, reserved.nemras_id, reserved.created_at, issued_at),
            )
            _append_audit(
                connection, uid, ACTION_ISSUED, reserved.nemras_id, issued_at
            )
            commit_sent = True
            connection.execute("COMMIT")
            return IssuanceResult(
                nemras_id=reserved.nemras_id,
                status=reserved.status,
                created_at=reserved.created_at,
                issued_at=issued_at,
                newly_issued=True,
            )
        except Exception as exc:
            # Release the ledger before touching the registry again, and never
            # let a cleanup failure replace the original error.
            _rollback(connection)
            _close_quietly(connection)
            connection = None
            if reserved is not None:
                self._handle_unrecorded_reservation(
                    registry, reserved.nemras_id, exc, commit_sent=commit_sent
                )
            if isinstance(exc, (IssuanceError, patient_id.PatientIdError)):
                raise
            if isinstance(exc, (OSError, sqlite3.Error)):
                raise IssuanceUnavailableError(
                    "NEMRAS Patient ID issuance could not be recorded."
                ) from exc
            raise
        finally:
            _close_quietly(connection)

    def _handle_unrecorded_reservation(
        self,
        registry: patient_id.PatientIdStore,
        nemras_id: str,
        exc: BaseException,
        *,
        commit_sent: bool,
    ) -> None:
        """Decide what to do with an ID the registry reserved but this ledger
        did not confirm recording.

        The ID is retired only when nothing can have been committed and a
        fresh read confirms the ledger does not hold it. Every other outcome
        leaves the ID untouched. This method never raises.
        """
        error = type(exc).__name__
        if isinstance(exc, sqlite3.IntegrityError):
            _diagnostic(logging.ERROR, EVENT_LEDGER_CONFLICT, error)
            return
        if commit_sent:
            state = self._ledger_state(nemras_id)
            _diagnostic(
                logging.ERROR, EVENT_COMMIT_OUTCOME_UNKNOWN, error, ledger_state=state
            )
            return

        state = self._ledger_state(nemras_id)
        if state == LEDGER_PRESENT:
            _diagnostic(logging.ERROR, EVENT_RESERVED_ID_IN_LEDGER, error)
            return
        if state != LEDGER_ABSENT:
            _diagnostic(logging.ERROR, EVENT_LEDGER_STATE_UNVERIFIED, error)
            return
        try:
            registry.retire(nemras_id)
        except Exception as retire_exc:  # noqa: BLE001 - original error is raised
            _diagnostic(
                logging.ERROR,
                EVENT_RETIRE_FAILED,
                error,
                retire_error=type(retire_exc).__name__,
            )
            return
        _diagnostic(logging.WARNING, EVENT_RESERVED_ID_RETIRED, error)

    def _ledger_state(self, nemras_id: str) -> str:
        """Report whether a fresh connection sees ``nemras_id`` in the ledger.

        This reads committed state only. It cannot tell whether an ambiguous
        commit will become durable later, so callers use ``present`` and
        ``absent`` as proof only when no ``COMMIT`` was sent.
        """
        connection: sqlite3.Connection | None = None
        try:
            connection = self._connect()
            row = connection.execute(
                "SELECT 1 FROM patient_id_issuance WHERE nemras_id = ? LIMIT 1",
                (nemras_id,),
            ).fetchone()
        except Exception:  # noqa: BLE001 - reported as unknown, never raised
            return LEDGER_UNKNOWN
        finally:
            _close_quietly(connection)
        return LEDGER_PRESENT if row is not None else LEDGER_ABSENT

    def audit_events(self, uid: str) -> list[AuditEvent]:
        """Return the audit trail for one UID, oldest first."""
        connection: sqlite3.Connection | None = None
        try:
            connection = self._connect()
            rows = connection.execute(
                """
                SELECT uid, action, nemras_id, occurred_at
                FROM patient_id_issuance_audit
                WHERE uid = ?
                ORDER BY event_id
                """,
                (uid,),
            ).fetchall()
        except IssuanceUnavailableError:
            raise
        except sqlite3.Error as exc:
            raise IssuanceUnavailableError(
                "Issuance audit lookup failed."
            ) from exc
        finally:
            _close_quietly(connection)
        return [
            AuditEvent(
                uid=row["uid"],
                action=row["action"],
                nemras_id=row["nemras_id"],
                occurred_at=row["occurred_at"],
            )
            for row in rows
        ]

    def _replay(
        self,
        connection: sqlite3.Connection,
        uid: str,
        row: sqlite3.Row,
        registry: patient_id.PatientIdStore,
    ) -> IssuanceResult:
        nemras_id = row["nemras_id"]
        occurred_at = _utc_now()
        try:
            current = registry.get(nemras_id)
        except patient_id.PatientIdNotFoundError:
            current = None

        if current is None or current.status != patient_id.STATUS_ACTIVE:
            _append_audit(
                connection, uid, ACTION_REPLAY_REJECTED, nemras_id, occurred_at
            )
            connection.execute("COMMIT")
            raise IssuedIdInactiveError("The issued NEMRAS Patient ID is not active.")

        _append_audit(connection, uid, ACTION_REPLAYED, nemras_id, occurred_at)
        connection.execute("COMMIT")
        return IssuanceResult(
            nemras_id=nemras_id,
            status=current.status,
            created_at=row["id_created_at"],
            issued_at=row["issued_at"],
            newly_issued=False,
        )

    def _reject_shared_file(self, registry: patient_id.PatientIdStore) -> None:
        # The ledger lock is held while the registry opens its own write
        # transaction. On the same SQLite file that would wait on itself.
        registry_path = getattr(registry, "database_path", None)
        if registry_path is None:
            return
        if Path(registry_path).resolve() == self._path.resolve():
            raise IssuanceConfigurationError(
                "Issuance ledger and Patient ID registry must use separate files."
            )

    def _connect(self) -> sqlite3.Connection:
        connection: sqlite3.Connection | None = None
        try:
            connection = sqlite3.connect(
                self._path,
                timeout=BUSY_TIMEOUT_MS / 1000,
                isolation_level=None,
            )
            connection.row_factory = sqlite3.Row
            connection.execute("PRAGMA foreign_keys = ON")
            # Without this, the REPLACE conflict strategy deletes rows without
            # firing the append-only DELETE triggers.
            connection.execute("PRAGMA recursive_triggers = ON")
            connection.execute(f"PRAGMA busy_timeout = {BUSY_TIMEOUT_MS}")
            return connection
        except (OSError, sqlite3.Error) as exc:
            _close_quietly(connection)
            raise IssuanceUnavailableError(
                "Issuance database is unavailable."
            ) from exc


_SCHEMA: Final = (
    """
    CREATE TABLE IF NOT EXISTS patient_id_issuance (
        uid TEXT NOT NULL PRIMARY KEY,
        nemras_id TEXT NOT NULL UNIQUE CHECK (length(nemras_id) = 13),
        id_created_at TEXT NOT NULL,
        issued_at TEXT NOT NULL
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS patient_id_issuance_audit (
        event_id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT NOT NULL,
        action TEXT NOT NULL
            CHECK (action IN ('issued', 'replayed', 'replay_rejected')),
        nemras_id TEXT NOT NULL,
        occurred_at TEXT NOT NULL
    )
    """,
    """
    CREATE TRIGGER IF NOT EXISTS patient_id_issuance_no_update
    BEFORE UPDATE ON patient_id_issuance
    BEGIN
        SELECT RAISE(ABORT, 'patient_id_issuance is append-only');
    END
    """,
    """
    CREATE TRIGGER IF NOT EXISTS patient_id_issuance_no_delete
    BEFORE DELETE ON patient_id_issuance
    BEGIN
        SELECT RAISE(ABORT, 'patient_id_issuance is append-only');
    END
    """,
    """
    CREATE TRIGGER IF NOT EXISTS patient_id_issuance_audit_no_update
    BEFORE UPDATE ON patient_id_issuance_audit
    BEGIN
        SELECT RAISE(ABORT, 'patient_id_issuance_audit is append-only');
    END
    """,
    """
    CREATE TRIGGER IF NOT EXISTS patient_id_issuance_audit_no_delete
    BEFORE DELETE ON patient_id_issuance_audit
    BEGIN
        SELECT RAISE(ABORT, 'patient_id_issuance_audit is append-only');
    END
    """,
)


def _append_audit(
    connection: sqlite3.Connection,
    uid: str,
    action: str,
    nemras_id: str,
    occurred_at: str,
) -> None:
    connection.execute(
        """
        INSERT INTO patient_id_issuance_audit (
            uid, action, nemras_id, occurred_at
        )
        VALUES (?, ?, ?, ?)
        """,
        (uid, action, nemras_id, occurred_at),
    )


def _diagnostic(
    level: int,
    event: str,
    error: str,
    *,
    ledger_state: str = "not_checked",
    retire_error: str = "none",
) -> None:
    """Log a reserved-ID outcome using codes and exception type names only."""
    logger.log(
        level,
        "[NEMRAS] patient-id issuance: event=%s error=%s ledger_state=%s "
        "retire_error=%s. Review manually; do not retire an ID based only on "
        "its absence from this ledger.",
        event,
        error,
        ledger_state,
        retire_error,
    )


def _rollback(connection: sqlite3.Connection | None) -> None:
    if connection is None:
        return
    try:
        if connection.in_transaction:
            connection.execute("ROLLBACK")
    except Exception:  # noqa: BLE001 - must not replace the original error
        return


def _close_quietly(connection: sqlite3.Connection | None) -> None:
    """Close without raising. An uncommitted transaction is discarded."""
    if connection is None:
        return
    try:
        connection.close()
    except Exception:  # noqa: BLE001 - must not replace the operation result
        return


def _require_uid(uid: object) -> None:
    if (
        not isinstance(uid, str)
        or not uid
        or uid != uid.strip()
        or len(uid) > MAX_UID_LENGTH
    ):
        raise IssuanceError("Verified UID is not usable for issuance.")


def _database_file(database_path: Path | str) -> Path:
    path = Path(database_path).expanduser()
    if not path.is_absolute():
        raise IssuanceConfigurationError(
            "Issuance database path must be an absolute path."
        )
    if path.exists() and path.is_dir():
        raise IssuanceConfigurationError(
            "Issuance database path must identify a file."
        )
    return path


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="microseconds").replace(
        "+00:00", "Z"
    )
