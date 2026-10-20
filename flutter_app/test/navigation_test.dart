import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nemras/dev/demo_auth.dart';
import 'package:nemras/navigation/app_router.dart';
import 'package:nemras/screens/citizen_sign_up_screen.dart';
import 'package:nemras/screens/forgot_password_screen.dart';
import 'package:nemras/screens/otp_verification_screen.dart';
import 'package:nemras/screens/reset_password_screen.dart';
import 'package:nemras/screens/role_selection_screen.dart';
import 'package:nemras/screens/profile_setup_screen.dart';
import 'package:nemras/screens/location_permission_screen.dart';
import 'package:nemras/screens/notification_permission_screen.dart';
import 'package:nemras/screens/onboarding_screen.dart';
import 'package:nemras/screens/emergency_details_screen.dart';
import 'package:nemras/screens/medical_profile_screen.dart';
import 'package:nemras/screens/emergency_tracking_screen.dart';
import 'package:nemras/screens/patient_home_screen.dart';
import 'package:nemras/screens/sos_emergency_screen.dart';
import 'package:nemras/screens/patient_shell.dart';
import 'package:nemras/screens/scan_screen.dart';
import 'package:nemras/screens/secure_boot_screen.dart';
import 'package:nemras/screens/splash_screen.dart';
import 'package:nemras/paramedic/screens/paramedic_shell.dart';
import 'package:nemras_design/nemras_design.dart';
import 'package:nemras_layout/nemras_layout.dart';

