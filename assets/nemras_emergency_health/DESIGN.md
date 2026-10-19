---
name: NEMRAS Emergency Health
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
  tertiary: '#9e1c23'
  on-tertiary: '#ffffff'
  tertiary-container: '#c03638'
  on-tertiary-container: '#ffe4e1'
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
  tertiary-fixed: '#ffdad7'
  tertiary-fixed-dim: '#ffb3ae'
  on-tertiary-fixed: '#410005'
  on-tertiary-fixed-variant: '#8f0e1a'
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
  headline-lg:
    fontFamily: Sora
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Sora
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Sora
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  headline-sm:
    fontFamily: Sora
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 18px
  body-strong:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
  label-md:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 16px
  telemetry-lg:
    fontFamily: JetBrains Mono
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.02em
  telemetry-md:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
  telemetry-sm:
    fontFamily: JetBrains Mono
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
    letterSpacing: 0.04em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1.5rem
  gutter-mobile: 1rem
  margin: 2rem
  margin-mobile: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

The design system establishes a clinical-grade, high-trust environment tailored for rapid response, triage, and patient oversight. The aesthetic is strictly modern clinical minimalism: daylight clarity, absolute legibility under high-stress conditions, and immediate visual hierarchy. 

Targeted at first responders, triage nurses, clinicians, and patients navigating urgent medical care, the interface eliminates all visual noise, decorative ambiguity, and high-fatigue styling. The emotional tone is decisive, calm, hygienic, and authoritative. Under no circumstances does the interface utilize dark canvas modes, black cards, or saturated decorative gradients; white surfaces, surgical teal accents, and explicit semantic signaling guarantee split-second cognitive processing.

## Colors

The palette is anchored by clinical-grade contrast standards, strictly exceeding WCAG 2.1 AAA for vital telemetry and text elements.

- **Primary Clinical Teal (`#0F766E`)**: The primary brand marker, key navigation focal points, affirmative actions, and critical active states.
- **Deep Teal (`#115E59`)**: Hover/pressed states, high-contrast headings, and focused clinical controls.
- **Pale Mint (`#E8F6F3`)**: Subdued container background for primary teal badges, active row states, and selected triage chips.
- **Medical Blue (`#EAF3FF`)**: Informational containers, patient demographic tags, and intake status markers.
- **Critical Red (`#D94848`) & Soft Alert (`#FEF2F2`)**: Emergency triage, allergic contraindications, severe vitals threshold breaches, and urgent dispatch callouts.
- **Warning Amber (`#D97706`) & Soft Warning (`#FFFBEB`)**: Triage tier-2 status, pending medication checks, and non-immediate anomalies.
- **Success Green (`#16A34A`) & Soft Success (`#F0FDF4`)**: Stable vitals, successful verification, and completed patient syncs.
- **Neutral Structure**: Canvas (`#F7FAFC`), Card Surface (`#FFFFFF`), Text Primary (`#243746`), Text Secondary (`#64748B`), and Muted Border (`#E2E8F0`). Dark mode is completely disallowed across the entire application ecosystem.

## Typography

Typography plays a specialized functional role across three designated typefaces:

1. **Sora (Headings & Identifiers)**: Geometrically precise, open counters, and high distinction at glance value. Used for patient screen headings, intake triage levels, and section headers.
2. **Inter (Interface & Clinical Narrative)**: Neutral, highly legible humanist-grotesque suited for clinical documentation, patient history, diagnostic findings, and standard form controls.
3. **JetBrains Mono (Data & Telemetry)**: Tabular spacing prevents layout shifts during live data streams. Enforced strictly for CNIC/national IDs, blood pressure, SpO2, heart rates, dosage matrices (e.g., `500mg q8h`), and audit-trail timestamps.

## Layout & Spacing

The layout is built on a strict 8-point spatial grid (with a 4px sub-rhythm for tight data clusters and badges).

- **Grid Architecture**:
  - **Desktop (1024px+)**: 12-column responsive fluid grid with `2rem` outer margins and `1.5rem` gutters. Maximum content canvas spans 1440px centered.
  - **Tablet (768px – 1023px)**: 8-column fluid grid with `1.5rem` margins and `1rem` gutters.
  - **Mobile (< 768px)**: 4-column layout with `1rem` safe margins and `1rem` gutters. Emergency action triggers convert into persistent sticky footers.
