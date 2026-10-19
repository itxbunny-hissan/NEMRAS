"""Opt-in PostgreSQL patient-ID adapter tests.

These tests use a fake connection. They do not open a database.
"""

import ast
from pathlib import Path

import pytest

import patient_id


SECRET_URL = "postgresql://user:super-secret-password@localhost/nemras"


class SqlStateError(Exception):
    def __init__(self, sqlstate: str, detail: str | None = None) -> None:
        super().__init__(sqlstate if detail is None else detail)
        self.sqlstate = sqlstate


class Result:
    def __init__(self, row, rowcount: int = 1) -> None:
        self._row = row
        self.rowcount = rowcount

    def fetchone(self):
        return self._row


class Transaction:
    def __init__(self, connection) -> None:
        self.connection = connection

    def __enter__(self):
        self.connection.events.append("begin")
        return self

    def __exit__(self, exc_type, exc, tb):
        self.connection.events.append("rollback" if exc_type else "commit")
        return False


class Connection:
    def __init__(self, registry) -> None:
        self.registry = registry
        self.events = []
        self.closed = False
        self.close_calls = 0
        self.session_commits = 0

    def execute(self, sql, params=None):
        self.registry.statements.append((sql, params))
        folded = " ".join(sql.split()).upper()
        if folded.startswith("SELECT SET_CONFIG"):
            if self.registry.fail_timeout_setup:
                raise SqlStateError("08006", detail=SECRET_URL)
            return Result(None)
        if self.registry.error is not None:
            raise self.registry.error
        if folded.startswith("CREATE") or folded.startswith("DELETE"):
            raise AssertionError("registry adapter attempted forbidden SQL")
        if folded.startswith("INSERT"):
            nemras_id, status, created_at = params
            if nemras_id in self.registry.rows:
                raise SqlStateError(patient_id.POSTGRESQL_UNIQUE_VIOLATION)
            self.registry.rows[nemras_id] = (nemras_id, status, created_at)
            return Result(None)
        if folded.startswith("SELECT"):
            return Result(self.registry.rows.get(params[0]))
        if folded.startswith("UPDATE"):
            status, nemras_id, expected = params
            row = self.registry.rows.get(nemras_id)
            if row is not None and row[1] == expected:
                self.registry.rows[nemras_id] = (row[0], status, row[2])
                return Result(None, 1)
            return Result(None, 0)
        raise AssertionError("unexpected SQL")

    def transaction(self):
        return Transaction(self)

    def commit(self) -> None:
        self.session_commits += 1
        if self.registry.fail_timeout_commit:
            raise SqlStateError("08006", detail=SECRET_URL)

    def close(self) -> None:
        self.close_calls += 1
        if self.registry.fail_close:
            raise RuntimeError("close failed")
        self.closed = True


class Registry:
    def __init__(
        self,
        error: SqlStateError | None = None,
        *,
        fail_close: bool = False,
        fail_connect: bool = False,
        fail_timeout_setup: bool = False,
        fail_timeout_commit: bool = False,
    ) -> None:
        self.rows = {}
        self.statements = []
        self.error = error
        self.fail_close = fail_close
        self.fail_connect = fail_connect
        self.fail_timeout_setup = fail_timeout_setup
        self.fail_timeout_commit = fail_timeout_commit
        self.connections = []
        self.connect_kwargs = []

    def connect(self, _database_url, **kwargs):
        self.connect_kwargs.append(kwargs)
        if self.fail_connect:
            raise SqlStateError("08006", detail=SECRET_URL)
        connection = Connection(self)
        self.connections.append(connection)
        return connection


def _postgres(registry: Registry) -> patient_id.PostgresPatientIdRegistry:
    return patient_id.PostgresPatientIdRegistry(SECRET_URL, connect=registry.connect)


def _operation_statements(registry: Registry):
    return [
        item
        for item in registry.statements
        if "set_config" not in item[0].lower()
    ]


def _assert_driver_text_hidden(error: BaseException) -> None:
    assert "super-secret-password" not in str(error)
    assert error.__context__ is None
    cause = error.__cause__
    assert cause is not None
    assert "super-secret-password" not in str(cause)
    assert getattr(cause, "sqlstate", None)


def test_unset_backend_selects_sqlite(monkeypatch):
    monkeypatch.delenv(patient_id.PATIENT_ID_BACKEND_ENV, raising=False)
    monkeypatch.setenv(patient_id.PATIENT_ID_DATABASE_URL_ENV, SECRET_URL)

    registry = patient_id.open_patient_id_registry()

    assert isinstance(registry, patient_id.PatientIdRegistry)


