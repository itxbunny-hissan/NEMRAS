"""Tests for POST /api/v1/me/patient-id and the issuance ledger.

No test contacts Firebase or PostgreSQL. Authentication is exercised through
the same seam as test_auth.py: ``auth._verify_id_token`` is patched, so header
parsing, claim checks, and status mapping still run for real. Every ledger and
registry is a temporary SQLite file.

Tokens here are opaque placeholder strings, never real credentials.
"""

from concurrent.futures import ThreadPoolExecutor
import logging
import sqlite3
import time

import pytest

import auth
import main
import patient_id
import patient_id_issuance


ENDPOINT = "/api/v1/me/patient-id"
GENERIC_503 = "NEMRAS Patient ID issuance is temporarily unavailable."
EXPECTED_KEYS = {
    "nemras_id",
    "display_id",
    "status",
    "created_at",
    "issued_at",
    "newly_issued",
    "binding_status",
    "record_access",
    "detail",
}


def bearer(uid: str) -> dict:
    """The placeholder token names the UID the patched verifier will return."""
    return {"Authorization": f"Bearer placeholder-token-for-{uid}"}


def claims_for(uid: str) -> dict:
    project = auth.expected_project_id()
    now = int(time.time())
    return {
        "uid": uid,
        "sub": uid,
        "aud": project,
        "iss": f"https://securetoken.google.com/{project}",
        "iat": now,
        "exp": now + 3600,
    }


@pytest.fixture
def verified(monkeypatch):
    """Accept any placeholder token and verify it as the UID it names."""
    prefix = "placeholder-token-for-"

    def _verify(token: str) -> dict:
        if not token.startswith(prefix):
            raise auth.TokenInvalid("token_invalid")
        return claims_for(token[len(prefix):])

    monkeypatch.setattr(auth, "_verify_id_token", _verify)


@pytest.fixture
def ledger(tmp_path):
    return patient_id_issuance.PatientIdIssuanceLedger.create(
        tmp_path / "issuance.sqlite3"
    )


@pytest.fixture
def registry(tmp_path):
    return patient_id.PatientIdRegistry.create(tmp_path / "registry.sqlite3")


@pytest.fixture
def backends(monkeypatch, ledger, registry):
    monkeypatch.setattr(
        main, "patient_id_issuance_backends", lambda: (ledger, registry)
    )
    return ledger, registry


def rows(path, query):
    connection = sqlite3.connect(path)
    try:
        return connection.execute(query).fetchall()
    finally:
        connection.close()


def mapping_rows(ledger):
    return rows(ledger.database_path, "SELECT uid, nemras_id FROM patient_id_issuance")


def registry_rows(registry):
    return rows(registry.database_path, "SELECT nemras_id, status FROM patient_id")


# ------------------------------------------------------------------
# Authentication
# ------------------------------------------------------------------
def test_missing_authentication_returns_401_and_issues_nothing(
    client, backends
):
    ledger, registry = backends

    response = client.post(ENDPOINT)

    assert response.status_code == 401
    assert mapping_rows(ledger) == []
    assert registry_rows(registry) == []


def test_invalid_token_returns_401_and_issues_nothing(client, backends, verified):
    ledger, registry = backends

    response = client.post(
        ENDPOINT, headers={"Authorization": "Bearer not-an-accepted-token"}
    )

    assert response.status_code == 401
    assert mapping_rows(ledger) == []
    assert registry_rows(registry) == []


def test_storage_is_not_opened_before_authentication(client, monkeypatch):
    def _must_not_run():
        raise AssertionError("storage opened for an unauthenticated request")

    monkeypatch.setattr(main, "patient_id_issuance_backends", _must_not_run)

    assert client.post(ENDPOINT).status_code == 401


# ------------------------------------------------------------------
# Issuance and idempotent replay
# ------------------------------------------------------------------
def test_first_request_issues_a_valid_patient_id(client, backends, verified):
    ledger, registry = backends

    response = client.post(ENDPOINT, headers=bearer("uid-first"))

    assert response.status_code == 201
    body = response.json()
    assert len(body["nemras_id"]) == 13
    assert body["nemras_id"].isdigit()
    assert patient_id.is_valid_patient_id(body["nemras_id"])
    assert body["display_id"] == patient_id.format_patient_id(body["nemras_id"])
    assert body["status"] == "active"
    assert body["newly_issued"] is True
    assert body["binding_status"] == "not_bound"
    assert body["record_access"] == "none"
    assert "does not open or authorize access" in body["detail"]
    assert mapping_rows(ledger) == [("uid-first", body["nemras_id"])]
    assert registry_rows(registry) == [(body["nemras_id"], "active")]


