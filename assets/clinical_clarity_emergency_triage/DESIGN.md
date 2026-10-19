---
name: Clinical Clarity & Emergency Triage
colors:
  surface: '#f6f9ff'
  surface-dim: '#c8dcf0'
  surface-bright: '#f6f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#ecf5ff'
  surface-container: '#e1f0ff'
  surface-container-high: '#d6ebfe'
  surface-container-highest: '#d1e5f8'
  on-surface: '#091d2b'
  on-surface-variant: '#3e4947'
  inverse-surface: '#1f3241'
  inverse-on-surface: '#e6f2ff'
  outline: '#6e7977'
  outline-variant: '#bdc9c6'
  surface-tint: '#006a63'
  primary: '#005c55'
  on-primary: '#ffffff'
  primary-container: '#0f766e'
  on-primary-container: '#a3faef'
  inverse-primary: '#80d5cb'
  secondary: '#216963'
  on-secondary: '#ffffff'
  secondary-container: '#a8ece5'
  on-secondary-container: '#266d68'
  tertiary: '#49525c'
  on-tertiary: '#ffffff'
  tertiary-container: '#616a74'
  on-tertiary-container: '#e1ebf6'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#9cf2e8'
  primary-fixed-dim: '#80d5cb'
  on-primary-fixed: '#00201d'
  on-primary-fixed-variant: '#00504a'
  secondary-fixed: '#abefe8'
  secondary-fixed-dim: '#8fd3cc'
  on-secondary-fixed: '#00201e'
  on-secondary-fixed-variant: '#00504b'
  tertiary-fixed: '#dae3ef'
  tertiary-fixed-dim: '#bec7d3'
  on-tertiary-fixed: '#141c25'
  on-tertiary-fixed-variant: '#3f4851'
  background: '#f6f9ff'
  on-background: '#091d2b'
  surface-variant: '#d1e5f8'
typography:
  display-lg:
    fontFamily: Sora
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
    letterSpacing: -0.02em
  display-lg-mobile:
    fontFamily: Sora
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.01em
  headline-lg:
    fontFamily: Sora
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Sora
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 30px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Sora
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: 0em
  headline-sm:
    fontFamily: Sora
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: 0em
  title-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: 0em
  title-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.005em
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: 0em
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: 0em
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 18px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.04em
  metric-lg:
    fontFamily: JetBrains Mono
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 30px
    letterSpacing: -0.02em
  metric-md:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0em
  metric-sm:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.02em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-md: 1.5rem
  gutter-lg: 2rem
  margin: 1rem
  margin-md: 1.5rem
  margin-lg: 2.5rem
  space-2xs: 0.25rem
  space-xs: 0.5rem
  space-sm: 0.75rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
  space-2xl: 3rem
---

## Brand & Style
The design system establishes an uncompromising standard of calm, clinical authority and rapid cognitive processing for mission-critical national healthcare infrastructure. Designed for frontline paramedics, triage nurses, clinical specialists, and emergency dispatchers, the interface minimizes cognitive friction under acute operational stress.

The aesthetic blends Modern Healthcare Minimalism with institutional rigor: pristine cool surfaces, deliberate color semantics, and precise typographic hierarchy. It avoids gratuitous decoration, dark panels, and visual noise in favor of luminous contrast, generous breathing room, and instantaneous data recognition. Emergency indicators cut through the clinical calm with unambiguous priority, while everyday patient workflows feel humane, stable, and meticulously organized.

## Colors
The color architecture relies on a pristine clinical foundation:

