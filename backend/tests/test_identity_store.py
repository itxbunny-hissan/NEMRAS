"""Isolated tests for the A2 SQLite identity-store foundation."""

from concurrent.futures import ThreadPoolExecutor
import logging
from pathlib import Path
import sqlite3

import pytest

import identity_store


UID_A = "firebase-uid-a"
UID_B = "firebase-uid-b"
CNIC_A = "00000-0000001-0"
CNIC_B = "00000-0000002-0"
STRONG_KEY_A = "a" * identity_store.MIN_HMAC_KEY_BYTES
STRONG_KEY_B = "b" * identity_store.MIN_HMAC_KEY_BYTES


@pytest.fixture
def store(tmp_path):
    value = identity_store.IdentityStore(tmp_path / "identity.sqlite3")
    value.initialize_schema()
    return value


def test_schema_initializes_with_safety_pragmas(tmp_path):
    path = tmp_path / "identity.sqlite3"
    store = identity_store.IdentityStore(path)

    store.initialize_schema()

    with sqlite3.connect(path) as connection:
        columns = {
            row[1]: row for row in connection.execute(
                "PRAGMA table_info(identity_binding)"
            )
        }
        journal_mode = connection.execute("PRAGMA journal_mode").fetchone()[0]
        foreign_keys = connection.execute("PRAGMA foreign_keys").fetchone()[0]

    assert set(columns) == {"uid", "cnic", "created_at", "updated_at"}
    assert columns["uid"][5] == 1  # PRIMARY KEY
    assert journal_mode.lower() == "wal"
    # foreign_keys is connection-local, so prove the store enables it directly.
    with store._connect() as connection:
        assert connection.execute("PRAGMA foreign_keys").fetchone()[0] == 1


def test_database_path_configuration_is_required(monkeypatch):
    monkeypatch.delenv(identity_store.IDENTITY_DB_PATH_ENV, raising=False)

    with pytest.raises(identity_store.StoreConfigurationError):
        identity_store.IdentityStore.from_environment()


def test_relative_database_path_is_rejected(monkeypatch):
    monkeypatch.setenv(identity_store.IDENTITY_DB_PATH_ENV, "relative/store.db")

    with pytest.raises(identity_store.StoreConfigurationError):
        identity_store.IdentityStore.from_environment()


def test_missing_parent_is_not_created_without_explicit_permission(tmp_path):
    path = tmp_path / "not-created" / "identity.sqlite3"
    store = identity_store.IdentityStore(path)

    with pytest.raises(identity_store.StoreConfigurationError):
        store.initialize_schema()

    assert not path.parent.exists()


def test_parent_can_be_created_when_explicitly_permitted(tmp_path):
    path = tmp_path / "permitted" / "identity.sqlite3"
    store = identity_store.IdentityStore(path)

    store.initialize_schema(create_parent=True)

    assert path.is_file()


def test_uid_and_cnic_have_database_level_unique_constraints(store):
    store.create_binding(UID_A, CNIC_A)

    with sqlite3.connect(store._path) as connection:
        indexes = list(connection.execute("PRAGMA index_list(identity_binding)"))

    unique_indexes = [row for row in indexes if row[2] == 1]
    assert len(unique_indexes) == 2


def test_duplicate_uid_is_rejected(store):
    store.create_binding(UID_A, CNIC_A)

    with pytest.raises(identity_store.DuplicateUidError):
        store.create_binding(UID_A, CNIC_B)

    assert store.get_binding_by_uid(UID_A).cnic == CNIC_A
    assert not store.is_cnic_bound(CNIC_B)


def test_duplicate_cnic_is_rejected(store):
    store.create_binding(UID_A, CNIC_A)

    with pytest.raises(identity_store.DuplicateCnicError):
        store.create_binding(UID_B, CNIC_A)

    assert not store.is_uid_bound(UID_B)
    assert store.get_binding_by_uid(UID_A).cnic == CNIC_A


def test_successful_binding_can_be_retrieved_by_uid(store):
    created = store.create_binding(UID_A, CNIC_A)

    found = store.get_binding_by_uid(UID_A)

    assert found == created
    assert found.created_at.endswith("Z")
    assert found.updated_at == found.created_at
    assert store.is_uid_bound(UID_A)
    assert store.is_cnic_bound(CNIC_A)


def test_missing_binding_is_explicit(store):
    with pytest.raises(identity_store.BindingNotFoundError):
        store.get_binding_by_uid("uid-with-no-binding")