def test_repeated_request_returns_same_id_and_original_timestamps(
    client, backends, verified
):
    ledger, registry = backends

    first = client.post(ENDPOINT, headers=bearer("uid-repeat")).json()
    second = client.post(ENDPOINT, headers=bearer("uid-repeat"))
    third = client.post(ENDPOINT, headers=bearer("uid-repeat"))

    assert second.status_code == 200
    assert third.status_code == 200
    for replay in (second.json(), third.json()):
        assert replay["nemras_id"] == first["nemras_id"]
        assert replay["created_at"] == first["created_at"]
        assert replay["issued_at"] == first["issued_at"]
        assert replay["newly_issued"] is False
        assert replay["binding_status"] == "not_bound"
    assert len(mapping_rows(ledger)) == 1
    assert len(registry_rows(registry)) == 1


def test_different_uids_receive_different_ids(client, backends, verified):
    ledger, _ = backends

    ids = {
        client.post(ENDPOINT, headers=bearer(f"uid-{n}")).json()["nemras_id"]
        for n in range(5)
    }

    assert len(ids) == 5
    assert len(mapping_rows(ledger)) == 5


def test_issuance_and_replays_are_audited(client, backends, verified):
    ledger, _ = backends

    issued = client.post(ENDPOINT, headers=bearer("uid-audited")).json()
    client.post(ENDPOINT, headers=bearer("uid-audited"))

    events = ledger.audit_events("uid-audited")
    assert [event.action for event in events] == ["issued", "replayed"]
    assert all(event.uid == "uid-audited" for event in events)
    assert all(event.nemras_id == issued["nemras_id"] for event in events)
    assert all(event.occurred_at.endswith("Z") for event in events)
    assert events[0].occurred_at == issued["issued_at"]


# ------------------------------------------------------------------
# The client cannot choose the UID or the ID, and sees no personal data
# ------------------------------------------------------------------
def test_client_supplied_uid_cnic_and_id_are_ignored(client, backends, verified):
    ledger, _ = backends
    forged_id = "0000000000018"

    response = client.post(
        ENDPOINT,
        headers=bearer("uid-from-verified-token"),
        params={"uid": "uid-forged-in-query", "cnic": "35202-1234567-1"},
        json={
            "uid": "uid-forged-in-body",
            "cnic": "35202-1234567-1",
            "name": "Forged Name",
            "phone": "+923001234567",
            "nemras_id": forged_id,
        },
    )

    assert response.status_code == 201
    issued = response.json()["nemras_id"]
    assert issued != forged_id
    assert mapping_rows(ledger) == [("uid-from-verified-token", issued)]


def test_response_exposes_no_personal_or_clinical_data(client, backends, verified):
    response = client.post(
        ENDPOINT,
        headers=bearer("uid-private"),
        json={"cnic": "35202-1234567-1", "name": "Forged Name"},
    )

    body = response.json()
    assert set(body) == EXPECTED_KEYS
    text = response.text.lower()
    for leaked in ("35202", "forged name", "cnic\"", "phone\"", "uid-private"):
        assert leaked not in text
    for clinical in ("allergy", "medication", "condition", "blood", "diagnos"):
        assert clinical not in text


# ------------------------------------------------------------------
# Failures return a generic 503
# ------------------------------------------------------------------
class _UnavailableRegistry:
    def register(self, *, max_attempts=8):
        raise patient_id.PatientIdRegistryUnavailableError(
            "internal detail host=db.internal role=nemras"
        )

    def get(self, nemras_id):
        raise patient_id.PatientIdRegistryUnavailableError("internal detail")

    def retire(self, nemras_id):
        raise patient_id.PatientIdRegistryUnavailableError("internal detail")


def test_registry_failure_returns_generic_503(client, monkeypatch, ledger, verified):
    monkeypatch.setattr(
        main,
        "patient_id_issuance_backends",
        lambda: (ledger, _UnavailableRegistry()),
    )

    response = client.post(ENDPOINT, headers=bearer("uid-registry-down"))

    assert response.status_code == 503
    assert response.json() == {"detail": GENERIC_503}
    assert mapping_rows(ledger) == []


