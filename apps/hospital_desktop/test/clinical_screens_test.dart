import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_desktop/src/app.dart';
import 'package:hospital_desktop/src/data/audit_models.dart';
import 'package:hospital_desktop/src/data/demo_handover_repository.dart';
import 'package:hospital_desktop/src/data/handover_models.dart';
import 'package:hospital_desktop/src/data/staff_identity.dart';
import 'package:hospital_desktop/src/navigation/clinical_navigation.dart';
import 'package:hospital_desktop/src/screens/alerts_escalation_screen.dart';
import 'package:hospital_desktop/src/screens/bed_capacity_screen.dart';
import 'package:hospital_desktop/src/screens/clinical_handoff_screen.dart';
import 'package:hospital_desktop/src/screens/clinical_audit_screen.dart';
import 'package:hospital_desktop/src/screens/clinical_overview_screen.dart';
import 'package:hospital_desktop/src/screens/clinical_shell.dart';
import 'package:hospital_desktop/src/screens/emergency_encounter_screen.dart';
import 'package:hospital_desktop/src/screens/emergency_queue_screen.dart';
import 'package:hospital_desktop/src/screens/hospital_login_screen.dart';
import 'package:hospital_desktop/src/screens/patient_clinical_record_screen.dart';
import 'package:hospital_desktop/src/screens/patient_search_screen.dart';
import 'package:hospital_desktop/src/state/hospital_session_controller.dart';
import 'package:hospital_desktop/src/state/session_scope.dart';
import 'package:hospital_desktop/src/widgets/break_glass_dialog.dart';
import 'package:hospital_desktop/src/widgets/clinical_ui.dart';
import 'package:nemras_design/nemras_design.dart';
import 'package:nemras_layout/nemras_layout.dart';

import 'support/fake_backend.dart';

/// A desktop-sized surface. The clinical desktop targets Windows, so a phone
/// viewport would not exercise the layout it actually ships.
const Size _desktop = Size(1440, 960);

HospitalSessionController buildController({
  int patientStatus = 200,
  bool offline = false,
}) {
  final clock = DateTime.utc(2026, 10, 4, 9, 30);
  return HospitalSessionController(
    apiClient: offline
        ? offlineApiClient()
        : fakeApiClient(patientStatus: patientStatus),
    handoverRepository: DemoHandoverRepository(seedTime: clock),
    auditRepository: InMemoryAuditRepository(),
    clock: () => clock,
  );
}

