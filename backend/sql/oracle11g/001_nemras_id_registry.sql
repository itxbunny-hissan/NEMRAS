-- NEMRAS Patient ID registry
-- Target: Oracle Database 11g Release 2
-- Status: UNAPPLIED. The NEMRAS application does not execute this file.
--
-- A row in this table is a record locator. It does not authenticate a person
-- and it does not grant access to a medical record.
--
-- Review before applying
--   1. Read the whole script.
--   2. Confirm the session is connected to the intended Oracle 11.2 instance
--      and schema. This file contains no host, username, or password.
--   3. Confirm the table is absent:
--        SELECT table_name
--          FROM user_tables
--         WHERE table_name = 'NEMRAS_ID_REGISTRY';
--
-- Apply later, manually, from the backend directory in SQL*Plus:
--   SQL> @sql/oracle11g/001_nemras_id_registry.sql
-- SQL Developer can run the same file from an explicitly opened connection.
--
-- Rerun guidance
--   This script does not drop, truncate, or delete anything.
--   If NEMRAS_ID_REGISTRY already exists, Oracle raises ORA-00955 and leaves
--   the existing table and its rows unchanged. Stop there. Do not add a drop
--   statement to make a second run succeed.
--
-- Storage
--   nemras_id is CHAR(13), not a number, so all 13 digits and any leading
--   zeros are preserved. Python generates the value and validates the Luhn
--   check digit before insert. The database rejects a value that is not 13
--   digits.
--   status is ACTIVE or RETIRED. The Python protocol currently uses the
--   lowercase words active and retired. A future adapter maps those values.
--   This script does not change the SQLite registry.
--   created_at is TIMESTAMP(6) WITH TIME ZONE. The check constraint requires
--   a UTC offset: time-zone hour 0 and time-zone minute 0. Python writes an
--   ISO-8601 UTC instant; the future adapter binds it with offset +00:00.
--
-- Intentionally absent
--   No identity column, sequence, trigger, patient table, or national-ID
--   column. Retired identifiers are not deleted.

CREATE TABLE nemras_id_registry (
    nemras_id   CHAR(13)                      NOT NULL,
    status      VARCHAR2(8 CHAR)              NOT NULL,
    created_at  TIMESTAMP(6) WITH TIME ZONE   NOT NULL,
    CONSTRAINT nemras_id_registry_pk
        PRIMARY KEY (nemras_id),
    CONSTRAINT nemras_id_registry_id_digits
        CHECK (REGEXP_LIKE(nemras_id, '^[0-9]{13}$')),
    CONSTRAINT nemras_id_registry_status
        CHECK (status IN ('ACTIVE', 'RETIRED')),
    CONSTRAINT nemras_id_registry_created_utc
        CHECK (
            EXTRACT(TIMEZONE_HOUR FROM created_at) = 0
            AND EXTRACT(TIMEZONE_MINUTE FROM created_at) = 0
        )
);

COMMENT ON TABLE nemras_id_registry IS
    'Issued NEMRAS Patient IDs. A row locates a record slot and does not grant access.';

COMMENT ON COLUMN nemras_id_registry.nemras_id IS
    'Canonical 13-digit locator. CHAR(13) preserves leading zeros. Never reused.';

COMMENT ON COLUMN nemras_id_registry.status IS
    'ACTIVE or RETIRED. A retired identifier stays in the table.';

COMMENT ON COLUMN nemras_id_registry.created_at IS
    'UTC creation time. The stored offset must be +00:00.';
