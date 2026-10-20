"""
NEMRAS Backend API
National Emergency Medical Record Access System
FastAPI service backed by the real NEMRAS_Dataset.csv (64,182 patient records).

Run:
    pip install -r requirements.txt
    uvicorn main:app --reload --host 0.0.0.0 --port 8000

Docs available at http://localhost:8000/docs
Health probe at http://localhost:8000/health

Tests:
    pip install -r requirements-dev.txt
    pytest
"""

from contextlib import asynccontextmanager
from fastapi import Depends, FastAPI, HTTPException, Query, Response
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List, Tuple
import pandas as pd
import numpy as np
import logging
import os
import json
import threading

import auth
import patient_id
import patient_id_issuance

logger = logging.getLogger("nemras")

DATA_PATH = os.path.join(os.path.dirname(__file__), "NEMRAS_Dataset.csv")
PHONE_REGISTRY_PATH = os.path.join(os.path.dirname(__file__), "phone_registry.json")

# ------------------------------------------------------------------
# In-memory state (loaded once at startup, kept in memory for fast lookup)
# ------------------------------------------------------------------
DF: pd.DataFrame = pd.DataFrame()
PHONE_REGISTRY: dict = {}
DATA_LOAD_ERROR: Optional[str] = None


def load_data() -> pd.DataFrame:
    # NEMRAS_Dataset.csv is read-only source data - never written back to.
    df = pd.read_csv(DATA_PATH)
    # CNIC is the unique key for patient lookup (one row per patient in this dataset).
    df["CNIC"] = df["CNIC"].astype(str).str.strip()
    return df


def load_phone_registry() -> dict:
    """
    Development-only CNIC -> contact mapping used to decide whether a CNIC is
    eligible for OTP delivery. Keys beginning with "_" are documentation and
    are skipped.

    TODO(production-auth): replace this JSON file with the authenticated
    identity mapping (database + Firebase Authentication UID). Raw phone
    numbers must never be served to clients, and OTP values must never be
    stored here or in Firestore.
    """
    if not os.path.exists(PHONE_REGISTRY_PATH):
        return {}
    try:
        with open(PHONE_REGISTRY_PATH, "r", encoding="utf-8") as f:
            raw = json.load(f)
    except (OSError, json.JSONDecodeError) as exc:
        logger.error("[NEMRAS] Could not read phone registry: %s", exc)
        return {}
    return {k: v for k, v in raw.items() if not k.startswith("_")}


@asynccontextmanager
async def lifespan(_app: FastAPI):
    """Replaces the deprecated @app.on_event("startup") handler."""
    global DF, PHONE_REGISTRY, DATA_LOAD_ERROR
    try:
        DF = load_data()
        DATA_LOAD_ERROR = None
        print(f"[NEMRAS] Loaded {len(DF):,} patient records from {DATA_PATH}")
    except Exception as exc:  # noqa: BLE001 - surfaced via /health and 503s
        DF = pd.DataFrame()
        DATA_LOAD_ERROR = f"{type(exc).__name__}: {exc}"
        logger.error("[NEMRAS] Failed to load dataset: %s", DATA_LOAD_ERROR)

    PHONE_REGISTRY = load_phone_registry()
    print(f"[NEMRAS] Phone registry: {len(PHONE_REGISTRY)} registered numbers")
    yield


app = FastAPI(
    title="NEMRAS API",
    description="National Emergency Medical Record Access System - demo backend",
    version="1.0.0",
    lifespan=lifespan,
)

# Allow Flutter (mobile/web/desktop) to call the API during development.
# TODO(production): restrict allow_origins to the deployed NEMRAS clients.
#
# Credentials stay off: clients authenticate with an Authorization: Bearer
# header, never cookies. With a wildcard origin, allow_credentials=True makes
# Starlette echo any requesting origin back as trusted.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------
RISK_RANK = {"Stable": 0, "Elevated": 1, "Critical": 2}


def require_data() -> pd.DataFrame:
    """Guard so endpoints return 503 instead of crashing if the CSV never loaded."""
    if DF.empty:
        raise HTTPException(
            status_code=503,
            detail="Patient dataset is not loaded. Check the NEMRAS backend logs.",
        )
    return DF


def mask_phone(phone: str) -> Optional[str]:
    """
    Reduce a stored number to a non-identifying hint (country code + last 2
    digits). Never return enough digits to reconstruct the number.
    """
    digits = "".join(ch for ch in str(phone) if ch.isdigit())
    if len(digits) < 6:
        return None
    return f"+{digits[:2]}{'*' * (len(digits) - 4)}{digits[-2:]}"


def _clean(value):
    """Convert pandas/numpy values into JSON-friendly Python types."""
    if value is None:
        return None
    if isinstance(value, float) and np.isnan(value):
        return None
    if isinstance(value, (np.integer,)):
        return int(value)
    if isinstance(value, (np.floating,)):
        return float(value)
    return value


