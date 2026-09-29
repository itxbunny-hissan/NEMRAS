"""
NEMRAS Backend API
National Emergency Medical Record Access System
FastAPI service backed by the real NEMRAS_Dataset.csv (64,182 patient records).

Run:
    pip install -r requirements.txt
    uvicorn main:app --reload --host 0.0.0.0 --port 8000

Docs available at http://localhost:8000/docs
"""

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List
import pandas as pd
import numpy as np
import os
import json

DATA_PATH = os.path.join(os.path.dirname(__file__), "NEMRAS_Dataset.csv")
PHONE_REGISTRY_PATH = os.path.join(os.path.dirname(__file__), "phone_registry.json")

app = FastAPI(
    title="NEMRAS API",
    description="National Emergency Medical Record Access System - demo backend",
    version="1.0.0",
)

# Allow Flutter (mobile/web/desktop) to call the API during development.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ------------------------------------------------------------------
# Data loading (loaded once at startup, kept in memory for fast lookup)
# ------------------------------------------------------------------
DF: pd.DataFrame = pd.DataFrame()


def load_data() -> pd.DataFrame:
    df = pd.read_csv(DATA_PATH)
    # CNIC is the unique key for patient lookup (one row per patient in this dataset).
    df["CNIC"] = df["CNIC"].astype(str).str.strip()
    return df


PHONE_REGISTRY: dict = {}


@app.on_event("startup")
def _startup() -> None:
    global DF, PHONE_REGISTRY
    DF = load_data()
    if os.path.exists(PHONE_REGISTRY_PATH):
        with open(PHONE_REGISTRY_PATH, "r") as f:
            PHONE_REGISTRY = json.load(f)
    print(f"[NEMRAS] Loaded {len(DF):,} patient records from {DATA_PATH}")
    print(f"[NEMRAS] Phone registry: {len(PHONE_REGISTRY)} registered numbers")


# ------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------
RISK_RANK = {"Stable": 0, "Elevated": 1, "Critical": 2}


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
            "detail": "AI risk model classifies this patient as CRITICAL. "
                      "Recommend ICU pre-allocation and specialist activation.",
        })
    elif str(row["Risk_Score"]).strip() == "Elevated":
        alerts.append({
            "severity": "high",
            "title": "Elevated Risk Tier",
            "detail": "AI risk model classifies this patient as ELEVATED. "
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
    return {"service": "NEMRAS API", "records": len(DF), "status": "ok"}


@app.get("/api/stats")
def stats():
    """Population-level numbers for the hospital / central dashboard."""
    def vc(col):
        return {str(k): int(v) for k, v in DF[col].value_counts().items()}

    return {
        "total_patients": int(len(DF)),
        "risk_score": vc("Risk_Score"),
        "triage_level": vc("Triage_Level"),
        "drug_interaction_risk": vc("Drug_Interaction_Risk"),
        "medical_condition": vc("Medical_Condition"),
        "admission_type": vc("Admission_Type"),
        "chronic_condition": vc("Chronic_Condition"),
        "avg_age": round(float(DF["Age"].mean()), 1),
    }


@app.get("/api/patients/sample")
def sample_patients(n: int = Query(10, ge=1, le=50)):
    """A few real CNICs from the dataset so the demo always has valid logins."""
    cols = ["CNIC", "Patient_Name", "Age", "Medical_Condition", "Risk_Score"]
    sample = DF[cols].head(n)
    return sample.to_dict(orient="records")


@app.get("/api/patient/{cnic}")
def get_patient(cnic: str):
    """Core lookup: scan/enter a CNIC -> Critical Health Summary + alerts."""
    cnic = cnic.strip()
    match = DF[DF["CNIC"] == cnic]
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
    df = DF.copy()
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
    match = DF[DF["CNIC"] == req.cnic.strip()]
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
    Returns masked phone number for this CNIC if registered.
    Client uses this to trigger Firebase OTP to the real number.
    Returns 404 if CNIC not in dataset, 200 with masked/null phone otherwise.
    """
    cnic = cnic.strip()
    if DF[DF["CNIC"] == cnic].empty:
        raise HTTPException(status_code=404, detail=f"No patient found for CNIC {cnic}")
    entry = PHONE_REGISTRY.get(cnic)
    if entry:
        phone = entry["phone"]
        masked = phone[:5] + "****" + phone[-3:]
        return {"cnic": cnic, "has_phone": True, "masked_phone": masked, "phone": phone}
    return {"cnic": cnic, "has_phone": False, "masked_phone": None, "phone": None}
