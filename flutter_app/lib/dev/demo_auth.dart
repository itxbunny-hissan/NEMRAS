/// ============================================================
/// DEVELOPMENT / DEMO AUTHENTICATION  —  NOT PRODUCTION CODE
/// ============================================================
/// This file isolates the temporary demo sign-in used for the FYP viva so it
/// is never mistaken for the real authentication path. It contains:
///
///   * a fixed demo OTP (no SMS is sent, nothing is verified server-side)
///   * one clearly-labelled SYNTHETIC patient record so the demo runs with
///     the backend switched off
///
/// Everything here is fabricated for demonstration. No real patient record is
/// represented, and no value in this file is read from NEMRAS_Dataset.csv.
///
/// ---------------------------------------------------------------
/// TODO(production-auth): replace this entire file with Firebase
/// Authentication Phone Auth.
///
///   1. Call `/api/auth/phone/{cnic}` to confirm the CNIC is eligible for OTP
///      and to show the masked number hint. The raw number is never returned.
///   2. Call `FirebaseAuth.instance.verifyPhoneNumber(...)` so Firebase
///      generates, sends and verifies the OTP. NEMRAS never sees the code and
///      must never store it.
///   3. Send the resulting Firebase ID token to the backend; the backend
///      verifies it, resolves the Firebase UID -> CNIC mapping server-side,
///      and authorises record access. CNIC is the NEMRAS patient identifier;
///      the Firebase UID stays the identity identifier.
///   4. Enforce authorisation and audit logging in the backend, never in this
///      Flutter UI.
///
/// Until step 1-4 exist, [kDemoAuthEnabled] must stay the only way this code
/// path can be reached, and it must be false in any production build.
/// ---------------------------------------------------------------
library;

import '../api.dart';

/// Master switch for all demo authentication.
///
/// Set to false (or build with
/// `--dart-define=NEMRAS_DEMO_AUTH=false`) to disable every shortcut in this
/// file. Must be false once real Firebase Phone Auth is wired up.
const bool kDemoAuthEnabled = bool.fromEnvironment(
  'NEMRAS_DEMO_AUTH',
  defaultValue: true,
);

/// DEMO ONLY. Fixed code shown on screen instead of sending an SMS.
const String kDemoOtp = '123456';

/// DEMO ONLY. The single CNIC that the offline demo record is bound to,
/// digits only.
const String _kDemoCnicDigits = '3630224939607';

/// True for the synthetic offline record built by [buildDemoPatientRecord].
bool isDemoPatientRecord(PatientRecord record) {
  return record.summary.cnic.replaceAll('-', '').trim() == _kDemoCnicDigits;
}

/// True when these credentials match the offline demo account.
///
/// Returns false whenever [kDemoAuthEnabled] is false, so disabling the flag
/// removes the shortcut entirely rather than just hiding it.
bool isDemoLogin(String cnic, String otp) {
  if (!kDemoAuthEnabled) return false;
  return cnic.replaceAll('-', '').trim() == _kDemoCnicDigits &&
      otp.trim() == kDemoOtp;
}

/// DEMO ONLY. Fully synthetic record returned by the offline demo login.
///
/// Fabricated sample data for demonstration purposes. Not a real patient and
/// not sourced from NEMRAS_Dataset.csv.
PatientRecord buildDemoPatientRecord() {
  return PatientRecord(
    PatientSummary.fromJson({
      'cnic': '36302-2493960-7',
      'patient_name': 'Mirza Hissan',
      'age': 22,
      'gender': 'Male',
      'blood_type': 'A+',
      'medical_condition': 'Dermatitis',
      'medication': 'Hydrocortisone',
      'allergy': 'Penicillin',
      'chronic_condition': 'No',
      'drug_interaction_risk': 'No',
      'triage_level': '3',
      'risk_score': 'Low',
      'admission_type': 'Emergency',
      'test_results': 'Normal',
      'hospital': 'Nishtar Hospital',
      'doctor': 'Dr. Irfan',
      'insurance_provider': 'State Life',
      'admission_date': '2025-03-10',
      'discharge_date': '2025-03-12',
    }),
    [
      Alert.fromJson({
        'severity': 'info',
        'title': 'Known allergy on file',
        'detail': 'Patient is allergic to Penicillin. Avoid related drugs.',
      }),
    ],
  );
}