def test_explicit_sqlite_backend_selects_sqlite(monkeypatch):
    monkeypatch.setenv(patient_id.PATIENT_ID_BACKEND_ENV, " SQLite ")

    registry = patient_id.open_patient_id_registry()

    assert isinstance(registry, patient_id.PatientIdRegistry)


def test_invalid_backend_raises_a_clear_error(monkeypatch):
    monkeypatch.setenv(patient_id.PATIENT_ID_BACKEND_ENV, "oracle")
    monkeypatch.setenv(patient_id.PATIENT_ID_DATABASE_URL_ENV, SECRET_URL)

    with pytest.raises(patient_id.PatientIdConfigurationError) as caught:
        patient_id.open_patient_id_registry()

    assert "sqlite or postgresql" in str(caught.value)
    assert "super-secret-password" not in str(caught.value)


def test_postgresql_without_a_dsn_does_not_fall_back_to_sqlite(monkeypatch):
    monkeypatch.setenv(patient_id.PATIENT_ID_BACKEND_ENV, "postgresql")
    monkeypatch.delenv(patient_id.PATIENT_ID_DATABASE_URL_ENV, raising=False)

    with pytest.raises(patient_id.PatientIdConfigurationError) as caught:
        patient_id.open_patient_id_registry()

    message = str(caught.value)
    assert "NEMRAS_PATIENT_ID_DATABASE_URL" in message
    assert "not used as a fallback" in message


def test_selecting_postgresql_does_not_open_a_connection(monkeypatch):
    monkeypatch.setenv(patient_id.PATIENT_ID_BACKEND_ENV, " PostgreSQL ")
    monkeypatch.setenv(patient_id.PATIENT_ID_DATABASE_URL_ENV, SECRET_URL)
    monkeypatch.setattr(
        patient_id,
        "_load_psycopg",
        lambda: (_ for _ in ()).throw(AssertionError("Psycopg was loaded")),
    )

    registry = patient_id.open_patient_id_registry()

    assert isinstance(registry, patient_id.PostgresPatientIdRegistry)


def test_import_does_not_import_psycopg():
    source = Path(patient_id.__file__).read_text(encoding="utf-8")
    tree = ast.parse(source)
    for node in tree.body:
        if isinstance(node, ast.Import):
            assert all(alias.name != "psycopg" for alias in node.names)
        if isinstance(node, ast.ImportFrom):
            assert node.module != "psycopg"


def test_constructing_the_adapter_does_not_connect():
    def connect(_database_url):
        raise AssertionError("PostgreSQL connection was opened")

    patient_id.PostgresPatientIdRegistry(SECRET_URL, connect=connect)


def test_register_uses_parameterized_sql_and_preserves_leading_zeros(monkeypatch):
    monkeypatch.setattr(
        patient_id, "generate_patient_id", lambda: "0000000000018"
    )
    registry = Registry()

    created = _postgres(registry).register()

    sql, params = _operation_statements(registry)[0]
    assert "INSERT INTO nemras_id_registry" in sql
    assert "%s" in sql
    assert "0000000000018" not in sql
    assert params == ("0000000000018", "active", created.created_at)
    assert created.status == "active"
    assert registry.connections[0].closed is True
    assert registry.connections[0].events == ["begin", "commit"]


def test_unique_violation_retries_and_retired_id_is_not_reused(monkeypatch):
    sequence = iter(["0000000000018", "0000000000018", "1234567890128"])
    monkeypatch.setattr(patient_id, "generate_patient_id", lambda: next(sequence))
    registry = Registry()
    store = _postgres(registry)

    original = store.register()
    retired = store.retire(original.nemras_id)
    again = store.retire(original.nemras_id)
    replacement = store.register()

    assert retired.status == "retired"
    assert retired.created_at == original.created_at
    assert again == retired
    assert replacement.nemras_id == "1234567890128"
    assert registry.rows["0000000000018"][1] == "retired"
    assert "DELETE" not in " ".join(sql for sql, _params in registry.statements).upper()
    selects = [
        sql
        for sql, _params in _operation_statements(registry)
        if sql.lstrip().upper().startswith("SELECT")
    ]
    updates = [
        item for item in registry.statements
        if item[0].lstrip().upper().startswith("UPDATE")
    ]
    assert selects
    assert all("FOR UPDATE" in sql.upper() for sql in selects)
    assert all("%s" in sql and "0000000000018" not in sql for sql in selects)
    assert len(updates) == 1
    update_sql, update_params = updates[0]
    assert "%s" in update_sql
    assert "0000000000018" not in update_sql
    assert update_params[0] == "retired"
    collision = next(
        connection for connection in registry.connections if "rollback" in connection.events
    )
    assert collision.events == ["begin", "rollback"]
    assert collision.closed is True
    assert all(connection.closed for connection in registry.connections)


