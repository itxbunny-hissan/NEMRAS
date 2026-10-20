"""
Phase 0 backend tests.

Covers only what Phase 0 changed: the health endpoint, the lifespan-based
startup, basic error handling, and the guarantee that raw phone numbers are
never served by /api/auth/phone/{cnic}.
"""

import main


# ------------------------------------------------------------------
# Health / startup (lifespan)
# ------------------------------------------------------------------
def test_health_reports_loaded_dataset(client):
    response = client.get("/health")
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ok"
    assert body["dataset_loaded"] is True
    assert body["records"] > 0
    assert body["error"] is None


def test_lifespan_loaded_data_into_memory():
    # The lifespan handler replaced the deprecated on_event("startup") hook.
    assert not main.DF.empty


def test_root_contract_unchanged(client):
    response = client.get("/")
    assert response.status_code == 200
    assert response.json().keys() >= {"service", "records", "status"}
    assert response.json()["status"] == "ok"


# ------------------------------------------------------------------
# Error handling
# ------------------------------------------------------------------
def test_unknown_cnic_returns_404(client):
    response = client.get("/api/patient/00000-0000000-0")
    assert response.status_code == 404


def test_sample_rejects_out_of_range_n(client):
    assert client.get("/api/patients/sample", params={"n": 0}).status_code == 422
    assert client.get("/api/patients/sample", params={"n": 999}).status_code == 422


def test_chat_rejects_empty_message(client, known_cnic):
    response = client.post("/api/chat", json={"cnic": known_cnic, "message": "   "})
    assert response.status_code == 400


def test_chat_unknown_cnic_returns_404(client):
    response = client.post(
        "/api/chat", json={"cnic": "00000-0000000-0", "message": "allergies?"}
    )
    assert response.status_code == 404


# ------------------------------------------------------------------
# Phone registry security
# ------------------------------------------------------------------
def test_phone_endpoint_never_returns_raw_number(client, known_cnic):
    response = client.get(f"/api/auth/phone/{known_cnic}")
    assert response.status_code == 200
    body = response.json()
    assert "phone" not in body
    assert set(body) == {"cnic", "has_phone", "masked_phone"}


def test_registered_cnic_exposes_only_a_masked_hint(client):
    registered = [c for c in main.PHONE_REGISTRY if not c.startswith("_")]
    if not registered:
        return
    cnic = registered[0]
    response = client.get(f"/api/auth/phone/{cnic}")
    if response.status_code == 404:
        return  # registry entry is not in the dataset
    body = response.json()
    assert "phone" not in body
    if body["has_phone"]:
        assert "*" in body["masked_phone"]
        raw_digits = "".join(
            ch for ch in main.PHONE_REGISTRY[cnic]["phone"] if ch.isdigit()
        )
        assert raw_digits not in response.text


def test_phone_registry_skips_documentation_keys():
    assert all(not key.startswith("_") for key in main.load_phone_registry())


def test_mask_phone_keeps_at_most_four_digits():
    masked = main.mask_phone("+923000000000")
    assert masked == "+92********00"
    assert sum(ch.isdigit() for ch in masked) == 4


def test_mask_phone_rejects_too_short_values():
    assert main.mask_phone("123") is None


def _synthetic_alert_row(risk_score: str):
    """A fabricated row. It is not a dataset record and has no patient identifier."""
    return {
        "Allergy": "None",
        "Drug_Interaction_Risk": "No",
        "Medication": "Synthetic",
        "Risk_Score": risk_score,
        "Chronic_Condition": "No",
        "Medical_Condition": "Synthetic",
    }


def test_risk_alerts_describe_the_dataset_label():
    """Risk tiers come from the Risk_Score column, not from a trained model."""
    import pandas as pd

    critical = main.build_alerts(pd.Series(_synthetic_alert_row("Critical")))
    elevated = main.build_alerts(pd.Series(_synthetic_alert_row("Elevated")))
    stable = main.build_alerts(pd.Series(_synthetic_alert_row("Stable")))

    critical_alert = next(a for a in critical if a["title"] == "Critical Risk Tier")
    elevated_alert = next(a for a in elevated if a["title"] == "Elevated Risk Tier")

    assert critical_alert["severity"] == "critical"
    assert elevated_alert["severity"] == "high"
    assert critical_alert["detail"] == (
        "The dataset risk label for this patient is Critical. "
        "Recommend ICU pre-allocation and specialist activation."
    )
    assert elevated_alert["detail"] == (
        "The dataset risk label for this patient is Elevated. "
        "Prioritise assessment."
    )

    rendered = " ".join(alert["detail"] for alert in critical + elevated + stable)
    assert "AI risk model" not in rendered
    assert "ai risk model" not in rendered.lower()
    assert all(alert["title"] not in {"Critical Risk Tier", "Elevated Risk Tier"} for alert in stable)