def row_to_summary(row: pd.Series) -> dict:
    """The Critical Health Summary - the core 90-second emergency view."""
    return {
        "cnic": _clean(row["CNIC"]),
        "patient_name": _clean(row["Patient_Name"]),
        "age": _clean(row["Age"]),
        "gender": _clean(row["Gender"]),
        "blood_type": _clean(row["Blood_Type"]),
        "medical_condition": _clean(row["Medical_Condition"]),
        "medication": _clean(row["Medication"]),
        "allergy": _clean(row["Allergy"]),
        "chronic_condition": _clean(row["Chronic_Condition"]),
        "drug_interaction_risk": _clean(row["Drug_Interaction_Risk"]),
        "triage_level": _clean(row["Triage_Level"]),
        "risk_score": _clean(row["Risk_Score"]),
        "admission_type": _clean(row["Admission_Type"]),
        "admission_date": _clean(row["Admission_Date"]),
        "discharge_date": _clean(row["Discharge_Date"]),
        "test_results": _clean(row["Test_Results"]),
        "hospital": _clean(row["Hospital"]),
        "doctor": _clean(row["Doctor"]),
        "insurance_provider": _clean(row["Insurance_Provider"]),
    }


def build_alerts(row: pd.Series) -> List[dict]:
    """
    AI Decision Support layer.
    Generates point-of-care alerts from the patient's record - the kind a
    paramedic must see before administering anything.
    """
    alerts: List[dict] = []

    allergy = str(row["Allergy"]).strip()
    if allergy and allergy.lower() != "none":
        alerts.append({
            "severity": "critical",
            "title": f"Allergy: {allergy}",
            "detail": f"Patient has a documented {allergy} allergy. "
                      f"Avoid {allergy} and cross-reactive agents.",
        })

    if str(row["Drug_Interaction_Risk"]).strip().lower() == "yes":
        alerts.append({
            "severity": "high",
            "title": "Drug Interaction Risk",
            "detail": f"Current medication ({row['Medication']}) has known "
                      f"interaction flags. Verify before adding new drugs.",
        })

    if str(row["Risk_Score"]).strip() == "Critical":
        alerts.append({
            "severity": "critical",
            "title": "Critical Risk Tier",
            "detail": "The dataset risk label for this patient is Critical. "
                      "Recommend ICU pre-allocation and specialist activation.",
        })
    elif str(row["Risk_Score"]).strip() == "Elevated":
        alerts.append({
            "severity": "high",
            "title": "Elevated Risk Tier",
            "detail": "The dataset risk label for this patient is Elevated. "
                      "Prioritise assessment.",
        })

    if str(row["Chronic_Condition"]).strip().lower() == "yes":
        alerts.append({
            "severity": "info",
            "title": f"Chronic: {row['Medical_Condition']}",
            "detail": "Ongoing chronic condition - factor into treatment and discharge planning.",
        })

    if not alerts:
        alerts.append({
            "severity": "info",
            "title": "No critical flags",
            "detail": "No allergies, interactions, or critical risk on record.",
        })
    return alerts


# ------------------------------------------------------------------
# Response models
# ------------------------------------------------------------------
class ChatRequest(BaseModel):
    cnic: str
    message: str


# ------------------------------------------------------------------
# Routes
# ------------------------------------------------------------------
@app.get("/")
def root():
    # Response shape is unchanged - the Flutter client uses this as its ping.
    return {"service": "NEMRAS API", "records": len(DF), "status": "ok"}


@app.get("/health")
def health():
    """
    Liveness/readiness probe. Reports whether the dataset actually loaded so a
    half-started backend is visible instead of failing one request at a time.
    """
    ready = not DF.empty
    return {
        "status": "ok" if ready else "degraded",
        "dataset_loaded": ready,
        "records": int(len(DF)),
        "phone_registry_entries": len(PHONE_REGISTRY),
        "error": DATA_LOAD_ERROR,
    }


@app.get("/api/stats")
def stats():
    """Population-level numbers for the hospital / central dashboard."""
    df = require_data()

    def vc(col):
        return {str(k): int(v) for k, v in df[col].value_counts().items()}

    return {
        "total_patients": int(len(df)),
        "risk_score": vc("Risk_Score"),
        "triage_level": vc("Triage_Level"),
        "drug_interaction_risk": vc("Drug_Interaction_Risk"),
        "medical_condition": vc("Medical_Condition"),
        "admission_type": vc("Admission_Type"),
        "chronic_condition": vc("Chronic_Condition"),
        "avg_age": round(float(df["Age"].mean()), 1),
    }