def test_unrelated_database_error_is_not_retried_as_a_collision(monkeypatch):
    calls = {"n": 0}

    def generate():
        calls["n"] += 1
        return "1234567890128"

    monkeypatch.setattr(patient_id, "generate_patient_id", generate)
    registry = Registry(error=SqlStateError("08006", detail=SECRET_URL))

    with pytest.raises(patient_id.PatientIdRegistryUnavailableError) as caught:
        _postgres(registry).register()

    assert calls["n"] == 1
    assert "could not be reserved" in str(caught.value)
    assert patient_id.POSTGRESQL_REGISTRY_SCRIPT not in str(caught.value)
    _assert_driver_text_hidden(caught.value)
    assert caught.value.__cause__.sqlstate == "08006"
    assert registry.connections[0].closed is True
    assert registry.connections[0].events == ["begin", "rollback"]


def test_missing_table_is_reported_once_and_schema_is_not_executed(monkeypatch):
    calls = {"n": 0}

    def generate():
        calls["n"] += 1
        return "1234567890128"

    monkeypatch.setattr(patient_id, "generate_patient_id", generate)
    registry = Registry(
        error=SqlStateError(
            patient_id.POSTGRESQL_UNDEFINED_TABLE, detail=SECRET_URL
        )
    )

    with pytest.raises(patient_id.PatientIdRegistryUnavailableError) as caught:
        _postgres(registry).register()

    message = str(caught.value)
    assert calls["n"] == 1
    assert patient_id.POSTGRESQL_REGISTRY_SCRIPT in message
    assert "does not create the table" in message
    _assert_driver_text_hidden(caught.value)
    assert caught.value.__cause__.sqlstate == patient_id.POSTGRESQL_UNDEFINED_TABLE
    operation_statements = _operation_statements(registry)
    assert len(operation_statements) == 1
    assert "CREATE TABLE" not in operation_statements[0][0].upper()
    assert registry.connections[0].closed is True


def test_get_finds_an_existing_record_and_reports_a_missing_one(monkeypatch):
    monkeypatch.setattr(
        patient_id, "generate_patient_id", lambda: "0000000000018"
    )
    registry = Registry()
    store = _postgres(registry)
    created = store.register()

    found = store.get(created.nemras_id)

    assert found == created
    select_sql, select_params = registry.statements[-1]
    assert "SELECT" in select_sql.upper()
    assert "%s" in select_sql
    assert "0000000000018" not in select_sql
    assert select_params == ("0000000000018",)
    assert registry.connections[-1].closed is True
    assert registry.connections[-1].events == ["begin", "commit"]

    with pytest.raises(patient_id.PatientIdNotFoundError):
        store.get("0000000000000")

    assert registry.connections[-1].closed is True
    assert registry.connections[-1].events == ["begin", "commit"]


def test_display_form_ids_are_rejected_before_a_connection():
    registry = Registry()
    store = _postgres(registry)

    with pytest.raises(patient_id.InvalidPatientIdError):
        store.get("0000 0000 0001 8")
    with pytest.raises(patient_id.InvalidPatientIdError):
        store.retire("0000 0000 0001 8")

    assert registry.connections == []
    assert registry.statements == []


def test_registration_stops_when_every_collision_retry_is_exhausted(monkeypatch):
    monkeypatch.setattr(
        patient_id, "generate_patient_id", lambda: "1234567890128"
    )
    registry = Registry()
    store = _postgres(registry)
    reserved = store.register()

    with pytest.raises(patient_id.PatientIdAllocationError):
        store.register(max_attempts=2)

    assert registry.rows["1234567890128"] == (
        "1234567890128",
        "active",
        reserved.created_at,
    )
    assert [connection.events for connection in registry.connections] == [
        ["begin", "commit"],
        ["begin", "rollback"],
        ["begin", "rollback"],
    ]
    assert all(connection.closed for connection in registry.connections)


