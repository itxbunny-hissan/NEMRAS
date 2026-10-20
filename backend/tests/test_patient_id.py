"""Tests for the NEMRAS Patient ID generator and SQLite registry.

These tests use temporary databases only. They do not read patient records.
"""

from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import re
import sqlite3
import threading

import pytest

import patient_id


ORACLE_REGISTRY_SQL = (
    Path(patient_id.__file__).resolve().parent
    / "sql"
    / "oracle11g"
    / "001_nemras_id_registry.sql"
)


BODY_ZERO = "000000000000"
BODY_SMALL = "000000000001"
BODY_FORTY_TWO = "000000000042"
BODY_SAMPLE = "123456789012"


@pytest.fixture
def registry(tmp_path):
    return patient_id.PatientIdRegistry.create(tmp_path / "patient_ids.sqlite3")


def test_luhn_check_digit_matches_hand_calculated_vectors():
    assert patient_id.luhn_check_digit(BODY_ZERO) == "0"
    assert patient_id.luhn_check_digit(BODY_SMALL) == "8"
    assert patient_id.luhn_check_digit(BODY_FORTY_TWO) == "2"
    assert patient_id.luhn_check_digit(BODY_SAMPLE) == "8"

    issued = {
        BODY_ZERO: "0000000000000",
        BODY_SMALL: "0000000000018",
        BODY_FORTY_TWO: "0000000000422",
        BODY_SAMPLE: "1234567890128",
    }
    for body, canonical in issued.items():
        assert body + patient_id.luhn_check_digit(body) == canonical
        assert patient_id.is_valid_patient_id(canonical)


def test_generated_id_is_thirteen_digits_and_passes_luhn():
    issued = patient_id.generate_patient_id()

    assert len(issued) == patient_id.ID_LENGTH
    assert issued.isascii() and issued.isdigit()
    assert patient_id.is_valid_patient_id(issued)
    assert patient_id.luhn_check_digit(issued[:12]) == issued[12]


def test_invalid_length_characters_and_check_digits_are_rejected():
    valid = "1234567890128"
    altered_check = "1234567890120"
    altered_body = "2234567890128"

    assert patient_id.is_valid_patient_id(valid)
    assert not patient_id.is_valid_patient_id(altered_check)
    assert not patient_id.is_valid_patient_id(altered_body)
    assert not patient_id.is_valid_patient_id(valid[:12])
    assert not patient_id.is_valid_patient_id(valid + "0")
    assert not patient_id.is_valid_patient_id("")
    assert not patient_id.is_valid_patient_id("123456789012A")
    assert not patient_id.is_valid_patient_id("1234 5678 9012 8")
    assert not patient_id.is_valid_patient_id(None)
    assert not patient_id.is_valid_patient_id(1234567890128)

    for value in (altered_check, altered_body, valid[:12], "123456789012A"):
        with pytest.raises(patient_id.InvalidPatientIdError):
            patient_id.require_patient_id(value)


def test_body_generation_uses_secrets_and_preserves_leading_zeros(monkeypatch):
    seen = {}

    def fake_randbelow(upper):
        seen["upper"] = upper
        return 42

    monkeypatch.setattr(patient_id.secrets, "randbelow", fake_randbelow)

    assert patient_id.generate_body() == BODY_FORTY_TWO
    assert seen["upper"] == 10**12
    assert patient_id.generate_patient_id() == "0000000000422"


def test_display_format_groups_the_body_and_leaves_the_check_digit():
    assert patient_id.format_patient_id("0000000000018") == "0000 0000 0001 8"
    assert patient_id.format_patient_id("0000000000422") == "0000 0000 0042 2"
    assert patient_id.format_patient_id("1234567890128") == "1234 5678 9012 8"

    with pytest.raises(patient_id.InvalidPatientIdError):
        patient_id.format_patient_id("0000 0000 0001 8")


def test_schema_uses_the_id_as_primary_key_and_restricts_status(registry):
    with sqlite3.connect(registry.database_path) as connection:
        columns = {
            row[1]: row
            for row in connection.execute("PRAGMA table_info(patient_id)")
        }
        journal_mode = connection.execute("PRAGMA journal_mode").fetchone()[0]

    assert set(columns) == {"nemras_id", "status", "created_at"}
    assert columns["nemras_id"][5] == 1
    assert journal_mode.lower() == "wal"
    with registry._connect() as connection:
        assert connection.execute("PRAGMA foreign_keys").fetchone()[0] == 1

    with sqlite3.connect(registry.database_path) as connection:
        with pytest.raises(sqlite3.IntegrityError):
            connection.execute(
                """
                INSERT INTO patient_id (nemras_id, status, created_at)
                VALUES ('0000000000000', 'deleted', '2026-01-01T00:00:00Z')
                """
            )