void main() {
  group('AppRouter.onGenerateRoute', () {
    test('resolves the first-run flow by name', () {
      for (final name in <String>[
        NemrasRouteNames.splash,
        NemrasRouteNames.secureBoot,
        NemrasRouteNames.onboarding,
        NemrasRouteNames.signIn,
        NemrasRouteNames.signUp,
        NemrasRouteNames.forgotPassword,
        NemrasRouteNames.otpVerification,
        NemrasRouteNames.resetPassword,
        NemrasRouteNames.roleSelection,
        NemrasRouteNames.profileSetup,
        NemrasRouteNames.locationPermission,
        NemrasRouteNames.notificationPermission,
      ]) {
        expect(
          AppRouter.onGenerateRoute(RouteSettings(name: name)),
          isNotNull,
          reason: '$name should be addressable by name',
        );
      }
    });

    test('returns null for an unknown route', () {
      expect(
        AppRouter.onGenerateRoute(const RouteSettings(name: '/nope')),
        isNull,
      );
    });

    test('resolves every paramedic field destination by name', () {
      for (final name in <String>[
        NemrasRouteNames.paramedicScan,
        NemrasRouteNames.paramedicVoice,
        NemrasRouteNames.paramedicDrugs,
        NemrasRouteNames.paramedicRoute,
      ]) {
        expect(
          AppRouter.onGenerateRoute(RouteSettings(name: name)),
          isNotNull,
          reason: '$name should open the paramedic shell',
        );
      }
    });

    test('does not expose desktop destinations whose screens do not exist', () {
      for (final name in <String>[
        NemrasRouteNames.hospitalOverview,
        NemrasRouteNames.centralNationalOverview,
      ]) {
        expect(AppRouter.onGenerateRoute(RouteSettings(name: name)), isNull);
      }
    });
  });

  group('AppRouter.shellFor', () {
    test('the patient role resolves to the patient shell', () {
      final route = AppRouter.shellFor(
        NemrasRole.patient,
        patientRecord: buildDemoPatientRecord(),
      );
      expect(route, isNotNull);
    });

    test('the patient role needs a record', () {
      expect(AppRouter.shellFor(NemrasRole.patient), isNull);
    });

    test('the paramedic role resolves to the field shell', () {
      expect(AppRouter.shellFor(NemrasRole.paramedic), isNotNull);
    });

    test(
        'desktop roles whose shells are not implemented resolve to null rather than '
        'a fabricated screen', () {
      for (final role in <NemrasRole>[
        NemrasRole.emergencyPhysician,
        NemrasRole.hospitalAdministrator,
        NemrasRole.ministryAnalyst,
        NemrasRole.systemAdministrator,
      ]) {
        expect(AppRouter.shellFor(role), isNull, reason: '$role');
      }
    });
  });

  group('Paramedic shell routing', () {
    testWidgets('the paramedic route uses the separate dark field shell',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: nemrasClinicalLightTheme(),
          onGenerateRoute: AppRouter.onGenerateRoute,
          initialRoute: NemrasRouteNames.paramedicScan,
        ),
      );

      expect(find.byType(ParamedicShell), findsOneWidget);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(320, 640));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('No unit is assigned'), findsOneWidget);
      await tester.binding.setSurfaceSize(const Size(320, 640));
      await tester.pump();
      await tester.ensureVisible(find.text('View all dispatches'));
      await tester.tap(find.text('View all dispatches'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.text(
          'No live emergency requests are connected in this prototype.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Accept dispatch'),
            )
            .onPressed,
        isNull,
      );
      expect(find.textContaining('1.8'), findsNothing);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('No unit is assigned'), findsOneWidget);
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Accept dispatch'),
            )
            .onPressed,
        isNull,
      );
      final context = tester.element(find.byType(AdaptiveScaffold));
      expect(NemrasSemantics.of(context).isField, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('first-run flow', () {
    testWidgets('Splash advances to Secure Boot through the named route',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: nemrasClinicalLightTheme(),
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: const SplashScreen(),
        ),
      );
      expect(find.byType(SplashScreen), findsOneWidget);

      // Past the 2800ms splash delay plus the 500ms cross-fade.
      await tester.pump(const Duration(milliseconds: 2800));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(SecureBootScreen), findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing);

      // Dispose so the secure-boot countdown timer is cancelled.
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Onboarding advances to Sign In', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: nemrasClinicalLightTheme(),
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: const OnboardingScreen(),
        ),
      );

      // The welcome screen's primary action opens the existing sign-in route.
      final signIn = find.text('Sign In to Account  →');
      await tester.ensureVisible(signIn);
      expect(tester.takeException(), isNull);

      await tester.tap(signIn);
      await tester.pumpAndSettle();
      expect(find.text('Sign In to NEMRAS'), findsOneWidget);
      expect(tester.takeException(), isNull);

      expect(find.byType(ScanScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('unavailable welcome actions stay on this screen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: nemrasClinicalLightTheme(),
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: const OnboardingScreen(),
        ),
      );

      await tester.ensureVisible(find.text('Create Citizen Account'));
      await tester.tap(find.text('Create Citizen Account'));
      await tester.pumpAndSettle();
      expect(
        find.text('Citizen registration is not available in this prototype yet.'),
        findsOneWidget,
      );
      expect(tester.widget<ElevatedButton>(find.widgetWithText(
        ElevatedButton,
        'Continue to Verification',
      )).onPressed, isNull);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsOneWidget);

      await tester.ensureVisible(find.text('NFC Badge Rapid Tap →'));
      await tester.tap(find.text('NFC Badge Rapid Tap →'));
      await tester.pumpAndSettle();
      expect(
        find.text('NFC badge sign-in is not available in this build. '
            'Paramedic access is not started from this screen.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(ScanScreen), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('citizen sign-up is informational and returns to sign-in',
        (tester) async {
      Future<void> pumpAt(Size size) async {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          MaterialApp(
            theme: nemrasClinicalLightTheme(),
            onGenerateRoute: AppRouter.onGenerateRoute,
            home: const CitizenSignUpScreen(),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(
          find.text(
            'Citizen registration is not available in this prototype yet.',
          ),
          findsOneWidget,
        );
      }

      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpAt(const Size(320, 640));
      await pumpAt(const Size(390, 844));

      await tester.ensureVisible(find.text('Sign In Here'));
      await tester.tap(find.text('Sign In Here'));
      await tester.pumpAndSettle();
      expect(find.byType(ScanScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('forgot password is informational and returns to sign-in',
        (tester) async {
      Future<void> pumpAt(Size size) async {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          MaterialApp(
            theme: nemrasClinicalLightTheme(),
            onGenerateRoute: AppRouter.onGenerateRoute,
            home: const ForgotPasswordScreen(),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(
          find.text(
            'Account recovery is not available in this prototype. '
            'No verification code will be sent.',
          ),
          findsOneWidget,
        );
        expect(
          tester
              .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'Send Verification Code'),
              )
              .onPressed,
          isNull,
        );
      }

      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpAt(const Size(320, 640));
      await pumpAt(const Size(390, 844));

      await tester.ensureVisible(find.text('Back to Sign In'));
      await tester.tap(find.text('Back to Sign In'));
      await tester.pumpAndSettle();
      expect(find.byType(ScanScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('verification and reset layouts stay disabled', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(320, 640));
      await tester.pumpWidget(
        MaterialApp(
          theme: nemrasClinicalLightTheme(),
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: const OtpVerificationScreen(),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        find.text(
          'Identity verification is not available in this prototype. '
          'No code was sent to a phone number.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Verify Code'),
            )
            .onPressed,
        isNull,
      );

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        MaterialApp(
          theme: nemrasClinicalLightTheme(),
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: const ResetPasswordScreen(),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        find.text(
          'Password reset is not available in this prototype. '
          'Nothing entered here is saved.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Save & Sign In'),
            )
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(find.text('Back to Sign In'));
      await tester.tap(find.text('Back to Sign In'));
      await tester.pumpAndSettle();
      expect(find.byType(ScanScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('role and profile layouts do not grant access', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(320, 640));
      await tester.pumpWidget(
        MaterialApp(
          theme: nemrasClinicalLightTheme(),
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: const RoleSelectionScreen(),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        find.text(
          'Choosing a card does not grant access. '
          'Role provisioning is not available in this prototype.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(
                ElevatedButton,
                'Continue to Profile Setup',
              ),
            )
            .onPressed,
        isNull,
      );

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        MaterialApp(
          theme: nemrasClinicalLightTheme(),
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: const ProfileSetupScreen(),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        find.text(
          'Profile setup is not available in this prototype. '
          'No identity or medical details are collected.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(
                ElevatedButton,
                'Save & Proceed to Permissions',
              ),
            )
            .onPressed,
        isNull,
      );
      expect(find.text('Kashaf Sajjad'), findsNothing);
      await tester.ensureVisible(find.text('Back to Sign In'));
      await tester.tap(find.text('Back to Sign In'));
      await tester.pumpAndSettle();
      expect(find.byType(ScanScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('permission layouts do not request access', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(320, 640));
      await tester.pumpWidget(
        MaterialApp(
          theme: nemrasClinicalLightTheme(),
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: const LocationPermissionScreen(),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        find.text(
          'Location permission is not requested in this prototype. '
          'No coordinates are read or shared.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Allow Precise Location'),
            )
            .onPressed,
        isNull,
      );

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        MaterialApp(
          theme: nemrasClinicalLightTheme(),
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: const NotificationPermissionScreen(),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        find.text(
          'Notification permission is not requested in this prototype. '
          'No alert will be sent.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(
                ElevatedButton,
                'Enable Urgent Notifications',
              ),
            )
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(find.text('Continue to Sign In'));
      await tester.tap(find.text('Continue to Sign In'));
      await tester.pumpAndSettle();
      expect(find.byType(ScanScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('PatientShell on the layout foundation', () {
    Widget harness(Size size) => MaterialApp(
          theme: nemrasClinicalLightTheme(),
          home: MediaQuery(
            data: MediaQueryData(size: size),
            child: PatientShell(record: buildDemoPatientRecord()),
          ),
        );

    testWidgets('uses the shared adaptive scaffold', (tester) async {
      await tester.pumpWidget(harness(const Size(390, 844)));

      expect(find.byType(AdaptiveScaffold), findsOneWidget);
      expect(find.byType(NemrasBottomNavigation), findsOneWidget);
    });

    testWidgets('keeps the four patient destinations', (tester) async {
      await tester.pumpWidget(harness(const Size(390, 844)));

      for (final label in <String>['Home', 'Record', 'Chat', 'Profile']) {
        expect(find.text(label), findsWidgets);
      }
    });

    testWidgets('home shows the signed-in record and does not dispatch',
        (tester) async {
      final tabs = <int>[];
      Future<void> pumpAt(Size size) async {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          MaterialApp(
            theme: nemrasClinicalLightTheme(),
            home: PatientHomeScreen(
              record: buildDemoPatientRecord(),
              onTabChange: tabs.add,
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      }

      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpAt(const Size(320, 640));
      await pumpAt(const Size(390, 844));

      expect(find.text('Mirza Hissan'), findsOneWidget);
      expect(find.text('CNIC 36302-2493960-7'), findsOneWidget);
      expect(find.text('Penicillin'), findsOneWidget);
      expect(find.textContaining('Nishtar Hospital'), findsOneWidget);
      expect(find.text('Synthetic demo record'), findsOneWidget);
      expect(find.text('Kashaf Sajjad'), findsNothing);
      expect(find.textContaining('9821411'), findsNothing);
      expect(find.text('NADRA'), findsNothing);

      await tester.binding.setSurfaceSize(const Size(320, 640));
      await tester.pump();
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'SOS'));
      await tester.tap(find.widgetWithText(FilledButton, 'SOS'));
      await tester.pumpAndSettle();
      expect(find.byType(SosEmergencyScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(
        find.text(
          'This prototype does not contact Rescue 1122, send a location, or alert a hospital.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(
                ElevatedButton,
                'Call 1122 is not started here',
              ),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Medical / Cardiac'));
      await tester.pump();
      expect(find.text('Dispatch channel: not connected'), findsOneWidget);
      await tester.ensureVisible(find.text('Cancel / Exit'));
      await tester.tap(find.text('Cancel / Exit'));
      await tester.pumpAndSettle();
      expect(find.byType(PatientHomeScreen), findsOneWidget);

      await tester.ensureVisible(find.text('Medical profile'));
      await tester.tap(find.text('Medical profile'));
      await tester.pumpAndSettle();
      expect(find.byType(MedicalProfileScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(
        find.descendant(
          of: find.byType(MedicalProfileScreen),
          matching: find.text('Penicillin'),
        ),
        findsOneWidget,
      );
      expect(find.text('No emergency contact is stored on this record.'), findsOneWidget);
      expect(find.text('Kashaf Sajjad'), findsNothing);
      expect(find.text('NADRA'), findsNothing);
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(
                ElevatedButton,
                'Save & Synchronize Dossier',
              ),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(PatientHomeScreen), findsOneWidget);

      await tester.ensureVisible(find.text('Record notes'));
      await tester.tap(find.text('Record notes'));
      expect(tabs, [1]);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('medical profile fits a narrow width', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final size in const [Size(320, 640), Size(390, 844)]) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          MaterialApp(
            theme: nemrasClinicalLightTheme(),
            home: MedicalProfileScreen(record: buildDemoPatientRecord()),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Synthetic demo record'), findsOneWidget);
        expect(find.text('Blood type: A+'), findsOneWidget);
        expect(find.text('Dermatitis'), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('emergency details stays on the record and does not alert',
        (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      Future<void> openAt(Size size) async {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          MaterialApp(
            theme: nemrasClinicalLightTheme(),
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.push(
                  context,
                  AppRouter.emergencyDetails(
                    buildDemoPatientRecord(),
                    incident: 'Medical / Cardiac',
                  ),
                ),
                child: const Text('Open details'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open details'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(EmergencyDetailsScreen), findsOneWidget);
      }

      await openAt(const Size(320, 640));
      expect(find.text('Mirza Hissan'), findsOneWidget);
      expect(find.text('Synthetic demo'), findsOneWidget);
      expect(find.text('Penicillin'), findsOneWidget);
      expect(find.text('Blood A+'), findsOneWidget);
      expect(find.text('Dermatitis'), findsOneWidget);
      expect(find.text('Kashaf Sajjad'), findsNothing);
      expect(find.textContaining('Warfarin'), findsNothing);
      expect(find.textContaining('Gate 2'), findsNothing);
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(
                ElevatedButton,
                'Submit Request & Alert 1122',
              ),
            )
            .onPressed,
        isNull,
      );

      await tester.tap(find.text('Change'));
      await tester.pumpAndSettle();
      expect(find.text('Open details'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await openAt(const Size(390, 844));
      expect(find.text('No dispatch is active'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('tracking layout does not assign a responder', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final size in const [Size(320, 640), Size(390, 844)]) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          MaterialApp(
            theme: nemrasClinicalLightTheme(),
            home: EmergencyTrackingScreen(record: buildDemoPatientRecord()),
          ),
        );
        expect(tester.takeException(), isNull);
      }
      expect(find.text('No incident is active'), findsOneWidget);
      expect(find.textContaining('Nishtar Hospital'), findsOneWidget);
      expect(find.textContaining('AMB-37'), findsNothing);
      expect(find.textContaining('04:28'), findsNothing);
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(
                ElevatedButton,
                'Call crew is not available',
              ),
            )
            .onPressed,
        isNull,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('stays a mobile surface on a desktop-width window',
        (tester) async {
      await tester.pumpWidget(harness(const Size(1440, 900)));

      expect(find.byType(NemrasBottomNavigation), findsOneWidget);
      expect(find.byType(NemrasDesktopSidebar), findsNothing);
    });
  });
}