def test_failed_binding_transaction_leaves_no_partial_row(store):
    # A trigger forces SQLite to abort the INSERT after transaction start.
    # This exercises the rollback path without relying on duplicate handling.
    with sqlite3.connect(store._path) as connection:
        connection.execute(
            """
            CREATE TRIGGER reject_all_bindings
            BEFORE INSERT ON identity_binding
            BEGIN
                SELECT RAISE(ABORT, 'forced test failure');
            END
            """
        )

    with pytest.raises(identity_store.StoreUnavailableError):
        store.create_binding(UID_A, CNIC_A)

    assert not store.is_uid_bound(UID_A)
    assert not store.is_cnic_bound(CNIC_A)


def test_concurrent_attempts_create_exactly_one_binding(store):
    def bind(uid):
        try:
            store.create_binding(uid, CNIC_A)
            return "created"
        except identity_store.DuplicateCnicError:
            return "duplicate"

    with ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(bind, (UID_A, UID_B)))

    assert sorted(results) == ["created", "duplicate"]
    assert sum(store.is_uid_bound(uid) for uid in (UID_A, UID_B)) == 1


def test_hmac_is_deterministic_for_same_identifier_and_key():
    first = identity_store.pseudonymous_reference(
        CNIC_A, purpose="audit-subject", key=STRONG_KEY_A
    )
    second = identity_store.pseudonymous_reference(
        CNIC_A, purpose="audit-subject", key=STRONG_KEY_A
    )

    assert first == second
    assert len(first) == 64


def test_different_identifiers_produce_different_references():
    first = identity_store.pseudonymous_reference(
        CNIC_A, purpose="audit-subject", key=STRONG_KEY_A
    )
    second = identity_store.pseudonymous_reference(
        CNIC_B, purpose="audit-subject", key=STRONG_KEY_A
    )

    assert first != second


def test_different_keys_produce_different_references():
    first = identity_store.pseudonymous_reference(
        CNIC_A, purpose="audit-subject", key=STRONG_KEY_A
    )
    second = identity_store.pseudonymous_reference(
        CNIC_A, purpose="audit-subject", key=STRONG_KEY_B
    )

    assert first != second


def test_hmac_purpose_domain_separates_references():
    audit = identity_store.pseudonymous_reference(
        CNIC_A, purpose="audit-subject", key=STRONG_KEY_A
    )
    phone = identity_store.pseudonymous_reference(
        CNIC_A, purpose="phone-reference", key=STRONG_KEY_A
    )

    assert audit != phone


@pytest.mark.parametrize("key", [None, "", "short", b"x" * 31])
def test_missing_or_weak_hmac_key_fails_closed(monkeypatch, key):
    monkeypatch.delenv(identity_store.HMAC_KEY_ENV, raising=False)

    with pytest.raises(identity_store.InvalidHmacKeyError):
        identity_store.pseudonymous_reference(
            CNIC_A, purpose="audit-subject", key=key
        )


def test_hmac_key_can_come_from_environment(monkeypatch):
    monkeypatch.setenv(identity_store.HMAC_KEY_ENV, STRONG_KEY_A)

    reference = identity_store.pseudonymous_reference(
        CNIC_A, purpose="audit-subject"
    )

    assert len(reference) == 64


def test_exception_messages_and_logs_do_not_include_raw_identifiers_or_key(
    store, caplog
):
    weak_secret = "unique-secret-value"
    raw_uid = "unique-private-uid"
    raw_cnic = "99999-9999999-9"
    store.create_binding(raw_uid, raw_cnic)

    caplog.set_level(logging.DEBUG)
    with pytest.raises(identity_store.DuplicateUidError) as caught:
        store.create_binding(raw_uid, CNIC_B)
    with pytest.raises(identity_store.InvalidHmacKeyError) as hmac_caught:
        identity_store.pseudonymous_reference(
            raw_cnic, purpose="audit-subject", key=weak_secret
        )

    combined = " ".join(
        [str(caught.value), str(hmac_caught.value), caplog.text]
    )
    assert raw_uid not in combined
    assert raw_cnic not in combined
    assert weak_secret not in combined


def test_store_never_creates_token_or_phone_columns(store):
    with sqlite3.connect(store._path) as connection:
        columns = {
            row[1] for row in connection.execute(
                "PRAGMA table_info(identity_binding)"
            )
        }

    assert "token" not in columns
    assert "phone" not in columns
    assert columns == {"uid", "cnic", "created_at", "updated_at"}
