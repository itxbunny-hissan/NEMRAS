/// Stable identifiers for NEMRAS destinations.
///
/// This package only names routes so navigation models can reference them.
/// Mapping a name to a screen is the consuming application's job, which keeps
/// the dependency direction one-way.
abstract final class NemrasRouteNames {
  // First-run flow
  static const String splash = '/';
  static const String secureBoot = '/secure-boot';
  static const String onboarding = '/onboarding';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String forgotPassword = '/forgot-password';
  static const String otpVerification = '/otp-verification';
  static const String resetPassword = '/reset-password';
  static const String roleSelection = '/role-selection';
  static const String profileSetup = '/profile-setup';
  static const String locationPermission = '/location-permission';
  static const String notificationPermission = '/notification-permission';

  // Patient surface
  static const String patientHome = '/patient/home';
  static const String patientRecord = '/patient/record';
  static const String patientChat = '/patient/chat';
  static const String patientProfile = '/patient/profile';
  static const String patientAuditLog = '/patient/audit-log';

  // Paramedic field surface.
  static const String paramedicScan = '/paramedic/scan';
  static const String paramedicVoice = '/paramedic/voice';
  static const String paramedicDrugs = '/paramedic/drugs';
  static const String paramedicRoute = '/paramedic/route';

  // Hospital surface.
  //
  // The operational destinations below are transcribed from the reference
  // sidebar and are referenced by `NemrasNavigationCatalog.hospital`. The
  // clinical destinations that follow are not in the reference sidebar; they
  // belong to the Phase 3A clinical desktop, which composes its own
  // navigation. They are named here so no surface has to invent route strings.
  static const String hospitalOverview = '/hospital/overview';
  static const String hospitalBedOccupancy = '/hospital/bed-occupancy';
  static const String hospitalEmergency = '/hospital/emergency';
  static const String hospitalPatients = '/hospital/patients';
  static const String hospitalDepartments = '/hospital/departments';
  static const String hospitalCompliance = '/hospital/compliance';
  static const String hospitalAuditTrail = '/hospital/audit-trail';
  static const String hospitalSettings = '/hospital/settings';

  // Hospital operational destinations.
  static const String hospitalReports = '/hospital/reports';

  // Hospital clinical destinations.
  static const String hospitalLogin = '/hospital/login';
  static const String hospitalClinicalRecords = '/hospital/clinical-records';
  static const String hospitalAiAssistant = '/hospital/ai-assistant';
  static const String hospitalMedications = '/hospital/medications';
  static const String hospitalHandover = '/hospital/handover';

  // Central/ministry surface. Transcribed from the reference sidebar.
  static const String centralNationalOverview = '/central/national-overview';
  static const String centralRegionalMaps = '/central/regional-maps';
  static const String centralDiseaseTrends = '/central/disease-trends';
  static const String centralDemographics = '/central/demographics';
  static const String centralHospitalNodes = '/central/hospital-nodes';
  static const String centralSystemHealth = '/central/system-health';
  static const String centralPolicyReports = '/central/policy-reports';

  // Additional national destinations implemented by the ministry dashboard.
  // The reference sidebar predates these screens, so they are named here
  // rather than added to the transcribed catalogue.
  static const String centralEmergencyTrends = '/central/emergency-trends';
  static const String centralHealthIndicators = '/central/health-indicators';
  static const String centralHospitalNetwork = '/central/hospital-network';
  static const String centralFederation = '/central/federation';
  static const String centralReports = '/central/reports';
  static const String centralGovernance = '/central/governance';
  static const String centralSettings = '/central/settings';
}