def test_ledger_failure_after_reservation_retires_the_reserved_id(
    client, backends, verified
):
    ledger, registry = backends
    connection = sqlite3.connect(ledger.database_path)
    connection.execute("DROP TABLE patient_id_issuance_audit")
    connection.close()

    response = client.post(ENDPOINT, headers=bearer("uid-ledger-broken"))

    assert response.status_code == 503
    assert response.json() == {"detail": GENERIC_503}
    assert mapping_rows(ledger) == []
    reserved = registry_rows(registry)
    assert len(reserved) == 1
    reserved_id, status = reserved[0]
    assert status == "retired"
    assert reserved_id not in response.text


def test_unavailable_ledger_returns_generic_503(client, monkeypatch, tmp_path, registry, verified):
    missing_dir = tmp_path / "missing" / "issuance.sqlite3"
    broken = patient_id_issuance.PatientIdIssuanceLedger(missing_dir)
    monkeypatch.setattr(
        main, "patient_id_issuance_backends", lambda: (broken, registry)
    )

    response = client.post(ENDPOINT, headers=bearer("uid-no-ledger"))

    assert response.status_code == 503
    assert response.json() == {"detail": GENERIC_503}
    assert registry_rows(registry) == []


def test_postgresql_without_dsn_returns_503_without_sqlite_fallback(
    client, monkeypatch, tmp_path, verified
):
    ledger_path = tmp_path / "ledger" / "issuance.sqlite3"
    registry_path = tmp_path / "registry" / "registry.sqlite3"
    monkeypatch.setenv(patient_id_issuance.ISSUANCE_DB_PATH_ENV, str(ledger_path))
    monkeypatch.setenv(patient_id.PATIENT_ID_DB_PATH_ENV, str(registry_path))
    monkeypatch.setenv(patient_id.PATIENT_ID_BACKEND_ENV, "postgresql")
    monkeypatch.delenv(patient_id.PATIENT_ID_DATABASE_URL_ENV, raising=False)
    main.reset_patient_id_issuance_backends()
    try:
        response = client.post(ENDPOINT, headers=bearer("uid-misconfigured"))
    finally:
        main.reset_patient_id_issuance_backends()

    assert response.status_code == 503
    assert response.json() == {"detail": GENERIC_503}
    assert not registry_path.exists()
    assert not ledger_path.exists()


def test_default_backends_use_configured_sqlite_files(
    client, monkeypatch, tmp_path, verified
):
    ledger_path = tmp_path / "ledger" / "issuance.sqlite3"
    registry_path = tmp_path / "registry" / "registry.sqlite3"
    monkeypatch.setenv(patient_id_issuance.ISSUANCE_DB_PATH_ENV, str(ledger_path))
    monkeypatch.setenv(patient_id.PATIENT_ID_DB_PATH_ENV, str(registry_path))
    monkeypatch.delenv(patient_id.PATIENT_ID_BACKEND_ENV, raising=False)
    main.reset_patient_id_issuance_backends()
    try:
        response = client.post(ENDPOINT, headers=bearer("uid-default-backends"))
    finally:
        main.reset_patient_id_issuance_backends()

    assert response.status_code == 201
    assert ledger_path.exists()
    assert registry_path.exists()


def test_replay_of_retired_id_is_refused_with_409(client, backends, verified):
    ledger, registry = backends
    issued = client.post(ENDPOINT, headers=bearer("uid-retired")).json()
    registry.retire(issued["nemras_id"])

    response = client.post(ENDPOINT, headers=bearer("uid-retired"))

    assert response.status_code == 409
    assert issued["nemras_id"] not in response.text
    actions = [event.action for event in ledger.audit_events("uid-retired")]
    assert actions == ["issued", "replay_rejected"]


# ------------------------------------------------------------------
# Concurrency and database constraints
# ------------------------------------------------------------------
def test_concurrent_issuance_for_one_uid_reserves_exactly_one_id(ledger, registry):
    workers = 8

    with ThreadPoolExecutor(max_workers=workers) as pool:
        results = list(
            pool.map(
                lambda _: ledger.issue("uid-concurrent", registry), range(workers)
            )
        )

    assert len({result.nemras_id for result in results}) == 1
    assert sum(result.newly_issued for result in results) == 1
    assert len({result.created_at for result in results}) == 1
    assert registry_rows(registry) == [(results[0].nemras_id, "active")]
    actions = [event.action for event in ledger.audit_events("uid-concurrent")]
    assert actions.count("issued") == 1
    assert actions.count("replayed") == workers - 1


