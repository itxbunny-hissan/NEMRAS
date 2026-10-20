"""Static checks for the unapplied PostgreSQL patient-ID registry script.

This test reads the SQL file only. It does not connect to a database and it
does not read patient records.
"""

from pathlib import Path
import re


REGISTRY_SQL = (
    Path(__file__).resolve().parents[1]
    / "sql"
    / "postgresql"
    / "001_nemras_id_registry.sql"
)


def test_postgresql_registry_script_is_unapplied_and_constrained():
    source = REGISTRY_SQL.read_text(encoding="utf-8")
    executable = _strip_sql_comments(source)
    folded = executable.upper()

    assert "UNAPPLIED" in source
    assert "does not change the SQLite registry" in source
    assert "UTC" in source
    assert "42P07" in source
    assert executable.count("CREATE TABLE") == 1
    assert "CREATE TABLE nemras_id_registry" in executable
    assert (
        "nemras_id TEXT CONSTRAINT nemras_id_registry_pk PRIMARY KEY"
        in executable
    )
    assert "status TEXT NOT NULL" in executable
    assert "created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP" in executable
    assert "CONSTRAINT nemras_id_registry_id_digits CHECK (nemras_id ~ '^[0-9]{13}$')" in executable
    assert "CONSTRAINT nemras_id_registry_status CHECK (status IN ('active', 'retired'))" in executable
    assert "'ACTIVE'" not in executable
    assert "'RETIRED'" not in executable

    for prohibited in (
        "INTEGER",
        "BIGINT",
        "SMALLINT",
        "SERIAL",
        "BIGSERIAL",
        "IDENTITY",
        "SEQUENCE",
        "NEXTVAL",
        "GENERATED",
        "DELETE",
        "DROP",
        "TRUNCATE",
        "VARCHAR2",
        "REGEXP_LIKE",
        "NUMBER",
        "CHAR(13)",
        "SQL*PLUS",
        "ORA-",
        "SYSTIMESTAMP",
        "ROWNUM",
        "CREATE TABLE PATIENT",
        "CREATE TABLE ENCOUNTER",
        "CREATE TABLE ALLERGY",
        "CREATE TABLE OBSERVATION",
        "CREATE TABLE AUDIT",
        "SQLITE",
        "NEMRAS_DATASET",
    ):
        assert prohibited not in folded


def _strip_sql_comments(source: str) -> str:
    """Return SQL with comments removed and whitespace collapsed."""
    without_blocks = re.sub(r"/\*.*?\*/", " ", source, flags=re.DOTALL)
    lines = []
    for line in without_blocks.splitlines():
        comment_at = line.find("--")
        if comment_at >= 0:
            line = line[:comment_at]
        lines.append(line)
    return re.sub(r"\s+", " ", " ".join(lines)).strip()
