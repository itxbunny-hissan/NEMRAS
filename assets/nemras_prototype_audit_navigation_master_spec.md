# NEMRAS Comprehensive Prototype Audit & Navigation Master Spec
**National Emergency Medical Record Access System (Pakistan Sovereign Health Enclave)**
*Document Version: 1.0 · Prototype Audit & Handoff Checklist*

---

## 1. Executive Summary & Audit Matrix

A complete audit of all **40 core production screens** across the 5 distinct subsystem modules was conducted. All generated artifacts preserve the **NEMRAS Daylight Clinical Design System** (`#F6F9FF` canvas, `#FFFFFF` containers, `#0F766E` clinical teal primary, `#243746` slate typography, and `#D94848` emergency red). 

No screens were overwritten or discarded. This document maps out the connected journeys, resolves cross-module routing targets, catalogs duplicate/legacy candidates on the canvas, and provides the step-by-step interactive linking checklist.

### Subsystem Inventory Summary
1. **Foundation & Authentication** (`SCREEN_75` to `SCREEN_68`, plus `SCREEN_62`, `SCREEN_64`, `SCREEN_66`): 11 Screens (Complete)
2. **Patient / Citizen Mobile App** (`SCREEN_60`, `SCREEN_58`, `SCREEN_56`, `SCREEN_54`, `SCREEN_52`): 5 Screens (Complete)
3. **Emergency Responder Mobile App** (`SCREEN_42`, `SCREEN_50`, `SCREEN_48`, `SCREEN_44`, `SCREEN_46`, `SCREEN_40`): 6 Screens (Complete)
4. **Hospital Staff & Clinician Mobile App** (`SCREEN_36`, `SCREEN_32`, `SCREEN_38`, `SCREEN_34`, `SCREEN_30`, `SCREEN_28`): 6 Screens (Complete)
5. **National Operations Desktop Command** (`SCREEN_26`, `SCREEN_24`, `SCREEN_22`, `SCREEN_20`, `SCREEN_18`, `SCREEN_16`): 6 Screens (Complete)
6. **National Administrative Console** (`SCREEN_14`, `SCREEN_12`, `SCREEN_10`, `SCREEN_6`, `SCREEN_4`, `SCREEN_8`): 6 Screens (Complete)

---

## 2. Connected User Journeys & Target Mapping

### Journey 1: Patient / Citizen (Mobile)
```
[SCREEN_75: 01 Splash Screen]
   │ Tap anywhere / Auto-advance (2.4s)
   ▼
[SCREEN_74: 02 Welcome & Onboarding]
   │ CTA: "Get Started"
   ▼
[SCREEN_73: 03 Login] ──(New User)──► [SCREEN_72: 04 Sign Up]
   │ Form Submit                               │ Form Submit
   ▼                                           ▼
[SCREEN_70: 06 OTP Verification] ◄─────────────┘
   │ Verified
   ▼
[SCREEN_68: 08 Role Selection]
   │ Select "Citizen / Patient"
   ▼
[SCREEN_62: 09 Profile Setup]
   │ Save & Continue
   ▼
[SCREEN_64: 10 Location Permission]
   │ Allow Precise GPS
   ▼
[SCREEN_66: 11 Notification Permission]
   │ Enable Emergency Broadcasts
   ▼
[SCREEN_60: 12 Patient Home Dashboard] ◄─────────────────────────────────────────┐
   │                                  │                                         │
   │ (Tap SOS Button)                 │ (Bottom Nav: Profile / Medical Profile) │
   ▼                                  ▼                                         │
[SCREEN_58: 13 SOS Emergency Request] [SCREEN_52: 16 Medical Profile]           │
   │ Hold 3s / Category Select        │ (Back to Home)                          │
   ▼                                  └─────────────────────────────────────────┤
[SCREEN_56: 14 Emergency Details]                                               │
   │ Submit Request & Alert 1122                                                │
   ▼                                                                            │
[SCREEN_54: 15 Live Emergency Tracking]                                         │
   │ (Completed Handover / Return to Dashboard)                                 │
   └────────────────────────────────────────────────────────────────────────────┘
```

### Journey 2: Emergency Responder / Rescue 1122 (Mobile)
```
[SCREEN_68: 08 Role Selection] ──► Select "Emergency Responder"
   ▼
[SCREEN_42: 17 Responder Dashboard]
   │ Toggle Duty: "On Duty / Available"
   │ Select Active Alert banner OR tap "Dispatches" tab
   ▼
[SCREEN_50: 18 Incoming Emergency Requests]
   │ Inspect case: "Review Urgent Call" / Tap Request Card
   ▼
[SCREEN_48: 19 Patient Case Details]
   │ Review Allergies (Penicillin warning) & tap "Accept Assignment & Arm Route"
   ▼
[SCREEN_44: 20 Navigation & Dispatch]
   │ Mark "En Route" ──► Mark "Arrived At Pickup Point"
   ▼
[SCREEN_46: 21 On-Scene Assessment & Vitals]
   │ Stepper input vitals & tap "Save & Transmit Vitals to Receiving ER"
   ▼
[SCREEN_40: 22 Response Status & Hospital Handoff]
   │ Verify SBAR Checklist & tap "Confirm Hospital Handoff & Complete Incident"
   ▼
[SCREEN_42: 17 Responder Dashboard] (Returns to Ready queue)
```

