/// ============================================================
/// PORTFOLIO SCREENSHOT GENERATOR  —  NOT PART OF THE TEST SUITE
/// ============================================================
/// Renders the real patient and paramedic screens at a fixed phone surface and
/// writes them as PNGs into the portfolio's screen gallery.
///
/// This file is deliberately **not** named `*_test.dart`, so `flutter test`
/// does not pick it up. Regenerate the gallery explicitly:
///
///   flutter test test/portfolio_screenshots.dart --update-goldens
///
/// Why a test and not browser automation: the mobile surfaces render to a
/// canvas, and Flutter's text fields cannot be driven from outside the
/// framework, so the authenticated screens are unreachable through a browser.
/// Rendering here uses the same production widgets with the clearly-labelled
/// synthetic demo record from `lib/dev/demo_auth.dart`. No real patient data,
/// no network and no camera are involved.
///
/// The live CNIC scanner is intentionally never opened here. It needs real
/// camera permission and a camera device, so it cannot be captured in a
/// headless render. It is documented as such in the gallery rather than faked.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nemras/api.dart';
import 'package:nemras/dev/demo_auth.dart';
import 'package:nemras/paramedic/screens/paramedic_shell.dart';
import 'package:nemras/paramedic/state/paramedic_session_controller.dart';
import 'package:nemras/screens/audit_log_screen.dart';
import 'package:nemras/screens/onboarding_screen.dart';
import 'package:nemras/screens/patient_shell.dart';
import 'package:nemras/screens/scan_screen.dart';
import 'package:nemras/screens/secure_boot_screen.dart';
import 'package:nemras/screens/splash_screen.dart';
import 'package:nemras/screens/summary_screen.dart';
import 'package:nemras_design/nemras_design.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Phone surface the gallery is captured at, in logical pixels.
const Size _phone = Size(412, 915);

/// Captured at 2x so the gallery stays crisp when scaled down in the portfolio.
const double _scale = 2;

/// Where the portfolio gallery expects the PNGs, relative to this file.
const String _patientDir = '../../apps/portfolio/assets/screens/patient';
const String _paramedicDir = '../../apps/portfolio/assets/screens/paramedic';

/// Static font files declared by `nemras_design`, keyed by the family name
/// Flutter resolves them to once the `package:` prefix is applied.
const Map<String, List<String>> _fontFiles = <String, List<String>>{
  'packages/nemras_design/Sora': <String>[
    '../packages/nemras_design/fonts/sora/Sora-SemiBold.ttf',
    '../packages/nemras_design/fonts/sora/Sora-Bold.ttf',
    '../packages/nemras_design/fonts/sora/Sora-ExtraBold.ttf',
  ],
  'packages/nemras_design/Inter': <String>[
    '../packages/nemras_design/fonts/inter/Inter-Regular.ttf',
    '../packages/nemras_design/fonts/inter/Inter-Medium.ttf',
    '../packages/nemras_design/fonts/inter/Inter-SemiBold.ttf',
    '../packages/nemras_design/fonts/inter/Inter-Bold.ttf',
  ],
  'packages/nemras_design/JetBrainsMono': <String>[
    '../packages/nemras_design/fonts/jetbrains_mono/JetBrainsMono-Regular.ttf',
    '../packages/nemras_design/fonts/jetbrains_mono/JetBrainsMono-Medium.ttf',
    '../packages/nemras_design/fonts/jetbrains_mono/JetBrainsMono-SemiBold.ttf',
  ],
};

/// Candidate locations for the Material icon glyphs, which `flutter test` does
/// not load for us. Without them every `Icon` renders as an empty box.
List<String> _materialIconsCandidates() {
  final String? flutterRoot = Platform.environment['FLUTTER_ROOT'];
  return <String>[
    if (flutterRoot != null)
      '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    'build/unit_test_assets/fonts/MaterialIcons-Regular.otf',
  ];
}