Future<void> pumpDesktop(
  WidgetTester tester,
  HospitalSessionController controller,
  Widget child,
) async {
  tester.view.physicalSize = _desktop;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    HospitalSessionScope(
      controller: controller,
      child: MaterialApp(
        theme: nemrasClinicalLightTheme(),
        // The screens are normally hosted inside the shell's Scaffold, so a
        // Material ancestor has to be supplied when one is pumped alone.
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('application boot', () {
    testWidgets('boots into the hospital login route', (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);

      tester.view.physicalSize = _desktop;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(HospitalDesktopApp(controller: controller));
      await tester.pumpAndSettle();

      // `hospitalLogin` is a nested path, so this also proves the initial
      // route resolves without the intermediate segments being routable.
      expect(find.byType(HospitalLoginScreen), findsOneWidget);
      expect(find.byType(ClinicalShell), findsNothing);
    });

    testWidgets('entering the desktop replaces login with the shell',
        (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);

      tester.view.physicalSize = _desktop;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(HospitalDesktopApp(controller: controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enter clinical desktop'));
      await tester.pumpAndSettle();

      expect(find.byType(ClinicalShell), findsOneWidget);
      expect(find.byType(HospitalLoginScreen), findsNothing);
    });
  });

  group('hospital login', () {
    testWidgets('offers the three clinical roles and says it does not '
        'authenticate', (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);

      await pumpDesktop(
        tester,
        controller,
        HospitalLoginScreen(onSignedIn: () {}),
      );

      for (final role in ClinicalRole.values) {
        expect(find.text(role.label), findsOneWidget);
      }
      expect(
        find.textContaining('does not authenticate anyone'),
        findsOneWidget,
      );
      expect(find.byType(DemoChip), findsWidgets);
      expect(find.text('STAFF-001'), findsOneWidget);
      expect(find.text('HOSP-001'), findsOneWidget);
    });

    testWidgets('entering starts a demo session for the selected role',
        (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);
      var signedIn = false;

      await pumpDesktop(
        tester,
        controller,
        HospitalLoginScreen(onSignedIn: () => signedIn = true),
      );

      await tester.tap(find.text(ClinicalRole.nurse.label));
      await tester.pump();
      await tester.tap(find.text('Enter clinical desktop'));
      await tester.pumpAndSettle();

      expect(signedIn, isTrue);
      expect(controller.isSignedIn, isTrue);
      expect(controller.staff!.role, ClinicalRole.nurse);
    });
  });

  group('clinical shell', () {
    testWidgets('renders the nine-item sidebar and the desktop top bar',
        (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.emergencyPhysician);

      await pumpDesktop(tester, controller, const ClinicalShell());

      expect(find.byType(NemrasDesktopSidebar), findsOneWidget);
      expect(find.byType(NemrasDesktopTopBar), findsOneWidget);
      for (final item in HospitalClinicalNavigation.clinicalSidebar.items) {
        expect(
          find.text(item.label),
          findsWidgets,
          reason: '${item.label} must appear in the sidebar',
        );
      }
    });

    testWidgets('marks the session as demo and shows the staff context',
        (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.emergencyPhysician);

      await pumpDesktop(tester, controller, const ClinicalShell());

      expect(find.text('DEMO SESSION'), findsOneWidget);
      expect(
        find.textContaining('EMERGENCY PHYSICIAN'),
        findsOneWidget,
      );
    });

    testWidgets('selecting a sidebar destination swaps the content area',
        (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.emergencyPhysician);

      await pumpDesktop(tester, controller, const ClinicalShell());
      expect(find.byType(EmergencyQueueScreen), findsNothing);

      await tester.tap(find.text('Emergency Queue').first);
      await tester.pumpAndSettle();

      expect(find.byType(EmergencyQueueScreen), findsOneWidget);
    });

    testWidgets('keeps the desktop sidebar even on a narrow window',
        (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.doctor);

      tester.view.physicalSize = const Size(760, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        HospitalSessionScope(
          controller: controller,
          child: MaterialApp(
            theme: nemrasClinicalLightTheme(),
            home: const ClinicalShell(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // This is a desktop surface; it must never fall back to the mobile
      // bottom bar the patient and paramedic shells use.
      expect(find.byType(NemrasDesktopSidebar), findsOneWidget);
      expect(find.byType(NemrasBottomNavigation), findsNothing);
    });
  });

  group('clinical overview', () {
    testWidgets('the sidebar returns to the dashboard and a case opens in '
        'the queue', (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.emergencyPhysician);

      await pumpDesktop(tester, controller, const ClinicalShell());
      expect(find.byType(ClinicalOverviewScreen), findsOneWidget);

      await tester.tap(find.text('Emergency Queue').first);
      await tester.pumpAndSettle();
      expect(find.byType(ClinicalOverviewScreen), findsNothing);
      await tester.tap(find.text('Overview').first);
      await tester.pumpAndSettle();

      expect(find.byType(ClinicalOverviewScreen), findsOneWidget);
      expect(find.text('1 pending incoming case'), findsOneWidget);
      expect(find.text('Clinical operations'), findsOneWidget);
      final overviewScroll = find
          .descendant(
            of: find.byType(ClinicalOverviewScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('RECORDS IN DATASET'),
        300,
        scrollable: overviewScroll,
      );
      expect(find.text('RECORDS IN DATASET'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Review case'),
        -300,
        scrollable: overviewScroll,
      );

      await tester.tap(find.text('Review case'));
      await tester.pumpAndSettle();
      expect(find.byType(EmergencyQueueScreen), findsOneWidget);
      expect(controller.selectedCase?.emergencyId, 'EMG-2026-000001');
      expect(find.text('Accept case'), findsOneWidget);
    });

    testWidgets('fits phone widths and states what is not recorded',
        (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.doctor);
      addTearDown(tester.view.reset);

      for (final size in const <Size>[Size(320, 640), Size(390, 844)]) {
        await tester.pumpWidget(const SizedBox.shrink());
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        int? navigatedTo;
        await tester.pumpWidget(
          HospitalSessionScope(
            controller: controller,
            child: MaterialApp(
              theme: nemrasClinicalLightTheme(),
              home: Scaffold(
                body: ClinicalOverviewScreen(
                  onNavigate: (index) => navigatedTo = index,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('1 pending incoming case'), findsOneWidget);

        final scroll = find.byType(Scrollable).first;
        await tester.scrollUntilVisible(
          find.text('Bed & capacity manager'),
          200,
          scrollable: scroll,
        );
        expect(
          find.text('Not available. NEMRAS records no bed or capacity data.'),
          findsOneWidget,
        );
        expect(
          find.text('Not available. No escalation feed is connected.'),
          findsOneWidget,
        );
        await Scrollable.ensureVisible(
          tester.element(find.text('Incoming triage queue')),
          alignment: 0.3,
        );
        await tester.pump();
        await tester.tap(find.text('Incoming triage queue'));
        await tester.pump();
        expect(navigatedTo, HospitalClinicalNavigation.emergencyQueueIndex);

        await tester.scrollUntilVisible(
          find.text(
            'Not available. NEMRAS stores no arrival history, so no trend '
            'is drawn.',
          ),
          200,
          scrollable: scroll,
        );
        expect(tester.takeException(), isNull);
      }

      expect(find.textContaining('AMB-37'), findsNothing);
      expect(find.textContaining('Kashaf'), findsNothing);
      expect(find.textContaining('88%'), findsNothing);
      expect(find.textContaining('REAL-TIME'), findsNothing);
      expect(find.textContaining('ETA 4'), findsNothing);
    });

    testWidgets('an empty queue shows no pending or inbound case',
        (tester) async {
      final controller = HospitalSessionController(
        apiClient: fakeApiClient(),
        handoverRepository: _EmptyHandoverRepository(),
        auditRepository: InMemoryAuditRepository(),
      );
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.doctor);

      await pumpDesktop(
        tester,
        controller,
        ClinicalOverviewScreen(onNavigate: (_) {}),
      );

      expect(find.text('No pending incoming case'), findsOneWidget);
      expect(find.text('Review case'), findsNothing);
      expect(
        find.text(
          'No open emergency cases have been announced to this hospital.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a dataset failure keeps the queue and offers a retry',
        (tester) async {
      final controller = HospitalSessionController(
        apiClient: offlineApiClient(),
        handoverRepository: DemoHandoverRepository(
          seedTime: DateTime.utc(2026, 10, 4, 9, 30),
        ),
        auditRepository: InMemoryAuditRepository(),
      );
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.doctor);

      await pumpDesktop(
        tester,
        controller,
        ClinicalOverviewScreen(onNavigate: (_) {}),
      );

      expect(find.text('1 pending incoming case'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('RECORDS IN DATASET'), findsNothing);
    });
  });

  group('bed capacity', () {
    testWidgets('the dashboard opens capacity, which records nothing',
        (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.emergencyPhysician);

      await pumpDesktop(tester, controller, const ClinicalShell());
      final overviewScroll = find
          .descendant(
            of: find.byType(ClinicalOverviewScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Bed & capacity manager'),
        200,
        scrollable: overviewScroll,
      );
      await tester.tap(find.text('Bed & capacity manager'));
      await tester.pumpAndSettle();

      expect(find.byType(BedCapacityScreen), findsOneWidget);
      expect(find.text('Not available'), findsNWidgets(3));
      expect(
        find.text('No units or wards are recorded for HOSP-001.'),
        findsOneWidget,
      );
      expect(find.text('3 open cases in the demo queue'), findsOneWidget);
      expect(find.text('No bed is assigned to any case.'), findsOneWidget);

      final capacityScroll = find
          .descendant(
            of: find.byType(BedCapacityScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Save & broadcast is not available'),
        200,
        scrollable: capacityScroll,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(
                FilledButton,
                'Save & broadcast is not available',
              ),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged,
        isNull,
      );
      expect(find.textContaining('AMB-37'), findsNothing);
      expect(find.textContaining('1122'), findsNothing);
      expect(find.textContaining('88%'), findsNothing);
      expect(find.textContaining('Bay 03'), findsNothing);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(BedCapacityScreen), findsNothing);
      expect(find.byType(ClinicalOverviewScreen), findsOneWidget);
    });

    testWidgets('the clinical summary links to capacity and back',
        (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.emergencyPhysician);

      await pumpDesktop(tester, controller, const EmergencyQueueScreen());
      await tester.tap(find.text('EMG-2026-000001'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View bed & capacity'));
      await tester.pumpAndSettle();
      expect(find.byType(BedCapacityScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(EmergencyEncounterScreen), findsOneWidget);
      expect(controller.selectedCase?.emergencyId, 'EMG-2026-000001');
    });

    testWidgets('capacity fits phone widths', (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.nurse);
      addTearDown(tester.view.reset);

      for (final size in const <Size>[Size(320, 640), Size(390, 844)]) {
        await tester.pumpWidget(const SizedBox.shrink());
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(
          HospitalSessionScope(
            controller: controller,
            child: MaterialApp(
              theme: nemrasClinicalLightTheme(),
              home: const BedCapacityScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.text('No changes to discard'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.textContaining('Demo Clinical Nurse'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('clinical handoff', () {
    Future<void> openHandoff(WidgetTester tester, String id) async {
      await tester.tap(find.text(id));
      await tester.pumpAndSettle();
      final button = find.text('Open handoff & admission');
      Scrollable.ensureVisible(tester.element(button), alignment: 0.3);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    testWidgets('opens from the encounter with recorded and absent fields',
        (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.emergencyPhysician);

      await pumpDesktop(tester, controller, const EmergencyQueueScreen());
      await openHandoff(tester, 'EMG-2026-000001');

      expect(find.byType(ClinicalHandoffScreen), findsOneWidget);
      expect(find.text('DEMO Patient 000001 (58, Male)'), findsOneWidget);
      expect(find.text('PARA-001'), findsOneWidget);
      expect(find.text('Not recorded'), findsWidgets);
      expect(find.text('Condition: Heart Disease'), findsOneWidget);
      expect(find.textContaining('DEMO handover note.'), findsOneWidget);
      expect(find.text('Recorded allergy: Penicillin'), findsOneWidget);
      expect(find.text('Not available'), findsWidgets);
      expect(find.text('No orders are recorded.'), findsOneWidget);
      expect(find.textContaining('Kashaf'), findsNothing);
      expect(find.textContaining('AMB-37'), findsNothing);
      expect(find.textContaining('Bay 03'), findsNothing);
      expect(find.textContaining('1122'), findsNothing);
    });

    testWidgets('unsupported actions are disabled; demo step is labelled',
        (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.emergencyPhysician);

      await pumpDesktop(tester, controller, const EmergencyQueueScreen());
      await openHandoff(tester, 'EMG-2026-000001');

      for (final tile in tester.widgetList<CheckboxListTile>(
        find.byType(CheckboxListTile),
      )) {
        expect(tile.onChanged, isNull);
      }
      for (final tile in tester.widgetList<RadioListTile<String>>(
        find.byType(RadioListTile<String>),
      )) {
        expect(tile.enabled, isFalse);
      }
      expect(find.text('0/4 RECORDED'), findsOneWidget);
      expect(find.text('Signature not recorded'), findsOneWidget);
      expect(find.text('Signature not available'), findsOneWidget);

      final scroll = find
          .descendant(
            of: find.byType(ClinicalHandoffScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Flagging a discrepancy is not available'),
        200,
        scrollable: scroll,
      );
      for (final label in const <String>[
        'Confirming handoff & admission is not available',
        'Flagging a discrepancy is not available',
      ]) {
        expect(
          tester
              .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, label))
              .onPressed,
          isNull,
        );
      }

      await tester.tap(find.text('Demo status step: Accept case'));
      await tester.pumpAndSettle();
      expect(
        controller.selectedCase?.status,
        EmergencyCaseStatus.accepted,
      );
      expect(find.text('Demo status step: Start treatment'), findsOneWidget);
      expect(find.textContaining('admitted'), findsOneWidget);
    });

    testWidgets('back returns to the same selected encounter',
        (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.emergencyPhysician);

      await pumpDesktop(tester, controller, const EmergencyQueueScreen());
      await openHandoff(tester, 'EMG-2026-000002');
      expect(find.text('RECEIVING CLINICIAN'), findsOneWidget);
      expect(find.text('STAFF-001'), findsWidgets);
      expect(
        find.text('No handover note was recorded for this case.'),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(ClinicalHandoffScreen), findsNothing);
      expect(find.byType(EmergencyEncounterScreen), findsOneWidget);
      expect(controller.selectedCase?.emergencyId, 'EMG-2026-000002');
      expect(find.text('Start treatment'), findsOneWidget);
    });

    testWidgets('missing case shows an empty state', (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.emergencyPhysician);

      await pumpDesktop(
        tester,
        controller,
        const ClinicalHandoffScreen(emergencyId: 'EMG-UNKNOWN'),
      );
      expect(find.text('Case not found'), findsOneWidget);
    });

    testWidgets('handoff fits phone widths', (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.nurse);
      addTearDown(tester.view.reset);

      for (final size in const <Size>[Size(320, 640), Size(390, 844)]) {
        await tester.pumpWidget(const SizedBox.shrink());
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(
          HospitalSessionScope(
            controller: controller,
            child: MaterialApp(
              theme: nemrasClinicalLightTheme(),
              home: const ClinicalHandoffScreen(emergencyId: 'EMG-2026-000003'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Medication: Not available'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Flagging a discrepancy is not available'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
      }
      expect(
        controller.queue
            .firstWhere((c) => c.emergencyId == 'EMG-2026-000003')
            .status,
        EmergencyCaseStatus.inProgress,
      );
    });
  });

  group('alerts & escalation', () {
    testWidgets('dashboard opens rule-based flags; open case reaches queue',
        (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.emergencyPhysician);

      await pumpDesktop(tester, controller, const ClinicalShell());
      final overviewScroll = find
          .descendant(
            of: find.byType(ClinicalOverviewScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Alerts & escalations'),
        200,
        scrollable: overviewScroll,
      );
      await tester.tap(find.text('Alerts & escalations'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertsEscalationScreen), findsOneWidget);
      expect(find.text('4 flags from 3 open cases'), findsOneWidget);
      expect(find.text('Awaiting acceptance'), findsOneWidget);
      expect(find.text('High triage label'), findsOneWidget);
      expect(find.text('Recorded allergy: Penicillin'), findsOneWidget);
      expect(find.text('Drug interaction risk recorded'), findsOneWidget);
      expect(find.text('RULE-BASED'), findsNWidgets(4));
      expect(find.textContaining('Inbound Cardiac'), findsNothing);
      expect(find.textContaining('AMB-18'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(
                FilledButton,
                'Broadcasting a surge alert is not available',
              ),
            )
            .onPressed,
        isNull,
      );
      for (final label in const <String>[
        'Acknowledge is not available',
        'Escalate is not available',
      ]) {
        for (final button in tester.widgetList<TextButton>(
          find.widgetWithText(TextButton, label),
        )) {
          expect(button.onPressed, isNull);
        }
      }

      final openCase = find.text('Open case').first;
      Scrollable.ensureVisible(tester.element(openCase), alignment: 0.3);
      await tester.pumpAndSettle();
      await tester.tap(openCase);
      await tester.pumpAndSettle();
      expect(find.byType(AlertsEscalationScreen), findsNothing);
      expect(find.byType(EmergencyQueueScreen), findsOneWidget);
      expect(controller.selectedCase?.emergencyId, 'EMG-2026-000001');
      expect(controller.selectedCase?.status, EmergencyCaseStatus.pending);
    });

    testWidgets('back returns to the dashboard without selecting',
        (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.emergencyPhysician);

      await pumpDesktop(tester, controller, const ClinicalShell());
      final overviewScroll = find
          .descendant(
            of: find.byType(ClinicalOverviewScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Alerts & escalations'),
        200,
        scrollable: overviewScroll,
      );
      await tester.tap(find.text('Alerts & escalations'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(ClinicalOverviewScreen), findsOneWidget);
      expect(controller.selectedCase, isNull);
    });

    testWidgets('empty queue shows no flags', (tester) async {
      final controller = HospitalSessionController(
        apiClient: fakeApiClient(),
        handoverRepository: _EmptyHandoverRepository(),
        auditRepository: InMemoryAuditRepository(),
      );
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.emergencyPhysician);

      await pumpDesktop(tester, controller, const AlertsEscalationScreen());
      expect(find.text('0 flags from 0 open cases'), findsOneWidget);
      expect(find.text('No rule-based flags for open cases.'), findsOneWidget);
    });

    testWidgets('alerts fit phone widths', (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.nurse);
      addTearDown(tester.view.reset);

      for (final size in const <Size>[Size(320, 640), Size(390, 844)]) {
        await tester.pumpWidget(const SizedBox.shrink());
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(
          HospitalSessionScope(
            controller: controller,
            child: MaterialApp(
              theme: nemrasClinicalLightTheme(),
              home: const AlertsEscalationScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Open case'), findsNothing);
        await tester.scrollUntilVisible(
          find.text('Last delivery'.toUpperCase()),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('emergency queue', () {
    testWidgets('lists the demo cases with their status and demo marking',
        (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.emergencyPhysician);

      await pumpDesktop(tester, controller, const EmergencyQueueScreen());

      expect(find.text('EMG-2026-000001'), findsOneWidget);
      expect(find.text('PENDING'), findsWidgets);
      expect(find.byType(DemoChip), findsWidgets);
      expect(
        find.textContaining('No live hospital network'),
        findsOneWidget,
      );
    });

    testWidgets('selecting a case opens the encounter detail pane',
        (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.emergencyPhysician);

      await pumpDesktop(tester, controller, const EmergencyQueueScreen());
      expect(find.text('Select a case'), findsOneWidget);

      await tester.tap(find.text('EMG-2026-000001'));
      await tester.pumpAndSettle();

      expect(find.text('DEMO Patient 000001'), findsWidgets);
      expect(find.text('Accept case'), findsOneWidget);
    });

    testWidgets('advancing a case updates the visible status', (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.emergencyPhysician);

      await pumpDesktop(tester, controller, const EmergencyQueueScreen());
      await tester.tap(find.text('EMG-2026-000001'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Accept case'));
      await tester.pumpAndSettle();

      expect(find.text('Start treatment'), findsOneWidget);
      expect(controller.pendingCaseCount, 0);
    });

    testWidgets('an encounter reports unavailable rather than inventing '
        'vitals or an ETA', (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.emergencyPhysician);

      await pumpDesktop(tester, controller, const EmergencyQueueScreen());
      await tester.tap(find.text('EMG-2026-000001'));
      await tester.pumpAndSettle();

      expect(find.byType(EmergencyEncounterScreen), findsOneWidget);
      // Field labels render upper-cased through ClinicalSectionLabel.
      expect(find.text('HEART RATE'), findsOneWidget);
      expect(find.text('LABORATORY PANEL'), findsOneWidget);
      expect(find.text('AMBULANCE ETA'), findsOneWidget);
      expect(find.text('ASSIGNED BED'), findsOneWidget);
      expect(find.text('Not available'), findsWidgets);
    });

    testWidgets('triage filters narrow the list and say what is not recorded',
        (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.emergencyPhysician);

      await pumpDesktop(tester, controller, const EmergencyQueueScreen());

      expect(find.text('Incoming cases & triage queue'), findsOneWidget);
      expect(find.text('All (3)'), findsOneWidget);
      expect(
        find.text('Field vitals not recorded  ·  ETA not available'),
        findsNWidgets(3),
      );

      await tester.tap(find.text('High (1)'));
      await tester.pumpAndSettle();
      expect(find.text('EMG-2026-000001'), findsOneWidget);
      expect(find.text('EMG-2026-000002'), findsNothing);
      expect(find.text('EMG-2026-000003'), findsNothing);

      await tester.tap(find.text('Low (1)'));
      await tester.pumpAndSettle();
      expect(find.text('EMG-2026-000001'), findsNothing);
      expect(find.text('EMG-2026-000003'), findsOneWidget);

      await tester.tap(find.text('All (3)'));
      await tester.pumpAndSettle();
      expect(find.text('EMG-2026-000002'), findsOneWidget);

      expect(find.textContaining('AVPU'), findsNothing);
      expect(find.textContaining('Kashaf'), findsNothing);
      expect(find.textContaining('Bay 03'), findsNothing);
      expect(find.textContaining('Assign Nurse'), findsNothing);
    });

    testWidgets('sorting by triage level reorders the recorded cases',
        (tester) async {
      final now = DateTime.utc(2026, 10, 4, 9, 30);
      final controller = HospitalSessionController(
        apiClient: fakeApiClient(),
        handoverRepository: _FixedHandoverRepository(<EmergencyHandover>[
          _testHandover('EMG-TEST-LOW', 'Low', now),
          _testHandover(
            'EMG-TEST-HIGH',
            'High',
            now.subtract(const Duration(minutes: 30)),
          ),
        ]),
        auditRepository: InMemoryAuditRepository(),
      );
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.doctor);

      await pumpDesktop(tester, controller, const EmergencyQueueScreen());

      double top(String id) => tester.getTopLeft(find.text(id)).dy;
      expect(top('EMG-TEST-LOW'), lessThan(top('EMG-TEST-HIGH')));

      await tester.tap(find.text('Triage level'));
      await tester.pumpAndSettle();
      expect(top('EMG-TEST-HIGH'), lessThan(top('EMG-TEST-LOW')));
    });

    testWidgets('fits phone widths and returns from a case to the queue',
        (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.emergencyPhysician);
      addTearDown(tester.view.reset);

      for (final size in const <Size>[Size(320, 640), Size(390, 844)]) {
        await tester.pumpWidget(const SizedBox.shrink());
        controller.clearSelectedCase();
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(
          HospitalSessionScope(
            controller: controller,
            child: MaterialApp(
              theme: nemrasClinicalLightTheme(),
              home: const Scaffold(body: EmergencyQueueScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Incoming cases & triage queue'), findsOneWidget);

        await tester.tap(find.text('EMG-2026-000001'));
        await tester.pumpAndSettle();
        expect(find.byType(EmergencyEncounterScreen), findsOneWidget);
        expect(find.text('Back to queue'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Back to queue'));
        await tester.pumpAndSettle();
        expect(find.byType(EmergencyEncounterScreen), findsNothing);
        expect(find.text('All (3)'), findsOneWidget);
      }
    });

    testWidgets('the clinical summary shows recorded fields and marks the '
        'rest unavailable', (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.emergencyPhysician);

      await pumpDesktop(tester, controller, const EmergencyQueueScreen());
      await tester.tap(find.text('EMG-2026-000001'));
      await tester.pumpAndSettle();

      expect(find.text('PATIENT IDENTITY'), findsOneWidget);
      expect(find.text('FIELD ASSESSMENT & VITALS'), findsOneWidget);
      expect(find.text('RECORD BASELINE'), findsOneWidget);
      expect(find.text('PENDING DIAGNOSTICS'), findsOneWidget);
      expect(find.text('58 y · Male'), findsOneWidget);
      expect(find.text('Aspirin'), findsOneWidget);
      expect(find.text('Allergy: Penicillin'), findsOneWidget);
      expect(find.text('GLASGOW COMA SCALE'), findsOneWidget);
      expect(find.text('CONSCIOUSNESS (AVPU)'), findsOneWidget);
      expect(find.text('EMERGENCY CONTACT'), findsOneWidget);
      expect(find.text('Not recorded'), findsOneWidget);
      expect(find.textContaining('DEMO handover note'), findsOneWidget);
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(
                OutlinedButton,
                'Ordering diagnostics is not available',
              ),
            )
            .onPressed,
        isNull,
      );

      expect(find.textContaining('Kashaf'), findsNothing);
      expect(find.textContaining('118/76'), findsNothing);
      expect(find.textContaining('Troponin'), findsNothing);
      expect(find.textContaining('NADRA'), findsNothing);
      expect(find.textContaining('Bay 03'), findsNothing);
    });

    testWidgets('a case without flags or a note says so', (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.emergencyPhysician);

      await pumpDesktop(tester, controller, const EmergencyQueueScreen());
      await tester.tap(find.text('EMG-2026-000003'));
      await tester.pumpAndSettle();

      expect(find.text('No safety flags on record'), findsOneWidget);
      expect(
        find.text('No handover note was recorded for this case.'),
        findsOneWidget,
      );
      expect(find.text('DEMO Patient 000003'), findsWidgets);
    });

    testWidgets('a narrow shell returns to the queue and opens another case',
        (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.emergencyPhysician);

      tester.view.physicalSize = const Size(760, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        HospitalSessionScope(
          controller: controller,
          child: MaterialApp(
            theme: nemrasClinicalLightTheme(),
            home: const ClinicalShell(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Emergency Queue').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('EMG-2026-000001'));
      await tester.pumpAndSettle();
      expect(find.byType(EmergencyEncounterScreen), findsOneWidget);
      expect(find.text('Back to queue'), findsOneWidget);
      expect(find.byType(NemrasDesktopSidebar), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Back to queue'));
      await tester.pumpAndSettle();
      expect(find.byType(EmergencyEncounterScreen), findsNothing);

      await tester.tap(find.text('EMG-2026-000002'));
      await tester.pumpAndSettle();
      expect(controller.selectedCase?.emergencyId, 'EMG-2026-000002');
      expect(find.text('DEMO Patient 000002'), findsWidgets);
      expect(
        find.text('No handover note was recorded for this case.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the clinical summary fits phone widths', (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.emergencyPhysician);
      addTearDown(tester.view.reset);

      for (final size in const <Size>[Size(320, 640), Size(390, 844)]) {
        await tester.pumpWidget(const SizedBox.shrink());
        controller.clearSelectedCase();
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(
          HospitalSessionScope(
            controller: controller,
            child: MaterialApp(
              theme: nemrasClinicalLightTheme(),
              home: const Scaffold(body: EmergencyQueueScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('EMG-2026-000001'));
        await tester.pumpAndSettle();
        expect(find.byType(EmergencyEncounterScreen), findsOneWidget);

        final summaryScroll = find
            .descendant(
              of: find.byType(EmergencyEncounterScreen),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(
          find.text('Ordering diagnostics is not available'),
          300,
          scrollable: summaryScroll,
        );
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Back to queue'));
        await tester.pumpAndSettle();
        expect(find.text('All (3)'), findsOneWidget);
      }
    });

    testWidgets('shows an empty state when nothing has been announced',
        (tester) async {
      final controller = HospitalSessionController(
        apiClient: fakeApiClient(),
        handoverRepository: _EmptyHandoverRepository(),
        auditRepository: InMemoryAuditRepository(),
      );
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.doctor);

      await pumpDesktop(tester, controller, const EmergencyQueueScreen());

      expect(find.text('No emergency cases'), findsOneWidget);
    });
  });

  group('patient search and record', () {
    testWidgets('an unknown CNIC surfaces a safe error, not the raw detail',
        (tester) async {
      final controller = buildController(patientStatus: 404);
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.doctor);

      await pumpDesktop(
        tester,
        controller,
        PatientSearchScreen(onNavigate: (_) {}),
      );

      await tester.enterText(find.byType(TextField), '00000-0000009-9');
      await tester.tap(find.text('Open record'));
      await tester.pumpAndSettle();

      expect(find.text('Lookup failed'), findsOneWidget);
      // The CNIC stays visible in the field the clinician typed it into; what
      // must not happen is the backend echoing it back inside the error.
      expect(
        find.descendant(
          of: find.byType(ClinicalAlertBox),
          matching: find.textContaining('00000-0000009-9'),
        ),
        findsNothing,
      );
    });

    testWidgets('a successful search hands the clinician to the record',
        (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.doctor);
      int? navigatedTo;

      await pumpDesktop(
        tester,
        controller,
        PatientSearchScreen(onNavigate: (index) => navigatedTo = index),
      );

      await tester.enterText(find.byType(TextField), '00000-0000001-0');
      await tester.tap(find.text('Open record'));
      await tester.pumpAndSettle();

      expect(
        navigatedTo,
        HospitalClinicalNavigation.clinicalRecordsIndex,
      );
      expect(controller.record, isNotNull);
    });

    testWidgets('the record screen is empty until a record is opened',
        (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.doctor);

      await pumpDesktop(
        tester,
        controller,
        PatientClinicalRecordScreen(onNavigate: (_) {}),
      );

      expect(find.text('No record open'), findsOneWidget);
    });

    testWidgets('the record labels alerts as rule-based, not as a model',
        (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.doctor);
      await controller.lookUpPatient('00000-0000001-0');

      await pumpDesktop(
        tester,
        controller,
        PatientClinicalRecordScreen(onNavigate: (_) {}),
      );

      expect(find.text('RULE-BASED RECORD ALERTS'), findsOneWidget);
      expect(
        find.textContaining('not the output of a trained model'),
        findsOneWidget,
      );
      expect(find.textContaining('not a clinically validated'), findsWidgets);
    });

    testWidgets('a connectivity failure shows the error state with a retry',
        (tester) async {
      final controller = buildController(offline: true);
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.doctor);
      await controller.lookUpPatient('00000-0000001-0');

      await pumpDesktop(
        tester,
        controller,
        PatientClinicalRecordScreen(onNavigate: (_) {}),
      );

      expect(find.byType(ClinicalErrorState), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('break-glass', () {
    testWidgets('the dialog refuses to confirm until a reason is given',
        (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.emergencyPhysician);

      await pumpDesktop(
        tester,
        controller,
        PatientSearchScreen(onNavigate: (_) {}),
      );

      await tester.enterText(find.byType(TextField), '00000-0000001-0');
      await tester.tap(find.text('Break-glass access'));
      await tester.pumpAndSettle();

      expect(find.byType(BreakGlassDialog), findsOneWidget);

      final confirm = find.widgetWithText(
        FilledButton,
        'Record reason and open record',
      );
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

      await tester.enterText(
        find.descendant(
          of: find.byType(BreakGlassDialog),
          matching: find.byType(TextField),
        ),
        'Unconscious patient, no consent obtainable.',
      );
      await tester.pump();
      // The acknowledgement is also required.
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
    });

    testWidgets('cancelling records nothing and opens no record',
        (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.emergencyPhysician);
      final before = controller.auditEvents.length;

      await pumpDesktop(
        tester,
        controller,
        PatientSearchScreen(onNavigate: (_) {}),
      );

      await tester.enterText(find.byType(TextField), '00000-0000001-0');
      await tester.tap(find.text('Break-glass access'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(controller.record, isNull);
      expect(controller.auditEvents, hasLength(before));
      expect(controller.breakGlassEventCount, 0);
    });

    testWidgets('confirming opens the record with a visible override banner',
        (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.emergencyPhysician);

      await pumpDesktop(
        tester,
        controller,
        PatientSearchScreen(onNavigate: (_) {}),
      );

      await tester.enterText(find.byType(TextField), '00000-0000001-0');
      await tester.tap(find.text('Break-glass access'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(BreakGlassDialog),
          matching: find.byType(TextField),
        ),
        'Unconscious patient, no consent obtainable.',
      );
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Record reason and open record'));
      await tester.pumpAndSettle();

      expect(controller.isBreakGlassAccess, isTrue);
      expect(controller.breakGlassEventCount, 1);

      await pumpDesktop(
        tester,
        controller,
        PatientClinicalRecordScreen(onNavigate: (_) {}),
      );
      expect(
        find.text('Opened with break-glass emergency access'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Unconscious patient'),
        findsOneWidget,
      );
    });
  });

  group('audit screen', () {
    testWidgets('shows the session events and says they are not durable',
        (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.emergencyPhysician);
      await controller.lookUpPatient('00000-0000001-0');

      await pumpDesktop(tester, controller, const ClinicalAuditScreen());

      expect(find.text('Patient record viewed'), findsOneWidget);
      expect(find.text('Staff session started'), findsOneWidget);
      expect(
        find.textContaining('session only'),
        findsOneWidget,
      );
    });

    testWidgets('highlights a break-glass entry with its reason',
        (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.emergencyPhysician);
      await controller.lookUpPatient(
        '00000-0000001-0',
        basis: RecordAccessBasis.breakGlass,
        breakGlassReason: 'Unconscious patient.',
      );

      await pumpDesktop(tester, controller, const ClinicalAuditScreen());

      expect(find.text('Break-glass access'), findsOneWidget);
      expect(find.text('Unconscious patient.'), findsOneWidget);
    });

    testWidgets('shows an empty state before anything is recorded',
        (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);

      await pumpDesktop(tester, controller, const ClinicalAuditScreen());

      expect(
        find.text('No access events have been recorded in this session.'),
        findsOneWidget,
      );
    });
  });
}

/// A synthetic demo case for ordering tests. No real record is reproduced.
EmergencyHandover _testHandover(String id, String triage, DateTime at) {
  return EmergencyHandover(
    emergencyId: id,
    patientId: 'DEMO-PAT-$id',
    paramedicId: 'PARA-001',
    ambulanceId: 'NEMRAS-AMB-001',
    destinationHospitalId: DemoHospitalIdentity.hospitalId,
    announcedAt: at,
    status: EmergencyCaseStatus.pending,
    isDemo: true,
    snapshot: HandoverClinicalSnapshot(
      patientLabel: 'DEMO $id',
      ageLabel: '40',
      gender: 'Female',
      bloodType: 'O+',
      medicalCondition: 'Asthma',
      chronicCondition: 'No',
      medication: 'None',
      allergy: 'None',
      drugInteractionRisk: 'No',
      triageLevel: triage,
      riskCategory: 'Stable',
    ),
  );
}

/// A repository returning a fixed list, for the sort test.
class _FixedHandoverRepository implements HandoverRepository {
  _FixedHandoverRepository(this.cases);

  final List<EmergencyHandover> cases;

  @override
  Future<List<EmergencyHandover>> fetchQueue({required String hospitalId}) =>
      Future<List<EmergencyHandover>>.value(cases);

  @override
  Future<EmergencyHandover> updateStatus({
    required String emergencyId,
    required EmergencyCaseStatus status,
    required String staffId,
  }) =>
      throw StateError('read-only');
}

/// A repository with nothing announced, for the empty-state test.
class _EmptyHandoverRepository implements HandoverRepository {
  @override
  Future<List<EmergencyHandover>> fetchQueue({required String hospitalId}) =>
      Future<List<EmergencyHandover>>.value(const <EmergencyHandover>[]);

  @override
  Future<EmergencyHandover> updateStatus({
    required String emergencyId,
    required EmergencyCaseStatus status,
    required String staffId,
  }) =>
      throw StateError('no cases');
}
