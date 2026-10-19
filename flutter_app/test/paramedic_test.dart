import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nemras/api.dart';
import 'package:nemras/dev/demo_auth.dart';
import 'package:nemras/paramedic/models/paramedic_models.dart';
import 'package:nemras/paramedic/screens/emergency_patient_summary_screen.dart';
import 'package:nemras/paramedic/screens/hospital_handoff_screen.dart';
import 'package:nemras/paramedic/screens/on_scene_assessment_screen.dart';
import 'package:nemras/paramedic/screens/paramedic_handover_screen.dart';
import 'package:nemras/paramedic/screens/paramedic_shell.dart';
import 'package:nemras/paramedic/state/paramedic_session_controller.dart';
import 'package:nemras_design/nemras_design.dart';
import 'package:nemras_layout/nemras_layout.dart';

void main() {
  final fixedTime = DateTime.utc(2026, 10, 4, 10, 30);

  Future<PatientRecord> successfulLookup(String _) async =>
      buildDemoPatientRecord();

  group('Paramedic architecture models', () {
    test('demo identity separates staff and ambulance identifiers', () {
      const profile = DemoParamedicIdentity.profile;
      const assignment = DemoParamedicIdentity.assignment;

      expect(profile.paramedicId, 'PARA-001');
      expect(profile.firebaseUid, isNot(profile.paramedicId));
      expect(assignment.ambulanceId, 'NEMRAS-AMB-001');
      expect(profile.isDemo, isTrue);
      expect(assignment.isDemo, isTrue);
    });

    test('successful lookup creates one demo emergency and safe audit event',
        () async {
      final controller = ParamedicSessionController(
        patientLookup: successfulLookup,
        clock: () => fixedTime,
      );

      final result =
          await controller.lookupAndStartEmergency('00000-0000001-0');

      expect(result, isTrue);
      expect(controller.patientRecord, isNotNull);
      expect(controller.emergencySession?.emergencyId, 'EMG-2026-000001');
      expect(controller.emergencySession?.patientId, 'DEMO-PAT-000001');
      expect(controller.emergencySession?.paramedicId, 'PARA-001');
      expect(
        controller.emergencySession?.ambulanceId,
        'NEMRAS-AMB-001',
      );
      expect(controller.emergencySession?.isDemo, isTrue);
      expect(controller.auditEvents, hasLength(1));

      final audit = controller.auditEvents.single;
      expect(audit.reason, 'Emergency patient lookup');
      expect(audit.patientId, 'DEMO-PAT-000001');
      expect(audit.isDemo, isTrue);
      expect(audit.reason, isNot(contains('00000-0000001-0')));

      controller.dispose();
    });

    test('failed lookup creates neither emergency nor audit event', () async {
      final controller = ParamedicSessionController(
        patientLookup: (_) async => throw const ApiException(
          ApiErrorKind.notFound,
          'No patient found for that CNIC.',
        ),
        clock: () => fixedTime,
      );

      final result =
          await controller.lookupAndStartEmergency('00000-0000001-0');

      expect(result, isFalse);
      expect(controller.emergencySession, isNull);
      expect(controller.auditEvents, isEmpty);
      expect(controller.lookupError, 'No patient found for that CNIC.');

      controller.dispose();
    });

    test('handover state is local and transitions explicitly', () async {
      final controller = ParamedicSessionController(
        patientLookup: successfulLookup,
        clock: () => fixedTime,
      );
      await controller.lookupAndStartEmergency('00000-0000001-0');

      controller.updateHandoverNotes('Synthetic handover note.');
      controller.prepareHandover();

      expect(
        controller.emergencySession?.status,
        EmergencyStatus.handoverPreparing,
      );
      expect(
        controller.emergencySession?.handoverNotes,
        'Synthetic handover note.',
      );

      controller.markReadyForTransport();
      expect(
        controller.emergencySession?.status,
        EmergencyStatus.readyForTransport,
      );

      controller.dispose();
    });

    test('clearing an emergency preserves the assignment and audit trail',
        () async {
      final controller = ParamedicSessionController(
        patientLookup: successfulLookup,
        clock: () => fixedTime,
      );
      await controller.lookupAndStartEmergency('00000-0000001-0');

      controller.clearEmergency();

      expect(controller.patientRecord, isNull);
      expect(controller.emergencySession, isNull);
      expect(controller.auditEvents, hasLength(1));
      expect(controller.assignment.ambulanceId, 'NEMRAS-AMB-001');

      controller.dispose();
    });
  });

  group('Paramedic field shell', () {
    Widget harness(ParamedicSessionController controller) {
      return MaterialApp(
        theme: nemrasClinicalLightTheme(),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: ParamedicShell(controller: controller),
        ),
      );
    }

    testWidgets('uses field theme and four dedicated destinations',
        (tester) async {
      final controller = ParamedicSessionController(
        patientLookup: successfulLookup,
        clock: () => fixedTime,
      );

      await tester.pumpWidget(harness(controller));

      expect(find.byType(AdaptiveScaffold), findsOneWidget);
      expect(find.byType(NemrasBottomNavigation), findsOneWidget);
      for (final label in <String>['Scan', 'Voice', 'Drugs', 'Route']) {
        expect(find.text(label), findsWidgets);
      }
      expect(find.text('PARA-001'), findsWidgets);
      expect(find.text('NEMRAS-AMB-001'), findsWidgets);
      expect(find.text('DEMO'), findsWidgets);

      final context = tester.element(find.byType(AdaptiveScaffold));
      expect(NemrasSemantics.of(context).isField, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    });

    testWidgets('does not fabricate medication data before a lookup',
        (tester) async {
      final controller = ParamedicSessionController(
        patientLookup: successfulLookup,
        clock: () => fixedTime,
      );
      await tester.pumpWidget(harness(controller));

      await tester.tap(find.text('Drugs').last);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Scan a patient to view recorded medication safety fields.',
        ),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    });

    testWidgets('successful lookup replaces Scan with emergency summary',
        (tester) async {
      final controller = ParamedicSessionController(
        patientLookup: successfulLookup,
        clock: DateTime.now,
      );
      await controller.lookupAndStartEmergency('00000-0000001-0');

      await tester.pumpWidget(harness(controller));

      expect(find.byType(EmergencyPatientSummaryScreen), findsOneWidget);
      final summaryScroll = find.descendant(
        of: find.byType(EmergencyPatientSummaryScreen),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.text('RULE-BASED RECORD ALERTS'),
        300,
        scrollable: summaryScroll,
      );
      expect(find.text('RULE-BASED RECORD ALERTS'), findsOneWidget);
      expect(find.textContaining('0.'), findsNothing);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(320, 640));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        find.text('No pickup location is on this record.'),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    });

    testWidgets('route screen states that no hospital was notified',
        (tester) async {
      final controller = ParamedicSessionController(
        patientLookup: successfulLookup,
        clock: () => fixedTime,
      );
      await controller.lookupAndStartEmergency('00000-0000001-0');
      await tester.pumpWidget(harness(controller));

      final summaryScroll = find.descendant(
        of: find.byType(EmergencyPatientSummaryScreen),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.text('Prepare Route & Handover'),
        300,
        scrollable: summaryScroll,
      );
      await tester.tap(find.text('Prepare Route & Handover'));
      await tester.pumpAndSettle();

      final routeScroll = find.descendant(
        of: find.byType(ParamedicHandoverScreen),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.textContaining('No hospital has been notified'),
        300,
        scrollable: routeScroll,
      );
      expect(
          find.textContaining('No hospital has been notified'), findsOneWidget);
      expect(find.byKey(const Key('prepare-handover-button')), findsOneWidget);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(320, 640));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Turn-by-turn navigation is not available.'),
        -300,
        scrollable: routeScroll,
      );
      expect(
        find.text('Turn-by-turn navigation is not available.'),
        findsOneWidget,
      );
      expect(find.textContaining('1.4 km'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Return to incident assessment'),
        300,
        scrollable: routeScroll,
      );
      await tester.tap(find.text('Return to incident assessment'));
      await tester.pump();
      expect(find.text('Incident Assessment'), findsOneWidget);
      final assessmentScroll = find.descendant(
        of: find.byType(EmergencyPatientSummaryScreen),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.text('End Demo Session / New Scan'),
        300,
        scrollable: assessmentScroll,
      );
      expect(find.text('End Demo Session / New Scan'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    });

    testWidgets('on-scene vitals are not recorded or transmitted',
        (tester) async {
      final controller = ParamedicSessionController(
        patientLookup: successfulLookup,
        clock: () => fixedTime,
      );
      await controller.lookupAndStartEmergency('00000-0000001-0');
      addTearDown(() => tester.binding.setSurfaceSize(null));
      addTearDown(controller.dispose);
      for (final size in const <Size>[Size(320, 640), Size(390, 844)]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          MaterialApp(
            theme: nemrasFieldDarkTheme(),
            home: EmergencyPatientSummaryScreen(
              controller: controller,
              onOpenRoute: () {},
              onNewScan: () {},
            ),
          ),
        );
        await tester.pump();
        final assessmentScroll = find.descendant(
          of: find.byType(EmergencyPatientSummaryScreen),
          matching: find.byType(Scrollable),
        );
        final vitalsButton = find.widgetWithText(
          OutlinedButton,
          'View on-scene vitals',
        );
        await tester.scrollUntilVisible(
          vitalsButton,
          200,
          scrollable: assessmentScroll,
        );
        await Scrollable.ensureVisible(
          tester.element(vitalsButton),
          alignment: 0.3,
        );
        await tester.pump();
        await tester.tap(vitalsButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
        expect(find.byType(OnSceneAssessmentScreen), findsOneWidget);
        expect(find.text('Mirza Hissan'), findsWidgets);
        expect(
          find.text(
            'Blood pressure, heart rate, oxygen saturation, and consciousness '
            'are not recorded. Nothing on this page is saved or sent.',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('chest pain'), findsNothing);
        await tester.drag(
          find.descendant(
            of: find.byType(OnSceneAssessmentScreen),
            matching: find.byType(ListView),
          ),
          const Offset(0, -360),
        );
        await tester.pump();
        expect(
          tester
              .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'Save & transmit vitals'),
              )
              .onPressed,
          isNull,
        );
        expect(
          tester
              .widget<OutlinedButton>(
                find.widgetWithText(
                  OutlinedButton,
                  'Save local draft is not available',
                ),
              )
              .onPressed,
          isNull,
        );
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.byTooltip('Back'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Incident Assessment'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('hospital handoff does not notify or complete', (tester) async {
      final controller = ParamedicSessionController(
        patientLookup: successfulLookup,
        clock: () => fixedTime,
      );
      await controller.lookupAndStartEmergency('00000-0000001-0');
      addTearDown(() => tester.binding.setSurfaceSize(null));
      addTearDown(controller.dispose);
      for (final size in const <Size>[Size(320, 640), Size(390, 844)]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          MaterialApp(
            theme: nemrasFieldDarkTheme(),
            home: ParamedicHandoverScreen(
              controller: controller,
              onOpenScan: () {},
            ),
          ),
        );
        final routeScroll = find.descendant(
          of: find.byType(ParamedicHandoverScreen),
          matching: find.byType(Scrollable),
        );
        final handoffButton = find.widgetWithText(
          OutlinedButton,
          'View hospital handoff',
        );
        await tester.scrollUntilVisible(
          handoffButton,
          200,
          scrollable: routeScroll,
        );
        await Scrollable.ensureVisible(
          tester.element(handoffButton),
          alignment: 0.3,
        );
        await tester.pump();
        await tester.tap(handoffButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
        expect(find.byType(HospitalHandoffScreen), findsOneWidget);
        expect(find.text('No mission stage is recorded.'), findsOneWidget);
        expect(find.textContaining('5 MIN'), findsNothing);
        expect(find.textContaining('AMB-37'), findsNothing);
        expect(find.textContaining('Gate 2'), findsNothing);
        expect(find.textContaining('Live Link'), findsNothing);
        final handoffList = find.descendant(
          of: find.byType(HospitalHandoffScreen),
          matching: find.byType(ListView),
        );
        final handoffScroll = find
            .descendant(
              of: handoffList,
              matching: find.byType(Scrollable),
            )
            .first;
        final confirmButton = find.widgetWithText(
          ElevatedButton,
          'Confirm hospital handoff',
        );
        await tester.scrollUntilVisible(
          confirmButton,
          160,
          scrollable: handoffScroll,
        );
        expect(find.text('Nishtar Hospital'), findsOneWidget);
        expect(tester.widget<ElevatedButton>(confirmButton).onPressed, isNull);
        final sceneButton = find.widgetWithText(
          OutlinedButton,
          'Scene discharge',
        );
        await tester.scrollUntilVisible(
          sceneButton,
          -160,
          scrollable: handoffScroll,
        );
        await Scrollable.ensureVisible(
          tester.element(sceneButton),
          alignment: 0.3,
        );
        await tester.pump();
        await tester.tap(sceneButton);
        await tester.pump();
        expect(
          find.text('No witness, signature, or scene discharge is recorded.'),
          findsOneWidget,
        );
        final completeButton = find.widgetWithText(
          ElevatedButton,
          'Complete scene discharge',
        );
        await tester.scrollUntilVisible(
          completeButton,
          160,
          scrollable: handoffScroll,
        );
        expect(tester.widget<ElevatedButton>(completeButton).onPressed, isNull);
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.byTooltip('Back'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Route & Handover'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