@app.get("/api/patients/sample")
def sample_patients(n: int = Query(10, ge=1, le=50)):
    """A few real CNICs from the dataset so the demo always has valid logins."""
    df = require_data()
    cols = ["CNIC", "Patient_Name", "Age", "Medical_Condition", "Risk_Score"]
    sample = df[cols].head(n)
    return sample.to_dict(orient="records")


@app.get("/api/patient/{cnic}")
def get_patient(cnic: str):
    """Core lookup: scan/enter a CNIC -> Critical Health Summary + alerts."""
    df = require_data()
    cnic = cnic.strip()
    if not cnic:
        raise HTTPException(status_code=400, detail="CNIC must not be empty")
    match = df[df["CNIC"] == cnic]
    if match.empty:
        raise HTTPException(status_code=404, detail=f"No patient found for CNIC {cnic}")
    row = match.iloc[0]
    return {
        "summary": row_to_summary(row),
        "alerts": build_alerts(row),
    }


@app.get("/api/dashboard/critical")
def critical_patients(limit: int = Query(20, ge=1, le=100)):
    """Live emergency tracker feed - highest-risk patients first."""
    df = require_data().copy()
    df["rank"] = df["Risk_Score"].map(RISK_RANK).fillna(0)
    df = df.sort_values("rank", ascending=False).head(limit)
    cols = ["CNIC", "Patient_Name", "Age", "Medical_Condition",
            "Triage_Level", "Risk_Score", "Admission_Type", "Hospital"]
    return df[cols].to_dict(orient="records")


@app.post("/api/chat")
def chat(req: ChatRequest):
    """
    Patient chatbot - grounded ONLY in this patient's own record.
    Strictly informational. In production this routes to Claude API with the
    record as context; here it is a deterministic, record-grounded responder
    so the demo runs offline.
    """
    df = require_data()
    if not req.message.strip():
        raise HTTPException(status_code=400, detail="message must not be empty")
    match = df[df["CNIC"] == req.cnic.strip()]
    if match.empty:
        raise HTTPException(status_code=404, detail="Unknown CNIC")
    row = match.iloc[0]
    msg = req.message.lower()

    if any(w in msg for w in ["allerg"]):
        a = str(row["Allergy"])
        reply = (f"Your records show no known drug allergy." if a.lower() == "none"
                 else f"Your records list a {a} allergy. Always tell any clinician about this.")
    elif any(w in msg for w in ["medication", "medicine", "drug", "taking"]):
        reply = (f"Your record lists {row['Medication']} as your primary medication. "
                 f"Follow your prescribed dosage and ask your doctor before changing it.")
    elif any(w in msg for w in ["blood", "type", "group"]):
        reply = f"Your blood type on record is {row['Blood_Type']}."
    elif any(w in msg for w in ["condition", "diagnos", "disease", "wrong"]):
        reply = (f"Your primary recorded condition is {row['Medical_Condition']}. "
                 f"This is informational - please discuss details with your doctor.")
    elif any(w in msg for w in ["risk", "serious", "critical"]):
        reply = (f"Your current AI risk tier is {row['Risk_Score']} and triage level "
                 f"{row['Triage_Level']}. This helps the medical team prioritise care.")
    elif any(w in msg for w in ["emergency", "chest pain", "can't breathe", "cant breathe", "bleeding"]):
        reply = ("This sounds urgent. Please call emergency services or go to the nearest "
                 "ER immediately. I am informational only and cannot handle emergencies.")
    else:
        reply = (f"I can explain what's in your NEMRAS record - your condition "
                 f"({row['Medical_Condition']}), medication ({row['Medication']}), "
                 f"allergies, or blood type. What would you like to know? "
                 f"I am informational only and do not diagnose or prescribe.")

    return {"reply": reply, "grounded_on_cnic": req.cnic}


@app.get("/api/auth/phone/{cnic}")
def get_phone(cnic: str):
    """
    Reports whether a CNIC has a contact number registered for OTP delivery,
    and returns a masked hint the patient can recognise ("+92********93").

    The raw phone number is NEVER returned. Clients must not need it: OTP
    delivery is the identity provider's job, not the client's.

    TODO(production-auth): the client will call Firebase Authentication to send
    the OTP, and the backend will resolve CNIC -> Firebase UID server-side from
    the authenticated identity store. Until then this endpoint only confirms
    eligibility. OTP values are never generated, returned or stored here.

    404 if the CNIC is not in the dataset; 200 with has_phone=false otherwise.
    """
    df = require_data()
    cnic = cnic.strip()
    if df[df["CNIC"] == cnic].empty:
        raise HTTPException(status_code=404, detail=f"No patient found for CNIC {cnic}")
    entry = PHONE_REGISTRY.get(cnic)
    if entry and entry.get("phone"):
        return {
            "cnic": cnic,
            "has_phone": True,
            "masked_phone": mask_phone(entry["phone"]),
        }
    return {"cnic": cnic, "has_phone": False, "masked_phone": None}