def test_concurrent_issuance_for_many_uids_gives_distinct_ids(ledger, registry):
    uids = [f"uid-parallel-{n}" for n in range(10)]

    with ThreadPoolExecutor(max_workers=5) as pool:
        results = list(pool.map(lambda uid: ledger.issue(uid, registry), uids))

    assert len({result.nemras_id for result in results}) == len(uids)
    assert len(registry_rows(registry)) == len(uids)


def test_database_rejects_a_second_id_for_the_same_uid(ledger, registry):
    ledger.issue("uid-unique", registry)
    connection = sqlite3.connect(ledger.database_path)
    try:
        with pytest.raises(sqlite3.IntegrityError):
            connection.execute(
                "INSERT INTO patient_id_issuance VALUES (?, ?, ?, ?)",
                ("uid-unique", "0000000000018", "t", "t"),
            )
    finally:
        connection.close()


@pytest.mark.parametrize(
    "statement",
    [
        "UPDATE patient_id_issuance SET nemras_id = '0000000000018'",
        "DELETE FROM patient_id_issuance",
        "UPDATE patient_id_issuance_audit SET action = 'issued'",
        "DELETE FROM patient_id_issuance_audit",
    ],
)
def test_ledger_tables_are_append_only(ledger, registry, statement):
    ledger.issue("uid-append-only", registry)
    connection = sqlite3.connect(ledger.database_path)
    try:
        with pytest.raises(sqlite3.DatabaseError):
            connection.execute(statement)
    finally:
        connection.close()


def test_ledger_and_registry_must_not_share_a_file(tmp_path):
    shared = tmp_path / "shared.sqlite3"
    ledger = patient_id_issuance.PatientIdIssuanceLedger.create(shared)
    registry = patient_id.PatientIdRegistry.create(shared)

    with pytest.raises(patient_id_issuance.IssuanceConfigurationError):
        ledger.issue("uid-shared", registry)


def test_relative_ledger_path_is_rejected():
    with pytest.raises(patient_id_issuance.IssuanceConfigurationError):
        patient_id_issuance.PatientIdIssuanceLedger("relative/issuance.sqlite3")


# ------------------------------------------------------------------
# Existing surface is unchanged
# ------------------------------------------------------------------
def test_identity_endpoint_is_unchanged_after_issuance(client, backends, verified):
    client.post(ENDPOINT, headers=bearer("uid-identity"))

    response = client.get("/api/v1/me/identity", headers=bearer("uid-identity"))

    assert response.status_code == 200
    body = response.json()
    assert set(body) == {"uid", "binding_status", "bound", "detail"}
    assert body["uid"] == "uid-identity"
    assert body["binding_status"] == "not_implemented"
    assert body["bound"] is False


# ------------------------------------------------------------------
# Append-only triggers hold against INSERT OR REPLACE
# ------------------------------------------------------------------
def test_ledger_connections_enable_recursive_triggers(ledger):
    connection = ledger._connect()
    try:
        assert connection.execute("PRAGMA recursive_triggers").fetchone()[0] == 1
    finally:
        connection.close()


@pytest.mark.parametrize("verb", ["INSERT OR REPLACE", "REPLACE"])
def test_replace_cannot_swap_a_uid_mapping(ledger, registry, verb):
    issued = ledger.issue("uid-replace", registry)
    connection = ledger._connect()
    try:
        with pytest.raises(sqlite3.DatabaseError, match="append-only"):
            connection.execute(
                f"{verb} INTO patient_id_issuance VALUES (?, ?, ?, ?)",
                ("uid-replace", "0000000000018", "t", "t"),
            )
    finally:
        connection.close()

    assert mapping_rows(ledger) == [("uid-replace", issued.nemras_id)]


