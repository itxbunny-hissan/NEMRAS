# NEMRAS — Demo Build

National Emergency Medical Record Access System
**BS Data Science · Batch 2023–2027** · Kashaf Sajjad, Mirza Hissan Baig, Azka Ashraf

A runnable demo of the core NEMRAS flow:
**Scan/enter CNIC → Critical Health Summary → AI Risk Score + Drug-Interaction Alerts → Patient Chatbot.**
Backed by the real `NEMRAS_Dataset.csv` (64,182 patient records).

```
nemras/
├── backend/              # Python FastAPI — serves the dataset
│   ├── main.py
│   ├── requirements.txt
│   ├── requirements-dev.txt  # test-only dependencies
│   ├── tests/                # pytest suite
│   ├── phone_registry.json   # DEV data, fictional numbers only
│   └── NEMRAS_Dataset.csv    # read-only source data
└── flutter_app/          # Flutter mobile app (clinical light theme)
    ├── lib/
    │   ├── api.dart          # API client + typed ApiException
    │   ├── dev/demo_auth.dart  # DEMO authentication — not production
    │   └── screens/
    ├── test/
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
| GET | `/` | Service banner, used by the app as a connectivity ping |
| GET | `/health` | Health probe — reports whether the dataset actually loaded |
| GET | `/api/patient/{cnic}` | Critical Health Summary + rule-based alerts |
| GET | `/api/patients/sample` | Real demo CNICs to log in with |
| GET | `/api/stats` | Population stats (for dashboard) |
| GET | `/api/dashboard/critical` | Highest-risk patients feed |
| POST | `/api/chat` | Record-grounded patient chatbot (rule-based) |
| GET | `/api/auth/phone/{cnic}` | Whether a CNIC is registered for OTP, plus a masked hint |
| GET | `/api/v1/me/identity` | **Requires a Firebase ID token.** Returns the verified UID only |

`/api/auth/phone/{cnic}` never returns a raw phone number — only
`has_phone` and a masked hint such as `+92********00`.

Endpoints return `503` if `NEMRAS_Dataset.csv` failed to load, `404` for an
unknown CNIC, and `422` for out-of-range query parameters.

> **Authentication status.** Only `/api/v1/me/identity` verifies a caller.
> Every unversioned route above is still unauthenticated and is addressed in a
> later increment. Do not treat this backend as access-controlled yet.

### Backend authentication (Firebase ID tokens)

`/api/v1/me/identity` verifies a Firebase ID token with the Firebase Admin SDK
and returns the verified UID. It grants no record access: the UID → CNIC
binding that would authorise that does not exist yet.

Accepted project: **`nemras-3230f`**. Tokens from any other Firebase project
are rejected.

Set up credentials by copying the example file and pointing it at a
service-account key stored **outside this repository**:

```bash
cd backend
cp .env.example .env          # Windows: copy .env.example .env
# then edit .env and set GOOGLE_APPLICATION_CREDENTIALS
```

Download the key from Firebase Console → Project settings → Service accounts.
It is a private key — never commit it, paste it into source, or share it. The
repository's `.gitignore` already excludes `.env`, `*-service-account*.json`
and `serviceAccountKey*.json`.

Either credential source works:

| Variable | Purpose |
|----------|---------|
| `GOOGLE_APPLICATION_CREDENTIALS` | Absolute path to a service-account JSON file |
| `NEMRAS_FIREBASE_PROJECT_ID` | Project whose tokens are accepted (default `nemras-3230f`) |

Leave `GOOGLE_APPLICATION_CREDENTIALS` unset to use Application Default
Credentials instead, such as an attached service account in a managed
environment.

Call it with a token obtained from a signed-in Firebase client:

```bash
curl -H "Authorization: Bearer <FIREBASE_ID_TOKEN>" \
     http://localhost:8000/api/v1/me/identity