def test_check_violation_is_not_treated_as_a_collision(monkeypatch):
    calls = {"n": 0}

    def generate():
        calls["n"] += 1
        return "1234567890128"

    monkeypatch.setattr(patient_id, "generate_patient_id", generate)
    registry = Registry(error=SqlStateError("23514", detail=SECRET_URL))

    with pytest.raises(patient_id.PatientIdRegistryUnavailableError) as caught:
        _postgres(registry).register()

    assert calls["n"] == 1
    assert "could not be reserved" in str(caught.value)
    assert patient_id.POSTGRESQL_REGISTRY_SCRIPT not in str(caught.value)
    _assert_driver_text_hidden(caught.value)
    assert caught.value.__cause__.sqlstate == "23514"
    assert registry.connections[0].closed is True
    assert registry.connections[0].events == ["begin", "rollback"]


def test_lookup_unique_violation_is_not_retried_as_a_collision():
    registry = Registry(error=SqlStateError("23505", detail=SECRET_URL))

    with pytest.raises(patient_id.PatientIdRegistryUnavailableError) as caught:
        _postgres(registry).get("1234567890128")

    assert len(_operation_statements(registry)) == 1
    assert "lookup failed" in str(caught.value)
    _assert_driver_text_hidden(caught.value)
    assert caught.value.__cause__.sqlstate == "23505"
    assert registry.connections[0].closed is True


def test_close_failure_does_not_replace_a_successful_registration(monkeypatch):
    monkeypatch.setattr(
        patient_id, "generate_patient_id", lambda: "0000000000018"
    )
    registry = Registry(fail_close=True)

    created = _postgres(registry).register()

    assert created.nemras_id == "0000000000018"
    assert created.status == "active"
    assert registry.rows["0000000000018"][1] == "active"
    assert registry.connections[0].close_calls == 1
    assert registry.connections[0].events == ["begin", "commit"]


def test_close_failure_does_not_stop_collision_retry(monkeypatch):
    sequence = iter(["0000000000018", "1234567890128"])
    monkeypatch.setattr(patient_id, "generate_patient_id", lambda: next(sequence))
    registry = Registry(fail_close=True)
    registry.rows["0000000000018"] = (
        "0000000000018",
        "retired",
        "2026-01-01T00:00:00.000000Z",
    )

    created = _postgres(registry).register()

    assert created.nemras_id == "1234567890128"
    assert created.status == "active"
    assert [connection.events for connection in registry.connections] == [
        ["begin", "rollback"],
        ["begin", "commit"],
    ]
    assert all(connection.close_calls == 1 for connection in registry.connections)
    assert registry.rows["0000000000018"][1] == "retired"


def test_close_failure_does_not_hide_a_database_error(monkeypatch):
    monkeypatch.setattr(
        patient_id, "generate_patient_id", lambda: "1234567890128"
    )
    registry = Registry(
        error=SqlStateError("08006", detail=SECRET_URL), fail_close=True
    )

    with pytest.raises(patient_id.PatientIdRegistryUnavailableError) as caught:
        _postgres(registry).register()

    assert "could not be reserved" in str(caught.value)
    assert "close failed" not in str(caught.value)
    _assert_driver_text_hidden(caught.value)
    assert registry.connections[0].close_calls == 1
    assert registry.connections[0].events == ["begin", "rollback"]


def test_close_failure_does_not_replace_a_successful_retirement(monkeypatch):
    monkeypatch.setattr(
        patient_id, "generate_patient_id", lambda: "0000000000018"
    )
    registry = Registry(fail_close=True)
    store = _postgres(registry)

    created = store.register()
    retired = store.retire(created.nemras_id)
    again = store.retire(created.nemras_id)

    assert retired.status == "retired"
    assert retired.created_at == created.created_at
    assert again == retired
    assert registry.rows["0000000000018"][1] == "retired"
    assert all(connection.close_calls == 1 for connection in registry.connections)


def test_retiring_a_missing_id_reports_not_found_and_rolls_back():
    registry = Registry()

    with pytest.raises(patient_id.PatientIdNotFoundError):
        _postgres(registry).retire("0000000000000")

    sql, params = _operation_statements(registry)[0]
    assert "FOR UPDATE" in sql.upper()
    assert "%s" in sql
    assert "0000000000000" not in sql
    assert params == ("0000000000000",)
    assert not any(
        statement.lstrip().upper().startswith("UPDATE")
        for statement, _params in registry.statements
    )
    assert registry.connections[0].events == ["begin", "rollback"]
    assert registry.connections[0].closed is True


