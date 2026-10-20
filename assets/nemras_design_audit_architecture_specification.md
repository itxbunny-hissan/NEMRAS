# NEMRAS UI & Experience Design System Audit

## 1. Executive Summary & Audit Matrix
An audit of the current NEMRAS canvas reveals two distinct generations of work:
1. **Legacy Dark / High-Contrast Generation** (`{{DATA:SCREEN:SCREEN_11}}`, `{{DATA:SCREEN:SCREEN_13}}`, `{{DATA:SCREEN:SCREEN_15}}`, `{{DATA:SCREEN:SCREEN_17}}`, `{{DATA:SCREEN:SCREEN_19}}`, `{{DATA:SCREEN:SCREEN_21}}`, `{{DATA:SCREEN:SCREEN_23}}`, `{{DATA:SCREEN:SCREEN_25}}`): Built using dark navy/ink surfaces (`#0B1F2A`, `#143041`) or mixed headers. This creates jarring discrepancies against the new daylight clinical direction.
2. **First Light-Theme Redesign Generation** (`{{DATA:SCREEN:SCREEN_3}}`, `{{DATA:SCREEN:SCREEN_5}}`, `{{DATA:SCREEN:SCREEN_7}}`, `{{DATA:SCREEN:SCREEN_9}}`): Successfully introduced the calm `#F7FAFC` background and `#0F766E` clinical teal palette. However, several header components, typography treatments, and bottom navigation states require fine-tuning for unified token compliance and pixel-perfect developer handoff.

| Screen Name | Current State | Issue / Discrepancy | Remediation Plan |
| :--- | :--- | :--- | :--- |
| **Patient Home & CHS** (`SCREEN_9`) | Light Theme (`#F7FAFC`) | Header says "Paramedic Triage" instead of "NEMRAS Health / Patient". Bottom nav active tab points to Triage rather than Home. | Standardize header & navigation bar to Patient Mode tokens. |
| **Emergency Triage & Vitals** (`SCREEN_7`) | Light Theme (`#F7FAFC`) | Excellent clinical structure. Needs refined tactile borders, accessible contrast on contraindication warnings, and consistent 8pt spacing. | Keep as primary reference for Paramedic Triage; align tokens. |
| **CNIC Field Scanner** (`SCREEN_5`) | Light Theme (`#F7FAFC`) | Clean light layout. Top status bar and bottom tabs require unified typography and active indicator matching `#0F766E`. | Realign with master design system tokens. |
| **Hospital Route & Telemetry** (`SCREEN_3`) | Light Theme (`#F7FAFC`) | Light map graphics and telemetry are solid. Minor card border and badge contrast normalization needed. | Retain as reference for Paramedic Route. |
| **Record Timeline** (`SCREEN_23`) | Legacy Dark Header / Light Body | Header has broken logo link & dark icon contrast. | Scheduled for batch update into Light Design System. |
| **AI Clinical Chat** (`SCREEN_21`) | Legacy Partial Dark / Mixed | Mixed styling, header inconsistencies. | Scheduled for batch update into Light Design System. |
| **Access & Audit Log** (`SCREEN_19`) | Legacy Hybrid Theme | Header contains broken image reference, inconsistent toggle tokens. | Scheduled for batch update into Light Design System. |

---

## 2. Master Light Clinical Design Tokens

```css
:root {
  /* Surfaces & Backgrounds */
  --bg-app: #F7FAFC;
  --surface-card: #FFFFFF;
  --surface-subtle: #F1F5F9;
  --surface-mint: #E8F6F3;
  --surface-blue: #EAF3FF;
  --surface-alert-light: #FEF2F2;
  --surface-warning-light: #FFFBEB;
  --surface-success-light: #F0FDF4;

  /* Brand & Accents */
  --brand-teal-primary: #0F766E;
  --brand-teal-hover: #0D655E;
  --brand-teal-dark: #115E59;
  --brand-teal-subtle: #CCFBF1;

  /* Typography Colors */
  --text-main: #243746;
  --text-secondary: #64748B;
  --text-muted: #94A3B8;
  --text-on-teal: #FFFFFF;
  --text-on-alert: #991B1B;

  /* Clinical Status Accents */
  --alert-red: #D94848;
  --alert-red-border: #FCA5A5;
  --warning-amber: #D97706;
  --warning-amber-border: #FCD34D;
  --success-green: #16A34A;
  --success-green-border: #86EFAC;

  /* Borders & Dividers */
  --border-light: #E2E8F0;
  --border-subtle: #EDF2F7;
  --border-focus: #0F766E;

  /* Radii */
  --radius-sm: 8px;
  --radius-md: 12px;
  --radius-lg: 16px;
  --radius-pill: 9999px;

  /* Elevation / Shadows */
  --shadow-sm: 0 1px 2px 0 rgba(36, 55, 70, 0.05);
  --shadow-card: 0 2px 8px -2px rgba(36, 55, 70, 0.06), 0 1px 4px -1px rgba(36, 55, 70, 0.04);
  --shadow-dropdown: 0 10px 15px -3px rgba(36, 55, 70, 0.08);

  /* Typography Families */
  --font-heading: 'Sora', -apple-system, sans-serif;
  --font-body: 'Inter', -apple-system, sans-serif;
  --font-mono: 'JetBrains Mono', monospace;
}
```

---

## 3. Four-Role Architecture & Permission Boundaries

1. **Patient / Citizen**
   - *Primary Goal*: View verified Critical Health Summary (CHS), track medication schedules, inspect immutable hospital access logs, manage proxy guardian consent, query AI health assistant.
   - *Navigation Model*: `Home` · `Health Records` · `AI Assistant` · `Access & Privacy` · `Profile`.
2. **Emergency Responder / Paramedic**
   - *Primary Goal*: Rapid daylight CNIC scan / NFC tap, instant contraindication identification, live vitals telemetry sync, hands-free voice sitrep, hospital route ETA.
   - *Navigation Model*: `Triage & Vitals` · `CNIC Scanner` · `Voice Co-Pilot` · `Route & ICU`.
3. **Hospital Staff / Clinicians**
   - *Primary Goal*: ER intake queue management, bed & telemetry monitoring, clinical RAG assistant queries, emergency override audit clearance.
4. **System Administrator**
   - *Primary Goal*: Federated node synchronization health (487 hospital nodes), Kafka pipeline health, zero-trust cryptographic audit validation.

---

## 4. Batch Delivery Roadmap
- **Batch 1 (Current)**: Architecture Audit & Polishing core Patient Home (`{{DATA:SCREEN:SCREEN_9}}`) to resolve header/tab discrepancies and enshrine master light tokens.
- **Batch 2**: Patient Records Timeline & RAG Clinical Chat redesign in pure light theme.
- **Batch 3**: Access Permissions, Emergency Break-Glass, and Notification Center (inbox, filters, alert states).
- **Batch 4**: Paramedic & Clinician Intake refinement and handoff specs.