def test_replace_cannot_move_an_id_to_another_uid(ledger, registry):
    issued = ledger.issue("uid-owner", registry)
    connection = ledger._connect()
    try:
        with pytest.raises(sqlite3.DatabaseError, match="append-only"):
            connection.execute(
                "INSERT OR REPLACE INTO patient_id_issuance VALUES (?, ?, ?, ?)",
                ("uid-thief", issued.nemras_id, "t", "t"),
            )
    finally:
        connection.close()

    assert mapping_rows(ledger) == [("uid-owner", issued.nemras_id)]


def test_replace_cannot_overwrite_an_audit_row(ledger, registry):
    issued = ledger.issue("uid-audit-replace", registry)
    connection = ledger._connect()
    try:
        with pytest.raises(sqlite3.DatabaseError, match="append-only"):
            connection.execute(
                """
                INSERT OR REPLACE INTO patient_id_issuance_audit (
                    event_id, uid, action, nemras_id, occurred_at
                )
                VALUES (1, 'uid-other', 'replayed', '0000000000018', 't')
                """
            )
    finally:
        connection.close()

    events = ledger.audit_events("uid-audit-replace")
    assert [(e.action, e.nemras_id) for e in events] == [
        ("issued", issued.nemras_id)
    ]


# ------------------------------------------------------------------
# Recovery when the ledger does not confirm a reservation
# ------------------------------------------------------------------
MAPPING_INSERT = "INSERT INTO patient_id_issuance ("
AUDIT_INSERT = "INSERT INTO patient_id_issuance_audit ("


class FaultyConnection:
    """Wrap a real ledger connection and fail one chosen statement."""

    def __init__(
        self,
        inner,
        *,
        fail_on=None,
        error=sqlite3.OperationalError,
        commit_first=False,
        fail_rollback=False,
        fail_close=False,
    ):
        self._inner = inner
        self._fail_on = fail_on
        self._error = error
        self._commit_first = commit_first
        self._fail_rollback = fail_rollback
        self._fail_close = fail_close

    def execute(self, sql, params=()):
        statement = " ".join(sql.split())
        if statement == "ROLLBACK" and self._fail_rollback:
            raise sqlite3.OperationalError("simulated rollback failure")
        if self._fail_on is not None and statement.startswith(self._fail_on):
            self._fail_on = None
            if self._commit_first:
                # The statement takes effect, then an error is reported.
                self._inner.execute(sql, params)
            raise self._error("simulated disk I/O error")
        return self._inner.execute(sql, params)

    @property
    def in_transaction(self):
        return self._inner.in_transaction

    def close(self):
        self._inner.close()
        if self._fail_close:
            raise sqlite3.ProgrammingError("simulated close failure")


class FaultyLedger(patient_id_issuance.PatientIdIssuanceLedger):
    """The first connection (the issuance transaction) is faulty."""

    def __init__(self, path, *, verification_unavailable=False, **faults):
        super().__init__(path)
        self._faults = faults
        self._verification_unavailable = verification_unavailable
        self._opened = 0

    def _connect(self):
        self._opened += 1
        if self._opened == 1:
            return FaultyConnection(super()._connect(), **self._faults)
        if self._verification_unavailable:
            raise patient_id_issuance.IssuanceUnavailableError("simulated")
        return super()._connect()


class RecordingRegistry:
    """Delegate to a real registry, recording retirements."""

    def __init__(self, inner, *, fail_retire=False, reserve=None):
        self._inner = inner
        self._fail_retire = fail_retire
        self._reserve = reserve
        self.retired = []

    def register(self, *, max_attempts=8):
        if self._reserve is not None:
            return self._reserve
        return self._inner.register(max_attempts=max_attempts)

    def get(self, nemras_id):
        return self._inner.get(nemras_id)

    def retire(self, nemras_id):
        self.retired.append(nemras_id)
        if self._fail_retire:
            raise patient_id.PatientIdRegistryUnavailableError("simulated")
        return self._inner.retire(nemras_id)


@pytest.fixture
def diagnostics(caplog):
    caplog.set_level(logging.WARNING, logger="nemras.patient_id_issuance")
    return caplog


def only_reserved_id(registry):
    reserved = registry_rows(registry)
    assert len(reserved) == 1
    return reserved[0]


def assert_event(caplog, event, *, ledger_state=None, hidden=()):
    messages = [record.getMessage() for record in caplog.records]
    matching = [m for m in messages if f"event={event} " in m]
    assert matching, messages
    if ledger_state is not None:
        assert f"ledger_state={ledger_state} " in matching[0]
    for value in hidden:
        assert value not in caplog.text