- **Spacing Principles**: Generous vertical and horizontal whitespace prevents input error and visual crowding during critical emergencies. Form clusters and vital readouts group related data with `space-xs` and `space-sm`, separating distinct clinical sections with `space-lg` to `space-xl`.

## Elevation & Depth

Depth is conveyed through a crisp, hygienic combination of low-contrast borders and low-opacity ambient shadows. Blur values remain short to avoid visual fuzziness.

- **Level 0 (Flat Canvas)**: Background canvas (`#F7FAFC`). No shadow, no border.
- **Level 1 (Card & Content Surface)**: Pure white background (`#FFFFFF`), solid border `1px solid #E2E8F0`, and ambient drop: `box-shadow: 0 1px 3px 0 rgba(36, 55, 70, 0.04), 0 1px 2px -1px rgba(36, 55, 70, 0.04)`.
- **Level 2 (Dropdowns, Popovers, & Critical Cards)**: White background (`#FFFFFF`), border `1px solid #E2E8F0`, with `box-shadow: 0 4px 6px -1px rgba(36, 55, 70, 0.07), 0 2px 4px -2px rgba(36, 55, 70, 0.05)`.
- **Level 3 (Emergency Modals & Action Sheets)**: White background (`#FFFFFF`), no perimeter line, supported by `box-shadow: 0 20px 25px -5px rgba(36, 55, 70, 0.1), 0 8px 10px -6px rgba(36, 55, 70, 0.05)`. Backdrop overlay is locked to `#243746` at 35% opacity.

## Shapes

The geometric personality balances clinical precision with approachable reassurance:

- **Cards & Data Panels**: 16px corner radius (`1rem` to `1.125rem`). This provides soft separation without wasting screen real estate.
- **Interactive Controls (Buttons, Inputs, Selects)**: 10px corner radius (`0.625rem`), providing clean tactile affordance that resists accidental clicks.
- **Badges, Telemetry Tags, & Status Pills**: Full pill border-radius (`9999px`) for instantaneous scanning.
- **Dividers & Outlines**: Hairline `1px` geometry across all surfaces, avoiding thick brutalist outlines.

## Components

### Buttons
- **Primary Clinical Action**: Background `#0F766E`, text `#FFFFFF`, radius `10px`, min-height `44px` (48px on mobile for target acquisition). Active/hover: `#115E59`.
- **Critical Emergency Action**: Background `#D94848`, text `#FFFFFF`, radius `10px`. Reserved strictly for cardiac arrest alerts, rapid response dispatch, and irreversible critical commands.
- **Secondary / Ghost**: Background `transparent`, text `#243746`, border `1px solid #E2E8F0`, radius `10px`. Hover: background `#F7FAFC`.

### Input Fields & Controls
- **Fields**: Background `#FFFFFF`, border `1px solid #E2E8F0`, radius `10px`, typography `Inter body-md`. Focused state: border `#0F766E` with a `2px` focus-ring outline in `#E8F6F3`.
- **Monospace Fields (CNIC, Dosages)**: Pre-formatted input mask with `JetBrains Mono telemetry-md` to avoid numerical confusion.
- **Checkboxes & Radios**: 20px hitboxes, `#0F766E` active fill with white check/dot, border `#E2E8F0` when unselected.

### Cards & Telemetry Displays
- **Standard Clinical Card**: White background, `16px` border-radius, border `1px solid #E2E8F0`, padding `1.5rem`.
- **Vital Telemetry Card**: White background containing a top badge with vital name in `Inter label-md`, numeric reading in `JetBrains Mono telemetry-lg`, and baseline status indicator (e.g., green pill badge `#F0FDF4` / text `#16A34A`).
- **Emergency Alert Card**: Soft red container `#FEF2F2`, border `1px solid #D94848`, text `#243746`, with an emergency critical red left indicator rail (`4px` thick).

### Chips & Badges
- **Status Pills**: 4px vertical, 10px horizontal padding, pill-shaped.
  - Critical: Background `#FEF2F2`, text `#D94848`, font `JetBrains Mono telemetry-sm`.
  - Moderate/Warning: Background `#FFFBEB`, text `#D97706`.
  - Normal/Active: Background `#E8F6F3`, text `#0F766E`.
  - Informational: Background `#EAF3FF`, text `#243746`.

### Clinical Triage List Rows
- Edge-to-edge separators using `#E2E8F0`. Hover row states switch to `#F7FAFC`. Patient identifier rendered in `JetBrains Mono`, names in `Sora headline-sm`, and clinical notes in `Inter body-sm`.