- **Primary Teal (`#0F766E`) & Deep Teal (`#115E59`)**: Anchor the brand identity, interactive triggers, primary navigation, and confirmed clinical statuses.
- **Pale Mint (`#E8F6F3`)**: Serves as tinted badge fills, active row highlights, and patient status verification containers.
- **Soft Medical Blue (`#EAF3FF`)**: Dedicated to non-urgent informational callouts, intake context cards, and secondary data groupings.
- **Neutral Core**:
  - Background: `#F7FAFC` provides a clinical, low-strain canvas.
  - Surfaces: `#FFFFFF` (Surface Container & Lowest) keeps cards crystalline; `#F1F5F9` (Surface Container Low) partitions subtle sub-regions; `#E2E8F0` defines structural border lines and muted canvas dimming.
  - Typography: Dark Slate (`#243746`) delivers WCAG AAA contrast without the harshness of pure black; Muted Text (`#64748B`) establishes secondary hierarchy for metadata and secondary labels.
- **Semantic Severity States**:
  - **Emergency Red (`#D94848`) & Soft Red (`#FEF2F2`)**: Reserved strictly for code-red alerts, anaphylaxis warnings, critical vitals out-of-range, and irreversible actions. Never used purely for decoration.
  - **Caution Amber (`#D97706`) & Soft Amber (`#FFFBEB`)**: Flags pending labs, allergy warnings, triage level 3/4 flags, and verification warnings.
  - **Success Green (`#16A34A`) & Soft Green (`#F0FDF4`)**: Confirms synchronized records, authenticated biometric scans, and normalized vitals.

## Typography
Typographic clarity directly impacts patient outcomes. The system uses a disciplined three-tier font stack:

- **Sora (Clinical Headings & Architecture)**: Structural, geometric clarity with modern proportions. Gives executive stability to hospital department titles, patient names, and primary section anchors.
- **Inter (Interface & Narrative)**: Maximally legible across varying display fidelities. Handles all clinical narrative notes, metadata labels, form controls, and body documentation.
- **JetBrains Mono (Critical Data & Identifiers)**: Eliminates character ambiguity (such as `0` vs `O`, `1` vs `I`). Enforces fixed tab stops for CNIC numbers, national medical IDs, vital sign metrics (BPM, SpO2, systolic/diastolic values), ICD-10 diagnostic codes, and emergency arrival timestamps.

## Layout & Spacing
The layout follows a fluid-responsive 12-column grid system calibrated for rapid scanning and multi-pane clinical dashboards (e.g., patient intake lists adjacent to live vital charts).

- **Grid Architecture**:
  - **Desktop (≥ 1280px)**: 12 columns, 24px/32px gutters, 40px safe page margins. Supports multi-column split views (e.g., permanent 4-column triage roster + 8-column detailed medical profile).
  - **Tablet / Workstation (768px – 1279px)**: 8 columns, 20px gutters, 24px margins. Collapses secondary sidebars into modular bottom drawers or slide-in overlays.
  - **Mobile / EMS Handheld (< 768px)**: 4 columns, 16px gutters, 16px canvas margins. Linear single-column flow optimized for single-hand emergency triage.
- **Spatial Rhythm**:
  - Components adhere strictly to an 8px base rhythm (`space-2xs` at 4px for tight badge padding and metric sub-labels).
  - Internal card padding is consistently `1.5rem` (24px) on desktop and `1rem` (16px) on mobile viewports.

## Elevation & Depth
Depth is created through subtle surface contrasts and restrained elevation shadows, strictly avoiding muddy drops, heavy black shadows, or pitch-dark containers.

- **Level 0 (Flat Canvas)**: `#F7FAFC` canvas. Cards, tables, and sidebars sit directly on this field, separated by crisp `1px solid #E2E8F0` hairline strokes.
- **Level 1 (Clinical Cards & Data Modules)**: White (`#FFFFFF`) surfaces elevated with an ambient shadow: `0 1px 3px 0 rgba(36, 55, 70, 0.04), 0 2px 8px -2px rgba(36, 55, 70, 0.04)`, bounded by `1px solid #E2E8F0`.
- **Level 2 (Hovered Cards & Interactive Trays)**: Slight elevation boost: `0 4px 14px -2px rgba(15, 118, 110, 0.06), 0 2px 6px -1px rgba(36, 55, 70, 0.04)`.
- **Level 3 (Modals, Triage Drawers & Critical Prompts)**: `0 12px 32px -4px rgba(36, 55, 70, 0.12), 0 4px 12px -2px rgba(36, 55, 70, 0.06)` with backdrop blur `backdrop-filter: blur(4px)` over a `rgba(36, 55, 70, 0.35)` medical scrim.

