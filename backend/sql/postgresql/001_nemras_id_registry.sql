-- NEMRAS Patient ID registry
-- Target: PostgreSQL
-- Status: UNAPPLIED. The NEMRAS application does not execute this file.
--
-- A row in this table is a record locator. It does not authenticate a person
-- and it does not grant access to a medical record.
--
-- This script does not change the SQLite registry. SQLite remains the
-- running store.
--
-- Review before applying
--   1. Read the whole script.
--   2. Confirm the session is the intended PostgreSQL database and schema.
--      This file contains no host, username, or password.
--   3. Confirm the table is absent:
--        SELECT table_name
--          FROM information_schema.tables
--         WHERE table_schema = current_schema()
--           AND table_name = 'nemras_id_registry';
--
-- Apply later, manually, from the backend directory:
--   psql -d <database-name> -f sql/postgresql/001_nemras_id_registry.sql
--
-- Rerun guidance
--   This script does not remove an existing table or its rows.
--   If nemras_id_registry already exists, PostgreSQL raises SQLSTATE 42P07
--   and leaves the existing rows in place. Stop there.
--
-- Storage
--   nemras_id is TEXT, not a numeric type, so all 13 digits and any leading
--   zeros are preserved. Python generates the value and validates the Luhn
--   check digit before insert. The check below rejects any value that is
--   not exactly 13 ASCII digits.
--   status is active or retired, the same words the Python registry stores.
--   created_at is TIMESTAMPTZ. PostgreSQL stores that type in UTC.
--   CURRENT_TIMESTAMP is the UTC-compatible default used only when an insert
--   omits the column. A future adapter should still bind an explicit UTC
--   instant.
--
-- Intentionally absent
--   No database-assigned identifier, no clinical tables, and no statement
--   that removes a retired identifier.

CREATE TABLE nemras_id_registry (
    nemras_id   TEXT
        CONSTRAINT nemras_id_registry_pk PRIMARY KEY,
    status      TEXT        NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT nemras_id_registry_id_digits
        CHECK (nemras_id ~ '^[0-9]{13}$'),
    CONSTRAINT nemras_id_registry_status
        CHECK (status IN ('active', 'retired'))
);

COMMENT ON TABLE nemras_id_registry IS
    'Issued NEMRAS Patient IDs. A row locates a record slot and does not grant access.';

COMMENT ON COLUMN nemras_id_registry.nemras_id IS
    'Canonical 13-digit locator stored as text so leading zeros are preserved. Never reused.';

COMMENT ON COLUMN nemras_id_registry.status IS
    'active or retired. A retired identifier stays in the table.';

COMMENT ON COLUMN nemras_id_registry.created_at IS
    'Creation time as timestamptz. PostgreSQL stores this value in UTC.';