def test_ambiguous_commit_that_committed_does_not_retire_the_mapped_id(
    tmp_path, ledger, registry, diagnostics
):
    faulty = FaultyLedger(
        ledger.database_path, fail_on="COMMIT", commit_first=True
    )
    recording = RecordingRegistry(registry)

    with pytest.raises(patient_id_issuance.IssuanceUnavailableError):
        faulty.issue("uid-ambiguous", recording)

    nemras_id, status = only_reserved_id(registry)
    assert recording.retired == []
    assert status == "active"
    assert mapping_rows(ledger) == [("uid-ambiguous", nemras_id)]
    assert_event(
        diagnostics,
        patient_id_issuance.EVENT_COMMIT_OUTCOME_UNKNOWN,
        ledger_state="present",
        hidden=("uid-ambiguous", nemras_id),
    )

    replay = ledger.issue("uid-ambiguous", registry)
    assert replay.nemras_id == nemras_id
    assert replay.newly_issued is False


def test_ambiguous_commit_that_did_not_commit_leaves_the_id_active(
    ledger, registry, diagnostics
):
    faulty = FaultyLedger(ledger.database_path, fail_on="COMMIT")
    recording = RecordingRegistry(registry)

    with pytest.raises(patient_id_issuance.IssuanceUnavailableError):
        faulty.issue("uid-not-committed", recording)

    nemras_id, status = only_reserved_id(registry)
    # Absent now, but a failed COMMIT cannot prove it stays absent, so the
    # ID is left for manual review rather than retired.
    assert recording.retired == []
    assert status == "active"
    assert mapping_rows(ledger) == []
    assert_event(
        diagnostics,
        patient_id_issuance.EVENT_COMMIT_OUTCOME_UNKNOWN,
        ledger_state="absent",
        hidden=("uid-not-committed", nemras_id),
    )


@pytest.mark.parametrize("statement", [MAPPING_INSERT, AUDIT_INSERT])
def test_write_failure_before_commit_retires_the_verified_unrecorded_id(
    ledger, registry, diagnostics, statement
):
    faulty = FaultyLedger(ledger.database_path, fail_on=statement)

    with pytest.raises(patient_id_issuance.IssuanceUnavailableError):
        faulty.issue("uid-write-failed", registry)

    nemras_id, status = only_reserved_id(registry)
    assert status == "retired"
    assert mapping_rows(ledger) == []
    assert ledger.audit_events("uid-write-failed") == []
    assert_event(
        diagnostics,
        patient_id_issuance.EVENT_RESERVED_ID_RETIRED,
        hidden=("uid-write-failed", nemras_id),
    )


def test_failed_retirement_keeps_the_original_error_and_logs(
    ledger, registry, diagnostics
):
    faulty = FaultyLedger(ledger.database_path, fail_on=MAPPING_INSERT)
    recording = RecordingRegistry(registry, fail_retire=True)

    with pytest.raises(patient_id_issuance.IssuanceUnavailableError) as raised:
        faulty.issue("uid-retire-fails", recording)

    assert isinstance(raised.value.__cause__, sqlite3.OperationalError)
    nemras_id, status = only_reserved_id(registry)
    assert recording.retired == [nemras_id]
    assert status == "active"
    assert_event(
        diagnostics,
        patient_id_issuance.EVENT_RETIRE_FAILED,
        hidden=("uid-retire-fails", nemras_id),
    )
    assert "retire_error=PatientIdRegistryUnavailableError" in diagnostics.text


def test_unverifiable_ledger_state_leaves_the_id_untouched(
    ledger, registry, diagnostics
):
    faulty = FaultyLedger(
        ledger.database_path,
        fail_on=MAPPING_INSERT,
        verification_unavailable=True,
    )
    recording = RecordingRegistry(registry)

    with pytest.raises(patient_id_issuance.IssuanceUnavailableError):
        faulty.issue("uid-unverifiable", recording)

    nemras_id, status = only_reserved_id(registry)
    assert recording.retired == []
    assert status == "active"
    assert_event(
        diagnostics,
        patient_id_issuance.EVENT_LEDGER_STATE_UNVERIFIED,
        hidden=("uid-unverifiable", nemras_id),
    )


