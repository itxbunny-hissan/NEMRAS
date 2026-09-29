# NEMRAS — Demo Build

National Emergency Medical Record Access System
**BS Data Science · Batch 2023–2027** · Kashaf Sajjad, Mirza Hissan Baig, Azka Ashraf

A runnable demo of the core NEMRAS flow:
**Scan/enter CNIC → Critical Health Summary → AI Risk Score + Drug-Interaction Alerts → Patient Chatbot.**
Backed by the real `NEMRAS_Dataset.csv` (64,182 patient records).

```
nemras/
├── backend/          # Python FastAPI — serves the dataset
│   ├── main.py
│   ├── requirements.txt
│   └── NEMRAS_Dataset.csv
└── flutter_app/      # Flutter mobile app (clinical light theme)
    ├── lib/
    └── pubspec.yaml
```

---

## 1. Run the backend (Python)

You need Python 3.10+.

```bash
cd backend
python -m venv venv
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Check it works: open **http://localhost:8000/docs** in a browser — you'll see
all endpoints and can test them live. The terminal should print:
`[NEMRAS] Loaded 64,182 patient records`.

### Endpoints
| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/patient/{cnic}` | Critical Health Summary + AI alerts |
| GET | `/api/patients/sample` | Real demo CNICs to log in with |
| GET | `/api/stats` | Population stats (for dashboard) |
| GET | `/api/dashboard/critical` | Highest-risk patients feed |
| POST | `/api/chat` | Record-grounded patient chatbot |

---

## 2. Run the Flutter app

You need Flutter installed (`flutter --version`).

```bash
cd flutter_app
flutter pub get
flutter run
```

### IMPORTANT — point the app at your backend
Open `lib/api.dart` and set `kBaseUrl`:

- **Android emulator:** `http://10.0.2.2:8000` (default — 10.0.2.2 is the host PC)
- **iOS simulator / Chrome / Desktop:** `http://127.0.0.1:8000`
- **Physical phone:** `http://<your-PC-LAN-IP>:8000` (e.g. `http://192.168.1.5:8000`)
  and make sure phone + PC are on the same Wi-Fi.

To run in Chrome quickly: `flutter run -d chrome` (then use `127.0.0.1` URL).

---

## 3. Demo script (for the viva)

1. Launch app → tap a **demo patient** (e.g. *Emily Johnson*).
2. Show the **Critical Health Summary** — point out blood type, allergy, condition.
3. Highlight the **AI Decision Support alerts** — Codeine allergy (critical),
   drug-interaction flag, Critical risk tier. Explain each maps to a real
   dataset column (`Allergy`, `Drug_Interaction_Risk`, `Risk_Score`).
4. Open the **Health Assistant** → ask "what are my allergies?" → show the
   reply is grounded only in that patient's record.
5. Tie it back to your AI features: the `Risk_Score` column is the target your
   XGBoost model (PDF §4.1) predicts; the chatbot is the RAG feature (§4.4).

---

## How this maps to your project document

| Screen / endpoint | NEMRAS PDF feature |
|---|---|
| CNIC scan → summary | §3 Unified Health Identity, Real-Time Access |
| AI alerts | §3 AI Decision Support, §4.1 Risk Scoring |
| Risk badge | `Risk_Score` (target var) |
| Health Assistant | §4.4 AI Chatbot (RAG, informational only) |
| `/api/stats`, `/dashboard/critical` | §4.3 Population Analytics, §6.4 Hospital Dashboard |

> **Note on AI features:** the risk tier and chatbot here use the validated
> dataset values and a rule-based responder so the demo runs offline with no
> API key. To wire in real models: train your XGBoost classifier on the CSV and
> have `/api/patient` call it for live scoring, and point `/api/chat` at the
> Claude/GPT API with the patient summary as context (per PDF §4.2/§4.4).
> The API contract stays identical, so the Flutter app needs no changes.