```

Status codes: `401` for a missing, malformed, expired, revoked or
wrong-project token; `503` when the Admin SDK is not configured on the server.
A `503` never falls back to allowing the request.

### SQLite identity-store foundation

A2 adds a storage module for future one-to-one Firebase UID → CNIC bindings.
It is not connected to an API route yet, creates no database at application
startup, and does not change `/api/v1/me/identity`.

Configure both values before a future increment activates the store:

| Variable | Purpose |
|----------|---------|
| `NEMRAS_IDENTITY_DB_PATH` | Absolute path to a SQLite file outside this repository |
| `NEMRAS_HMAC_KEY` | Deployment secret of at least 32 bytes for keyed pseudonymous references |

The configured database directory must already exist unless the caller
explicitly permits its creation. SQLite database files and their WAL/SHM
sidecars are git-ignored. The store persists only UID, CNIC, and UTC
timestamps; it never stores Firebase tokens, credentials, OTPs, raw phone
numbers, or patient records.

The HMAC key belongs in deployment secret configuration, not source control.
It must be backed up separately: changing or losing it changes all future
pseudonymous references.

### Backend tests

```bash
cd backend
pip install -r requirements-dev.txt
pytest
```

---

## 2. Run the Flutter app

You need Flutter installed (`flutter --version`).

```bash
cd flutter_app
flutter pub get
flutter run
```

### IMPORTANT — point the app at your backend
The API base URL is a build-time setting, so no machine-specific address needs
to be edited into source:

```bash
flutter run --dart-define=NEMRAS_API_URL=http://192.168.1.5:8000
```

- **iOS simulator / Chrome / Desktop:** `http://127.0.0.1:8000`
- **Android emulator:** `http://10.0.2.2:8000` (10.0.2.2 is the host PC; often
  blocked by Windows Firewall)
- **Physical phone:** `http://<your-PC-LAN-IP>:8000` (e.g. `http://192.168.1.5:8000`)
  and make sure phone + PC are on the same Wi-Fi.

If no `--dart-define` is passed, the development default in
`lib/api.dart` (`kDefaultApiUrl`) is used.

To run in Chrome quickly:
`flutter run -d chrome --dart-define=NEMRAS_API_URL=http://127.0.0.1:8000`

### Flutter checks

```bash
cd flutter_app
flutter analyze
flutter test
```

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

---

## Feature status — what is real vs. what is demo

This section is the honest inventory. Nothing below is described as AI/ML
unless a trained model is actually involved.

### Implemented
| Feature | Notes |
|---|---|
| CNIC lookup → Critical Health Summary | Real lookup against the 64,182-row dataset |
| CNIC barcode scanning | `mobile_scanner`, reads the barcode on the CNIC card |
| Population statistics & critical-patient feed | Computed live from the dataset |
| Point-of-care alerts | **Rule-based**, derived from `Allergy`, `Drug_Interaction_Risk`, `Risk_Score`, `Chronic_Condition` |
| Backend health probe | `GET /health`, reports dataset load state |
| Typed API error handling | `ApiException` in `lib/api.dart`; every call checks its status code |
| Build-time API configuration | `--dart-define=NEMRAS_API_URL` |
| Masked phone lookup | `/api/auth/phone/{cnic}` never returns a raw number |

### Demo / mock — not production behaviour
| Feature | Why it is not real |
|---|---|
| OTP sign-in | **No SMS is sent and no code is verified.** Fixed demo OTP, isolated in `lib/dev/demo_auth.dart`. Disable with `--dart-define=NEMRAS_DEMO_AUTH=false` |
| Offline demo patient | One **synthetic** record in `lib/dev/demo_auth.dart` so the viva works with the backend down. Not a real patient, not from the dataset |
| "AI Risk Score" | Read from the dataset's `Risk_Score` column. **No model is trained or executed at runtime** |
| Health Assistant chatbot | **Deterministic keyword matching** over the patient's own record. Not an LLM and not RAG |
| Secure-boot / TLS screen | Visual sequence only; it does not perform certificate verification |
| Audit log screen | Static illustrative entries; no audit trail is recorded yet |
| `backend/phone_registry.json` | Development data with **fictional placeholder numbers** only |
| CORS `allow_origins=["*"]` | Development convenience; must be restricted before deployment |

### Future — not started
| Feature | Blocking work |
|---|---|
| Firebase Phone Authentication | Replace `lib/dev/demo_auth.dart`; see its `TODO(production-auth)` notes |
| Backend-enforced authorisation | Verify Firebase ID tokens server-side and resolve UID → CNIC there. **Today there is no authorisation layer: the Flutter UI is not a security boundary** |
| Immutable audit trail | Persist every record access, including emergency/break-glass access |
| Trained risk-scoring model | XGBoost on the CSV with reproducible evaluation, called from `/api/patient` |
| Real RAG / LLM assistant | Grounded generation over approved sources, replacing the keyword responder |
| Hospital / ministry / paramedic portals | Only the patient experience and a hospital dashboard exist today |

> **Security status (honest):** this build has no real authentication or
> authorisation. Any CNIC known to the dataset can be looked up by anyone who
> can reach the backend. That is acceptable for a local demo with synthetic
> credentials, and must be fixed before any deployment with real patient data.
