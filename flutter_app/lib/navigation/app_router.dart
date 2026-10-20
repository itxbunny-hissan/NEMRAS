import 'package:flutter/material.dart';
import 'package:nemras_layout/nemras_layout.dart';

import '../api.dart';
import '../screens/audit_log_screen.dart';
import '../screens/emergency_details_screen.dart';
import '../screens/emergency_tracking_screen.dart';
import '../screens/medical_profile_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/patient_shell.dart';
import '../screens/scan_screen.dart';
import '../screens/secure_boot_screen.dart';
import '../screens/citizen_sign_up_screen.dart';
import '../screens/dev_email_sign_in_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/otp_verification_screen.dart';
import '../screens/reset_password_screen.dart';
import '../screens/role_selection_screen.dart';
import '../screens/profile_setup_screen.dart';
import '../screens/location_permission_screen.dart';
import '../screens/notification_permission_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/summary_screen.dart';
import '../paramedic/screens/paramedic_shell.dart';

/// Centralised NEMRAS route definitions.
///
/// Routes come in two kinds, deliberately:
///
/// * The first-run flow carries no arguments, so it is addressable by name
///   through [onGenerateRoute].
/// * Destinations that carry a [PatientRecord] stay typed factory methods.
///   Routing a patient record through `RouteSettings.arguments` would mean an
///   untyped cast on clinical data at every call site, which is a type-safety
///   downgrade NEMRAS should not take.
///
/// No routing package is used; these are Flutter's own [Route] types.
abstract final class AppRouter {
  /// The 500ms cross-fade the first-run screens already used.
  static Route<T> _fade<T>(Widget page) => PageRouteBuilder<T>(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      );

  static Route<T> _page<T>(Widget page) =>
      MaterialPageRoute<T>(builder: (_) => page);

  /// First-run flow: Splash -> Secure Boot -> Onboarding -> Sign In.
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case NemrasRouteNames.splash:
        return _page<void>(const SplashScreen());
      case NemrasRouteNames.secureBoot:
        return _fade<void>(const SecureBootScreen());
      case NemrasRouteNames.onboarding:
        return _fade<void>(const OnboardingScreen());
      case NemrasRouteNames.signIn:
        return _page<void>(const ScanScreen());
      case NemrasRouteNames.signUp:
        return _page<void>(const CitizenSignUpScreen());
      case NemrasRouteNames.forgotPassword:
        return _page<void>(const ForgotPasswordScreen());
      case NemrasRouteNames.otpVerification:
        return _page<void>(const OtpVerificationScreen());
      case NemrasRouteNames.resetPassword:
        return _page<void>(const ResetPasswordScreen());
      case NemrasRouteNames.roleSelection:
        return _page<void>(const RoleSelectionScreen());
      case NemrasRouteNames.profileSetup:
        return _page<void>(const ProfileSetupScreen());
      case NemrasRouteNames.locationPermission:
        return _page<void>(const LocationPermissionScreen());
      case NemrasRouteNames.notificationPermission:
        return _page<void>(const NotificationPermissionScreen());
      case NemrasRouteNames.paramedicScan:
        return _page<void>(const ParamedicShell(initialIndex: 0));
      case NemrasRouteNames.paramedicVoice:
        return _page<void>(const ParamedicShell(initialIndex: 1));
      case NemrasRouteNames.paramedicDrugs:
        return _page<void>(const ParamedicShell(initialIndex: 2));
      case NemrasRouteNames.paramedicRoute:
        return _page<void>(const ParamedicShell(initialIndex: 3));
      default:
        return null;
    }
  }

  // Authenticated patient flow.
  static Route<void> patientShell(PatientRecord record) =>
      _page<void>(PatientShell(record: record));

  static Route<void> patientAuditLog(PatientRecord record) =>
      _page<void>(AuditLogScreen(record: record));

  static Route<void> patientSummary(PatientRecord record) =>
      _page<void>(SummaryScreen(record: record));

  static Route<void> emergencyDetails(
    PatientRecord record, {
    required String incident,
  }) =>
      _page<void>(
        EmergencyDetailsScreen(record: record, incident: incident),
      );

  static Route<void> emergencyTracking(PatientRecord record) =>
      _page<void>(EmergencyTrackingScreen(record: record));

  static Route<void> medicalProfile(PatientRecord record) =>
      _page<void>(MedicalProfileScreen(record: record));

  static Route<void> chat({required String cnic, required String name}) =>
      _page<void>(ChatScreen(cnic: cnic, name: name));

  /// Development Supabase e-mail sign-in. Grants no patient-record access.
  static Route<void> devEmailSignIn() =>
      _page<void>(const DevEmailSignInScreen());

  static Route<void> paramedicShell({int initialIndex = 0}) =>
      _page<void>(ParamedicShell(initialIndex: initialIndex));

  /// The shell a role lands in after authentication.
  ///
  /// Desktop shells remain unavailable until their screens exist.
  static Route<void>? shellFor(
    NemrasRole role, {
    PatientRecord? patientRecord,
  }) {
    switch (NemrasRoleConfig.of(role).shell) {
      case NemrasShellKind.patientMobile:
        return patientRecord == null ? null : patientShell(patientRecord);
      case NemrasShellKind.paramedicField:
        return paramedicShell();
      case NemrasShellKind.desktopClinical:
      case NemrasShellKind.desktopOperational:
      case NemrasShellKind.desktopCentral:
        return null;
    }
  }
}