## Shapes
The system strikes a balance between sterile precision and modern human-centered care:

- **Cards & Data Modules**: Standardized to `16px` radius (`rounded-lg` per scale tier 2) with a permissible range of `14px` (dense data widgets) to `18px` (large master intake cards).
- **Interactive Controls (Inputs, Dropdowns, Standard Buttons)**: Standardized to `8px` (`0.5rem`) for clinical reliability and immediate affordance.
- **Status Pills & Metric Badges**: Full radius (`9999px` / pill-shaped) to distinguish transient status indicators and vital warnings from structural rectangular cards.
- **Borders**: Uniform `1px` crisp outlines using `#E2E8F0` across all cards, inputs, and segmented panels to maintain structural definition under high-glare clinical lights.

## Components

### Buttons
- **Primary Action**: Solid `#0F766E` background, `#FFFFFF` text, `font-weight: 600`, 8px corner radius. Hover state transitions to `#115E59`. Active state scales subtly to `0.98`.
- **Critical / Emergency Action**: Solid `#D94848` background, `#FFFFFF` text. Used solely for emergency record overrides, code triggers, or patient record deletion/lockdown.
- **Secondary / Ghost**: Background transparent, border `1px solid #E2E8F0`, text `#243746`. Hover initiates background tint `#F1F5F9` and border `#CBD5E1`.
- **Tonal Teal**: Background `#E8F6F3`, text `#0F766E`, border `1px solid rgba(15, 118, 110, 0.12)`. For frequent non-primary operations.

### Cards & Panels
- Background `#FFFFFF`, border `1px solid #E2E8F0`, corner radius `16px`.
- Card headers feature an explicit 48px to 56px height baseline with clear title typography (`headline-sm`), an optional badge, and trailing action icon buttons.
- Emergency cards (e.g., Severe Allergy, Code Blue record) feature a left-accent rail of `4px solid #D94848` with `#FEF2F2` header tinting.

### Chips & Badges
- **Emergency / Critical**: Text `#D94848`, background `#FEF2F2`, border `1px solid rgba(217, 72, 72, 0.2)`.
- **Verified / Stable**: Text `#0F766E`, background `#E8F6F3`, border `1px solid rgba(15, 118, 110, 0.2)`.
- **Informational / Triage Level 4-5**: Text `#1D4ED8`, background `#EAF3FF`, border `1px solid rgba(29, 78, 216, 0.2)`.
- Pill-shaped (`rounded-full`), padded with `0.25rem 0.75rem`, rendered in `label-sm` with `JetBrains Mono` for accompanying numeric codes.

### Input Fields & Controls
- Form inputs feature `#FFFFFF` fill, 8px corner radius, `1px solid #E2E8F0` default border, and `body-md` text in `#243746`.
- **Focus State**: `1px solid #0F766E` with a soft outer ring `box-shadow: 0 0 0 3px rgba(15, 118, 110, 0.15)`.
- **Checkboxes & Radios**: 18px size, primary teal active fill (`#0F766E`) with an explicit white check/disc, ensuring quick visual recognition.

### Patient Data & Metric Lists
- Table headers utilize `#F1F5F9` with uppercase tracking (`label-sm`, `#64748B`).
- Table rows display horizontal dividers `1px solid #E2E8F0` on white rows, with hover state shifting to `#F8FAFC`.
- Vital Signs indicators feature tabular lining figures using `JetBrains Mono`, paired with clear unit labels (`body-sm`, `#64748B`).