def test_missing_table_on_get_and_retire_asks_for_manual_sql():
    valid = "1234567890128"
    operations = ("get", "retire")

    for operation in operations:
        registry = Registry(
            error=SqlStateError(
                patient_id.POSTGRESQL_UNDEFINED_TABLE, detail=SECRET_URL
            )
        )
        store = _postgres(registry)
        with pytest.raises(patient_id.PatientIdRegistryUnavailableError) as caught:
            getattr(store, operation)(valid)

        message = str(caught.value)
        assert patient_id.POSTGRESQL_REGISTRY_SCRIPT in message
        assert "does not create the table" in message
        _assert_driver_text_hidden(caught.value)
        assert caught.value.__cause__.sqlstate == patient_id.POSTGRESQL_UNDEFINED_TABLE
        operation_statements = _operation_statements(registry)
        assert len(operation_statements) == 1
        assert "CREATE TABLE" not in operation_statements[0][0].upper()
        assert registry.connections[0].closed is True
        assert registry.connections[0].events == ["begin", "rollback"]


def _timeout_settings(registry: Registry):
    return [
        params
        for sql, params in registry.statements
        if "set_config" in sql.lower()
    ]


def test_connection_call_receives_a_finite_connect_timeout(monkeypatch):
    monkeypatch.setattr(
        patient_id, "generate_patient_id", lambda: "0000000000018"
    )
    registry = Registry()

    _postgres(registry).register()

    assert registry.connect_kwargs == [
        {"connect_timeout": patient_id.POSTGRESQL_CONNECT_TIMEOUT_SECONDS}
    ]
    assert patient_id.POSTGRESQL_CONNECT_TIMEOUT_SECONDS >= 2
    assert registry.connections[0].session_commits == 1


def test_session_receives_finite_statement_and_lock_timeouts(monkeypatch):
    monkeypatch.setattr(
        patient_id, "generate_patient_id", lambda: "0000000000018"
    )
    registry = Registry()

    _postgres(registry).register()

    assert _timeout_settings(registry) == [
        ("statement_timeout", str(patient_id.POSTGRESQL_STATEMENT_TIMEOUT_MS), False),
        ("lock_timeout", str(patient_id.POSTGRESQL_LOCK_TIMEOUT_MS), False),
    ]
    assert patient_id.POSTGRESQL_STATEMENT_TIMEOUT_MS >= 1
    assert patient_id.POSTGRESQL_LOCK_TIMEOUT_MS >= 1
    sql = " ".join(
        statement for statement, _params in registry.statements if "set_config" in statement.lower()
    )
    assert str(patient_id.POSTGRESQL_STATEMENT_TIMEOUT_MS) not in sql
    assert "%s" in sql


def test_connect_failure_uses_the_registry_error_contract():
    registry = Registry(fail_connect=True)

    with pytest.raises(patient_id.PatientIdRegistryUnavailableError) as caught:
        _postgres(registry).register()

    assert "could not be reserved" in str(caught.value)
    _assert_driver_text_hidden(caught.value)
    assert caught.value.__cause__.sqlstate == "08006"
    assert registry.connections == []
    assert registry.connect_kwargs[0]["connect_timeout"] == (
        patient_id.POSTGRESQL_CONNECT_TIMEOUT_SECONDS
    )
    assert registry.rows == {}


def test_timeout_setup_failure_closes_the_connection_and_keeps_the_error():
    registry = Registry(fail_timeout_setup=True, fail_close=True)

    with pytest.raises(patient_id.PatientIdRegistryUnavailableError) as caught:
        _postgres(registry).register()

    assert "could not be reserved" in str(caught.value)
    assert "close failed" not in str(caught.value)
    _assert_driver_text_hidden(caught.value)
    assert registry.connections[0].close_calls == 1
    assert registry.connections[0].session_commits == 0
    assert registry.rows == {}
    assert _operation_statements(registry) == []


def test_timeout_commit_failure_closes_the_connection():
    registry = Registry(fail_timeout_commit=True)

    with pytest.raises(patient_id.PatientIdRegistryUnavailableError) as caught:
        _postgres(registry).get("1234567890128")

    assert "lookup failed" in str(caught.value)
    _assert_driver_text_hidden(caught.value)
    assert registry.connections[0].session_commits == 1
    assert registry.connections[0].closed is True
    assert registry.connections[0].events == []
    assert _operation_statements(registry) == []