### Journey 3: Hospital Staff & Clinicians (Mobile)
```
[SCREEN_68: 08 Role Selection] ──► Select "Hospital Staff / Clinician"
   ▼
[SCREEN_36: 23 Hospital Staff Dashboard]
   │                                 │                              │
   │ Tap "Incoming Triage Queue"     │ Tap "Bed & Capacity Manager" │ Tap "Alerts & Escalations"
   ▼                                 ▼                              ▼
[SCREEN_32: 24 Incoming Cases]    [SCREEN_34: 26 Bed Capacity]   [SCREEN_28: 28 Hospital Alerts]
   │ Tap "Dossier →" on AMB-37       │ (Back to Dashboard)          │ (Acknowledge / Escalate)
   ▼                                 └──────────────────────────────┴─────────────────────────┐
[SCREEN_38: 25 Patient Intake]                                                                │
   │ Tap "Confirm Patient Arrival & Start Intake"                                             │
   ▼                                                                                          │
[SCREEN_30: 27 Clinical Handoff & Admission]                                                  │
   │ Complete Dual-Signoff & tap "Complete Clinical Handoff & Confirm Admission"              │
   ▼                                                                                          │
[SCREEN_36: 23 Hospital Staff Dashboard] ◄────────────────────────────────────────────────────┘
```

### Journey 4: National Emergency Operations Command (Desktop 1440px)
Persistent Left Navigation:
* `National Dashboard` ──► `SCREEN_26`
* `Emergency Map` ──► `SCREEN_24`
* `Regional Analytics` ──► `SCREEN_22`
* `Population Health` ──► `SCREEN_20`
* `Hospital Network` ──► `SCREEN_18`
* `Incident Reports` ──► `SCREEN_16`

Cross-Screen In-Context Connections:
- `SCREEN_26: National Dashboard` ➔ Escalation Card "Multi-Vehicle Collision" ➔ Jump to `SCREEN_24: Map` with incident highlighted.
- `SCREEN_24: Emergency Map` ➔ Side Drawer Case `#PK-1122-8921` ➔ "Open National Audit Record" ➔ Jump to `SCREEN_16: Incident Reports`.
- `SCREEN_18: Hospital Network` ➔ Nishtar Hospital Dossier ➔ "Declare Regional Trauma Surge Protocol" ➔ Updates status in `SCREEN_26`.

### Journey 5: National Administrative & Governance Console (Desktop 1440px)
Persistent Left Navigation:
* `Admin Overview` ──► `SCREEN_14`
* `User Verification` ──► `SCREEN_12`
* `Roles & Permissions` ──► `SCREEN_10`
* `Hospital Network` ──► `SCREEN_6`
* `Responders & Fleet` ──► `SCREEN_4`
* `Audit Logs & Settings` ──► `SCREEN_8`

Cross-Screen In-Context Connections:
- `SCREEN_14: Admin Overview` ➔ "Review Queue →" badge ➔ Jump to `SCREEN_12: User Verification`.
- `SCREEN_12: User Verification` ➔ "Approve Credentials & Provision Access" ➔ Triggers cryptographically signed transaction visible in `SCREEN_8: Audit Logs`.
- `SCREEN_10: Roles & Permissions` ➔ "Dual-Sign-off Protocol" ➔ Enforces authorization gate recorded in `SCREEN_8`.
- `SCREEN_6: Hospital Network Management` ➔ "Initiate Trauma Surge Diversion Override" ➔ Synchronizes with `SCREEN_18` in National Operations.

---

## 3. Discrepancy, Legacy, & Duplicate Screen Audit

The Canvas snapshot contains previous exploratory generations created earlier in the project lifecycle. These should be treated as follows during developer handoff:

| Canvas Artifact ID | Screen Title | Generation Type | Status / Recommendation |
| :--- | :--- | :--- | :--- |
| `SCREEN_99`, `SCREEN_97`, `SCREEN_95`, `SCREEN_93` | Citizen Mobile v1 | Session 0 (Exploratory Dark/Light mixed) | **Archive / Deprecate** in favor of canonical `SCREEN_60` through `SCREEN_52`. |
| `SCREEN_91`, `SCREEN_89`, `SCREEN_87`, `SCREEN_85` | Paramedic v1 (Dark) | Session 1 (High contrast dark mode) | **Archive / Deprecate** in favor of canonical light-theme `SCREEN_42` through `SCREEN_40`. |
| `SCREEN_83`, `SCREEN_81`, `SCREEN_79`, `SCREEN_77` | Redesign Batch v2 | Session 2 (Early light conversion) | **Archive / Reference**; replaced by the numbered, validated flows `SCREEN_12`–`SCREEN_28`. |
| `SCREEN_62`, `SCREEN_64`, `SCREEN_66` | Screens 09, 10, 11 | Session 5 (Mobile Foundation) | **Canonical Production Foundation**. Keep and link into Patient & Responder on-boarding. |
| `SCREEN_60`, `SCREEN_58`, `SCREEN_56`, `SCREEN_54`, `SCREEN_52` | Screens 12–16 | Session 6 (Patient Mode) | **Canonical Production Patient Suite**. Presentable. |
| `SCREEN_42`, `SCREEN_50`, `SCREEN_48`, `SCREEN_44`, `SCREEN_46`, `SCREEN_40` | Screens 17–22 | Session 7 (Responder Mode) | **Canonical Production Responder Suite**. Presentable. |
| `SCREEN_36`, `SCREEN_32`, `SCREEN_38`, `SCREEN_34`, `SCREEN_30`, `SCREEN_28` | Screens 23–28 | Session 8 (Hospital Staff) | **Canonical Production Hospital Staff Suite**. Presentable. |
| `SCREEN_26`, `SCREEN_24`, `SCREEN_22`, `SCREEN_20`, `SCREEN_18`, `SCREEN_16` | Screens 29–34 | Session 9 (National Ops) | **Canonical Production National Ops Suite**. Presentable. |
| `SCREEN_14`, `SCREEN_12`, `SCREEN_10`, `SCREEN_6`, `SCREEN_4`, `SCREEN_8` | Screens 35–40 | Session 10 (Admin Portal) | **Canonical Production Admin Console**. Presentable. |

---

## 4. State & Error Handling Verification

All production screens incorporate graceful state representations:
1. **Empty States**:
   - `SCREEN_50 (18 Incoming Requests)`: Displays "Sector 4 Clean & Clear" empty radar status.
   - `SCREEN_20 (Population Health)`: Features dedicated "No Records For Selected Filter" empty facet drawer.
   - `SCREEN_24 (Emergency Map)`: Includes interactive "Empty Search State" button.
2. **Permission & Security Gates**:
   - `SCREEN_64 (10 Location)` & `SCREEN_66 (11 Notifications)`: Dedicated recovery messaging explaining how to re-enable system access if denied.
   - `SCREEN_10 (Roles & Permissions)`: Red-tagged "STRICTLY FORBIDDEN" state preventing deletion or tampering of historical WORM audit trails.
3. **Network & Offline Buffers**:
   - `SCREEN_44 (20 Navigation)`: "Offline Tile Pre-Cached" confirmation indicator.
   - `SCREEN_40 (22 Hospital Handoff)`: "Offline buffer queued (3 items). Syncs automatically via P2P mesh."
4. **Validation & Confirmation**:
   - `SCREEN_58 (13 SOS Request)`: Hold-3s circular visual confirm loop preventing accidental triggers.
   - `SCREEN_30 (27 Clinical Handoff)`: 4-step dual sign-off checklist validating mutual physical and digital custody before sign-off commit.

---

## 5. Technical Implementation & Handoff Checklist

For prototyping tools (Figma / Flutter / React Web):
1. **Shared Navigation Bars**:
   - Link mobile bottom tabs (`Home`, `Queue/Dispatches`, `Beds/Records`, `Alerts/Profile`) across active module states.
   - Ensure the Left Sidebar on Desktop Dashboards (`SCREEN_14` to `SCREEN_8` and `SCREEN_26` to `SCREEN_16`) binds each link to its respective route with the active state set on current page load.
2. **Data Consistency**:
   - The fictional patient persona **Kashaf Sajjad (24F, CNIC 36302-XXXXXXX-8, Blood O+ POS)** with **Penicillin Anaphylaxis** correctly travels from SOS dispatch (`SCREEN_58`, `SCREEN_56`) to ambulance telemetry (`SCREEN_48`, `SCREEN_46`), hospital queue intake (`SCREEN_32`, `SCREEN_38`), clinical handoff (`SCREEN_30`), geospatial tracking (`SCREEN_24`), and national incident audit (`SCREEN_16`). Maintain this exact ID token mapping across all click-through interactions.
3. **Simulation Disclaimer Banner**:
   - All desktop dashboards feature persistent header banners stating: *"SIMULATED NATIONAL OPERATIONS DATA — FOR PROTOTYPE DEMONSTRATION PURPOSES ONLY"*. Maintain this for compliance with medical UI prototype standards.