def test_write_failure_never_retires_an_id_already_in_the_ledger(
    ledger, registry, diagnostics
):
    owned = ledger.issue("uid-existing-owner", registry)
    # A reset registry hands back a value the ledger already maps.
    recording = RecordingRegistry(
        registry, reserve=registry.get(owned.nemras_id)
    )
    faulty = FaultyLedger(ledger.database_path, fail_on=MAPPING_INSERT)

    with pytest.raises(patient_id_issuance.IssuanceUnavailableError):
        faulty.issue("uid-second", recording)

    assert recording.retired == []
    assert registry.get(owned.nemras_id).status == "active"
    assert mapping_rows(ledger) == [("uid-existing-owner", owned.nemras_id)]
    assert_event(
        diagnostics,
        patient_id_issuance.EVENT_RESERVED_ID_IN_LEDGER,
        hidden=("uid-second", owned.nemras_id),
    )


def test_integrity_conflict_never_retires_and_owner_still_replays(
    ledger, registry, diagnostics
):
    owned = ledger.issue("uid-conflict-owner", registry)
    recording = RecordingRegistry(
        registry, reserve=registry.get(owned.nemras_id)
    )

    with pytest.raises(patient_id_issuance.IssuanceUnavailableError) as raised:
        ledger.issue("uid-conflict-second", recording)

    assert isinstance(raised.value.__cause__, sqlite3.IntegrityError)
    assert recording.retired == []
    assert mapping_rows(ledger) == [("uid-conflict-owner", owned.nemras_id)]
    assert_event(
        diagnostics,
        patient_id_issuance.EVENT_LEDGER_CONFLICT,
        hidden=("uid-conflict-second", owned.nemras_id),
    )
    assert ledger.issue("uid-conflict-owner", registry).nemras_id == owned.nemras_id


def test_cleanup_failures_do_not_mask_the_original_error(
    ledger, registry, diagnostics
):
    faulty = FaultyLedger(
        ledger.database_path,
        fail_on=MAPPING_INSERT,
        fail_rollback=True,
        fail_close=True,
    )

    with pytest.raises(patient_id_issuance.IssuanceUnavailableError) as raised:
        faulty.issue("uid-cleanup-fails", registry)

    assert isinstance(raised.value.__cause__, sqlite3.OperationalError)
    assert "disk I/O" in str(raised.value.__cause__)
    assert mapping_rows(ledger) == []
    assert only_reserved_id(registry)[1] == "retired"


def test_close_failure_after_commit_keeps_the_successful_result(ledger, registry):
    faulty = FaultyLedger(ledger.database_path, fail_close=True)

    result = faulty.issue("uid-close-fails", registry)

    assert result.newly_issued is True
    assert mapping_rows(ledger) == [("uid-close-fails", result.nemras_id)]


def test_unexpected_error_before_commit_is_reraised_unchanged(
    ledger, registry, diagnostics
):
    faulty = FaultyLedger(ledger.database_path, fail_on=AUDIT_INSERT, error=TypeError)

    with pytest.raises(TypeError):
        faulty.issue("uid-unexpected", registry)

    assert only_reserved_id(registry)[1] == "retired"
    assert_event(diagnostics, patient_id_issuance.EVENT_RESERVED_ID_RETIRED)


def test_api_ambiguous_commit_returns_generic_503_without_identifiers(
    client, monkeypatch, ledger, registry, verified, diagnostics
):
    faulty = FaultyLedger(
        ledger.database_path, fail_on="COMMIT", commit_first=True
    )
    monkeypatch.setattr(
        main, "patient_id_issuance_backends", lambda: (faulty, registry)
    )

    response = client.post(ENDPOINT, headers=bearer("uid-api-ambiguous"))

    assert response.status_code == 503
    assert response.json() == {"detail": GENERIC_503}
    nemras_id, status = only_reserved_id(registry)
    assert status == "active"
    assert nemras_id not in response.text
    assert "uid-api-ambiguous" not in diagnostics.text
    assert nemras_id not in diagnostics.text

    monkeypatch.setattr(
        main, "patient_id_issuance_backends", lambda: (ledger, registry)
    )
    replay = client.post(ENDPOINT, headers=bearer("uid-api-ambiguous"))
    assert replay.status_code == 200
    assert replay.json()["nemras_id"] == nemras_id