def test_registration_preserves_leading_zeros_and_can_be_looked_up(
    registry, monkeypatch
):
    monkeypatch.setattr(
        patient_id, "generate_patient_id", lambda: "0000000000018"
    )

    created = registry.register()
    found = registry.get("0000000000018")

    assert created == found
    assert created.nemras_id == "0000000000018"
    assert created.status == patient_id.STATUS_ACTIVE
    assert created.created_at.endswith("Z")
    assert created.display == "0000 0000 0001 8"
    with pytest.raises(patient_id.InvalidPatientIdError):
        registry.get("0000 0000 0001 8")
    with pytest.raises(patient_id.PatientIdNotFoundError):
        registry.get("0000000000000")


def test_collision_retries_and_keeps_a_single_active_row(registry, monkeypatch):
    sequence = iter(["1234567890128", "1234567890128", "0000000000018"])
    monkeypatch.setattr(patient_id, "generate_patient_id", lambda: next(sequence))

    first = registry.register()
    second = registry.register()

    assert first.nemras_id == "1234567890128"
    assert second.nemras_id == "0000000000018"
    assert registry.get(first.nemras_id).status == patient_id.STATUS_ACTIVE
    with sqlite3.connect(registry.database_path) as connection:
        count = connection.execute("SELECT COUNT(*) FROM patient_id").fetchone()[0]
    assert count == 2


def test_retired_id_stays_reserved_and_is_not_reissued(registry, monkeypatch):
    sequence = iter(["0000000000018", "0000000000018", "1234567890128"])
    monkeypatch.setattr(patient_id, "generate_patient_id", lambda: next(sequence))

    original = registry.register()
    retired = registry.retire(original.nemras_id)
    again = registry.retire(original.nemras_id)
    replacement = registry.register()

    assert retired.status == patient_id.STATUS_RETIRED
    assert again == retired
    assert retired.created_at == original.created_at
    assert replacement.nemras_id == "1234567890128"
    assert registry.get(original.nemras_id).status == patient_id.STATUS_RETIRED
    with sqlite3.connect(registry.database_path) as connection:
        with pytest.raises(sqlite3.IntegrityError):
            connection.execute(
                """
                INSERT INTO patient_id (nemras_id, status, created_at)
                VALUES (?, 'active', '2026-01-01T00:00:00Z')
                """,
                (original.nemras_id,),
            )


def test_allocation_stops_when_every_attempt_collides(registry, monkeypatch):
    monkeypatch.setattr(
        patient_id, "generate_patient_id", lambda: "1234567890128"
    )
    reserved = registry.register()

    with pytest.raises(patient_id.PatientIdAllocationError):
        registry.register(max_attempts=3)

    assert registry.get(reserved.nemras_id) == reserved


def test_invalid_generated_value_is_not_inserted(registry, monkeypatch):
    monkeypatch.setattr(patient_id, "generate_patient_id", lambda: "not-an-id")

    with pytest.raises(patient_id.InvalidPatientIdError):
        registry.register()

    with sqlite3.connect(registry.database_path) as connection:
        count = connection.execute("SELECT COUNT(*) FROM patient_id").fetchone()[0]
    assert count == 0


def test_concurrent_registration_reserves_distinct_ids(registry):
    with ThreadPoolExecutor(max_workers=4) as pool:
        records = list(pool.map(lambda _index: registry.register(), range(4)))

    assert len({record.nemras_id for record in records}) == 4
    for record in records:
        assert registry.get(record.nemras_id) == record


def test_concurrent_collision_retries_without_duplicating_the_row(
    registry, monkeypatch
):
    values = ["1111111111112", "1111111111112", "2222222222224", "3333333333336"]
    assert patient_id.is_valid_patient_id(values[0])
    assert patient_id.is_valid_patient_id(values[2])
    assert patient_id.is_valid_patient_id(values[3])
    cursor = {"index": 0}
    lock = threading.Lock()

    def fake_generate():
        with lock:
            value = values[cursor["index"]]
            cursor["index"] += 1
            return value

    monkeypatch.setattr(patient_id, "generate_patient_id", fake_generate)

    with ThreadPoolExecutor(max_workers=2) as pool:
        records = list(pool.map(lambda _index: registry.register(), range(2)))

    issued = {record.nemras_id for record in records}
    assert len(issued) == 2
    assert "1111111111112" in issued
    with sqlite3.connect(registry.database_path) as connection:
        count = connection.execute(
            """
            SELECT COUNT(*) FROM patient_id
            WHERE nemras_id = '1111111111112'
            """
        ).fetchone()[0]
    assert count == 1