# ------------------------------------------------------------------
# /api/v1 - authenticated surface
#
# New endpoints are versioned. The unversioned routes above keep their current
# behaviour unchanged, including their current lack of authentication, until a
# migration is approved. Do not read the presence of this section as securing
# them.
# ------------------------------------------------------------------
class IdentityResponse(BaseModel):
    uid: str
    binding_status: str
    bound: bool
    detail: str


@app.get("/api/v1/me/identity", response_model=IdentityResponse)
def me_identity(
    caller: auth.CallerIdentity = Depends(auth.verify_caller),
) -> IdentityResponse:
    """
    Report the caller's verified identity (Firebase UID, or ``supabase:<uuid>``).

    Takes no parameters by design: the UID comes from the verified ID token,
    never from the client. Returns no patient or personal data - the CNIC
    binding that would authorise record access does not exist yet.
    """
    return IdentityResponse(
        uid=caller.uid,
        binding_status="not_implemented",
        bound=False,
        detail=(
            "CNIC binding is not implemented yet. This endpoint reports "
            "authenticated identity only and grants no record access."
        ),
    )


# ------------------------------------------------------------------
# NEMRAS Patient ID issuance
#
# Issues one Patient ID per verified Firebase UID. The ID locates a future
# record slot only: it is not bound to a CNIC and opens no patient record.
# ------------------------------------------------------------------
_issuance_lock = threading.Lock()
_issuance_backends: Optional[
    Tuple[patient_id_issuance.PatientIdIssuanceLedger, patient_id.PatientIdStore]
] = None


def patient_id_issuance_backends() -> Tuple[
    patient_id_issuance.PatientIdIssuanceLedger, patient_id.PatientIdStore
]:
    """
    Open the issuance ledger and the configured Patient ID registry once.

    The registry comes from open_patient_id_registry(), which never falls back
    from PostgreSQL to SQLite. Only a SQLite registry has its schema created
    here; PostgreSQL DDL stays a manual step. A failure is not cached, so the
    next request tries again.
    """
    global _issuance_backends
    with _issuance_lock:
        if _issuance_backends is not None:
            return _issuance_backends
        registry = patient_id.open_patient_id_registry()
        if isinstance(registry, patient_id.PatientIdRegistry):
            registry.initialize_schema(create_parent=True)
        ledger = patient_id_issuance.PatientIdIssuanceLedger()
        ledger.initialize_schema(create_parent=True)
        _issuance_backends = (ledger, registry)
        return _issuance_backends


def reset_patient_id_issuance_backends() -> None:
    """Drop the cached ledger and registry. Used by tests."""
    global _issuance_backends
    with _issuance_lock:
        _issuance_backends = None


class PatientIdIssuanceResponse(BaseModel):
    nemras_id: str
    display_id: str
    status: str
    created_at: str
    issued_at: str
    newly_issued: bool
    binding_status: str
    record_access: str
    detail: str


@app.post("/api/v1/me/patient-id", response_model=PatientIdIssuanceResponse)
def issue_my_patient_id(
    response: Response,
    caller: auth.CallerIdentity = Depends(auth.verify_caller),
) -> PatientIdIssuanceResponse:
    """
    Issue the caller's NEMRAS Patient ID, or return the one already issued.

    Takes no parameters by design: the UID comes from the verified ID token.
    No CNIC, name, phone number or client-chosen ID is accepted. Returns 201
    for a new issuance and 200 for a replay with the original timestamps.
    """
    try:
        ledger, registry = patient_id_issuance_backends()
        result = ledger.issue(caller.uid, registry)
    except patient_id_issuance.IssuedIdInactiveError:
        logger.warning("[NEMRAS] patient-id issuance: replay of an inactive ID refused")
        raise HTTPException(
            status_code=409,
            detail="This account's NEMRAS Patient ID is not active. Contact support.",
        ) from None
    except (patient_id.PatientIdError, patient_id_issuance.IssuanceError) as exc:
        logger.error("[NEMRAS] patient-id issuance unavailable: %s", type(exc).__name__)
        raise HTTPException(
            status_code=503,
            detail="NEMRAS Patient ID issuance is temporarily unavailable.",
        ) from None

    response.status_code = 201 if result.newly_issued else 200
    return PatientIdIssuanceResponse(
        nemras_id=result.nemras_id,
        display_id=result.display,
        status=result.status,
        created_at=result.created_at,
        issued_at=result.issued_at,
        newly_issued=result.newly_issued,
        binding_status="not_bound",
        record_access="none",
        detail=(
            "This NEMRAS Patient ID is not bound to a CNIC and does not open "
            "or authorize access to any patient record."
        ),
    )