Future<void> _loadFonts() async {
  final Map<String, List<String>> families = <String, List<String>>{
    ..._fontFiles,
    'MaterialIcons': <String>[
      _materialIconsCandidates().firstWhere(
        (String path) => File(path).existsSync(),
        orElse: () => throw StateError(
          'Material icon font not found; tried '
          '${_materialIconsCandidates().join(', ')}',
        ),
      ),
    ],
  };

  for (final MapEntry<String, List<String>> entry in families.entries) {
    final FontLoader loader = FontLoader(entry.key);
    for (final String path in entry.value) {
      final File file = File(path);
      if (!file.existsSync()) {
        throw StateError('Missing font for the gallery render: $path');
      }
      final Uint8List bytes = await file.readAsBytes();
      loader.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }
}

/// The paramedic controller resolves patients through an injected lookup, so
/// the field screens render from the synthetic demo record with no network.
Future<PatientRecord> _demoLookup(String _) async => buildDemoPatientRecord();

void main() {
  setUpAll(_loadFonts);

  // The sign-in screen restores a remembered session from SharedPreferences,
  // which has no plugin under `flutter test`. Start every render from empty
  // storage so the screen shows its first-use state.
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  /// Pins the surface so every gallery image shares one geometry.
  void usePhoneSurface(WidgetTester tester) {
    tester.view
      ..physicalSize = _phone * _scale
      ..devicePixelRatio = _scale;
    addTearDown(tester.view.reset);
  }

  /// Wraps a screen the way `main.dart` does, so themes and routes match the
  /// shipping app rather than a test-only approximation.
  Widget app(Widget home) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: nemrasClinicalLightTheme(),
        home: home,
      );

  /// Renders [home], settles it, writes the PNG, then unmounts so pending
  /// timers and animation controllers are disposed before the test ends.
  Future<void> capture(
    WidgetTester tester,
    String path,
    Widget home, {
    Duration? settleFor,
    Future<void> Function(WidgetTester tester)? after,
  }) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(app(home));
    if (settleFor == null) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump(settleFor);
    }
    if (after != null) {
      await after(tester);
    }
    await expectLater(find.byType(MaterialApp), matchesGoldenFile(path));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  group('Patient mobile gallery', () {
    testWidgets('splash', (WidgetTester tester) async {
      // Held short of the 2800ms auto-advance so the splash is still mounted.
      await capture(
        tester,
        '$_patientDir/patient_01_splash.png',
        const SplashScreen(),
        settleFor: const Duration(milliseconds: 1200),
      );
    });

    testWidgets('secure boot', (WidgetTester tester) async {
      await capture(
        tester,
        '$_patientDir/patient_02_secure_boot.png',
        const SecureBootScreen(),
        settleFor: const Duration(milliseconds: 1400),
      );
    });

    testWidgets('onboarding - one record', (WidgetTester tester) async {
      await capture(
        tester,
        '$_patientDir/patient_03_onboarding_record.png',
        const OnboardingScreen(),
      );
    });

    testWidgets('onboarding - federated and private',
        (WidgetTester tester) async {
      await capture(
        tester,
        '$_patientDir/patient_04_onboarding_privacy.png',
        const OnboardingScreen(),
        after: (WidgetTester tester) async {
          await tester.tap(find.text('Continue'));
          await tester.pumpAndSettle();
        },
      );
    });

    testWidgets('sign in', (WidgetTester tester) async {
      await capture(
        tester,
        '$_patientDir/patient_05_sign_in.png',
        const ScanScreen(),
      );
    });

    testWidgets('home', (WidgetTester tester) async {
      await capture(
        tester,
        '$_patientDir/patient_06_home.png',
        PatientShell(record: buildDemoPatientRecord()),
      );
    });

    testWidgets('record timeline', (WidgetTester tester) async {
      await capture(
        tester,
        '$_patientDir/patient_07_record_timeline.png',
        PatientShell(record: buildDemoPatientRecord()),
        after: (WidgetTester tester) async {
          await tester.tap(find.text('Record').last);
          await tester.pumpAndSettle();
        },
      );
    });

    testWidgets('assistant chat', (WidgetTester tester) async {
      await capture(
        tester,
        '$_patientDir/patient_08_assistant.png',
        PatientShell(record: buildDemoPatientRecord()),
        after: (WidgetTester tester) async {
          await tester.tap(find.text('Chat').last);
          await tester.pumpAndSettle();
        },
      );
    });

    testWidgets('profile', (WidgetTester tester) async {
      await capture(
        tester,
        '$_patientDir/patient_09_profile.png',
        PatientShell(record: buildDemoPatientRecord()),
        after: (WidgetTester tester) async {
          await tester.tap(find.text('Profile').last);
          await tester.pumpAndSettle();
        },
      );
    });

    testWidgets('access audit log', (WidgetTester tester) async {
      await capture(
        tester,
        '$_patientDir/patient_10_audit_log.png',
        AuditLogScreen(record: buildDemoPatientRecord()),
      );
    });

    testWidgets('emergency summary card', (WidgetTester tester) async {
      await capture(
        tester,
        '$_patientDir/patient_11_emergency_summary.png',
        SummaryScreen(record: buildDemoPatientRecord()),
      );
    });
  });

  group('Paramedic field gallery', () {
    testWidgets('scan - awaiting patient', (WidgetTester tester) async {
      final ParamedicSessionController controller =
          ParamedicSessionController(patientLookup: _demoLookup);
      addTearDown(controller.dispose);

      await capture(
        tester,
        '$_paramedicDir/paramedic_01_scan.png',
        ParamedicShell(controller: controller),
      );
    });

    testWidgets('emergency patient summary', (WidgetTester tester) async {
      final ParamedicSessionController controller =
          ParamedicSessionController(patientLookup: _demoLookup);
      addTearDown(controller.dispose);
      await controller.lookupAndStartEmergency('00000-0000001-0');

      await capture(
        tester,
        '$_paramedicDir/paramedic_02_emergency_summary.png',
        ParamedicShell(controller: controller),
      );
    });

    testWidgets('voice capture', (WidgetTester tester) async {
      final ParamedicSessionController controller =
          ParamedicSessionController(patientLookup: _demoLookup);
      addTearDown(controller.dispose);
      await controller.lookupAndStartEmergency('00000-0000001-0');

      await capture(
        tester,
        '$_paramedicDir/paramedic_03_voice.png',
        ParamedicShell(controller: controller, initialIndex: 1),
      );
    });

    testWidgets('medication safety', (WidgetTester tester) async {
      final ParamedicSessionController controller =
          ParamedicSessionController(patientLookup: _demoLookup);
      addTearDown(controller.dispose);
      await controller.lookupAndStartEmergency('00000-0000001-0');

      await capture(
        tester,
        '$_paramedicDir/paramedic_04_drugs.png',
        ParamedicShell(controller: controller, initialIndex: 2),
      );
    });

    testWidgets('route and handover', (WidgetTester tester) async {
      final ParamedicSessionController controller =
          ParamedicSessionController(patientLookup: _demoLookup);
      addTearDown(controller.dispose);
      await controller.lookupAndStartEmergency('00000-0000001-0');

      await capture(
        tester,
        '$_paramedicDir/paramedic_05_route_handover.png',
        ParamedicShell(controller: controller, initialIndex: 3),
      );
    });
  });
}