def test_reopening_the_registry_keeps_existing_rows(tmp_path):
    path = tmp_path / "nested" / "patient_ids.sqlite3"
    first = patient_id.PatientIdRegistry.create(path)
    created = first.register()

    reopened = patient_id.PatientIdRegistry(path)
    reopened.initialize_schema()

    assert reopened.get(created.nemras_id) == created
    assert path.is_file()


def test_missing_parent_is_not_created_unless_requested(tmp_path):
    path = tmp_path / "missing" / "patient_ids.sqlite3"
    registry = patient_id.PatientIdRegistry(path)

    with pytest.raises(patient_id.PatientIdConfigurationError):
        registry.initialize_schema()

    assert not path.parent.exists()


def test_database_path_defaults_under_backend_runtime_and_can_be_overridden(
    monkeypatch, tmp_path
):
    monkeypatch.delenv(patient_id.PATIENT_ID_DB_PATH_ENV, raising=False)
    default_path = patient_id.configured_database_path()

    assert default_path == (
        Path(patient_id.__file__).resolve().parent
        / "runtime"
        / "patient_id_registry.sqlite3"
    )
    assert default_path.is_absolute()

    override = tmp_path / "override.sqlite3"
    monkeypatch.setenv(patient_id.PATIENT_ID_DB_PATH_ENV, str(override))
    assert patient_id.configured_database_path() == override

    monkeypatch.setenv(
        patient_id.PATIENT_ID_DB_PATH_ENV, "runtime/patient_id_registry.sqlite3"
    )
    with pytest.raises(patient_id.PatientIdConfigurationError):
        patient_id.configured_database_path()

    monkeypatch.setenv(patient_id.PATIENT_ID_DB_PATH_ENV, str(tmp_path))
    with pytest.raises(patient_id.PatientIdConfigurationError):
        patient_id.configured_database_path()


def test_module_does_not_reference_the_patient_dataset():
    source = Path(patient_id.__file__).read_text(encoding="utf-8")

    assert "NEMRAS_Dataset" not in source
    assert "read_csv" not in source


def test_sqlite_registry_satisfies_the_storage_protocol(registry):
    store: patient_id.PatientIdStore = registry

    assert isinstance(registry, patient_id.PatientIdStore)
    created = store.register()
    found = store.get(created.nemras_id)
    retired = store.retire(created.nemras_id)

    assert found == created
    assert retired.status == patient_id.STATUS_RETIRED
    assert retired.created_at == created.created_at
    assert store.get(created.nemras_id).status == patient_id.STATUS_RETIRED


def test_oracle_registry_script_is_unapplied_and_constrained():
    source = ORACLE_REGISTRY_SQL.read_text(encoding="utf-8")
    executable = _executable_sql(source)

    assert "UNAPPLIED" in source
    assert "ORA-00955" in source
    assert "UTC" in source
    assert "SQL*Plus" in source
    assert executable.count("CREATE TABLE") == 1
    assert "CREATE TABLE NEMRAS_ID_REGISTRY" in executable
    assert "CHAR(13)" in executable
    assert "PRIMARY KEY (NEMRAS_ID)" in executable
    assert "REGEXP_LIKE(NEMRAS_ID, '^[0-9]{13}$')" in executable
    assert "STATUS IN ('ACTIVE', 'RETIRED')" in executable
    assert "TIMESTAMP(6) WITH TIME ZONE" in executable
    assert "EXTRACT(TIMEZONE_HOUR FROM CREATED_AT) = 0" in executable
    assert "NUMBER" not in executable

    for prohibited in (
        "CREATE SEQUENCE",
        "CREATE TRIGGER",
        "GENERATED ALWAYS",
        "GENERATED BY DEFAULT",
        "DROP TABLE",
        "DELETE FROM",
        "CNIC",
        "CREATE TABLE PATIENT",
        "IDENTITY",
    ):
        assert prohibited not in executable


def _executable_sql(source: str) -> str:
    """Return SQL with comments removed, so documentation can name forbidden DDL."""
    without_blocks = re.sub(r"/\*.*?\*/", " ", source, flags=re.DOTALL)
    lines = []
    for line in without_blocks.splitlines():
        comment_at = line.find("--")
        if comment_at >= 0:
            line = line[:comment_at]
        lines.append(line)
    return " ".join(lines).upper()
